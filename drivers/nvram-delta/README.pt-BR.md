# Delta de nvram (resumo)

## O que é

`4356r2nvram.txt` é o nvram OEM `bcm94356wlpagbl_P3_150828M.txt`, renomeado para o nome fixo que o driver procura.

- Tamanho: 5.361 bytes.
- SHA-256: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
- Idêntico ao arquivo OEM.
- Não está no estado do alvo.
- Não está em lugar nenhum do WIM 1809.

## Evidência no driver

Strings do `bcmpciedhd63.sys` inbox mostram:

```text
\SystemRoot\system32\drivers\4356r2rtecdc.bin
\SystemRoot\system32\drivers\4356r2nvram.txt
```

O firmware existe no DriverStore como `4356a2rtecdc.bin`. O nvram não existe.

O INF OEM tem a linha:

```text
4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6
```

O INF inbox não tem. Essa é a diferença.

## Relação com o fix

- H2 (principal): o driver inbox de 2017 é a regressão; o pacote OEM de 2015 é o fix. O OEM já inclui o nvram.
- H1 (secundária): se o nvram não for copiado na instalação, ele precisa ser colocado em `System32\drivers`.

O DISM offline adiciona o pacote ao DriverStore, mas não garante que a lista de cópia do INF rodou. A cópia acontece na instalação PnP do dispositivo. No QEMU sem o BCM4356, só dá para verificar o staging.

## Aplicar só o nvram (fallback)

```bat
for %%D in (C D E F G H) do if exist %%D:\4356r2nvram.txt copy /Y %%D:\4356r2nvram.txt %SystemRoot%\System32\drivers\
pnputil /scan-devices
netsh wlan show drivers
```

Não assumir pendrive, pasta compartilhada ou clipboard. O arquivo precisa já estar em um volume local ou chegar pelo canal externo em teste.

## O que confirmaria

- H1: `netsh wlan show drivers` lista a interface no hardware; erro 10 vira 0; o log não mostra `dongle nvram file download failed`.
- H2: o alvo mostra o driver 2017; o WIM modificado mostra o 2015; o hardware sobe com o 2015 e falha com o 2017.

O QEMU não confirma o rádio. Confirma o arquivo no caminho e o pacote no DriverStore.

Documento canônico em inglês: `README.md`.