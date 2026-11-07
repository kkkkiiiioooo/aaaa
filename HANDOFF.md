# HANDOFF
Snapshot (reescreva ao fim de cada rodada, sem histórico). Histórico: `PROGRESS.md` (só o fim). Última reescrita: 2026-11-07, reestruturador (claude-sonnet-5-5).

## Fase
E1–E3 feitas. **E4 INCONCLUSIVA** (5 boots reais, o PE nunca chegou ao autorun). Leases de E4 e E5 expiradas (reclamáveis). E6 livre.
- E2: 6 fabricantes, hash 17/17 (`docs/evidence/drivers-lote.md`).
- E3: só evidência offline (`winpeshl.ini` + `autorun-wwii.cmd` + `diag.cmd` no `Winre.lote.wim`, `autorun_offline.py` PASS). O runtime é a E4.
- E4: ISO gerada do próprio WIM (`scripts/montar_iso_winre.sh`), bootmgr carrega (SeaBIOS+etfsboot). Nenhum run chegou ao autorun: LZMS 232 s/1800 s, LZX 1159 s, raw 36 s (BSOD), XPRESS 425 s (BSOD). Run D6 (`-hda` + `-serial file:`): `serial.log` 0 bytes. Matriz em `docs/evidence/boot-winre-iso.md`.

## Fatos corrigidos (não refazer)
- `netsh wlan` provavelmente EXISTE: o helper é `wlancfg.dll` (hive NetSh + MUI), não `wlancmds.dll` (`docs/evidence/netsh-wlan-existe.md`). Falta só runtime.
- `wlansvc.dll` não importa `wcmsvc.dll`; ausência do WCM é tratada pelo serviço (p0402412842 resolvido).
- Bluetooth: 0 arquivos `bth` no WinRE, PAN só no Windows instalado (D4).
- Ambiente real da imagem (o que existe/falta, por nome): `docs/imagem/INVENTARIO.md`.

## Próximo passo (nesta ordem)
1. Não repetir TCG+CD de 1800 s. Mudar uma variável estrutural: transporte (USB/PXE; iPXE existe no QEMU) ou máquina real. Dossiê do lead: `casos/p0423333970.md` (branch `lider`).
2. Se o lead mandar repetir em TCG: gravar `info blockstats` e telas VNC em disco por run e testar `-cpu max` (`scripts/boot-winre.sh:107` fixa `qemu64`).
3. p0502061818: confirmar com o lead manter D1 (add profile + connect no autorun).
4. Toda proposta nova entra no mural: `sh scripts/mural.sh proposta "<ideia>" R1,R3 N0`. Antes de agir, `sh scripts/mural.sh ler`.

## Premissas
- Hardware do dono desconhecido: o lote E2 cobre 6 fabricantes, o PnP escolhe.
- Cada agente tem ambiente próprio (`ambientes/<nome>.md`); os de 1 CPU/4 GB não conseguem bootar o WinRE em TCG.
- `wimlib-imagex optimize --compress=None` é proibido: produz o caso que dá BSOD em 36 s.

## Riscos
- Chamar E3 de confirmada com evidência offline: o gate é runtime.
- UEFI/OVMF neste QEMU não acha o loader: caminho confiável é BIOS+etfsboot.
- BSOD com WIM `raw`/`XPRESS` sem causa medida; não gastar tempo aí antes de trocar de transporte.

## Bloqueios
- E4 depende de decisão do lead (qual transporte vale como aceite), não do dono.
