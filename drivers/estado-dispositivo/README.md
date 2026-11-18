# Estado do dispositivo alvo

Este diretório é um retrato do estado do DriverStore da Broadcom na imagem WinRE 1809. Não é o pacote OEM e não é uma hipótese.

> **Procedência:** verificada. O retrato foi reconferido contra
> `winre-1809-oficial-intacta/`, extraído do ESD oficial (`Core_en-us.esd`,
> 522.499.063 bytes, SHA-1 `8352af76…`). Os 11 arquivos são idênticos byte a byte à
> extração derivada anterior. Veja `docs/06-auditoria-imagem-1809.md`.

## Nomes exatos de pastas do DriverStore

| Pasta | Arquivos |
|---|---|
| `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` | 4 |
| `bcmdhd64.inf_amd64_e0bae6831f60ea5f/` | 5 |
| `bcmfn2.inf_amd64_5ebadf201c5b5845/` | 2 |

## Pacote Wi-Fi

`bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/`:

- `bcmwdidhdpcie.inf`
- `bcmpciedhd63.sys`
- `4356a2rtecdc.bin`
- `43596a0rtecdc.bin`

A pasta não tem arquivo de nvram.

O arquivo `43596a0rtecdc.bin` pertence à seção BCM4359 / `DEV_4355`. Ele permanece na pasta porque o DriverStore alvo é mantido idêntico. A seção `DEV_43EC` usa `4356a2rtecdc.bin`.

## Pacotes SDIO

`bcmdhd64.inf_amd64_e0bae6831f60ea5f/`:

- `bcmdhd64.inf`
- `bcmdhd63.sys`
- `43241b4rtecdc.bin`
- `4324b5rtecdc.bin`
- `43341b0rtecdc.bin`

`bcmfn2.inf_amd64_5ebadf201c5b5845/`:

- `bcmfn2.inf`
- `bcmfn2.sys`

## Checksums

`SHA256SUMS` é um artefato do repositório neste nível. Ele cobre os arquivos de driver com caminhos relativos. Não é copiado para dentro de uma pasta do DriverStore.

## Origem

Extraído de `winre-1809-oficial-intacta/` (ESD oficial), índice de imagem 2, caminho `Windows/System32/DriverStore/FileRepository/`. Procedência verificada: os 11 arquivos são idênticos byte a byte à extração derivada anterior em `winre-1809-254MB/`.

Os nomes exatos das pastas foram lidos com `wimlib-imagex dir`.

## O que este estado significa

- O pacote Wi-Fi é o pacote inbox de 2017, versão 1.558.53.25.
- O estado alvo não contém a nvram da placa.
- O estado alvo é a linha de base quebrada. O pacote OEM é a carga de correção.
- Não adicione a nvram aqui. Use `drivers/nvram-delta/` ou o pacote OEM.
- Não trate este retrato como a partição de recuperação completa de 398 MB. É apenas o subconjunto de drivers Broadcom.
