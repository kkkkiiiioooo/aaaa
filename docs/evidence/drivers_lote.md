# Evidência E2 — um .cab oficial por fabricante, INF conferido, injetado, hash

**Agente:** stackai · **quando:** 2026-11-04 19:03 (UTC-3) · **etapa:** E2
**Método:** execução real, sem mock. Catálogo Microsoft Update → `.cab` → INF
(UTF-16LE e ASCII) → `wimlib-imagex update` no WinRE 1809 → reextrair e
comparar sha256.

```
python3 scripts/buscar_driver.py lote --tabela scripts/drivers-1809.tsv
sh scripts/obter_imagem.sh --wim
sh scripts/injetar_driver.sh --imagem .work/wim/Winre.lote.wim --driver .work/drivers/<fab>/extracted
python3 scripts/tests/unit/inf_utf16.py   # PASS
```

## 1. Catálogo — 6/6 fabricantes

| fab | HWID | pacote (catálogo) | cab bytes | INF |
|---|---|---|---:|---|
| intel | `PCI\VEN_8086&DEV_24FD` (AC 8265) | Intel - net - 22.200.0.6 | 3 192 701 | Netwtw06.INF MATCH |
| realtek | `PCI\VEN_10EC&DEV_B822` (RTL8822BE) | Realtek - Net - 2024.0.10.137 | 2 877 544 | netrtwlane.inf MATCH |
| qualcomm | `PCI\VEN_168C&DEV_003E` (QCA6174) | Qualcomm Atheros - Net - 12.0.0.1272 | 2 043 180 | netathr10x.inf MATCH |
| broadcom | `PCI\VEN_14E4&DEV_4365` (BCM4365) | Broadcom - Net - 7.35.352.0 | 8 670 650 | bcmwdi.inf MATCH |
| mediatek | `PCI\VEN_14C3&DEV_7961` (MT7921) | MediaTek Net 3.0.1.1338 | 1 172 824 | mtkwl6ex.inf MATCH |
| marvell | `PCI\VEN_11AB&DEV_2B38` (88W8897) | Marvell - Net - 15.68.17022.122 | 642 650 | mrvlpcie8897.inf MATCH |

URLs oficiais `catalog.s.download.windowsupdate.com`. Cache em `.work/driver-cache/`
(retomável). Tabela: `scripts/drivers-1809.tsv`.

## 2. Regressão do parser INF

A primeira passagem marcou intel/realtek/mediatek como "CAB-SEM-MATCH": os INF
do catálogo são **UTF-16LE** (BOM `FF FE`), e `inf_hardware_ids` lia UTF-8.
Corrigido (mesmo critério de `listar_hwid.py`). Teste:

```
python3 scripts/tests/unit/inf_utf16.py
PASS: UTF-16 INF casou
PASS: negativo ok
```

## 3. Injeção no Winre.wim 17763

Imagem: branch `imagem` remontada (`obter_imagem.sh --wim`), sha256
`f9e30ca308aa23e83d852ccefcfe7bca09a23d7c5b759ae655557612487879b8`,
Boot Index 1, 254 MB → 274 MB após os 6 pacotes.

| caminho na imagem | origem |
|---|---|
| `/Windows/INF/netwtw06.inf` + `NETwtw06.sys` | intel |
| `/Windows/INF/netrtwlane.inf` + `rtwlane.sys` | realtek |
| `/Windows/INF/netathr10x.inf` + `Qcamain10x64.sys` | qualcomm |
| `/Windows/INF/bcmwdi.inf` + `bcmwl63.sys` | broadcom |
| `/Windows/INF/mtkwl6ex.inf` + `mtkwl6ex.sys` | mediatek |
| `/Windows/INF/mrvlpcie8897.inf` + `mrvlpcie8897.sys` | marvell |

## 4. Hash byte a byte (reextrair)

| fab | arquivo | orig16 | reex16 |
|---|---|---|---|
| intel | Netwtw06.INF | 6d0f38841ac3ac4b | 6d0f38841ac3ac4b |
| intel | NETwtw06.sys | 9b215b9dfc971288 | 9b215b9dfc971288 |
| realtek | netrtwlane.inf | e6cb49df40dd206f | e6cb49df40dd206f |
| realtek | rtwlane.sys | 1f92f949aabf6354 | 1f92f949aabf6354 |
| qualcomm | netathr10x.inf | 10016b46de41d79c | 10016b46de41d79c |
| qualcomm | Qcamain10x64.sys | 0931b68d8c13f79f | 0931b68d8c13f79f |
| broadcom | bcmwdi.inf | 2594a0a42a46d98b | 2594a0a42a46d98b |
| broadcom | bcmwl63.sys | a32c39030a251f64 | a32c39030a251f64 |
| mediatek | mtkwl6ex.inf | 70f2012778169aff | 70f2012778169aff |
| mediatek | mtkwl6ex.sys | 5394de8902fffbe8 | 5394de8902fffbe8 |
| marvell | mrvlpcie8897.inf | 327a15175bcc03ad | 327a15175bcc03ad |
| marvell | mrvlpcie8897.sys | b4aa190f4a45a7ae | b4aa190f4a45a7ae |

**17/17 IGUAL, 0 DIFERE.** Gate E2 cumprido.

## 5. Limite (não é falha da E2)

- `wimlib-imagex update` grava arquivos; não registra o driver no hive.
  Na máquina real o passo continua `dism /Add-Driver` ou `drvload`.
- Runtime (erro 10, `WlanSvc`/`wcmsvc.dll`) é E4. Hipótese p0402412842
  permanece: driver sozinho pode não bastar.
- Hardware do dono desconhecido: PnP escolhe entre os 6 fabricantes.

## Reproduzir

```sh
python3 scripts/buscar_driver.py lote
sh scripts/obter_imagem.sh --wim
for f in intel realtek qualcomm broadcom mediatek marvell; do
  sh scripts/injetar_driver.sh --imagem .work/wim/Winre.lote.wim \
      --driver .work/drivers/$f/extracted
done
python3 scripts/tests/unit/inf_utf16.py
```
