# drivers/ — Broadcom do Mi Pad 2 (extraídos, sem compactar)

Binários: não abra no chat. Use `python3 scripts/listar_hwid.py`, `sha256sum -c SHA256SUMS` (em cada pasta) e `objdump`. `.gitattributes`: `drivers/** -text` (sem conversão de fim de linha).

| Pasta | Origem | Versão | Arquivos / bytes |
|---|---|---|---|
| `mipad2-oficial/wifi` | pacote oficial (GitHub) · `Net/Broadcom 802.11ac Wireless PCIE Full Dongle Adapter` | 1.558.14.0 (2015-12-23) | 16 / 13,97 MB · DEV 4355 4364 43A3 43BA 43C3 43EC 43EF 440D |
| `mipad2-oficial/bt-uart` | idem · `System/Broadcom Serial Bus Driver over UART Bus Enumerator` | 12.0.1.731 (2015-09-10) | 31 / 4,0 MB · ACPI\BCM2Exx + firmware .hcd |
| `winre-inbox/wifi-wdi-pcie` | Microsoft, já dentro do WinRE 1809 (`bcmwdidhdpcie.inf`) | 1.558.53.25 (2017-04-21) | 4 / 2,2 MB · DEV 4355 43EC |
| `winre-inbox/wifi-dhd64` | Microsoft, dentro do WinRE (`bcmdhd64.inf`) | 5.93.102.22 (2015-08-06) | 5 / 1,7 MB |
| `winre-inbox/bt-fn2` | Microsoft, dentro do WinRE (`bcmfn2.inf`) | 5.93.102.22 | 2 / 14 KB |

## Origem e hashes
- Oficial: https://github.com/brianwoo/mipad2-win10-howto commit `8526424ca49d9077c16329f150fa176b88bd642e`, `win10_drivers.7z.001..004` (extraído com `7z x`). É um backup do DoubleDriver (há `restore.ini` e `oem*.inf`) dos drivers do Windows 10 build 10586 de fábrica — inferência, não confirmada.
- sha256 dos volumes: 001=10c5b7dfa4c229f6e46a0473e131dd37832973a0b2945e85365998049906b7c3; 002=8445601afb505de97d23d4f2da25ccab3bb9ff091b73a227ac2b06f182b9198a; 003=884b82c033fb87cde6a3df9d190eb6197e49f1ebf12cf0bb129803578bd0ada6; 004=190004e186e0b6aefa4f29778f9affeebe85f3605e6433c799d2daf8456e4c22
- Só Wi-Fi e Bluetooth foram extraídos. O resto do pacote (display 448 MB, áudio, câmera, sensores) não ajuda a conectar e ficou de fora.
- Inbox: extraído de `subset-inspecao.tar.xz` (ramo `imagem`, sha256 024ba88c…); `git show origin/imagem:subset-inspecao.tar.xz | tar -xJ --wildcards '*bcmwdidhdpcie*'`.

## Medido
- Mesmo nome de driver nos dois: `bcmpciedhd63.sys` — inbox 1037824 B, oficial 1041320 B (versões diferentes).
- Conjunto do Wi-Fi para DEV_43EC/BCM4356: `bcmpciedhd63.sys` 1041320 B · `4356a2rtecdc.bin` 641951 B · `bcm94356wlpagbl_P3_150828M.txt` (nvram da placa) **5361 B** · `oem25.inf` 26.405 B · `bcmpciedhd63.cat` 16.636 B · `bcmihvsrv64.dll` 4.141.720 B · `bcmihvui64.dll` 3.770.008 B.
- O INF inbox não cita nvram, `bcmihv*.dll` nem `CatalogFile`; o oficial cita os três. O WinRE já tem o `.sys` e o firmware `4356a2rtecdc.bin`, mas não o nvram `.txt`.
