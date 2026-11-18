#!/usr/bin/env python3
"""Extract basename (name + extension) from inventory path listings.

Usage:
  scripts/extract-basenames.py inventory/winre-1809-files.txt [-o inventory/names-only]
  scripts/extract-basenames.py inventory/*.txt -o inventory/names-only
Writes one <input-stem>.names.txt per input with one basename per line.
"""
import argparse, os, pathlib, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inputs", nargs="+", help="path-listing .txt files")
    ap.add_argument("-o", "--outdir", default="inventory/names-only", help="output directory")
    args = ap.parse_args()
    outdir = pathlib.Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    for inp in args.inputs:
        p = pathlib.Path(inp)
        out = outdir / (p.stem + ".names.txt")
        n = 0
        with p.open("r", encoding="utf-8", errors="replace") as f, out.open("w", encoding="utf-8") as g:
            for line in f:
                name = os.path.basename(line.rstrip("\r\n"))
                g.write(name + "\n")
                n += 1
        print(f"{inp} -> {out} ({n} entries)")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
