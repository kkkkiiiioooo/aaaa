#!/usr/bin/env python3
"""Host-side mechanics of the proposed WinRE alphabet decoder.

NOT a WinRE proof and NOT hardware proof. Reconstructs a binary from ASCII hex
by concatenating 256 one-byte files (the same idea as:
  fsutil file createnew b00 1          -> 0x00
  FSO Write(Chr(i)) for i=1..255       -> other bytes (UNPROVEN in WinRE)
  copy /b bHH+bHH+... out.bin)

Usage:
  python3 scripts/alphabet-decode.py <hex.txt> <out.bin>
  python3 scripts/alphabet-decode.py --selftest
"""
from __future__ import annotations
import hashlib, pathlib, sys, tempfile

def hex_clean(s: str) -> str:
    return "".join(c for c in s if c in "0123456789abcdefABCDEF")

def build_alphabet(dir: pathlib.Path) -> dict[int, pathlib.Path]:
    d = {}
    for i in range(256):
        p = dir / f"{i:02x}"
        p.write_bytes(bytes([i]))
        d[i] = p
    return d

def decode(hex_text: str, alphabet: dict[int, pathlib.Path]) -> bytes:
    h = hex_clean(hex_text)
    if len(h) % 2:
        raise SystemExit("alphabet-decode: odd hex length")
    parts = []
    for i in range(0, len(h), 2):
        b = int(h[i:i+2], 16)
        parts.append(alphabet[b].read_bytes())
    return b"".join(parts)

def sha256(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()

def selftest() -> int:
    payload = bytes(range(256)) + bytes([0, 10, 13, 26, 255]) + b"bcmwdidhdpcie"
    hex_text = payload.hex()
    with tempfile.TemporaryDirectory() as td:
        td = pathlib.Path(td)
        alphabet = build_alphabet(td)
        out = decode(hex_text, alphabet)
    ok = out == payload
    print("selftest", "PASS" if ok else "FAIL")
    print("bytes", len(payload))
    print("sha256", sha256(payload))
    return 0 if ok else 1

def main(argv: list[str]) -> int:
    if len(argv) == 2 and argv[1] == "--selftest":
        return selftest()
    if len(argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    src, dst = pathlib.Path(argv[1]), pathlib.Path(argv[2])
    with tempfile.TemporaryDirectory() as td:
        out = decode(src.read_text(encoding="ascii", errors="strict"), build_alphabet(pathlib.Path(td)))
    dst.write_bytes(out)
    print(sha256(out), len(out))
    return 0

if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
