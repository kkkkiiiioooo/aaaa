# Drivers Broadcom do Mi Pad 2 (resumo)

## Estrutura

| Caminho | Origem | Versão | Conteúdo |
|---|---|---|---|
| `mipad2-oficial/wifi/` | Pacote OEM oficial do backup do Mi Pad 2 | 1.558.14.0 (2015-12-23) | 16 arquivos, 13,97 MB |
| `mipad2-oficial/bt-uart/` | Mesmo backup OEM | 12.0.1.731 (2015-09-10) | 31 arquivos, 4,0 MB |
| `estado-dispositivo/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` | Inbox do WinRE 1809 | 1.558.53.25 (2017-04-21) | 4 arquivos, 2,2 MB |
| `estado-dispositivo/bcmdhd64.inf_amd64_e0bae6831f60ea5f/` | Inbox do WinRE 1809 | 5.93.102.22 (2015-08-06) | 5 arquivos, 1,7 MB |
| `estado-dispositivo/bcmfn2.inf_amd64_5ebadf201c5b5845/` | Inbox do WinRE 1809 | 5.93.102.22 | 2 arquivos, 14 KB |
| `nvram-delta/` | nvram OEM renomeado para o driver | n/a | 1 arquivo, 5.361 bytes |

O estado do alvo é `estado-dispositivo/`. O pacote OEM é o payload de substituição, não o estado do alvo. O nvram não está no estado do alvo.

## Pacote Wi-Fi do alvo

A pasta `estado-dispositivo/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` tem exatamente:

- `bcmwdidhdpcie.inf`
- `bcmpciedhd63.sys`
- `4356a2rtecdc.bin`
- `43596a0rtecdc.bin`

Não tem nvram. O `43596a0rtecdc.bin` é do BCM4359 / `DEV_4355`; fica junto para manter a pasta idêntica ao DriverStore. A seção ativa do `DEV_43EC` usa o firmware `4356a2rtecdc.bin`.

O `SHA256SUMS` fica em `estado-dispositivo/SHA256SUMS`, um nível acima das pastas do DriverStore.

## Pacote OEM

`mipad2-oficial/wifi/oem25.inf` é a versão 1.558.14.0. A seção do `DEV_43EC` é `BCM43XAC_NT62_4356`. Ela copia:

- `bcmpciedhd63.sys`
- `4356r2rtecdc.bin` a partir de `4356a2rtecdc.bin`
- `4356r2nvram.txt` a partir de `bcm94356wlpagbl_P3_150828M.txt`

O pacote OEM inclui o catálogo `bcmpciedhd63.cat` e as DLLs IHV. O INF inbox não tem a linha do nvram nem catálogo.

## Conflito de versão

- Inbox: 2017-04-21, 1.558.53.25.
- OEM: 2015-12-23, 1.558.14.0.
- O Windows prefere o mais novo.
- Só instalar o pacote OEM não resolve; é preciso remover o inbox ou forçar o OEM.

## Detalhes medidos

- `bcmpciedhd63.sys` difere: inbox 1.037.824 bytes; OEM 1.041.320 bytes.
- O WinRE já tem o `.sys` inbox e o firmware `4356a2rtecdc.bin` no DriverStore, mas não o nvram.

## Origem

- OEM: https://github.com/brianwoo/mipad2-win10-howto, commit `8526424ca49d9077c16329f150fa176b88bd642e`.
- Inbox: WIM `winre-1809-254MB/`.
- nvram OEM SHA-256: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.

Documento canônico em inglês: `drivers/README.md`.