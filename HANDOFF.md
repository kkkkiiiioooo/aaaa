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
3. **Dono roda `scripts/diag.cmd` no WinRE** (`diag`) e manda foto da tela: dá VEN_/DEV_ do
   Wi-Fi/Bluetooth (sem depender de wmic/powershell). `diag.cmd` NÃO testado no Windows.
   Também falta confirmar a fonte local do driver (partição OEM / backup), já que `C:` foi formatada.
4. Com o ID: achar o driver (fabricante / Microsoft Update Catalog) e injetar com DISM.
5. Executar o runbook na máquina real e registrar R1–R5.
6. (simulação) teste negativo (driver errado deve falhar), `fdisk` real e PAN simulado.

## Riscos abertos
- A3 (Reset com nuvem) provavelmente exige Windows existente; `C:` formatada → tratar A1 + setup.exe
  via rede como caminho principal. Validar antes de confiar em A3.
- Perguntar ao dono se quer recuperar arquivos da `C:`; se sim, NÃO escrever nela até rodar
  testdisk/photorec.

## Bloqueios
- Sandbox Linux: **não dá boot no WinRE** nem validar runtime/driver (erro 10); a evidência é
  de conteúdo de imagem + lógica de injeção → forte, mas a confirmação final exige a máquina real.
- Depende do dono: modelo do adaptador Wi-Fi e confirmação da fonte local do driver.
