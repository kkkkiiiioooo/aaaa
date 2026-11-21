# Delta de nvram

> **Procedência:** verificada. As afirmações de "ausente da imagem" abaixo foram
> reconferidas em `winre-1809-oficial-intacta/`, extraído do ESD oficial
> (`Core_en-us.esd`, 522.499.063 bytes, SHA-1 `8352af76…`). O nome da nvram ocorre zero
> vezes na imagem. Veja `docs/06-auditoria-imagem-1809.md`.

## Propósito

Este diretório contém a menor carga de nvram de que o driver Broadcom pode precisar quando o pacote OEM de 2015 é usado.

`4356r2nvram.txt` é o arquivo de nvram OEM `bcm94356wlpagbl_P3_150828M.txt`, renomeado para o nome fixo que o driver procura.

- Tamanho: 5.361 bytes.
- SHA-256: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
- O arquivo é idêntico byte a byte à origem OEM.
- O arquivo não está presente no estado do DriverStore alvo.
- O arquivo não está presente em nenhum lugar da imagem WinRE 1809 (verificado na extração oficial: zero ocorrências).

## Evidência da busca do driver

Strings lidas do `bcmpciedhd63.sys` inbox mostram estes caminhos:

```text
\SystemRoot\system32\drivers\%04Xr%drtecdc.bin
\SystemRoot\system32\drivers\%04Xr%dnvram.txt
```

Para o dispositivo BCM4356 / `DEV_43EC`, os nomes resolvem para:

```text
\SystemRoot\system32\drivers\4356r2rtecdc.bin
\SystemRoot\system32\drivers\4356r2nvram.txt
```

A origem do firmware existe no DriverStore do WinRE como `4356a2rtecdc.bin`. A origem da nvram não existe na imagem.

Os INFs OEM e inbox concordam na renomeação do firmware:

```text
4356r2rtecdc.bin,4356a2rtecdc.bin,,6
```

Apenas o INF do OEM contém a renomeação da nvram:

```text
4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6
```

Essa linha ausente é o delta de nvram.

## Relação com a correção

O H2 é a hipótese primária: o driver inbox de 2017 é a regressão, e o pacote OEM de 2015 é a correção. O pacote OEM já contém a origem da nvram e a regra de cópia.

O H1 é secundário: se a nvram não for copiada pela instalação do driver, a nvram deve ser fornecida separadamente. O driver procura em `System32\drivers`.

A adição de driver por DISM offline prepara o pacote OEM no DriverStore offline. Não garante que a lista de cópia do INF rodou para o dispositivo. O `CopyFiles` real acontece durante a instalação PnP do dispositivo. No QEMU sem o BCM4356, só o preparo pode ser verificado.

## Aplicando só a nvram

Isto é um plano B, não a correção primária:

```bat
for %%D in (C D E F G H) do if exist %%D:\4356r2nvram.txt copy /Y %%D:\4356r2nvram.txt %SystemRoot%\System32\drivers\
pnputil /scan-devices
netsh wlan show drivers
```

Não assuma unidade USB, pasta compartilhada ou clipboard. A carga já precisa estar num volume local ou chegar pelo canal externo sob teste.

## O que confirmaria o H1

- `netsh wlan show drivers` lista o adaptador no dispositivo físico.
- `ConfigManagerErrorCode` vira `0`.
- O log do driver deixa de reportar `dongle nvram file download failed`.

O QEMU não pode confirmar o resultado do rádio. Pode confirmar que o arquivo está presente no caminho esperado e que o pacote de driver está preparado.

## O que confirmaria o H2

- O estado alvo mostra o driver inbox de 2017.
- A imagem offline mostra o driver OEM de 2015 depois da remoção do pacote inbox.
- O dispositivo físico inicia o adaptador com o driver de 2015.
- O mesmo dispositivo falha com o driver de 2017.

## Referências

- `drivers/README.md`
- `docs/03-driver-wifi-erro-10.md`
- `docs/05-offline-servicing.md`
