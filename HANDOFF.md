# HANDOFF

Estado atual (snapshot; reescreva ao fim de cada rodada — não append).

## Fase
Evidência real obtida: o WinRE do **Windows 10 Home 1809 (build 17763.9376)** foi inspecionado
(conteúdo da imagem, não documentação). Solução A1+A3 confirmada e **runbook corrigido**.
Base pronta em `scripts/` (kit reutilizável por outros agentes). Remoto: `0`, `4.4mmii1`,
`backup`, `main`.

## Descobertas que mudam o plano
- `netsh wlan` **existe** no WinRE 1809 (`netshell.dll` + `wlancfg.dll` + pilha WLAN completa)
  → **não** é preciso o WinPE-WiFi-Package do ADK.
- **`certutil.exe` e `powershell.exe` não existem** no WinRE 1809 → o download da ISO (R3)
  precisa de outra via: `net use` (SMB), VBScript com `WinHttpRequest`/`MSXML2.XMLHTTP`
  (DLLs presentes) ou `ftp.exe`.
- Só **um** driver Wi-Fi de fabricante vem embutido (`mrvlpcie8897`) → **A1 (injetar driver
  via `dism.exe`, que está presente) continua sendo o passo 1**.
- Detalhes e comandos: `docs/evidence/winre_1809_evidencia.md`.

## Próximo passo
1. ~~Validar a injeção de driver offline~~ **FEITO**: `Winre.wim` exportado e `.inf` de teste
   injetado com sucesso (`/Windows/INF/wifiteste.inf` visível na imagem). Ver
   "Validação offline executada" em `docs/evidence/winre_1809_evidencia.md`.
2. ~~Artefatos de download~~ **FEITO**: `scripts/download.vbs` (HTTP via cscript) e
   `scripts/download_ftp.txt` (ftp.exe) versionados no kit.
3. Falta do dono: **modelo do adaptador Wi-Fi** (para copiar o driver correto) e confirmação
   de onde está a fonte local do driver (partição de recuperação OEM / backup).
4. Com isso, executar o runbook na máquina real e registrar R1–R5.

## Bloqueios
- Sandbox Linux: **não é possível dar boot no WinRE** nem validar runtime/driver (erro 10).
  A evidência é de conteúdo de imagem — forte o bastante para eliminar as incógnitas do
  plano, mas a confirmação final exige a máquina real.
- Ainda depende do dono: **modelo do adaptador Wi-Fi** (para escolher/copiar o driver) e
  confirmação de que existe fonte local do driver (partição de recuperação OEM), já que `C:`
  foi formatada.
