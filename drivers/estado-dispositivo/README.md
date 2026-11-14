# Target device state

This directory is a snapshot of the Broadcom DriverStore state from the WinRE 1809 image. It is not the OEM package and it is not a hypothesis.

## Exact DriverStore names

| Folder | Files |
|---|---|
| `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` | 4 |
| `bcmdhd64.inf_amd64_e0bae6831f60ea5f/` | 5 |
| `bcmfn2.inf_amd64_5ebadf201c5b5845/` | 2 |

## Wi-Fi package

`bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/`:

- `bcmwdidhdpcie.inf`
- `bcmpciedhd63.sys`
- `4356a2rtecdc.bin`
- `43596a0rtecdc.bin`

The folder has no nvram file.

The `43596a0rtecdc.bin` file belongs to the BCM4359 / `DEV_4355` section. It remains in the folder because the target DriverStore is kept identical. The `DEV_43EC` section uses `4356a2rtecdc.bin`.

## SDIO packages

`bcmdhd64.inf_amd64_e0bae6831f60ea5f/`:

- `bcmdhd64.inf`
- `bcmdhd63.sys`
- `43241b4rtecdc.bin`
- `4324b5rtecdc.bin`
- `43341b0rtecdc.bin`

`bcmfn2.inf_amd64_5ebadf201c5b5845/`:

- `bcmfn2.inf`
- `bcmfn2.sys`

## Checksums

`SHA256SUMS` is a repository artifact at this level. It covers the driver files with relative paths. It is not copied into a DriverStore folder.

## Source

Extracted from `winre-1809-254MB/`, image index 1, path `Windows/System32/DriverStore/FileRepository/`.

The exact folder names were read with `wimlib-imagex dir`.

## What this state means

- The Wi-Fi package is the 2017 inbox package, version 1.558.53.25.
- The target state does not contain the board nvram.
- The target state is the broken baseline. The OEM package is the replacement payload.
- Do not add the nvram here. Use `drivers/nvram-delta/` or the OEM package.
- Do not treat this snapshot as the full 398 MB recovery partition. It is the Broadcom driver subset only.