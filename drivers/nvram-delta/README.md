# nvram-delta — o menor delta para o erro 10 do Wi-Fi no WinRE (front 0b)

## O que é

`4356r2nvram.txt` (5361 B) = `bcm94356wlpagbl_P3_150828M.txt` do pacote oficial
(sha256 `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`),
renomeado para o **nome fixo que o driver procura**.

## Prova (N2, lida do binário `bcmpciedhd63.sys` do próprio WinRE 1809)

O driver monta os caminhos com formato, sem registrar em lugar nenhum:

```
\SystemRoot\system32\drivers\%04Xr%drtecdc.bin   ->  4356r2rtecdc.bin  (firmware: EXISTE no WinRE)
\SystemRoot\system32\drivers\%04Xr%dnvram.txt    ->  4356r2nvram.txt  (nvram: NÃO EXISTE no WinRE)
```

Strings literais no binário (medido com grep no `.sys`, 2026-11-12):
`firmware path=%s, nvram path=%s` · `dhd_bus_download_firmware() failed` ·
`dongle nvram file download failed`. Sem o nvram, `dhd_bus_download_firmware()`
falha → o adaptador não sobe → **erro 10**. O `.sys` e o firmware
(`4356a2rtecdc.bin`, renomeado para `4356r2rtecdc.bin` pelo próprio INF inbox na
instalação) estão no FileRepository
`/Windows/System32/DriverStore/FileRepository/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/`
— verificado no WIM: **0 arquivos nvram.txt na imagem inteira**.

O nome `4356r2` é consistente entre INF oficial e inbox:
`4356r2rtecdc.bin,4356a2rtecdc.bin,,6` (renomeio do CopyFiles) e
`4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6` (só o oficial; o inbox não tem
essa linha — é exatamente o delta).

## Como aplicar na máquina real (WinRE, cmd do autorun; ~2 linhas)

O arquivo pode vir de QUALQUER volume (pendrive não é necessário; pode entrar pelo
canal teclado/tela da E6 ou já estar numa partição local):

```bat
for %%D in (C D E F G H) do if exist %%D:\4356r2nvram.txt copy /Y %%D:\4356r2nvram.txt %SystemRoot%\System32\drivers\
pnputil /scan-devices
netsh wlan show drivers
```

O `autorun-wwii.cmd` desta branch já faz esse passo sozinho (seção "nvram delta").

## O que falta para CONFIRMADO

- `netsh wlan show drivers` listando a interface **na máquina real** (D5 do lead) —
  a VM QEMU não tem chip BCM4356, então aqui só prova a mecânica (copy + scan),
  não o erro 10.
- Se `4356r2nvram.txt` não bastar, capturar o código do adaptador: o driver loga
  em `DbgPrint`/WPP — no WinRE sem depurador, o caminho é o próprio
  `netsh wlan show drivers` + Device Manager equivalente do Windows instalado.
