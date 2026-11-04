#!/usr/bin/env python3
"""E3 offline: winpeshl.ini lanca autorun; cmd nao chama ferramentas ausentes no 1809."""
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[2]


def read(p: Path) -> str:
    raw = p.read_bytes()
    if raw.startswith(b"\xff\xfe"):
        return raw.decode("utf-16-le")
    return raw.decode("utf-8")


def test_ini():
    txt = read(SCRIPTS / "winpeshl.ini")
    assert "[LaunchApps]" in txt
    assert "autorun-wwii.cmd" in txt
    assert "wpeinit" in txt.lower()
    print("PASS ini")


def test_cmd():
    raw = read(SCRIPTS / "autorun-wwii.cmd")
    lines = [ln for ln in raw.splitlines() if not ln.strip().lower().startswith("rem")]
    body = "\n".join(lines).lower()
    for banned in ("findstr", "powershell", "certutil", "bitsadmin", "pause", "msiexec"):
        assert banned not in body, banned
    assert "drvload" in body
    assert "wwii.log" in body
    assert "@echo off" in raw.lower()
    print("PASS cmd")


if __name__ == "__main__":
    test_ini()
    test_cmd()
    print("PASS autorun_offline")
