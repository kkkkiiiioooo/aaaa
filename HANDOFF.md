# HANDOFF

Estado atual (snapshot; reescreva ao fim de cada rodada — não append).

## Fase
Duas frentes convergentes:
- **WinRE 1809 inspecionado** (conteúdo de imagem, não documentação): `netsh wlan` **existe**
  (dispensa WinPE-WiFi-Package); `certutil.exe`/`powershell.exe` **não** existem (download de
  ISO via `net use`/VBScript/`ftp.exe`); só um driver Wi-Fi de fábrica embutido (`mrvlpcie8897`).
  Solução A1+A3 confirmada e runbook corrigido. Detalhes: `docs/evidence/winre_1809_evidencia.md`.
- **Ambiente de teste QEMU** montado e verde: `scripts/` (env-setup, fetch-base,
  build-initramfs, run-vm) + `tests/`; suíte 6/6 PASS em TCG (sem KVM). Evidência em
  `docs/evidence/ambiente-teste.md`. Remoto: `0`, `4.4mmii1`, `backup`, `main`.

## Próximo passo
1. Validar injeção de driver offline no `Winre.wim` → **FEITO** (`.inf` de teste visível na imagem).
2. Artefatos de download (`scripts/download.vbs`, `scripts/download_ftp.txt`) → **FEITO**.
3. Falta do dono: **modelo do adaptador Wi-Fi** + confirmação da fonte local do driver
   (partição de recuperação OEM / backup), já que `C:` foi formatada.
4. Executar o runbook na máquina real e registrar R1–R5.
5. (simulação) evoluir a suíte: particionamento real (`fdisk`) e cenário de PAN simulado.

## Bloqueios
- Sandbox Linux: **não dá boot no WinRE** nem validar runtime/driver (erro 10); a evidência é
  de conteúdo de imagem + lógica de injeção → forte, mas a confirmação final exige a máquina real.
- Depende do dono: modelo do adaptador Wi-Fi e confirmação da fonte local do driver.
