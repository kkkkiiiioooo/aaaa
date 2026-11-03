"""Lista os HWIDs realmente presentes no WinRE 1809 (INFs sao UTF-16LE!).

grep ASCII em arquivo UTF-16 devolve zero sem avisar — foi o que quase produziu
um falso "o WinRE nao tem driver de nenhum fabricante". Este script decodiza.

LEIA ANTES DE CONCLUIR: contagem alta de HWID NAO e cobertura de driver. A maior
parte dos IDs do WinRE vem de `machine.inf`, que e lista de compatibilidade de
upgrade, nao driver. Para "este hardware tem driver in-box?", pergunte por INF de
classe net/ que declare o HWID, e confira o .sys ao lado no DriverStore.

Uso: python3 scripts/listar_hwid.py <dir-raiz-do-fs> [filtro]
Ex.: python3 scripts/listar_hwid.py .work/fs 8086
     python3 scripts/listar_hwid.py .work/fs net
"""
import os
import re
import sys

RAIZ = sys.argv[1] if len(sys.argv) > 1 else "."
FILTRO = sys.argv[2].upper() if len(sys.argv) > 2 else ""

HWID = re.compile(r"(?:PCI|USB|ACPI|HDAUDIO|BTHUSB|BTHENUM|SD|NVME|VEN)\\?[A-Z0-9_&*.+]+", re.U)


def ler(caminho):
    with open(caminho, "rb") as f:
        raw = f.read(400_000)
    for enc in ("utf-16-le", "utf-16-be", "utf-8", "latin-1"):
        try:
            txt = raw.decode(enc)
        except Exception:  # noqa: BLE001
            continue
        if "VEN_" in txt or "Class=" in txt or "[Version]" in txt.upper():
            return txt.replace("\x00", "")
    return raw.decode("latin-1").replace("\x00", "")


def main():
    inf = []
    for base, _, files in os.walk(RAIZ):
        for n in files:
            if n.lower().endswith(".inf"):
                inf.append(os.path.join(base, n))
    print("INFs examinados: %d" % len(inf))
    por_hwid = {}
    codificados = 0
    for p in inf:
        txt = ler(p)
        if "VEN_" in txt or "DEV_" in txt:
            codificados += 1
        for m in HWID.finditer(txt.upper()):
            h = m.group(0)
            if h.startswith(("PCI\\", "USB\\", "ACPI\\", "HDAUDIO", "BTH", "NVME", "SD\\")):
                por_hwid.setdefault(h, set()).add(os.path.basename(p))
    chaves = sorted(k for k in por_hwid if FILTRO in k)
    print("INFs com HWID: %d de %d" % (codificados, len(inf)))
    print("HWIDs distintos: %d%s" % (len(chaves), " (filtro=%s)" % FILTRO if FILTRO else ""))
    for k in chaves[:60]:
        print("  %-46s %s" % (k[:46], ", ".join(sorted(por_hwid[k]))[:60]))
    if len(chaves) > 60:
        print("  ... +%d omitidos" % (len(chaves) - 60))
    pci = [k for k in chaves if k.startswith("PCI\\VEN_")]
    print("\nPCI por fornecedor (contagem de DEV distintos):")
    fornecedores = {}
    for k in pci:
        ven = k.split("VEN_")[1][:4]
        fornecedores.setdefault(ven, 0)
        fornecedores[ven] += 1
    for v, c in sorted(fornecedores.items(), key=lambda x: -x[1])[:12]:
        print("  VEN_%s : %d" % (v, c))


if __name__ == "__main__":
    main()
