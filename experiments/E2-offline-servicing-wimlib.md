# Experiment E2 — Offline servicing of the 1809 WIM (wimlib file mechanics)

## Objective

Show that the 2017 inbox Broadcom package can be removed from a copy of the WinRE 1809 WIM and the 2015 OEM package staged in its place.

## Fidelity level

F2-metadata. Base is WinRE 1809 (build 17763), whose provenance is not independently verified (see E0.1). The tool is wimlib, not DISM. This proves file-level mechanics only. It does not prove that DISM accepts the removal, that the OEM catalog validates, or that PnP selects the OEM driver. It is not hardware proof.

## Environment

- Date: 2026-11-14
- Host kernel: 6.18.44-fc-v470, no KVM, 1 CPU
- Tool: wimlib-imagex 1.14.4
- Base WIM SHA-256: f9e30ca308aa23e83d852ccefcfe7bca09a23d7c5b759ae655557612487879b8 (reassembled from tracked parts, not modified)

## Commands

```sh
cat winre-1809-254MB/winre-1809.wim.part-* > /tmp/work/f1809.wim
cp /tmp/work/f1809.wim /tmp/work/e2.wim
wimlib-imagex update e2.wim 1 < e2.cmds   # delete 2017 package + INF, add OEM files
wimlib-imagex optimize e2.wim --recompress --compress=LZX
wimlib-imagex verify e2.wim
```

e2.cmds: delete -r the folder bcmwdidhdpcie.inf_amd64_977dcc915465b0e9; delete /Windows/INF/bcmwdidhdpcie.inf; add the seven OEM files into FileRepository/oem25.inf_amd64_synthetic plus /Windows/INF/oem25.inf. The folder suffix `synthetic` is a placeholder: Windows generates the real hash at staging.

## Observed output

- Baseline: the 1809 WIM has `bcmwdidhdpcie.inf` with `DriverVer=04/21/2017, 1.558.53.25` and the folder `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9` (4 files).
- After update: that folder and `/Windows/INF/bcmwdidhdpcie.inf` are gone; `oem25.inf_amd64_synthetic` (7 files) and `/Windows/INF/oem25.inf` exist.
- `wimlib-imagex verify`: successful, before and after recompression.
- Without `--compress`, wimlib wrote the new data as LZMS (WIM became mixed/LZMS). A boot WIM must be LZX or XPRESS, so the WIM was recompressed to LZX.
- Size: original 266,283,250 bytes; modified, LZX, 377,838,930 bytes; modified SHA-256 333c59a39b8c888d6d9c208d5ebef651718a95fa1a8255b0b7ecdc5587a9f518.

## Interpretation

### Observed facts

- Removal and staging work at file level on a copy; tracked parts were not touched.
- The modified WIM (377.8 MB) is below the approximately 398 MB recovery partition by about 20 MB. That is tight and must be re-checked on the real partition.

### Hypotheses (untested)

- DISM `/Remove-Driver` will accept the inbox package; the `oemNN.inf` published name is image-local.
- nvram: the fallback copy to `System32\drivers\4356r2nvram.txt` was NOT applied here (prefer the PnP path).

## Limitations

- Not DISM; no driver signature or catalog check; no boot; QEMU lacks the BCM4356.
- Generated WIM is not committed (rule: no generated artifacts).

## Rollback

Delete /tmp/work/e2.wim. Tracked WIM parts are unchanged (verify-repo passes).
