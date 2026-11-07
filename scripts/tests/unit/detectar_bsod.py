#!/usr/bin/env python3
"""Teste do scripts/detectar-bsod.py — a classificacao do quadro tem que ser provada.

Criterio: dado um PPM sintetico de cada um dos tres estados (BSOD laranja, pagina
tecnica branca, tela normal escura), o detector tem que responder a palavra certa.
Sem isto, "o BSOD foi detectado" e so opiniao.

Uso: python3 scripts/tests/unit/detectar_bsod.py
"""
import os
import subprocess
import sys
import tempfile

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DET = os.path.join(RAIZ, "scripts", "detectar-bsod.py")


def ppm(caminho, w, h, cor):
    with open(caminho, "wb") as f:
        f.write(b"P6\n%d %d\n255\n" % (w, h))
        f.write(bytes(cor) * (w * h))


def roda(arquivo):
    out = subprocess.run([sys.executable, DET, arquivo], capture_output=True, text=True)
    return out.stdout.strip()


def main():
    tmp = tempfile.mkdtemp(prefix="bsodtest-")
    falhas = 0

    casos = [
        ("bsod", (232, 91, 4), "bsod"),
        ("tecnico", (240, 240, 240), "tecnico"),
        ("normal-escuro", (8, 8, 12), "normal"),
        ("normal-azul", (16, 40, 120), "normal"),
    ]
    for nome, cor, esperado in casos:
        p = os.path.join(tmp, nome + ".ppm")
        ppm(p, 64, 32, cor)
        got = roda(p)
        if got == esperado:
            print("PASS: %s -> %s" % (nome, got))
        else:
            print("FAIL: %s -> %s (esperado %s)" % (nome, got, esperado))
            falhas += 1

    # quadro real (PPM do QEMU): o arquivo do repo, se existir, tem que ser lido sem erro
    real = os.path.join(RAIZ, ".work", "vm", "shot-001.ppm")
    if os.path.exists(real):
        got = roda(real)
        print("PASS: quadro real %s -> %s" % (os.path.basename(real), got))
    else:
        print("SKIP: nenhum quadro real em .work/vm/ para ler")

    print("FAILURES: %d" % falhas)
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
