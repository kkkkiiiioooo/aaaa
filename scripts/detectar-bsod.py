#!/usr/bin/env python3
"""detectar-bsod.py — classifica um quadro (PPM P6) do console do convidado.

Por que existe: o BSOD "amigavel" do Windows 10 1809 mostra so o nome do stop
code ("SYSTEM_THREAD_EXCEPTION_NOT_HANDLED") e ESCONDE o codigo hexadecimal, os
parametros e o modulo culpado. O codigo so aparece na PAGINA TECNICA, que aparece
quando se aperta a seta para a direita. Sem essa pagina, um bugcheck e so uma
palavra generica e nao da para saber QUAL driver quebrou.

Este script le um PPM (do screendump do QEMU ou do cliente RFB de scripts/vncshot.py)
e responde, em uma palavra:

  bsod      -> tela laranja do bugcheck (o stop code em nome, sem hexadecimal)
  tecnico   -> pagina tecnica (fundo branco com texto): codigo, parametros, dump
  normal    -> qualquer outra coisa (SeaBIOS, bootmgr, modo texto do PE)

Uso: python3 scripts/detectar-bsod.py <arquivo.ppm>
Saida: uma das tres palavras + as razoes (em stderr).
"""
import sys


def ler_ppm(caminho):
    """Le PPM P6 (RGB, maxval 255). Devolve (w, h, bytes_rgb)."""
    with open(caminho, "rb") as f:
        d = f.read()
    if not d.startswith(b"P6"):
        raise ValueError("nao e PPM P6: %r" % d[:2])
    # cabecalho P6: magic, whitespace, w, h, maxval  (comentarios # ... ate \n)
    pos = 2
    campos = []
    while len(campos) < 3:
        while pos < len(d) and d[pos:pos + 1].isspace():
            pos += 1
        if d[pos:pos + 1] == b"#":
            while pos < len(d) and d[pos:pos + 1] not in (b"\n", b"\r"):
                pos += 1
            continue
        ini = pos
        while pos < len(d) and not d[pos:pos + 1].isspace():
            pos += 1
        campos.append(int(d[ini:pos]))
    pos += 1  # um unico whitespace depois do maxval
    w, h, maxval = campos
    if maxval != 255:
        raise ValueError("maxval %d (so 255 suportado)" % maxval)
    esperado = w * h * 3
    px = d[pos:pos + esperado]
    if len(px) < esperado:
        raise ValueError("truncado: %d de %d bytes" % (len(px), esperado))
    return w, h, px


def classificar(w, h, px):
    laranja = branco = preto = 0
    total = w * h
    for i in range(0, total * 3, 3):
        r, g, b = px[i], px[i + 1], px[i + 2]
        # laranja do BSOD do Win10 1809: fundo #E85B04 aprox
        if r >= 150 and 20 <= g <= 140 and b <= 70:
            laranja += 1
        elif r >= 200 and g >= 200 and b >= 200:
            branco += 1
        elif r <= 40 and g <= 40 and b <= 40:
            preto += 1
    lo = laranja / total
    br = branco / total
    return lo, br, preto / total


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    try:
        w, h, px = ler_ppm(sys.argv[1])
    except Exception as e:  # noqa: BLE001 - aqui o erro vira resposta util
        print("erro", file=sys.stderr)
        print("leitura falhou: %s" % e, file=sys.stderr)
        print("normal")
        return 0
    lo, br, pr = classificar(w, h, px)
    if lo >= 0.30:
        print("bsod")
    elif br >= 0.50:
        print("tecnico")
    else:
        print("normal")
    print("quadro %dx%d  laranja=%.2f  branco=%.2f  preto=%.2f" % (w, h, lo, br, pr),
          file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
