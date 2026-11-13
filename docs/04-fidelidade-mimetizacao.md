# Fidelity and emulation

## Why fidelity matters

The real device has a 398 MB recovery partition. The repository does not have that image. It was only seen on the device screen and cannot be transferred. The challenge must be explicit about what is exact and what is approximate.

## Levels

### F1 — default

Contents:

- WinRE 1809 254 MB WIM.
- Target 2017 inbox DriverStore state.
- OEM 2015 Wi-Fi package.
- nvram source.

Exact:

- WinRE build.
- Inbox driver version.
- OEM driver version.
- Driver file names.
- DriverStore folder names.
- nvram contents.

Not exact:

- Full 398 MB recovery partition.
- OEM extras outside the Broadcom driver subset.
- Device-specific registry and BCD state.

F1 is the default test definition because its content is exact for the driver problem, assuming the 1809 WIM provenance is verified.

### F2 — approximate partition

Contents:

- F1.
- OEM extras extracted from the 10586 factory WIM.

The base remains the WinRE 1809 WIM. The 10586 factory WIM contributes OEM extras only. It does **not** contain `bcmwdidhdpcie.inf`, so it cannot be the driver base and cannot reproduce the 2017 PCIe driver failure without injection.

Exact:

- Broadcom driver state from WinRE 1809.
- More of the OEM file layout from the factory image.

Not exact:

- Build 10586 extras versus the 1809 base.
- The actual 398 MB partition layout.
- The actual device configuration.

F2 is optional for driver mechanics and useful for testing space and file layout. It is a candidate approximation to the 398 MB partition, not an approved one; F1 remains the default for proving the driver fix.

### F3 — actual device image

Contents:

- The actual 398 MB WIM from the device.

This is the only fully identical level. It is not available. Do not require it for the default test. If the user ever provides it, use it without modifying the tracked original.

## Base image selection

Only WinRE 1809 contains the broken 2017 PCIe package:

| Image | Build | `bcmwdidhdpcie.inf` | Role |
|---|---:|---|---|
| `winre-1809-254MB/` | 17763.1 | 1.558.53.25 | Driver base |
| `winre-fabrica-10586-424MB/` | 10586 | Absent | OEM extras source |

The factory WIM has `bcmdhd`, `bcmdhd64`, `bcmfn2`, and `bcmfn`, but no PCIe `bcmwdidhdpcie` package. It is a 2015 recovery image, not a newer version of the 1809 image. Using it as the driver base would require injecting the 2017 package, which changes the very state under test.

Working choices:

- F1: WinRE 1809 only. Best for the driver-fix mechanics.
- F2: WinRE 1809 plus OEM extras from the 10586 factory WIM. Best available approximation to the 398 MB partition.
- F2b: 10586 factory WIM plus an injected 2017 PCIe package. Less faithful to the device build; use only as a control.
- F3: actual 398 MB device image. Unavailable.

The repository keeps both WIMs. It does not delete the factory image. No base is approved yet. F2 is a candidate only after the 1809 WIM is verified against an official reference; the driver base, if approved, is 1809. If that provenance check fails, the base selection is reopened.

## What “identical” means

“Identical” can mean three different things:

1. Identical driver state: F1 is sufficient.
2. Identical recovery partition content: F2 approximates, F3 is exact.
3. Identical hardware behavior: only the physical device can provide this.

The repository must not conflate them.

## QEMU capability

QEMU can:

- Boot WinRE.
- Run `cmd`.
- Read and write a virtual disk.
- Run DISM offline servicing.
- Stage and remove driver packages.
- Serve a local HTTP endpoint through user-mode networking.
- Prove that files and driver versions changed.

QEMU cannot:

- Emulate the BCM4356 radio.
- Reproduce PCI error 10 for that device.
- Prove Wi-Fi association.
- Prove that the nvram is consumed by the firmware.
- Prove that the device boots Windows 10 after recovery.

## Hardware-only checks

- `ConfigManagerErrorCode` for `PCI\VEN_14E4&DEV_43EC`.
- `netsh wlan show drivers`.
- `netsh wlan show interfaces`.
- Wi-Fi association.
- Windows installation and boot.
- Touch and display behavior.

## No data transfer

The physical device cannot send files out. The user can only read the screen and type commands. Therefore:

- Do not ask the user to paste WMIC output as a required step.
- Do not require the 398 MB image for the default test.
- Do not assume clipboard or shared folders.
- Treat any file on the device as either already local or delivered through the channel under test.
- Document hardware evidence as screen observations and typed commands.

## Reporting rule

Every result must state its fidelity level. A QEMU result is a software-mechanics result. It is not a hardware result. A hardware result must come from the physical device and must include the observed error code and adapter state.