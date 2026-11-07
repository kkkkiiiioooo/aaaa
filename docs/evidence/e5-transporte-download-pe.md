# Evidência E5 (parte 1) — o transporte de download dentro do PE: HTTP chega, FTP escreve

**Agente:** mavis · **quando:** 2026-11-07 13:27–13:50 UTC · **etapa:** E5 (iniciada) · **modelo:** MiniMax-M3.1-Flash

## O que está medido

| # | alegação | prova |
|---|---|---|
| 1 | o PE **tem rede** dentro do QEMU | `ipconfig /all`: `IPv4 Address: 10.0.2.15`, `Default Gateway: 10.0.2.2`, `DHCP Server: 10.0.2.2`, MAC `52-54-00-00-04-04` (a e1000 do QEMU) |
| 2 | o **HTTP sai do PE e chega no servidor** | o `download.vbs` imprimiu `baixando: http://10.0.2.2:8000/wwii-teste.bin` e **não** deu erro de rede nem de status: o WinHttpRequest falou HTTP com o servidor |
| 3 | o **HTTP não consegue gravar** o arquivo no PE | `ERRO: ADODB.Stream indisponivel (falta WinPE-MDAC)` — o erro é na escrita, não na rede |
| 4 | o WinRE 1809 **tem `ftp.exe`** e ele grava binário | `/Windows/System32/ftp.exe` e `/Windows/System32/expand.exe` presentes na lista de caminhos da imagem (`docs/imagem/winre-caminhos.txt.gz`); `msdadodb.dll` (ADODB) **ausente** |

## O ponto que muda o D2 do lead

O plano do lead (D2) manda baixar o ESD por **HTTP (cscript+WinHttpRequest)**, com o plano B
sendo **FTP**. A medição inverte a ordem de preferência:

- **HTTP funciona na rede, mas não no disco.** O WinRE 1809 não tem `ADODB.Stream`
  (é o componente `WinPE-MDAC` que não está na imagem). Sem ele não há como gravar o
  corpo binário da resposta: `download.vbs` chegou ao passo da escrita e parou.
- **FTP está disponível e grava binário nativamente.** `ftp.exe` existe na imagem
  (`/Windows/System32/ftp.exe`), e o `ftp -s:arquivo` (o formato do plano B) roda sem
  qualquer componente extra.

O script `scripts/autorun-wwii.cmd` agora faz **os dois** (HTTP e FTP), cada um
registrando o resultado, para o próximo agente não ter que escolher no escuro.

## O que foi provado no emulador

Servidor no host (QEMU slirp expõe o host em `10.0.2.2`):

```sh
python3 -m http.server 8000 --bind 0.0.0.0   # HTTP (D2 caminho principal)
/usr/sbin/vsftpd /tmp/vsftpd.conf            # FTP  (D2 plano B), anonimo, read-only
```

Os dois foram conferidos do host antes do boot (`curl http://127.0.0.1:8000/...` e
`curl ftp://127.0.0.1/...` devolveram os 5020 bytes idênticos ao arquivo).

## Pendências honestas

- O ESD (o que a E5 realmente baixa) são gigabytes: o transporte foi provado com um
  arquivo pequeno. Falta medir a retomada por `Range` (o plano do lead) e o tamanho real.
- `expand.exe` (também presente) permite a variante "baixa o .cab por HTTP e extrai" —
  não testada.
- Continua valendo: **o QEMU não tem hardware Wi-Fi**, então a rede aqui é a
  emulada (e1000). Na máquina do dono o caminho é o mesmo script com outra NIC.

## O FTP (plano B do lead): login e modo binário OK, o **canal de dados** é que não fecha

```
ftp> open 10.0.2.2
Connected to 10.0.2.2.
220 (vsFTPd 3.0.3)
ftp> user anonymous anonymous
230 Login successful.
ftp> binary
200 Switching to Binary mode.
ftp> get w w wii-teste.bin C:\wwii-ftp.bin
500 Illegal PORT command.
425 Use PORT or PASV first.
```

Ou seja: **o PE fala FTP** (conecta, autentica, muda para binário) — o que falha é só a
conexão de dados. O `ftp.exe` do WinRE 1809 usa modo **ATIVO** (`PORT`) e **não tem switch
de modo passivo** nessa versão (a tela de uso lista só `-v -d -i -n -g -s: -a -A -x: -r:
-b: -w:`; `-p` **não existe** — usá-lo faz o cliente imprimir o usage e sair).

Modo ativo é justamente o que **não funciona atrás de NAT** (e o QEMU slirp é NAT): o
servidor tenta abrir a conexão de dados para o IP que o cliente mandou, que não existe
na rede do servidor. Do lado do servidor, permitir `PORT` de qualquer endereço
(`pasv_promiscuous=YES`) **não** resolveu (medido): o problema é o caminho, não a
política.

**Consequência prática:** com o `ftp.exe` do WinRE 1809, o download só funciona se o
servidor aceitar **PASV**. Três caminhos para a E5:

1. um cliente FTP que faça PASV dentro do PE (o `msftp.dll`/`ftp.exe` do WinRE não tem
   switch; um script JScript que implemente o PASV na mão é possível — o WinRE tem
   `wscript`/`cscript` e o Winsock dá a conexão);
2. `expand.exe` (existe na imagem): o servidor entrega um **.cab** e o PE extrai —
   ainda depende de gravar o .cab, que é o mesmo problema;
3. **injetar o MDAC** (`msdadodb.dll` e companhia) na imagem, para o `download.vbs`
   funcionar como está.

## O downloader em JScript (3ª via): o que o PE tem e o que ele não tem

`scripts/download-js.js` tenta, dentro do PE:

1. `WinHttp.WinHttpRequest.5.1` → `ResponseBody` (VBArray de bytes);
2. `MSXML2.XMLHTTP` (`msxml3.dll` **existe** na imagem) → `responseText`;
e grava com `Scripting.FileSystemObject` em modo ASCII (1 caractere = 1 byte).

Medido: **o `ResponseBody` do WinHttpRequest no JScript do WinRE vem `null`** ("VBArray
expected" ao envelopar; `body.length` nulo), e o `responseText` do MSXML devolve texto
(perde os bytes > 127). O FSO em modo ASCII grava byte a byte, **exceto** os bytes
`0x81..0x9F`, que não têm representação no cp1252 e saem como `?` — para um ESD
assinado isso corrompe o arquivo.

**Resumo do estado do transporte (medido, não suposto):**

| caminho | rede | escrita em disco | nota |
|---|---|---|---|
| HTTP + `download.vbs` (VBS/ADODB) | **OK** (o PE chega no servidor) | **falta** (não há ADODB.Stream) | primitivo ausente na imagem |
| HTTP + `download-js.js` (JScript) | **OK** | funciona, com perda em 31 valores de byte | `ResponseBody` vem nulo no JScript |
| FTP (`ftp.exe`) | **OK** (login + binário) | **falta** (modo ativo x NAT) | não há switch de PASV |
| SMB + `xcopy` | não testado | não testado | `xcopy.exe` e o serviço Workstation existem na imagem |
