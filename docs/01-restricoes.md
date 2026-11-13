# Restrictions

## Device restrictions

| Item | Rule |
|---|---|
| USB | Not allowed. Do not assume it exists or works. |
| SD card | Not allowed. |
| Ethernet | Not allowed. |
| Physical keyboard | Not allowed. |
| Opening the device | Not allowed. |
| Clipboard | Not allowed. |
| Shared folder | Not allowed. |
| Serial file transfer | Not allowed. |
| Host-forwarded ports | Not allowed in QEMU. |
| `-virtfs` / 9p | Not allowed in QEMU. |

## Allowed device channels

- Screen output.
- WinRE `cmd` input.
- Wi-Fi.
- Bluetooth.
- Touch.

The only external path in the challenge is a local HTTP endpoint reachable through QEMU user-mode networking. The only external path on the physical device is Wi-Fi, Bluetooth, or touch-driven input under the same no-data-transfer rule.

## WinRE restrictions

- WinRE provides `cmd` only.
- Do not assume PowerShell.
- Do not assume a full Windows installation.
- Do not assume `devcon` is present.
- Do not assume `curl`, `bitsadmin`, or `certutil` are present.
- `pnputil` may exist but its feature set depends on the WinRE build.
- WMIC may not exist in WinRE.

## QEMU restrictions

The harness must not expose host files or host services beyond the intended HTTP endpoint.

Forbidden:

- `-virtfs`
- 9p mounts
- shared folders
- `-netdev user,hostfwd=...`
- `-serial file:...`
- `-chardev file:...`
- clipboard integration
- hidden proxy or port forwarding

Allowed:

- OVMF UEFI firmware.
- KVM when available.
- A local HTTP server reached through QEMU user-mode NAT at `10.0.2.2`.
- A qcow2 disk created by the harness.
- A WinRE ISO or equivalent boot media created from the tracked WIM parts.

## Evidence restrictions

- Do not present QEMU output as hardware proof.
- Do not claim the radio works without a physical-device result.
- Do not claim success without the commands, output, hashes, and timestamps.
- Do not hide failed attempts or rollbacks.
- Do not commit generated images, logs, or secrets.

## Scope restrictions

This repository assembles the challenge. It does not authorize bypassing the constraints, fabricating a recovery, or attacking any third-party system.