# Mi Pad 2 Windows Recovery Challenge

This repository is a reproducible, multi-agent challenge for a specific recovery problem:

- Xiaomi Mi Pad 2, x64, Windows 10 build 17763.
- `C:` was quick-formatted.
- The only remaining Windows environment is the recovery partition on `D:`.
- The device has no USB, SD, Ethernet, or physical keyboard connection.
- The available input/output channels are the screen, the recovery command prompt, Wi-Fi, Bluetooth, and touch.
- The Wi-Fi adapter reports error 10 after the 2017 PCIe package is used.

The repository does not contain a full Windows installation image. The only tracked WIM is the factory firmware recovery image. The repository assembles the evidence, the target driver state, a QEMU harness, and experiment protocols so agents can reproduce the software path before anyone claims a hardware result.

## Status

- Repository scaffolding is the current deliverable.
- The factory firmware WIM is the only tracked image. It lacks `bcmwdidhdpcie.inf` and cannot reproduce error 10 by itself.
- The working test injects the 2017 PCIe target package into a copy of the firmware WIM. That is a synthetic state, labeled F2.
- The QEMU harness is specified but has not been executed as part of this scaffold.
- The BCM4356 radio cannot be emulated by QEMU. The harness proves driver and file mechanics, not the hardware error 10.
- The actual approximately 398 MB recovery WIM from the device is not available.

## Key facts

- The broken state is the 2017 PCIe package `bcmwdidhdpcie.inf`, version `1.558.53.25`.
- The known-good package is the 2015 OEM driver `oem25.inf`, version `1.558.14.0`.
- Windows prefers the newer driver. Replacing the package alone is not enough; the 2017 package must be removed or the older driver must be forced.
- The target DriverStore state does not contain the board nvram file.
- The OEM package contains the nvram source file. The nvram is a separate payload, not part of the target state.
- The firmware WIM has bcmdhd, bcmdhd64, bcmfn2, and bcmfn packages, but no `bcmwdidhdpcie.inf`.
- The device cannot send files out. The challenge must not assume clipboard, shared folders, USB, or any other data-transfer channel.

## Repository map

| Path | Purpose |
|---|---|
| `GOAL.md` | Mission, constraints, milestones, and acceptance criteria. |
| `ANOTACOES-IMPORTANTES.md` | Canonical facts and evidence for agents. |
| `AGENTS.md` | Operating rules for agents. |
| `drivers/` | Target DriverStore state, OEM packages, and nvram hypothesis. |
| `winre-fabrica-10586-424MB/` | Factory firmware WIM split into tracked parts. |
| `docs/` | Technical explanations and runbooks. |
| `qemu/` | QEMU harness design and scripts. |
| `experiments/` | Reproducible experiment protocols. |
| `scripts/` | Host validation and WinRE command sheets. |

## Reading order

1. `GOAL.md`
2. `ANOTACOES-IMPORTANTES.md`
3. `AGENTS.md`
4. `docs/00-visao-geral.md`
5. `docs/01-restricoes.md`
6. `docs/02-estado-do-dispositivo.md`
7. `docs/03-driver-wifi-erro-10.md`
8. `docs/04-fidelidade-mimetizacao.md`
9. `docs/05-offline-servicing.md`
10. `experiments/E0.1-firmware-baseline.md`
11. `experiments/README.md`

Portuguese entry point: `README.pt-BR.md`.

## Safety and scope

- Do not connect the device to USB, SD, Ethernet, or a physical keyboard.
- Do not assume any file-transfer path from the device.
- Do not describe a QEMU result as hardware proof.
- Do not modify tracked WIM parts. Work on copies under `qemu/work/` or `/tmp`.
- Do not commit generated WIMs, disk images, ISOs, logs, or secrets.
- Do not commit unless explicitly requested.

## Next step

Review `experiments/E0.1-firmware-baseline.md` for the firmware inventory. After tools are installed, validate the repository with `scripts/verify-repo.sh`. The QEMU experiments are defined in `experiments/` and must be run separately.