# Offline servicing

## Purpose

Modify a copy of the WinRE WIM so that it contains the 2015 OEM Wi-Fi driver instead of the 2017 inbox driver. Offline servicing works on the image while it is not booted.

This is the primary path. The fallback paths are `pnputil` and `devcon` in a running WinRE.

## Preconditions

- WinRE `cmd` is available.
- A copy of the WinRE WIM is accessible.
- The base WIM must contain `bcmwdidhdpcie.inf` version `1.558.53.25`. Use WinRE 1809 (`winre-1809-254MB/`).
- Do not use the 10586 factory WIM as the driver base: it has no `bcmwdidhdpcie.inf` and cannot reproduce the 2017 PCIe failure.
- The OEM Wi-Fi package is accessible on a local volume.
- The target WIM is backed up.
- Enough free space exists on `C:` for the copy, mount directory, and modified WIM.
- The BCM4356 device is present on the physical device. QEMU does not have it.

## Locate the WIM

Common path:

```bat
dir D:\Recovery\WindowsRE\Winre.wim
```

If not found:

```bat
dir /s /b D:\Winre.wim
```

Adjust the drive letter to the recovery partition. Do not assume it is always `D:`.

## Backup

```bat
copy /Y D:\Recovery\WindowsRE\Winre.wim C:\winre-orig.wim
```

Keep `C:\winre-orig.wim` until the modified image is verified and the device is recovered.

## Mount

```bat
mkdir C:\mnt
dism /Mount-Wim /WimFile:C:\winre-orig.wim /Index:1 /MountDir:C:\mnt
```

## List drivers

```bat
dism /Image:C:\mnt /Get-Drivers /Format:Table
```

Find the Broadcom inbox package. It has:

- Original file name: `bcmwdidhdpcie.inf`
- Version: `1.558.53.25`
- Date: `2017-04-21`
- Published name: `oemXX.inf`

Record the published name. The `XX` value is local to the image.

If this package is absent, the base image is wrong. Stop and use WinRE 1809. The 10586 factory WIM does not contain this package.

## Remove the inbox package

```bat
dism /Image:C:\mnt /Remove-Driver /Driver:oemXX.inf
```

Replace `oemXX.inf` with the published name from the previous step.

If DISM refuses because the package is not removable, stop and record the exact error. Do not delete files by hand yet. Use the fallback path in `docs/03-driver-wifi-erro-10.md`.

## Add the OEM package

```bat
dism /Image:C:\mnt /Add-Driver /Driver:C:\OEM\wifi\oem25.inf
```

The directory must contain `oem25.inf` and all files it references, including:

- `bcmpciedhd63.sys`
- `bcmpciedhd63.cat`
- `4356a2rtecdc.bin`
- `bcm94356wlpagbl_P3_150828M.txt`
- `bcmihvsrv64.dll`
- `bcmihvui64.dll`

In the QEMU harness the OEM package is placed at `C:\OEM\wifi`. On the physical device it must already be local or arrive through the external channel under test.

## Verify staging

```bat
dism /Image:C:\mnt /Get-Drivers /Format:Table
```

Expected:

- The 2017 package is gone.
- A Broadcom package with version `1.558.14.0` and date `2015-12-23` is listed.

Check the DriverStore:

```bat
dir C:\mnt\Windows\System32\DriverStore\FileRepository\oem25.inf_amd64_*
dir C:\mnt\Windows\System32\DriverStore\FileRepository\oem25.inf_amd64_*\4356a2rtecdc.bin
dir C:\mnt\Windows\System32\DriverStore\FileRepository\oem25.inf_amd64_*\bcm94356wlpagbl_P3_150828M.txt
```

The exact folder hash is generated when the package is staged. Do not expect the inbox folder name to remain.

## nvram note

`dism /Add-Driver` stages the package. It does not necessarily run the INF copy list for the device. The `System32\drivers\4356r2nvram.txt` copy normally happens during PnP installation.

If the physical-device test shows that the nvram was not copied, use the fallback before booting the modified image:

```bat
copy /Y C:\mnt\Windows\System32\DriverStore\FileRepository\oem25.inf_amd64_*\bcm94356wlpagbl_P3_150828M.txt C:\mnt\Windows\System32\drivers\4356r2nvram.txt
```

Only do this if the copy rule did not run. Prefer the INF and PnP path. Record the decision.

The firmware has a similar rename:

```text
4356a2rtecdc.bin -> 4356r2rtecdc.bin
```

The inbox image already contains the firmware source. The OEM INF also contains it. Prefer the PnP copy path.

## Commit

```bat
dism /Unmount-Wim /MountDir:C:\mnt /Commit
```

The modified WIM is now `C:\winre-orig.wim`. Do not overwrite the original recovery WIM until the modified copy has been verified.

## Boot the modified image

QEMU:

- Build the boot media from the modified WIM.
- Boot the modified WinRE.
- Verify with `dism`, `pnputil`, and `dir`.
- The BCM4356 is absent, so the radio result is not testable.

Physical device:

- If the modified WIM fits on the recovery partition, back up the original and replace it.
- If it does not fit, keep it on `C:` and create a BCD entry for it. This is advanced and must be tested in QEMU first.
- Do not delete the original until the modified image boots and the adapter works.

## Space constraint

The real recovery partition is about 398 MB. The original WIM is about the same size. The modified WIM can be larger after adding the OEM package. Do not assume there is room on `D:`.

Preferred order:

1. Keep the original on `C:`.
2. Modify the copy on `C:`.
3. Boot the copy from `C:` through a BCD entry.
4. Only replace `D:` if the modified file fits and the original is backed up.

## Rollback

Immediate rollback:

```bat
copy /Y C:\winre-orig.wim D:\Recovery\WindowsRE\Winre.wim
```

If a BCD entry was added, remove it. If the original was replaced, restore from the backup. Record the rollback result.

## Fallback: pnputil in running WinRE

This changes the running RAM-based WinRE, not the WIM. It is useful for a one-session download.

```bat
pnputil /enum-drivers
pnputil /delete-driver oemXX.inf /uninstall /force
pnputil /add-driver C:\OEM\wifi\oem25.inf /install
pnputil /scan-devices
netsh wlan show drivers
```

If the inbox package cannot be deleted, use `devcon update` or the manual selection equivalent.

## Fallback: devcon

`devcon` is not part of WinRE. It must already be local.

```bat
devcon update C:\OEM\wifi\oem25.inf "PCI\VEN_14E4&DEV_43EC"
devcon status "PCI\VEN_14E4&DEV_43EC"
```

## Last resort: manual .sys replacement

Do not start here. Replacing `System32\drivers\bcmpciedhd63.sys` by hand bypasses normal driver package handling and can break service registration or signature checks. Use it only if DISM and `pnputil` both fail, and record every step.

## Validation checklist

- [ ] Original WIM backed up.
- [ ] 2017 package identified by published name.
- [ ] 2017 package removed.
- [ ] 2015 package staged.
- [ ] `Get-Drivers` shows 1.558.14.0.
- [ ] OEM firmware and nvram sources present in the staged package.
- [ ] Commit succeeded.
- [ ] Modified WIM boots.
- [ ] Fallback decision recorded.
- [ ] Hardware check performed separately.