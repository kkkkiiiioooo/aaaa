# Wi-Fi driver and error 10

## Symptom

The BCM4356 adapter is `PCI\VEN_14E4&DEV_43EC`. After the 2017 inbox driver is in use, Windows reports:

```text
ConfigManagerErrorCode = 10
```

Error 10 means the device cannot start. The adapter does not appear as a working Wi-Fi interface.

## Versions

| Package | Version | Date | Source |
|---|---|---|---|
| Inbox `bcmwdidhdpcie.inf` | 1.558.53.25 | 2017-04-21 | WinRE 1809 |
| OEM `oem25.inf` | 1.558.14.0 | 2015-12-23 | Mi Pad 2 factory backup |

Both packages use a file named `bcmpciedhd63.sys`, but the binaries differ:

- Inbox: 1,037,824 bytes.
- OEM: 1,041,320 bytes.

## Why copying the older driver is not enough

Windows driver ranking prefers the newer driver for the same device. The 2017 inbox package outranks the 2015 OEM package. Adding the OEM package without removing the inbox package or forcing the OEM package leaves the newer driver selected.

The working options are:

1. Remove the inbox package, then add the OEM package.
2. Force the OEM package with `devcon update`.
3. Use the Device Manager equivalent of “Let me pick from a list” and select the 2015 Broadcom driver.

The user's manual selection worked on the physical device. That is consistent with a driver-version regression.

## Known external evidence

Microsoft Q&A documents the same Mi Pad 2 symptom and the older-driver workaround:

https://learn.microsoft.com/en-us/answers/questions/2779164/broadcom-802-11ac-wireless-pcie-cant-be-started-af

The Microsoft Update Catalog lists Broadcom BCM4356 packages:

https://www.catalog.update.microsoft.com/Search.aspx?q=Broadcom%20BCM4356

These sources support H2. They do not replace a physical-device test.

## The nvram factor

The driver builds these paths:

```text
\SystemRoot\system32\drivers\4356r2rtecdc.bin
\SystemRoot\system32\drivers\4356r2nvram.txt
```

The target DriverStore contains `4356a2rtecdc.bin`, which the INF renames to `4356r2rtecdc.bin` during installation. The target DriverStore does not contain the nvram.

The OEM INF contains:

```text
4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6
```

The inbox INF does not. This is the nvram delta.

H2 is primary: the 2017 driver is the regression. H1 is secondary: if the OEM package installation does not copy the nvram, the nvram must be placed separately under `System32\drivers`.

## Offline servicing behavior

`dism /Add-Driver` on an offline image stages the driver package in the offline DriverStore. It does not perform a full PnP installation for a device that is not present. The INF `CopyFiles` operation normally runs when the device is installed.

Consequences:

- The modified WIM can be verified for driver package staging.
- The nvram source can be verified in the DriverStore.
- The final `System32\drivers\4356r2nvram.txt` copy may require PnP installation on hardware, or a manual copy as fallback.
- QEMU without the BCM4356 cannot verify the final radio path.

## Verification commands

On hardware, before the fix:

```bat
wmic path Win32_PnPEntity where "DeviceID like '%VEN_14E4&DEV_43EC%'" get Name,DeviceID,Status,ConfigManagerErrorCode
pnputil /enum-drivers
netsh wlan show drivers
```

After the fix:

```bat
wmic path Win32_PnPEntity where "DeviceID like '%VEN_14E4&DEV_43EC%'" get Name,DeviceID,Status,ConfigManagerErrorCode
pnputil /enum-drivers
netsh wlan show drivers
netsh wlan show interfaces
```

Expected: error code `0`, the 2015 package listed, and the adapter visible. If WMIC is missing in WinRE, use `pnputil /enum-devices /problem` or `devcon status` if available.

## What QEMU can and cannot prove

Can prove:

- The target image contains the 2017 package.
- The target image does not contain the nvram.
- The offline image has the 2017 package removed.
- The offline image has the 2015 package staged.
- The nvram source is present in the staged OEM package.
- The driver files are in the expected DriverStore paths.

Cannot prove:

- The BCM4356 starts.
- Error 10 becomes 0.
- Wi-Fi associates.
- The nvram is copied to `System32\drivers` by PnP.

## References

- `drivers/README.md`
- `drivers/nvram-delta/README.md`
- `docs/05-offline-servicing.md`
- `docs/08-checklist-hardware.md`
- `experiments/E1-baseline-winre.md`
- `experiments/E2-offline-servicing.md`