# Canonical Notes

## Device and situation

- Xiaomi Mi Pad 2, x64.
- Windows 10 build 17763 was installed.
- `C:` was quick-formatted.
- The only remaining Windows environment is the recovery partition on `D:`.
- No USB, SD, Ethernet, physical keyboard, or case opening is allowed.
- Available channels: screen, WinRE `cmd`, Wi-Fi, Bluetooth, touch.
- The device cannot send files out. There is no clipboard or shared folder.

## Provided image

The repository contains one WIM: the factory firmware image.

- Path: `winre-fabrica-10586-424MB/`.
- WIM size: 444,856,529 bytes.
- Build: 10586.
- Architecture: x86_64.
- Languages: en-US, zh-CN, zh-TW.
- Edition: WindowsPE.
- Files: 21,867.
- Directories: 4,593.
- Total bytes: 2,234,709,726.
- Compression: LZX.
- Boot index: 1.
- Reassembled WIM SHA-256: `152addc420748815c2cad90d382229e249ec853d3842531ddcc2b9998248067a`.
- DriverStore `FileRepository` entries: 752.

Broadcom DriverStore packages:

- `bcmdhd.inf_amd64_73691eb4230e8b44`
- `bcmdhd64.inf_amd64_284d283773fa4a7a`
- `bcmfn2.inf_amd64_a54399b6da2a3cc5`
- `bcmfn.inf_amd64_3bf62da6fe3a6002`

The firmware WIM does **not** contain `bcmwdidhdpcie.inf` and does not contain a PCIe Wi-Fi package. It cannot reproduce the 2017 PCIe driver failure without injecting that package.

No nvram file was found in the firmware WIM.

The firmware WIM is 444,856,529 bytes, larger than the approximately 398 MB recovery partition. It cannot replace `D:` as-is.

## Target DriverStore state

Path: `drivers/estado-dispositivo/`.

The target state is retained as the broken 2017 package. Its original image is no longer in the repository.

Exact names:

- `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9` — four files.
- `bcmdhd64.inf_amd64_e0bae6831f60ea5f` — five files.
- `bcmfn2.inf_amd64_5ebadf201c5b5845` — two files.

Wi-Fi target files:

- `bcmwdidhdpcie.inf`
- `bcmpciedhd63.sys`
- `4356a2rtecdc.bin`
- `43596a0rtecdc.bin`

The target Wi-Fi folder does not contain an nvram file. The 4359 firmware remains in the same folder because the target DriverStore state is kept identical.

The checksum manifest is at `drivers/estado-dispositivo/SHA256SUMS`; it is a repository artifact, not part of the DriverStore.

## Driver versions

- Broken 2017 package: `bcmwdidhdpcie.inf`, version `1.558.53.25`, date `04/21/2017`.
- OEM package: `oem25.inf`, version `1.558.14.0`, date `12/23/2015`.
- Both use `bcmpciedhd63.sys`.
- The 2017 package has two device sections: `PCI\VEN_14E4&DEV_43EC` (BCM4356) and `PCI\VEN_14E4&DEV_4355` (BCM4359).
- The OEM package covers more devices, including `PCI\VEN_14E4&DEV_43EC`.
- The OEM package includes the nvram line: `4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6`.
- The 2017 package does not include that nvram line.

## nvram

- Source: `drivers/mipad2-oficial/wifi/bcm94356wlpagbl_P3_150828M.txt`.
- SHA-256: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
- Size: 5,361 bytes.
- The hypothesis copy is `drivers/nvram-delta/4356r2nvram.txt`, byte-identical to the source.
- The driver looks for `\SystemRoot\system32\drivers\4356r2nvram.txt`.
- The nvram is not in the target DriverStore state.
- The nvram is not present in the firmware WIM.

## Known issue

- The Mi Pad 2 Wi-Fi reports error 10 (`ConfigManagerErrorCode=10`, device cannot start) after the 2017 PCIe package is used.
- Microsoft Q&A documents the same symptom and the workaround: manually select the older Broadcom 2015 driver.
- Windows ranks the newer 2017 driver above the 2015 package. Adding the older package without removing or forcing the newer one is insufficient.
- The user remembers that manual driver selection restored Wi-Fi after the update.

## Hypotheses

### H2 — driver version regression (primary)

The 2017 PCIe package is the cause. Removing it and installing the 2015 OEM package, including its nvram, is the main fix.

### H1 — missing nvram (secondary)

The board nvram is missing from the target DriverStore state. Without it, firmware download may fail even with the correct driver. The nvram may need to be supplied separately if the OEM package installation does not copy it.

## Fidelity

- F1 — firmware baseline: factory firmware WIM as-is. It has no `bcmwdidhdpcie.inf`; it cannot reproduce error 10.
- F2 — working synthetic state: firmware WIM + injected 2017 PCIe target package + OEM 2015 package + nvram. This is an approximation, not the real recovery partition, and the build is 10586.
- F3 — actual device WIM: the real approximately 398 MB recovery image. Not available.

The real 398 MB image was only seen on the device screen and cannot be transferred. Do not require it for F2.

These are test definitions. They do not assert the origin of the 2017 package or of the firmware WIM.

## Evidence status

Verified by content:

- The firmware WIM contains bcmdhd, bcmdhd64, bcmfn2, and bcmfn.
- The firmware WIM does not contain `bcmwdidhdpcie.inf`.
- The target state files are present with the hashes in `drivers/estado-dispositivo/SHA256SUMS`.
- The firmware WIM metadata values recorded above.

Not verified:

- The origin of the firmware WIM. The user reports that it is the factory recovery; no independent reference hash has been compared.
- The origin of the 2017 PCIe package retained in the target state.
- Whether the real approximately 398 MB partition can be approximated by F2.
- Whether the 2017 package is original or was assembled from another source.

Consequence: F2 is a synthetic working state, not a reproduction of the real recovery partition. Label it as such in every experiment.

## QEMU limitations

- QEMU does not emulate the BCM4356 radio.
- QEMU cannot reproduce error 10.
- QEMU can prove driver staging, driver removal, file placement, offline servicing, and the 1 KB HTTP channel.
- Hardware validation requires the user to read the screen and type commands; no file transfer.

## Repository status

- Branch: `desafio`.
- Initial commit: `2b51dd0`.
- The repository was assembled from the initial branch contents.
- No full Windows image is present.
- The only tracked WIM is the factory firmware image.
- No QEMU experiment has been run as part of the scaffold.
- No commit is made without an explicit request.

## References

- Microsoft Q&A: https://learn.microsoft.com/en-us/answers/questions/2779164/broadcom-802-11ac-wireless-pcie-cant-be-started-af
- Microsoft Update Catalog: https://www.catalog.update.microsoft.com/Search.aspx?q=Broadcom%20BCM4356
- OEM source: https://github.com/brianwoo/mipad2-win10-howto
- Local driver evidence: `drivers/README.md`, `drivers/nvram-delta/README.md`, `docs/03-driver-wifi-erro-10.md`.

## Open technical checks

- Confirm the exact offline result of injecting the 2017 PCIe package into the firmware WIM.
- Confirm the exact offline result of removing `bcmwdidhdpcie.inf` from the modified WIM.
- Confirm whether PnP install copies `4356r2nvram.txt` to `System32\drivers` in the modified WinRE.
- Confirm whether the 2015 driver starts in WinRE on hardware.
- Confirm the final Windows installation path without a full image.