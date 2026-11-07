#!/usr/bin/env python3
"""ppm2png.py — converte PPM (P6) em PNG, sem PIL.

Por que existe: o QEMU so entrega PPM (screendump) e o cliente RFB de
scripts/vncshot.py tambem. A evidencia do projeto e PNG (docs/evidence/*.png), e
este sandbox nao tem PIL.entao o PPM vira PNG aqui, com zlib da biblioteca
padrao: IHDR + IDAT + IEND, sem filtro nenhum.

Uso: python3 scripts/ppm2png.py <entrada.ppm> <saida.png>
"""
import struct
import sys
import zlib


def ler_ppm(caminho):
    with open(caminho, "rb") as f:
        d = f.read()
    if not d.startswith(b"P6"):
        raise ValueError("nao e PPM P6")
    pos = 2
    campos = []
    while len(campos) < 3:
        while d[pos:pos + 1].isspace():
            pos += 1
        if d[pos:pos + 1] == b"#":
            while d[pos:pos + 1] not in (b"\n", b"\r"):
                pos += 1
            continue
        ini = pos
        while not d[pos:pos + 1].isspace():
            pos += 1
        campos.append(int(d[ini:pos]))
    pos += 1
    w, h, maxval = campos
    if maxval != 255:
        raise ValueError("maxval %d nao suportado" % maxval)
    px = d[pos:pos + w * h * 3]
    if len(px) < w * h * 3:
        raise ValueError("PPM truncado")
    return w, h, px


def escrever_png(caminho, w, h, px):
    raw = b"".join(b"\x00" + px[y * w * 3:(y + 1) * w * 3] for y in range(h))

    def chunk(tipo, dados):
        c = tipo + dados
        return struct.pack(">I", len(dados)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 6))
    png += chunk(b"IEND", b"")
    with open(caminho, "wb") as f:
        f.write(png)


def main():
    if len(sys.argv) != 3:
        print("uso: ppm2png.py <entrada.ppm> <saida.png>")
        return 2
    w, h, px = ler_ppm(sys.argv[1])
    escrever_png(sys.argv[2], w, h, px)
    print("%s -> %s (%dx%d)" % (sys.argv[1], sys.argv[2], w, h))
    return 0


if __name__ == "__main__":
    sys.exit(main())
