# Broadcom drivers for the Mi Pad 2

Binary files are not meant to be pasted into chat. Verify them with `sha256sum -c` and inspect metadata with `wimlib-imagex` or `objdump`.

## Layout

| Path | Origin | Version | Contents |
|---|---|---|---|
| `mipad2-oficial/wifi/` | Official OEM package from the Mi Pad 2 Windows 10 backup | 1.558.14.0 (2015-12-23) | 16 files, 13.97 MB. DEV 4355, 4364, 43A3, 43BA, 43C3, 43EC, 43EF, 440D |
| `mipad2-oficial/bt-uart/` | Same OEM backup | 12.0.1.731 (2015-09-10) | 31 files, 4.0 MB. UART Bluetooth enumerator and firmware |
| `estado-dispositivo/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` | WinRE 1809 inbox | 1.558.53.25 (2017-04-21) | 4 files, 2.2 MB. DEV 4355 and 43EC |
| `estado-dispositivo/bcmdhd64.inf_amd64_e0bae6831f60ea5f/` | WinRE 1809 inbox | 5.93.102.22 (2015-08-06) | 5 files, 1.7 MB |
| `estado-dispositivo/bcmfn2.inf_amd64_5ebadf201c5b5845/` | WinRE 1809 inbox | 5.93.102.22 | 2 files, 14 KB |
| `nvram-delta/` | OEM nvram, renamed for the driver lookup path | n/a | 1 file, 5,361 bytes |

The target state is `estado-dispositivo/`. The OEM package is not the target state; it is the replacement payload. The nvram is not in the target state.

## Target Wi-Fi state

`estado-dispositivo/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` contains exactly:

- `bcmwdidhdpcie.inf`
- `bcmpciedhd63.sys`
- `4356a2rtecdc.bin`
- `43596a0rtecdc.bin`

The folder has no nvram. The `43596a0rtecdc.bin` file belongs to the BCM4359 / `DEV_4355` section. It stays in the folder because the target DriverStore is kept identical. The active `DEV_43EC` section uses the `4356a2rtecdc.bin` firmware.

`SHA256SUMS` is at `estado-dispositivo/SHA256SUMS` and covers the files in the three DriverStore folders. It is a repository artifact, not a DriverStore file.

## OEM Wi-Fi payload

`mipad2-oficial/wifi/oem25.inf` is version 1.558.14.0. The `DEV_43EC` section is `BCM43XAC_NT62_4356`. Its copy list includes:

- `bcmpciedhd63.sys`
- `4356r2rtecdc.bin` from `4356a2rtecdc.bin`
- `4356r2nvram.txt` from `bcm94356wlpagbl_P3_150828M.txt`

The OEM package includes the catalog `bcmpciedhd63.cat` and the IHV DLLs. The inbox INF does not include the nvram copy line and does not include a catalog file.

## Version conflict

- Inbox: 2017-04-21, 1.558.53.25.
- OEM: 2015-12-23, 1.558.14.0.
- Windows ranks the newer driver higher.
- Installing the OEM package without removing the inbox package is not sufficient.
- The fix must remove the inbox package or force the OEM driver.

## Measured details

- `bcmpciedhd63.sys` differs between packages: inbox 1,037,824 bytes; OEM 1,041,320 bytes.
- Target Wi-Fi payload for `DEV_43EC`: `bcmpciedhd63.sys`, `4356a2rtecdc.bin`, OEM nvram, `oem25.inf`, `bcmpciedhd63.cat`, `bcmihvsrv64.dll`, `bcmihvui64.dll`.
- The inbox INF does not mention nvram, `bcmihv*.dll`, or `CatalogFile`.
- The WinRE image already contains the inbox `.sys` and the `4356a2rtecdc.bin` firmware in the DriverStore, but not the nvram.

## Origin and hashes

- OEM source: https://github.com/brianwoo/mipad2-win10-howto, commit `8526424ca49d9077c16329f150fa176b88bd642e`, archives `win10_drivers.7z.001..004`.
- The OEM source is a DoubleDriver backup from a factory Windows 10 build 10586. This is an inference, not independently confirmed.
- Archive SHA-256:
  - 001: `10c5b7dfa4c229f6e46a0473e131dd37832973a0b2945e85365998049906b7c3`
  - 002: `8445601afb505de97d23d4f2da25ccab3bb9ff091b73a227ac2b06f182b9198a`
  - 003: `884b82c033fb87cde6a3df9d190eb6197e49f1ebf12cf0bb129803578bd0ada6`
  - 004: `190004e186e0b6aefa4f29778f9affeebe85f3605e6433c799d2daf8456e4c22`
- Inbox source: WinRE 1809 WIM at `winre-1809-254MB/`.
- OEM nvram SHA-256: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.

Portuguese summary: `drivers/README.pt-BR.md`.