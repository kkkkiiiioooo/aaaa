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
    """Separa a tela de bugcheck da tela do OOBE do WinPE.

    Medido em 2026-11-07 (1024x768, VNC do QEMU):
      - BSOD: cor dominante (215,120,0) em 97% da tela + o QR code (bloco branco)
      - OOBE do WinPE ("Choose your keyboard layout"): cor dominante (178,103,32)
        em 100% da tela, **sem** bloco branco grande (so texto fino)

    So olhar "laranja" nao basta: o OOBE do WinPE 1809 e laranja tambem. O que
    distingue o BSOD e o QR code (bloco branco grande) e o tom mais saturado
    do fundo (R>=195 e B<=45).
    """
    contagem = {}
    total = w * h
    for i in range(0, total * 3, 3):
        k = (px[i], px[i + 1], px[i + 2])
        contagem[k] = contagem.get(k, 0) + 1
    dom = max(contagem.items(), key=lambda kv: kv[1])[0]
    frac_dom = contagem[dom] / total

    laranja = branco = 0
    for (r, g, b), c in contagem.items():
        if r >= 150 and 20 <= g <= 140 and b <= 70:
            laranja += c
        elif r >= 200 and g >= 200 and b >= 200:
            branco += c
    lo = laranja / total
    br = branco / total
    qr = bloco_branco(w, h, px)
    return dom, frac_dom, lo, br, qr


def bloco_branco(w, h, px, janela=80, passo=4):
    """Maior quantidade de pixels brancos numa janela janela x janela (amostragem grossa)."""
    melhor = 0
    for yy in range(0, max(1, h - janela), passo):
        for xx in range(0, max(1, w - janela), passo):
            c = 0
            for y2 in range(yy, min(yy + janela, h), passo):
                base = (y2 * w + xx) * 3
                for x2 in range(xx, min(xx + janela, w), passo):
                    i = base + x2 * 3
                    if px[i] >= 200 and px[i + 1] >= 200 and px[i + 2] >= 200:
                        c += 1
            if c > melhor:
                melhor = c
    return melhor


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
    dom, frac_dom, lo, br, qr = classificar(w, h, px)
    bsod = False
    if dom[0] >= 195 and 90 <= dom[1] <= 150 and dom[2] <= 45 and frac_dom >= 0.60:
        bsod = True          # fundo do bugcheck: laranja saturado e uniforme
    if lo >= 0.90 and qr >= 40:
        bsod = True          # laranja quase total + bloco branco grande (QR code)
    if bsod:
        print("bsod")
    elif br >= 0.50:
        print("tecnico")
    else:
        print("normal")
    print("quadro %dx%d  dominante=%s(%.0f%%)  laranja=%.2f  branco=%.2f  qr_max=%d" % (
        w, h, dom, frac_dom * 100, lo, br, qr), file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
