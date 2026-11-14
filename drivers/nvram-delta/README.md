# nvram delta

## Purpose

This directory contains the smallest nvram payload that the Broadcom driver may need when the 2015 OEM package is used.

`4356r2nvram.txt` is the OEM nvram file `bcm94356wlpagbl_P3_150828M.txt`, renamed to the fixed name the driver looks up.

- Size: 5,361 bytes.
- SHA-256: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
- The file is byte-identical to the OEM source.
- The file is not present in the target DriverStore state.
- The file is not present anywhere in the WinRE 1809 image.

## Driver lookup evidence

Strings read from the inbox `bcmpciedhd63.sys` show these paths:

```text
\SystemRoot\system32\drivers\%04Xr%drtecdc.bin
\SystemRoot\system32\drivers\%04Xr%dnvram.txt
```

For the BCM4356 / `DEV_43EC` device, the names resolve to:

```text
\SystemRoot\system32\drivers\4356r2rtecdc.bin
\SystemRoot\system32\drivers\4356r2nvram.txt
```

The firmware source exists in the WinRE DriverStore as `4356a2rtecdc.bin`. The nvram source does not exist in the image.

The OEM and inbox INFs agree on the firmware rename:

```text
4356r2rtecdc.bin,4356a2rtecdc.bin,,6
```

Only the OEM INF contains the nvram rename:

```text
4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6
```

That missing line is the nvram delta.

## Relationship to the fix

H2 is the primary hypothesis: the 2017 inbox driver is the regression, and the 2015 OEM package is the fix. The OEM package already contains the nvram source and the copy rule.

H1 is secondary: if the nvram is not copied by the driver installation, the nvram must be supplied separately. The driver looks for it under `System32\drivers`.

Offline DISM driver addition stages the OEM package in the offline DriverStore. It does not guarantee that the INF copy list has run for the device. Actual `CopyFiles` happens during PnP device installation. In QEMU without the BCM4356, only staging can be verified.

## Applying only the nvram

This is a fallback, not the primary fix:

```bat
for %%D in (C D E F G H) do if exist %%D:\4356r2nvram.txt copy /Y %%D:\4356r2nvram.txt %SystemRoot%\System32\drivers\
pnputil /scan-devices
netsh wlan show drivers
```

Do not assume a USB drive, shared folder, or clipboard. The payload must already be on a local volume or must arrive through the external channel under test.

## What would confirm H1

- `netsh wlan show drivers` lists the adapter on the physical device.
- `ConfigManagerErrorCode` becomes `0`.
- The driver log no longer reports `dongle nvram file download failed`.

QEMU cannot confirm the radio result. It can confirm that the file is present at the expected path and that the driver package is staged.

## What would confirm H2

- The target state shows the 2017 inbox driver.
- The offline image shows the 2015 OEM driver after removal of the inbox package.
- The physical device starts the adapter with the 2015 driver.
- The same device fails with the 2017 driver.

## References

- `drivers/README.md`
- `docs/03-driver-wifi-erro-10.md`
- `docs/05-offline-servicing.md`
- `experiments/E2-offline-servicing.md`

Portuguese summary: `README.pt-BR.md`.