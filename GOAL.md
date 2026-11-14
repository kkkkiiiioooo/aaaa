# Goal

## Mission

Build a reproducible challenge in which a cloud-hosted agent, with only the WinRE screen and command prompt, can restore an external channel and then recover Windows 10 build 17763 on a Xiaomi Mi Pad 2 without any physical connection.

## Primary objective

Prove, in a controlled QEMU environment, the software path that replaces the broken 2017 Broadcom inbox driver with the known-good 2015 OEM driver and makes the board nvram available to the driver.

## Hard constraints

- No USB, SD, Ethernet, physical keyboard, or opening the device.
- No data transfer from the device. The device only provides a screen and typed input.
- Available device channels: screen, WinRE `cmd`, Wi-Fi, Bluetooth, touch.
- No PowerShell in WinRE.
- Cloud agents run in containers; QEMU is the highest-fidelity environment available.
- QEMU must not expose host files through `-virtfs`, 9p, shared folders, serial file transfer, or host-forwarded ports.
- The only simulated external path is a local HTTP endpoint through QEMU user-mode networking.
- The BCM4356 radio is not emulated by QEMU.

## Non-goals

- Do not claim hardware proof from QEMU results.
- Do not provide a full Windows installation image in this repository.
- Do not bypass the challenge restrictions.
- Do not add unrelated drivers, display, audio, camera, or sensor packages.
- Do not modify the tracked WIM parts in place.
- Do not commit generated artifacts or secrets.

## Success criteria

### Repository

- `scripts/verify-repo.sh` passes.
- All checksums pass.
- `drivers/estado-dispositivo/` uses exact DriverStore folder names.
- The target Wi-Fi folder contains four driver files and no nvram.
- The OEM package and nvram hypothesis are documented separately.
- All agent-facing technical documentation is in English; user summaries are in Portuguese.

### QEMU software path

- WinRE boots in QEMU.
- The baseline shows the 2017 inbox driver.
- Offline servicing removes the inbox package and stages the 2015 OEM package.
- The modified image contains the 2015 driver and the nvram source.
- The fallback `pnputil`/`devcon` path is documented and testable.
- The 1 KB local HTTP channel works from the guest.

### Hardware validation

- `ConfigManagerErrorCode` for `PCI\VEN_14E4&DEV_43EC` is `0` after the fix.
- `netsh wlan show drivers` lists the adapter.
- The device connects to a Wi-Fi network.
- The user records screen evidence without transferring files.

## Milestones

| ID | Milestone | Pass condition |
|---|---|---|
| M0 | Inventory | Repository checksums pass; target state is reconstructed; tool inventory is recorded. |
| M1 | External channel | At least 1 KB can cross the simulated boundary; go/no-go recorded. |
| M2 | Driver payload | 2015 OEM driver is staged and 2017 inbox package is removed or overridden. |
| M3 | Wi-Fi | Adapter starts without error 10 on hardware. |
| M4 | Windows install | Windows 10 1809 is applied and boots. |
| M5 | Hardware validation | Wi-Fi, touch, and basic OS checks pass on the device. |

## Fidelity levels

| Level | Content | Use |
|---|---|---|
| F1 | Factory firmware 10586 WIM as-is | Baseline. It has no `bcmwdidhdpcie.inf` and cannot reproduce error 10. |
| F2 | Firmware WIM + injected 2017 PCIe target package + OEM 2015 package + nvram | Working synthetic state. Approximates the driver conflict; build 10586, not the real partition. |
| F3 | Actual approximately 398 MB WIM from the device | Exact target; unavailable unless the user provides it. |

F1 is the firmware baseline. F2 is the working synthetic state because the firmware image lacks the PCIe package. F3 is not available in this repository. Every F2 result must be labeled synthetic.

## Anti-cheat rules

- No host filesystem sharing.
- No host-forwarded ports.
- No serial file transfer.
- No clipboard integration.
- No hidden network proxy.
- No synthetic success claims.
- `qemu/audit.sh` must pass before an experiment is considered valid.

## Evidence requirements

Each experiment must record:

- Objective and fidelity level.
- Preconditions and tool versions.
- Exact commands.
- Observed output.
- Artifacts and checksums.
- Pass/fail decision.
- Limitations.
- Rollback result.

## References

- Microsoft Q&A: Broadcom 802.11ac Wireless PCIe cannot start, error 10, Mi Pad 2.
- Microsoft Update Catalog: Broadcom BCM4356 packages.
- Local evidence: `drivers/nvram-delta/README.md`, `drivers/README.md`, `docs/03-driver-wifi-erro-10.md`.

## Current status

Repository assembly is the current deliverable. QEMU experiments are defined but not executed. Hardware validation is pending.

Base image: the factory firmware WIM is the only tracked image. It lacks `bcmwdidhdpcie.inf`, so the working test requires injecting the 2017 target package into a copy. This is a synthetic state, not the real recovery partition. The approximately 398 MB device image remains unavailable.