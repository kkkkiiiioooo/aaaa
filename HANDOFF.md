# HANDOFF
Estado atual (snapshot; reescreva ao fim de cada rodada, não faça append).
Histórico: `PROGRESS.md` (só o fim).
## Fase
E4 **INCONCLUSIVA** (liberada por qoder em 2026-11-05T02:00Z após esgotar a decisão D6 do
lead). E1–E3 feitas; E5 ativa (claude).
- E2: 6/6 fabricantes, hash 17/17. `docs/evidence/drivers_lote.md`
- E3: **só evidência offline** — `winpeshl.ini` [LaunchApps] + `autorun-wwii.cmd` + `diag.cmd`
  presentes no `Winre.lote.wim`, teste `scripts/tests/unit/autorun_offline.py` PASS. O runtime
  da E3 é a E4, e a E4 não confirmou nada.
- E4: ISO de boot gerada do próprio WIM (`scripts/montar_iso_winre.sh`) →
  `.work/iso/winre-wwii.iso` 299 253 760 B, sha256 `72081aba30786afd…` (LZMS). SeaBIOS+etfsboot
  carregam o bootmgr (prova: `BOOTMGR;1` na raiz, `-boot-load-size 8`, sem `bootfix.bin`), e o
  host lê o disco por mtools. Nada disso é o problema.
  O que **não** fecha: em 5 boots reais (LZMS 232 s/1800 s, LZX 1159 s, raw 36 s, XPRESS 425 s)
  o PE nunca chegou ao autorun. Dois casos morreram em BSOD
  `SYSTEM_THREAD_EXCEPTION_NOT_HANDLED` (`docs/evidence/e4-bsod-xpress-425s.png`), três nunca
  saíram da fase do bootmgr. Run do D6 (`-hda` + `-serial file:`): `serial.log` 0 bytes.
  Evidência completa: `docs/evidence/boot_winre_iso.md` (matriz + veredito).
## Próximo passo
1. **Não re-tentar o mesmo run TCG+CD de 1800 s** — já foi feito 1× pelo D6 e falhou. Quem
   pegar E4 tem que mudar uma variável estrutural: transporte (USB/PXE — iPXE existe neste QEMU,
   descoberta 10 da evidência) ou máquina real. Dossiê escalado: `casos/p0423333970.md`
   (branch `relatorio`).
2. Se o lead mandar repetir em TCG: gravar `info blockstats` e as telas VNC **em disco por run**
   (`.work/vm/` é sobrescrito; o run D6 perdeu essa medida) e testar `-cpu max` — o engolidor
   ainda fixa `qemu64` em `scripts/boot-winre.sh:107`.
3. E4 tem um bug de ambiente não resolvido: BSOD com WIM `raw` (36 s) e `XPRESS` (425 s), sem
   BSOD com LZMS/LZX. A correlação antiga ("é o descomprimido") está refutada; mecanismo não
   medido. Não gastar tempo aí antes de trocar de transporte.
4. Transporte p0402452582: comandos curtíssimos (A2 PAN / recuperação / PXE).
## Premissas
- Hardware desconhecido: lote E2 cobre 6 fabricantes; PnP escolhe.
- Sandbox: 7 940 MB RAM, sem KVM → TCG puro. O gargalo é o bootmgr descomprimindo o WIM em CPU
  (medido: 1 core em 100 % durante todo o run LZMS de 1800 s, CD lido 1×).
- `wimlib-imagex optimize --compress=None` está proibido: produz o caso que BSOD em 36 s.
## Riscos
- Afirmar E3 como "confirmada" a partir da evidência offline. Não está: o gate é runtime.
- `wcmsvc.dll` ausente: `netsh wlan` pode falhar mesmo com driver (p0402412842). Plano B: A2 PAN.
- UEFI/OVMF neste QEMU não resolve o caminho do loader (`fw_cfg` gera opção de boot sem
  `Partition()`): três medidas, todas `No mapping`/`Not Found`. Caminho confiável = BIOS+etfsboot.
## Bloqueios
- E4 depende de decisão do **lead** (qual transporte vale como aceite), não do dono. Pergunta
  objetiva registrada em `casos/p0423333970.md`.
