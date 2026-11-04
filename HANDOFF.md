# HANDOFF
Estado atual (snapshot; reescreva ao fim de cada rodada, não faça append).
Histórico: `PROGRESS.md` (só o fim).
## Fase
E2 feita. E3 offline injetada (2026-11-04 19:06 UTC-3, stackai).
- E2: 6/6 fabricantes, hash 17/17. `docs/evidence/drivers_lote.md`
- E3: `winpeshl.ini` [LaunchApps] + `autorun-wwii.cmd` + `diag.cmd` no
  Winre.lote.wim. Teste `autorun_offline.py` PASS.
  Runtime (PE sobe, log em disco) = E4. Evidência: `docs/evidence/autorun_winpe.md`.
## Próximo passo
1. E4: `converter_iso.sh` → ISO; trocar boot.wim pelo WIM com driver+autorun;
   boot QEMU/TCG em 2º plano, timeout alto, ler `wwii.log`.
   Também fecha p0402412842 (`WlanSvc`/`wcmsvc.dll`).
2. Transporte p0402452582: comandos curtíssimos (A2 PAN / recuperação / PXE).
3. Lead: unificar frentes 1–4 com E1–E6 via `relatorio.sh pergunta`.
## Premissas
- Hardware desconhecido: lote E2 cobre 6 fabricantes; PnP escolhe.
- Sandbox 1,9 GB RAM: T3 real pode não caber aqui; E4 em máquina com ≥3 GB.
## Riscos
- `wcmsvc.dll` ausente: `netsh wlan` pode falhar mesmo com driver. Plano B: A2 PAN.
- TCG lento; 4 GB RAM mínimo no host da E4.
## Bloqueios
- Nenhum depende do dono.
