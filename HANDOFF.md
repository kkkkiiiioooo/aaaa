# HANDOFF
Estado atual (snapshot; reescreva ao fim de cada rodada, não faça append).
Histórico: `PROGRESS.md` (só o fim).
## Fase
E2 fechada (2026-11-04 19:03 UTC-3, stackai). Em paralelo ao desafio WinRE 1809.
- 6/6 fabricantes com `.cab` oficial do catálogo MS, INF MATCH, injetados no
  Winre.wim 17763, hash 17/17 IGUAL. Evidência: `docs/evidence/drivers_lote.md`.
- Parser INF agora lê UTF-16LE (regressão: `python3 scripts/tests/unit/inf_utf16.py`).
- WIM de trabalho local: `.work/wim/Winre.lote.wim` (274 MB, não versionado).
## Próximo passo
1. E3: autorun no WinRE — editar `winpeshl.ini` existente (`SetupCommandLine`),
   script único `drvload` + log em disco. Runtime real é E4; deixar o arquivo
   injetado e um teste offline do INI.
2. E4: ISO (`converter_iso.sh`) + boot PE em QEMU/TCG, timeout alto, 2º plano.
   Este é o teste de `WlanSvc`/`wcmsvc.dll` (p0402412842).
3. Transporte (p0402452582): entregável com comandos curtíssimos (A2 PAN /
   partição de recuperação / PXE). Ainda aberto.
4. Lead: PLANO usa frentes 1–4; ETAPAS usa E1–E6. Unificar via `relatorio.sh pergunta`.
## Premissas
- Hardware desconhecido: lote cobre Intel/Realtek/Qualcomm/Broadcom/MediaTek/Marvell.
- Runtime Wi-Fi (erro 10) exige adaptador real + talvez `wcmsvc.dll`.
## Riscos abertos
- T3 sem KVM: boot PE em TCG pode levar dezenas de minutos; RAM deste sandbox ~1,9 GB
  (abaixo do mínimo 3 GB do doctor para T3).
- `wcmsvc.dll` ausente no WinRE 1809: driver injetado é necessário, não suficiente.
## Bloqueios
- Nenhum depende do dono.
