# Target device state

## Meaning

`drivers/estado-dispositivo/` is the broken Broadcom DriverStore subset. It is the baseline, not the fix.

## Exact folders

| Folder | Files | Package |
|---|---|---|
| `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` | 4 | PCIe Wi-Fi |
| `bcmdhd64.inf_amd64_e0bae6831f60ea5f/` | 5 | SDIO Wi-Fi |
| `bcmfn2.inf_amd64_5ebadf201c5b5845/` | 2 | SDIO function |

These names are part of the target DriverStore snapshot. The source image is not in this repository.

## Wi-Fi target files

```text
bcmwdidhdpcie.inf
bcmpciedhd63.sys
4356a2rtecdc.bin
43596a0rtecdc.bin
```

No nvram file is present.

The `43596a0rtecdc.bin` file belongs to the BCM4359 / `DEV_4355` section. It stays in the folder because the target DriverStore is kept identical. The `DEV_43EC` section uses `4356a2rtecdc.bin`.

## SDIO target files

`bcmdhd64.inf_amd64_e0bae6831f60ea5f/`:

```text
bcmdhd64.inf
bcmdhd63.sys
43241b4rtecdc.bin
4324b5rtecdc.bin
43341b0rtecdc.bin
```

`bcmfn2.inf_amd64_5ebadf201c5b5845/`:

```text
bcmfn2.inf
bcmfn2.sys
```

## Checksums

Manifest: `drivers/estado-dispositivo/SHA256SUMS`.

It is a repository artifact at the parent level, outside the DriverStore folders. Verify with:

```sh
cd drivers/estado-dispositivo
sha256sum -c SHA256SUMS
```

## What is not here

- The nvram is not here.
- The full 398 MB recovery partition is not here.
- The OEM package is not here.
- The 2015 `bcmpciedhd63.sys` is not here.
- The fix is not applied.

## Relationship to the OEM package

The target state is the 2017 inbox package. The OEM package under `drivers/mipad2-oficial/wifi/` is the replacement. The OEM `oem25.inf` is version 1.558.14.0 and contains the nvram copy rule. The target `bcmwdidhdpcie.inf` is version 1.558.53.25 and does not contain the nvram copy rule.

## Target state rules

- Do not add the nvram to this directory.
- Do not replace the inbox files with OEM files in place.
- Do not treat the SDIO or function packages as the Wi-Fi fix.
- Do not claim this subset is the full recovery image.
- If the target state changes on the device, update this directory and its checksums together.