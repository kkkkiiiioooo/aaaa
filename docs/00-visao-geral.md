# Overview

## What this repository is

A challenge assembly for recovering a Xiaomi Mi Pad 2 that has only WinRE left on the recovery partition. The repository contains:

- The target Broadcom DriverStore state.
- The OEM 2015 package and the nvram hypothesis.
- The factory firmware recovery image, split into tracked parts.
- Documentation for the driver failure and the recovery paths.
- A QEMU harness specification and scripts.
- Experiment protocols and WinRE command sheets.

## What this repository is not

- It is not a full Windows installation image.
- It is not proof that the BCM4356 radio works.
- It is not a license to bypass the no-connection constraints.
- It is not a source of fabricated success.
- It is not the actual approximately 398 MB device recovery partition.

## The problem in one paragraph

The Mi Pad 2 has a BCM4356 PCIe Wi-Fi adapter (`PCI\VEN_14E4&DEV_43EC`). The target state contains the 2017 PCIe package `bcmwdidhdpcie.inf` version `1.558.53.25`, which is newer than the 2015 OEM driver `1.558.14.0`. The device reports error 10. The known workaround is to select the older OEM driver manually. Because the Windows driver rank prefers the newer package, the fix must remove the 2017 package or force the OEM package. The target state also lacks the board nvram. The OEM package contains the nvram source and the INF copy rule.

The factory firmware WIM does not contain `bcmwdidhdpcie.inf`. To test the driver conflict, the 2017 package must be injected into a copy of the firmware image. That produces a synthetic state, not the real recovery partition.

## Reading order

1. `GOAL.md`
2. `ANOTACOES-IMPORTANTES.md`
3. `AGENTS.md`
4. `docs/01-restricoes.md`
5. `docs/02-estado-do-dispositivo.md`
6. `docs/03-driver-wifi-erro-10.md`
7. `docs/04-fidelidade-mimetizacao.md`
8. `docs/05-offline-servicing.md`
9. `experiments/E0.1-firmware-baseline.md`
10. `experiments/README.md`

Portuguese glossary is planned.

## Status

- Repository assembly: in progress until validation passes.
- QEMU execution: not part of the scaffold.
- Hardware validation: pending and user-driven.
- Tracked image: factory firmware 10586 only.
- Working test: F2, a synthetic firmware image with the 2017 PCIe package injected.
- Default baseline: F1, the unmodified firmware image.

## Success path

1. Validate the repository and checksums.
2. Build the QEMU WinRE environment from the firmware image.
3. Reproduce the firmware baseline: no PCIe package, no nvram.
4. Inject the 2017 PCIe target package into a copy.
5. Remove the 2017 package and stage the OEM 2015 package.
6. Verify the 2015 driver and nvram source in the modified image.
7. Prove the 1 KB local HTTP channel in QEMU.
8. Validate the radio on the physical device with the checklist.

## Important limitations

QEMU does not emulate the BCM4356. It can prove that the driver package changed, that files were staged, and that the local HTTP channel works. It cannot prove that the radio starts, that error 10 disappears, or that Wi-Fi associates. Those are hardware checks.

The real approximately 398 MB recovery WIM is not available. The firmware WIM is 444,856,529 bytes, larger than that partition. It cannot replace `D:` as-is.

F2 is synthetic: it uses the firmware build 10586 plus an injected 2017 PCIe package. It is useful for driver mechanics, not as proof of the real partition contents.