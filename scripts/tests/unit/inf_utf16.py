#!/usr/bin/env python3
"""Garante que INF UTF-16LE (WinRE/MS catalog) casa HWID — regressao do lote E2."""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))
import buscar_driver as b  # noqa: E402

HERE = os.path.dirname(__file__)
INFDIR = HERE
HWID = r"PCI\VEN_14E4&DEV_4365"

def main():
    res = b.check_infs(HWID, INFDIR)
    hits = [r for r in res if r["match"] and r["inf"].lower().endswith("sample-utf16.inf")]
    if not hits:
        print("FAIL: UTF-16 INF nao casou", res)
        return 1
    print("PASS: UTF-16 INF casou", hits[0]["match"][:1])
    # negativo
    res2 = b.check_infs(r"PCI\VEN_8086&DEV_9A60", INFDIR)
    if any(r["match"] for r in res2 if r["inf"].lower().endswith("sample-utf16.inf")):
        print("FAIL: negativo deu match")
        return 1
    print("PASS: negativo ok")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
