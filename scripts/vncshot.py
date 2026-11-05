#!/usr/bin/env python3
"""vncshot.py — pega o framebuffer de um QEMU com -display vnc= e grava PNG/PPM.

Por que existe: com `-display none`, o `screendump` do QEMU 6.2 devolve uma
superficie invalida (checkerboard com -vga std, faixas com -vga cirrus) e o
`pmemsave 0xb8000` so serve enquanto o convidado esta em modo texto. Um cliente
RFB de verdade faz o servidor VNC alocar a superficie e dai sai a tela real.

Uso: python3 scripts/vncshot.py --porta 5900 --saida .work/vm/tela.png [--espera 2]
Sem cliente VNC instalado no sandbox (sem X, sem x11vnc), entao o protocolo e
falado aqui mesmo: RFB 3.8, seguranca None, update Raw completo.
"""
import argparse
import socket
import struct
import sys
import time


def recvn(s, n):
    buf = b""
    while len(buf) < n:
        chunk = s.recv(n - len(buf))
        if not chunk:
            raise IOError("VNC fechou a conexao em %d/%d bytes" % (len(buf), n))
        buf += chunk
    return buf


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--porta", type=int, default=5900)
    ap.add_argument("--saida", required=True)
    ap.add_argument("--espera", type=float, default=1.0)
    a = ap.parse_args()

    s = socket.create_connection((a.host, a.porta), timeout=15)
    s.settimeout(20)
    ver = recvn(s, 12)
    if b"003.008" not in ver:
        print("versao RFB nao suportada: %r" % ver, file=sys.stderr)
        return 2
    s.sendall(b"RFB 003.008\n")
    n = recvn(s, 1)[0]
    secs = [recvn(s, 1)[0] for _ in range(n)]
    if 1 not in secs:
        print("QEMU nao ofereceu seguranca None: %r" % secs, file=sys.stderr)
        return 2
    s.sendall(struct.pack("!B", 1))
    if struct.unpack("!I", recvn(s, 4))[0] != 0:   # SecurityResult (4 bytes no RFB 3.8)
        print("handshake de seguranca falhou", file=sys.stderr)
        return 2
    s.sendall(struct.pack("!B", 1))          # ClientInit: shared=1
    init = recvn(s, 24)                       # w(2) h(2) pixfmt(16) nameLen(4)
    w, h = struct.unpack("!HH", init[:4])
    bpp = init[4]                             # bits-per-pixel (32 no QEMU)
    ppx = bpp // 8
    if ppx not in (1, 2, 4):
        print("formato de pixel inesperado: bpp=%d" % bpp, file=sys.stderr)
        return 2
    name_len = struct.unpack("!I", init[20:24])[0]
    recvn(s, name_len)
    print("desktop %dx%d bpp=%d" % (w, h, bpp))

    # pede o framebuffer inteiro
    s.sendall(struct.pack("!BBHHHH", 3, 0, 0, 0, w, h))
    pix = bytearray(b"\0" * (w * h * ppx))
    fim = time.time() + max(a.espera, 1)
    while time.time() < fim:
        try:
            t = recvn(s, 1)[0]
        except (socket.timeout, OSError):
            break
        if t not in (0, 2):                   # 0 = FramebufferUpdate como o QEMU 6.2
            break                             # deste build manda (medido, nao chute)
        recvn(s, 1)
        nrect = struct.unpack("!H", recvn(s, 2))[0]
        for _ in range(nrect):
            x, y, rw, rh = struct.unpack("!HHHH", recvn(s, 8))
            enc = struct.unpack("!i", recvn(s, 4))[0]
            if enc != 0:                      # so sabemos ler Raw
                print("encoding %d nao suportado" % enc, file=sys.stderr)
                continue
            dados = recvn(s, rw * rh * ppx)
            for linha in range(rh):
                off_dst = ((y + linha) * w + x) * ppx
                off_src = linha * rw * ppx
                pix[off_dst:off_dst + rw * ppx] = dados[off_src:off_src + rw * ppx]
        break

    s.close()
    if not any(pix):
        print("framebuffer todo preto/vazio", file=sys.stderr)
    rgb = bytes(v for chunk in zip(pix[0::ppx], pix[1::ppx], pix[2::ppx]) for v in chunk)
    if a.saida.endswith(".ppm"):
        with open(a.saida, "wb") as f:
            f.write(b"P6\n%d %d\n255\n" % (w, h))
            f.write(rgb)
    else:
        from PIL import Image
        Image.frombytes("RGB", (w, h), rgb).save(a.saida)
    nonzero = sum(1 for i in range(0, len(pix), 4) if pix[i:i + 3] != b"\0\0\0")
    print("gravado %s (%dx%d, %d pixels nao-pretos)" % (a.saida, w, h, nonzero))
    return 0


if __name__ == "__main__":
    sys.exit(main())
