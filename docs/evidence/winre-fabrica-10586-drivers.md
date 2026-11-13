# Drivers dentro do Winre.wim de fábrica (10586) — MEDIDO 2026-11-13

Arquivo: `imagens/winre-fabrica-10586-424MB/winre-fabrica-10586.wim` (444 858 791 B, sha256 152addc4…067a). Comando: `wimlib-imagex dir <wim> 1` (26 461 caminhos) + `extract` só dos INFs.

| INF no WinRE | HWID (SDIO) | Chip | Nota |
|---|---|---|---|
| `bcmdhd.inf` (+ `bcmdhd63.sys`, `43241b4rtecdc.bin`) | `SD\VID_02D0&PID_4324` | BCM4324 | Wi-Fi SDIO |
| `bcmdhd64.inf` (+ `bcmdhd64.sys`, `43341b0rtecdc.bin`) | `SD\VID_02D0&PID_A94C/A94D` | BCM43341 | Wi-Fi SDIO |
| `bcmfn.inf` / `bcmfn2.inf` | idem | — | Bluetooth (função 2) |

- Alvo: Mi Pad 2 = BCM4356, **PCIe `DEV_43EC`**. Nenhum INF do WinRE de fábrica cobre PCIe 14E4.
- Ausentes: `bcmpciedhd63.sys`, `4356a2rtecdc.bin`, nvram `.txt`, `bcmihv*.dll`, `bcmwdidhdpcie.inf`, `oem25.inf`. (Os 15 casos de "43ec/4356" na busca por caminho são hashes em nomes de WinSxS — falso positivo.)
- Conclusão: o WinRE de fábrica **não tem** driver Wi-Fi do alvo (nem parcial). Diferente do WinRE 1809, que tem `bcmwdidhdpcie.inf` (DEV 4355/43EC) inbox, mas sem nvram nem `bcmihv*.dll` (ver `drivers/README.md`).
- O Windows instalado de fábrica tem o conjunto completo (14/14 idêntico a `drivers/mipad2-oficial/wifi`, ver `docs/MEMORIA.md`).
