#!/usr/bin/env python3
"""Divide uma listagem (nomes ou caminhos, um por linha) em arquivos por tipo.

Uso:
  scripts/dividir-inventario.py inventory/names-only/winre-1809-files.names.txt -o inventory/names-only/winre-1809
Saida: <outdir>/<categoria>.txt, so nomes de arquivo, unicos e ordenados.
Pipeline completo: wimlib-imagex dir <wim> 1 > /tmp/lista.txt ; scripts/extract-basenames.py /tmp/lista.txt ;
scripts/dividir-inventario.py <nomes> -o <pasta>
"""
import argparse, os, pathlib, collections

CATS = [
    ("executaveis",  {".exe", ".com", ".scr", ".efi"}),
    ("bibliotecas",  {".dll", ".ocx", ".cpl", ".drv", ".ax", ".tlb"}),
    ("drivers",      {".sys"}),
    ("inf",          {".inf", ".inf_loc", ".pnf"}),
    ("catalogos",    {".cat"}),
    ("manifestos",   {".manifest", ".mum"}),
    ("idiomas",      {".mui", ".nls"}),
    ("scripts",      {".js", ".vbs", ".cmd", ".bat", ".ps1", ".psm1", ".psd1", ".wsf", ".wsh", ".sh"}),
    ("config",       {".ini", ".xml", ".xsd", ".reg", ".mof", ".mfl", ".cdxml", ".dat", ".cdf-ms"}),
    ("fontes",       {".fon", ".ttf", ".otf"}),
]

def cat_of(name):
    ext = os.path.splitext(name)[1].lower()
    if ext.startswith(".mui"):
        return "idiomas"
    for c, exts in CATS:
        if ext in exts:
            return c
    return "outros"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("-o", "--outdir", required=True)
    a = ap.parse_args()
    out = pathlib.Path(a.outdir); out.mkdir(parents=True, exist_ok=True)
    buckets = collections.defaultdict(set)
    with open(a.input, encoding="utf-8", errors="replace") as f:
        for line in f:
            name = os.path.basename(line.rstrip("\r\n").replace("\\", "/"))
            if name:
                buckets[cat_of(name)].add(name)
    for c in [x for x, _ in CATS] + ["outros"]:
        names = sorted(buckets.get(c, ()), key=str.lower)
        (out / f"{c}.txt").write_text("\n".join(names) + ("\n" if names else ""), encoding="utf-8")
        print(f"{c:12s} {len(names):6d}")

if __name__ == "__main__":
    main()
