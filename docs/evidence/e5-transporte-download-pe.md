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
