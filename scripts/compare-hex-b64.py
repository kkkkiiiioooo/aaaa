#!/usr/bin/env python3
"""Host-only comparison hex vs base64 (size, cmd-special chars, ES3 round-trip).
NOT WinRE proof, NOT hardware proof. Usage: python3 scripts/compare-hex-b64.py [file...]"""
import base64, binascii, hashlib, os, subprocess, sys, tempfile, textwrap
files = sys.argv[1:] or ["drivers/nvram-delta/4356r2nvram.txt",
    "drivers/mipad2-oficial/wifi/4356a2rtecdc.bin"]
CMD_SPECIAL = set('^&|<>%!"()')
LINE = 120
print("file | bytes | hex chars | b64 chars | b64/hex | cmd-special hex/b64 | upper+sym in b64 | RT hex | RT b64")
for f in files:
    d = open(f, "rb").read(); h = hashlib.sha256(d).hexdigest()
    hx = binascii.hexlify(d).decode(); b6 = base64.b64encode(d).decode()
    sp = lambda s: sum(c in CMD_SPECIAL for c in s)
    r = {}
    for mode, enc in (("hex", hx), ("b64", b6)):
        with tempfile.TemporaryDirectory() as t:
            i, o = t + "/i.txt", t + "/o.bin"
            open(i, "w").write("\n".join(textwrap.wrap(enc, LINE)) + "\n")
            p = subprocess.run(["node", "scripts/hex-b64-es3.js", mode, i, o], capture_output=True, text=True)
            r[mode] = p.returncode == 0 and hashlib.sha256(open(o, "rb").read()).hexdigest() == h
    non = sum(not (c.islower() or c.isdigit()) for c in b6)
    print(f"{os.path.basename(f)} | {len(d)} | {len(hx)} | {len(b6)} | {len(b6)/len(hx):.3f} | {sp(hx)}/{sp(b6)} | {non} | {'PASS' if r['hex'] else 'FAIL'} | {'PASS' if r['b64'] else 'FAIL'}")
