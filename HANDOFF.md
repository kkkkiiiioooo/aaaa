# HANDOFF
Estado atual (snapshot; reescreva ao fim de cada rodada, não faça append).
Histórico: `PROGRESS.md` (só o fim).
## Fase
E4 ativa (qoder, desde 2026-11-04T22:55Z). E1–E3 feitas.
- E2: 6/6 fabricantes, hash 17/17. `docs/evidence/drivers_lote.md`
- E3: `winpeshl.ini` [LaunchApps] + `autorun-wwii.cmd` + `diag.cmd` no
  `Winre.lote.wim`; teste `autorun_offline.py` PASS.
- E4 (andamento): ISO de boot gerada **do próprio WIM**, sem UUP/ADK —
  `scripts/montar_iso_winre.sh` → `.work/iso/winre-wwii.iso` 297 893 888 B,
  sha256 `11540227a70deb4dae12e47a254b2a7ca52308b916f00d1ccee29e872b66340e`.
  SeaBIOS+etfsboot carregam bootmgr (prova: `BOOTMGR;1` na raiz, `-boot-load-size 8`,
  sem `bootfix.bin`). `scripts/boot-winre.sh` dá boot e lê `wwii.log` pelo host (mtools).
  Evidência: `docs/evidence/boot_winre_iso.md`.
## Próximo passo
1. E4: terminar o run em andamento (disco de dados agora preso em `-hdb`) e
   anexar o conteúdo de `t:/wwii.log`; gate = "PE rodou o autorun sozinho e o
   log foi lido no host". Fechar com `etapa.sh fechar E4 <evidencia>`.
2. E4 pendência de prova visual: com `-display none` o `screendump` do QEMU 6.2
   devolve superfície inválida. Trocar por `-display vnc=127.0.0.1:1` no
   `boot-winre.sh` e manter `pmemsave 0xb8000` só para a fase de texto.
3. Transporte p0402452582: comandos curtíssimos (A2 PAN / recuperação / PXE).
4. Lead: unificar frentes 1–4 com E1–E6 via `relatorio.sh pergunta`.
## Premissas
- Hardware desconhecido: lote E2 cobre 6 fabricantes; PnP escolhe.
- Sandbox: 7 940 MB RAM, sem KVM → TCG puro `-smp 3 -m 4096`; o boot LZMS é
  lento (≥20 min para o PE chegar no autorun), por isso o autorun persiste o
  log a cada bloco em vez de só no fim.
## Riscos
- `wcmsvc.dll` ausente: `netsh wlan` pode falhar mesmo com driver. Plano B: A2 PAN.
- UEFI/OVMF neste QEMU não resolve o caminho do loader (`fw_cfg` gera opção de
  boot sem `Partition()`): três medidas, todas `No mapping`/`Not Found`. O
  caminho confiável hoje é BIOS + etfsboot.
## Bloqueios
- Nenhum depende do dono. p0423333970 (transporte/ambiente) registrado no board.
