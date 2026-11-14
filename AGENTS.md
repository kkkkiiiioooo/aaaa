# Agent Rules

Read these files before changing anything:

1. `GOAL.md`
2. `ANOTACOES-IMPORTANTES.md`
3. `docs/00-visao-geral.md`
4. `docs/01-restricoes.md`

## Hard constraints

- Do not use or assume USB, SD, Ethernet, a physical keyboard, or opening the device.
- Do not assume any file-transfer path from the device. The device can only show a screen and accept typed input.
- Do not use clipboard integration, shared folders, `-virtfs`, 9p, serial file transfer, or host-forwarded ports in QEMU.
- The only simulated external path is a local HTTP endpoint reachable through QEMU user-mode networking.
- WinRE provides `cmd` only. Do not assume PowerShell.
- Do not present a QEMU result as hardware proof.
- Do not claim the BCM4356 radio works unless it was verified on the physical device.

## Driver rules

- The target DriverStore state is under `drivers/estado-dispositivo/`.
- The target Wi-Fi folder is `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9`.
- The target state has four driver files and no nvram.
- The OEM package is under `drivers/mipad2-oficial/wifi/`.
- The nvram hypothesis is under `drivers/nvram-delta/`.
- Do not add the nvram to `drivers/estado-dispositivo/`.
- The 2017 inbox driver is `1.558.53.25`. The 2015 OEM driver is `1.558.14.0`.
- Windows prefers the newer driver. Remove the inbox package or force the older driver; adding the older package alone is insufficient.

## Modification rules

- Do not modify tracked WIM parts. Reassemble and modify copies under `qemu/work/` or `/tmp`.
- Back up any WIM before offline servicing.
- Prefer the offline servicing path. Use `pnputil` or `devcon` as fallback.
- Do not run destructive real-hardware commands without explicit user authorization.
- Do not commit generated WIMs, disk images, ISOs, logs, or secrets.
- Do not commit unless explicitly requested.

## Evidence rules

- Record commands, outputs, hashes, and timestamps.
- Use `experiments/templates/experimento.md`.
- Separate observed facts from hypotheses.
- Mark QEMU limitations explicitly.
- Update `ANOTACOES-IMPORTANTES.md` when a fact changes.

## Language

- English is canonical for agent-facing technical files.
- Portuguese is used for user-facing summaries and the glossary.
- Keep file names and script names in English.

## Scope

This repository is for assembling the challenge and its evidence. It is not a license to bypass the stated restrictions or to fabricate a successful recovery.