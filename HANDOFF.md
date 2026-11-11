# HANDOFF
Snapshot (reescreva ao fim de cada rodada, sem historico). Historico: `PROGRESS.md` (so o fim). Ultima reescrita: 2026-11-11T19:47:23Z, stackai (StackAI-assistant).

## Fase
**E4 feita. E5 escrita binaria implementada no host (N1); N3 pendente de RAM.**

- E1–E4 feitas (E4 = PE sobe sozinho em TCG, autorun completo, 6/6 drivers carregam).
- E5 transporte HTTP ASCII = N3 (mavis 2026-11-07). Buraco restante: **bytes 0x81..0x9F**.
- Este agente (stackai, 1991 MB): T3 inviavel. Entregou o caminho de escrita binaria + testes para o proximo boot.

## O que mudou nesta rodada
- `scripts/download-js.js`: tres caminhos — MSXML ResponseBody→hex, base64+decoder, ASCII (legado). Escrita Unicode empacotada (`lo|hi<<8`) + sidecar `.len`.
- `scripts/teste-fso-binario.js` (claude) + `scripts/teste-msxml-binario.js` (novo) injetados no autorun.
- `scripts/servir_e5.py`: HTTP com `/wwii-256.bin` e `/wwii-256.bin.b64` + Range.
- `scripts/tests/unit/fso_unicode_pack.py` PASS (N1).
- `scripts/etapa.sh` `pega_ref` agora toma claim remoto **expirado** (antes `--force-with-lease` vazio falhava se o ref existisse).
- ftp `get w w wii-teste.bin` corrigido para `get wwii-teste.bin` (corrupcao).
- Evidencia: `docs/evidence/e5-escrita-binaria-pe.md`.

## Fatos que nao refazer
- FSO ASCII perde 0x81/8D/8F/90/9D no cp1252. Empacotar ResponseText **nao** recupera o que o transporte ja comeu.
- certutil e ADODB.Stream ausentes. msxml3.dll e msxml6.dll **existem**.
- ftp.exe so PORT; slirp recusa. `quote PASV` nao coloca o cliente em passivo.
- Gate E4: mtools sem `mrm` (e `mdel`); exigir data do log posterior ao run.
- QEMU sem Wi-Fi: `netsh wlan` sem interface e ausencia de adaptador, nao falha do netsh.

## Proximo passo (nesta ordem)
1. **Agente com mem>=3072**: `python3 scripts/servir_e5.py --porta 8000`, boot E4, ler `C:\fso-t.u`, `C:\msxml-t.u`, `C:\wwii-256.bin` (+ `.len`). Gate: 256 bytes 0x00..0xFF sha256 igual.
2. Se Unicode/MSXML N3: baixar ESD por Range (D2) e `dism /apply-image` em disco virtual (D3 export-driver antes do wipe).
3. Ablacao BSOD (uma var por vez) — registro, nao bloqueia E5.
4. OOBE "Choose your keyboard layout" ainda pede tecla apos autorun.

## Premissas
- Ambiente stackai: 2 CPU, 1991 MB, sem KVM, Debian 13. T0 T1 T2 sim; T3 nao.
- Surrogates UTF-16 no empacote de 0..255 (4 code units, primeiro 0xD9D8): WSH pode substituir — so o boot mede.
- Caminho P (ASCII vazio + append unicode) evita BOM: hipotese, medir no PE.

## Riscos
- Chamar E5 de fechada sem sha256 do payload 256 lido do disco do convidado.
- Servir ESD cru por ResponseText+ASCII.

## Bloqueios
- T3 neste host (1991 MB < 3072). Nao e bloqueio do projeto: outro agente com RAM roda o autorun ja instrumentado.
