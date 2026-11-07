#!/usr/bin/env python3
"""checar_firmware.py - confere se um pacote de driver traz os arquivos que o INF exige.

Por que existe: driver instalado sem firmware pode dar erro 10 (o dispositivo nao inicia).
Quem valida so o INF e o hash (drivers-lote.md) NAO pega isso.

Uso:  python3 scripts/checar_firmware.py <pasta-com-inf>
Saida: uma linha por arquivo exigido, e codigo 0 so se nada faltar.
"""
import os, re, sys

EXT_FIRMWARE = {".bin", ".fw", ".ucode", ".dat", ".hex", ".pnvm", ".dlt", ".mbn", ".fwimage", ".cfg", ".seq"}

def ler_inf(caminho):
    raw = open(caminho, "rb").read()
    for enc in ("utf-16", "utf-8", "latin-1"):
        if enc == "utf-16" and not raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
            continue
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode("latin-1")

def arquivos_exigidos(texto):
    """Nomes de arquivo citados em secoes SourceDisksFiles (lado esquerdo de '=')."""
    nomes, na_secao = set(), False
    for linha in texto.splitlines():
        linha = linha.split(";", 1)[0].strip()
        if not linha:
            continue
        if linha.startswith("["):
            na_secao = linha.lower().startswith("[sourcedisksfiles")
            continue
        if na_secao and "=" in linha:
            nome = linha.split("=", 1)[0].strip().strip('"')
            if nome:
                nomes.add(nome)
    return nomes

def main(pasta):
    infs = []
    for dp, _, fs in os.walk(pasta):
        infs += [os.path.join(dp, f) for f in fs if f.lower().endswith(".inf")]
    if not infs:
        print("ERRO: nenhum .inf em", pasta); return 2
    existentes = {f.lower(): os.path.join(dp, f) for dp, _, fs in os.walk(pasta) for f in fs}
    faltam = 0
    for inf in infs:
        exigidos = arquivos_exigidos(ler_inf(inf))
        fw = sorted(n for n in exigidos if os.path.splitext(n)[1].lower() in EXT_FIRMWARE)
        for n in fw:
            ok = n.lower() in existentes
            faltam += 0 if ok else 1
            print(f"{'OK    ' if ok else 'FALTA '} firmware {n}  (exigido por {os.path.basename(inf)})")
        if not fw:
            print(f"sem firmware exigido: {os.path.basename(inf)}")
    print("RESULTADO:", "OK" if faltam == 0 else f"{faltam} arquivo(s) de firmware faltando")
    return 0 if faltam == 0 else 1

if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "."))
