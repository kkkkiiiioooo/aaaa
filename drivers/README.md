# Drivers Broadcom do Mi Pad 2

Arquivos binários não devem ser colados no chat. Verifique-os com `sha256sum -c` e inspecione metadados com `wimlib-imagex` ou `objdump`.

> **Procedência:** verificada. Os arquivos "inbox do WinRE 1809" abaixo foram reconferidos contra
> `winre-1809-oficial-intacta/`, extraído do ESD oficial (`Core_en-us.esd`,
> 522.499.063 bytes, SHA-1 `8352af76…`). Os 11 arquivos das três pastas do DriverStore
> são idênticos byte a byte à extração derivada anterior; o WIM tem a mesma
> listagem de 21.230 caminhos. Veja `docs/06-auditoria-imagem-1809.md`.

## Layout

| Caminho | Origem | Versão | Conteúdo |
|---|---|---|---|
| `mipad2-oficial/wifi/` | Pacote OEM oficial do backup do Windows 10 do Mi Pad 2 | 1.558.14.0 (23/12/2015) | 16 arquivos, 13,97 MB. DEV 4355, 4364, 43A3, 43BA, 43C3, 43EC, 43EF, 440D |
| `mipad2-oficial/bt-uart/` | Mesmo backup OEM | 12.0.1.731 (10/09/2015) | 31 arquivos, 4,0 MB. Enumerador Bluetooth UART e firmware |
| `estado-dispositivo/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` | Inbox do WinRE 1809 | 1.558.53.25 (21/04/2017) | 4 arquivos, 2,2 MB. DEV 4355 e 43EC |
| `estado-dispositivo/bcmdhd64.inf_amd64_e0bae6831f60ea5f/` | Inbox do WinRE 1809 | 5.93.102.22 (06/08/2015) | 5 arquivos, 1,7 MB |
| `estado-dispositivo/bcmfn2.inf_amd64_5ebadf201c5b5845/` | Inbox do WinRE 1809 | 5.93.102.22 | 2 arquivos, 14 KB |
| `nvram-delta/` | Nvram OEM, renomeada para o caminho de busca do driver | n/d | 1 arquivo, 5.361 bytes |

O estado alvo é `estado-dispositivo/`. O pacote OEM não é o estado alvo; é a carga de substituição. A nvram não está no estado alvo.

## Estado Wi-Fi alvo

`estado-dispositivo/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` contém exatamente:

- `bcmwdidhdpcie.inf`
- `bcmpciedhd63.sys`
- `4356a2rtecdc.bin`
- `43596a0rtecdc.bin`

A pasta não tem nvram. O arquivo `43596a0rtecdc.bin` pertence à seção BCM4359 / `DEV_4355`. Ele fica na pasta porque o DriverStore alvo é mantido idêntico. A seção ativa `DEV_43EC` usa o firmware `4356a2rtecdc.bin`.

`SHA256SUMS` está em `estado-dispositivo/SHA256SUMS` e cobre os arquivos das três pastas do DriverStore. É um artefato do repositório, não um arquivo do DriverStore.

## Carga Wi-Fi OEM

`mipad2-oficial/wifi/oem25.inf` é a versão 1.558.14.0. A seção `DEV_43EC` é `BCM43XAC_NT62_4356`. A lista de cópia inclui:

- `bcmpciedhd63.sys`
- `4356r2rtecdc.bin` a partir de `4356a2rtecdc.bin`
- `4356r2nvram.txt` a partir de `bcm94356wlpagbl_P3_150828M.txt`

O pacote OEM inclui o catálogo `bcmpciedhd63.cat` e as DLLs IHV. O INF do inbox não inclui a linha de cópia da nvram e não inclui arquivo de catálogo.

## Conflito de versões

- Inbox: 21/04/2017, 1.558.53.25.
- OEM: 23/12/2015, 1.558.14.0.
- O Windows classifica o driver mais novo acima.
- Instalar o pacote OEM sem remover o pacote inbox não basta.
- A correção precisa remover o pacote inbox ou forçar o driver OEM.

## Detalhes medidos

- `bcmpciedhd63.sys` difere entre os pacotes: inbox 1.037.824 bytes; OEM 1.041.320 bytes.
- Carga Wi-Fi alvo para o `DEV_43EC`: `bcmpciedhd63.sys`, `4356a2rtecdc.bin`, nvram OEM, `oem25.inf`, `bcmpciedhd63.cat`, `bcmihvsrv64.dll`, `bcmihvui64.dll`.
- O INF do inbox não menciona nvram, `bcmihv*.dll` nem `CatalogFile`.
- A imagem do WinRE já contém o `.sys` inbox e o firmware `4356a2rtecdc.bin` no DriverStore, mas não a nvram.

## Origem e hashes

- Origem OEM: https://github.com/brianwoo/mipad2-win10-howto, commit `8526424ca49d9077c16329f150fa176b88bd642e`, arquivos `win10_drivers.7z.001..004`.
- A origem OEM é um backup DoubleDriver de um Windows 10 de fábrica build 10586. Isto é uma inferência, não confirmada independentemente.
- SHA-256 dos arquivos:
  - 001: `10c5b7dfa4c229f6e46a0473e131dd37832973a0b2945e85365998049906b7c3`
  - 002: `8445601afb505de97d23d4f2da25ccab3bb9ff091b73a227ac2b06f182b9198a`
  - 003: `884b82c033fb87cde6a3df9d190eb6197e49f1ebf12cf0bb129803578bd0ada6`
  - 004: `190004e186e0b6aefa4f29778f9affeebe85f3605e6433c799d2daf8456e4c22`
- Origem inbox: WinRE 1809 extraído do ESD oficial em `winre-1809-oficial-intacta/` (verificado); a cópia derivada anterior `winre-1809-254MB/` foi superada.
- SHA-256 da nvram OEM: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
