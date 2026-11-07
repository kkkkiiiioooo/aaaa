#!/usr/bin/env python3
"""Teste do scripts/detectar-bsod.py — a classificacao do quadro tem que ser provada.

Criterio: dado um PPM sintetico de cada estado, o detector responde a palavra certa.
O caso do OOBE do WinPE (fundo laranja como o BSOD, mas SEM o QR code) foi o
falso positivo real de 2026-11-07: ele esta aqui de proposito, para nao voltar.

Uso: python3 scripts/tests/unit/detectar_bsod.py
"""
import os
import subprocess
import sys
import tempfile

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DET = os.path.join(RAIZ, "scripts", "detectar-bsod.py")


def ppm(caminho, w, h, cor, bloco_branco=None):
    with open(caminho, "wb") as f:
        f.write(b"P6\n%d %d\n255\n" % (w, h))
        px = bytearray(bytes(cor) * (w * h))
        if bloco_branco:
            bx, by, lado = bloco_branco
            for y in range(by, min(by + lado, h)):
                for x in range(bx, min(bx + lado, w)):
                    i = (y * w + x) * 3
                    px[i:i + 3] = b"\xff\xff\xff"
        f.write(bytes(px))


def roda(arquivo):
    out = subprocess.run([sys.executable, DET, arquivo], capture_output=True, text=True)
    return out.stdout.strip()


def main():
    tmp = tempfile.mkdtemp(prefix="bsodtest-")
    falhas = 0

    casos = [
        # nome, cor de fundo, bloco branco (x,y,lado), esperado
        ("bsod-qr", (215, 120, 0), (100, 300, 100), "bsod"),
        ("oobe-winpe", (178, 103, 32), None, "normal"),
        ("tecnico", (240, 240, 240), None, "tecnico"),
        ("normal-escuro", (8, 8, 12), None, "normal"),
        ("normal-azul", (16, 40, 120), None, "normal"),
        ("oobe-com-texto", (178, 103, 32), (100, 300, 20), "normal"),
    ]
    for nome, cor, bloco, esperado in casos:
        p = os.path.join(tmp, nome + ".ppm")
        ppm(p, 320, 240, cor, bloco)
        got = roda(p)
        if got == esperado:
            print("PASS: %s -> %s" % (nome, got))
        else:
            print("FAIL: %s -> %s (esperado %s)" % (nome, got, esperado))
            falhas += 1

    # quadro real do OOBE do WinPE (R2): e o falso positivo que aconteceu
    real = os.path.join(RAIZ, ".work", "vm", "tela-028.ppm")
    if os.path.exists(real):
        got = roda(real)
        if got == "normal":
            print("PASS: quadro real do OOBE -> %s" % got)
        else:
            print("FAIL: quadro real do OOBE -> %s (esperado normal)" % got)
            falhas += 1
    else:
        print("SKIP: nenhum quadro real em .work/vm/ para ler")

    print("FAILURES: %d" % falhas)
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
