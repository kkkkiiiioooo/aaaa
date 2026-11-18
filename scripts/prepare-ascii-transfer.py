#!/usr/bin/env python3
"""Prepare a screen-only WinRE ASCII probe. Never transfers data to a guest.

The operator must TYPE every command and the bootstrap via the virtual keyboard.
No clipboard, shared folders, serial output or pre-seeded files are permitted.
Outputs a Markdown command sheet; all guest work is in a temporary scratch folder.
"""
import argparse
import hashlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASCII_BYTES = set(range(32, 127)) | {9, 10, 13}
LEAF = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]{0,31}\Z")


def prepare(data, chunk_size=128, session="mipad-e3b"):
    if not data or len(data) > 16384:
        raise ValueError("payload must contain 1..16384 bytes (text probe only)")
    if not 1 <= chunk_size <= 512:
        raise ValueError("chunk size must be 1..512 bytes")
    if not LEAF.fullmatch(session):
        raise ValueError("session must be a safe 1..32-character folder name")
    if session.upper() in {"CON", "PRN", "AUX", "NUL"} or re.fullmatch(r"(?:COM|LPT)[1-9]", session, re.I):
        raise ValueError("session is a reserved Windows name")
    if any(b not in ASCII_BYTES for b in data):
        raise ValueError("only printable ASCII, TAB, CR and LF are supported")
    chunks = []
    for offset in range(0, len(data), chunk_size):
        block = data[offset:offset + chunk_size]
        name = "p%05d.txt" % (len(chunks) + 1)
        sha = hashlib.sha256(block).hexdigest()
        command = 'cscript //nologo ascii.js write %s %s %s' % (name, block.hex(), sha)
        chunks.append({"name": name, "size": len(block), "sha256": sha, "command": command})
    # Bound each explicit copy command. No wildcard ordering, even with tiny chunks.
    merges, names, level = [], [c["name"] for c in chunks], 0
    while len(names) > 16:
        next_names = []
        for start in range(0, len(names), 16):
            name = "m%d_%05d.txt" % (level, len(next_names) + 1)
            merges.append("copy /b /y " + "+".join(names[start:start + 16]) + " " + name)
            next_names.append(name)
        names, level = next_names, level + 1
    merges.append("copy /b /y " + "+".join(names) + " 4356r2nvram.txt")
    sha = hashlib.sha256(data).hexdigest()
    verify = "cscript //nologo ascii.js verify 4356r2nvram.txt %d %s" % (len(data), sha)
    return {"size": len(data), "sha256": sha, "session": session,
            "chunks": chunks, "merges": merges, "verify": verify}


def render(plan, bootstrap):
    lines = ["# WinRE ASCII transfer command sheet", "",
             "**Prepared on the host; NOT evidence of WinRE or hardware success.**", "",
             "Type everything using the touch-screen virtual keyboard. Do not paste, mount a share,",
             "use serial ACKs, pre-seed the guest, or use a network transfer.", "",
             "Use a fresh temporary folder. Do not change any driver, WIM, BCD or device setting.",
             "The reconstructed file stays in scratch storage and disappears on a WinRE RAM-disk reboot.", "",
             "## 1. Prepare scratch storage", "", "```bat",
             'md "%TEMP%\\' + plan["session"] + '"',
             'cd /d "%TEMP%\\' + plan["session"] + '"', "notepad ascii.js", "```", "",
             "Check that `cd` succeeded. In Notepad, TYPE the following source; save as **ANSI**",
             "with file name **ascii.js**, not ascii.js.txt. Do not assume clipboard access.", "",
             "```js", bootstrap.rstrip(), "```", "",
             "## 2. Test hashing before sending the payload", "", "```bat",
             "cscript //nologo ascii.js selftest", "echo %errorlevel%", "```", "",
             "Expected (not yet observed in WinRE): `PASS SHA256 selftest vectors=3`, then `0`.",
             "Stop if either differs. Confirm cscript, JScript and FSO execute in this WinRE.", "",
             "## 3. Type and acknowledge each chunk", "",
             "Wait for the **current file name**, byte count and full SHA-256 on screen before",
             "typing the next command. These ACKs are instructions to the operator, not automatic",
             "flow control. Retrying the exact same chunk command overwrites only that scratch chunk.", ""]
    for i, chunk in enumerate(plan["chunks"], 1):
        lines.extend(["### Chunk %d/%d" % (i, len(plan["chunks"])), "", "```bat",
                      chunk["command"], "```", "",
                      "Expected: `ACK %s bytes=%d sha256=%s`." %
                      (chunk["name"], chunk["size"], chunk["sha256"]), ""])
    lines.extend(["## 4. Concatenate in explicit order, then verify", "", "```bat"])
    lines.extend(plan["merges"])
    lines.extend([plan["verify"], "echo %errorlevel%", "```", "",
                  "**PASS requires** the screen to show:", "", "```text",
                  "ACK 4356r2nvram.txt bytes=%d sha256=%s" % (plan["size"], plan["sha256"]),
                  "0", "```", "",
                  "Stop on any failed command, size/digest mismatch, missing file or COM/engine error.",
                  "Do not install this probe output. Keep screen evidence; no output file transfer.", "",
                  "After recording results, close Notepad, leave the scratch folder, and remove only",
                  "this probe folder if desired. Never reuse the commands to delete a system directory.", ""])
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("payload", type=Path, nargs="?", default=ROOT / "drivers/nvram-delta/4356r2nvram.txt")
    parser.add_argument("--chunk-size", type=int, default=128)
    parser.add_argument("--session", default="mipad-e3b")
    args = parser.parse_args()
    try:
        plan = prepare(args.payload.read_bytes(), args.chunk_size, args.session)
        bootstrap = (ROOT / "scripts/winre-ascii.js").read_text(encoding="ascii")
    except (OSError, ValueError) as err:
        parser.error(str(err))
    print(render(plan, bootstrap))


if __name__ == "__main__":
    main()
