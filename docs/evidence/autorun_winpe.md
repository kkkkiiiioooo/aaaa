# Evidência E3 — autorun no WinRE (offline)

**Agente:** stackai · **quando:** 2026-11-04 19:06 (UTC-3) · **etapa:** E3

O `winpeshl.ini` de fábrica só lança a GUI:

```
[LaunchApp]
AppPath=X:\sources\recovery\recenv.exe
```

`startnet.cmd` é só `wpeinit`. Substituído por `[LaunchApps]` (se os dois
existem, a MS ignora `LaunchApp`) para subir a pilha, o script e a GUI,
sem tecla.

## Arquivos

| no repo | no WIM |
|---|---|
| `scripts/winpeshl.ini` | `/Windows/System32/winpeshl.ini` |
| `scripts/autorun-wwii.cmd` | `/Windows/System32/autorun-wwii.cmd` |
| `scripts/diag.cmd` | `/Windows/System32/diag.cmd` |

`autorun-wwii.cmd`: `wpeinit` → `drvload` dos 6 INF da E2 → `diag.cmd` →
`pnputil`/`netsh wlan`/`ipconfig` → copia `X:\wwii.log` para C:..H: se
existirem. Sem `pause`/`findstr`/`powershell`/`certutil`.

## Verificação offline

```
python3 scripts/tests/unit/autorun_offline.py   # PASS ini + PASS cmd
sh scripts/injetar_autorun.sh --imagem .work/wim/Winre.lote.wim
# INJECAO AUTORUN VERIFICADA
# INI reextraido contem LaunchApps + autorun-wwii.cmd
```

## Aceite runtime (não fechado aqui)

O gate "PE inicia o script sozinho e grava log em disco" exige boot.
Este sandbox tem 1,9 GB RAM (doctor T3 pede ≥3 GB) e sem KVM. O aceite
de runtime fica na **E4** (ISO + QEMU, timeout alto, 2º plano). Offline
prova: o loader vai achar o INI e o cmd, e o cmd não depende de binário
ausente no 1809.
