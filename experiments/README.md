# Experiments

Each experiment records one question, the exact commands, the observed output, the artifacts, and the limits of the conclusion.

## Index

| ID | Title | Status |
|---|---|---|
| E0.1 | Base image provenance | Evidence recorded; base decision pending |
| E1 | WinRE baseline in QEMU | Planned |
| E2 | Offline servicing | File mechanics done with wimlib (F2-metadata); DISM and boot pending |
| E3 | 1 KB HTTP channel | Planned |
| E4 | Hardware validation | Planned; user-driven |

## Rules

- Use `experiments/templates/experimento.md`.
- State the fidelity level: F1, F2, F2b, F3, or `metadata only`.
- Separate observed facts from hypotheses.
- Record the exact commands and the observed output.
- Record SHA-256 values for every artifact.
- State QEMU limitations explicitly.
- Never present a QEMU result as hardware proof.
- Do not modify tracked WIM parts. Work on copies under `qemu/work/` or `/tmp`.
- Do not commit generated images, logs, or secrets.

## Current base decision

No base is approved. WinRE 1809 is the only provided image observed with `bcmwdidhdpcie.inf`, but its origin is not independently verified. The 10586 factory image supplies OEM extras only. F2 is a candidate only after the 1809 provenance is verified; F1 is the fallback driver-only test. See `E0.1-base-provenance.md`.