#!/usr/bin/env python3
"""Empacote FSO Unicode + perda cp1252 + base64: o algoritmo de download-js.js.

Nao substitui a medida no PE (N3). Fecha regressao do empacote no host (N1).
"""
import base64
import sys

# cp1252: bytes 0x81,0x8D,0x8F,0x90,0x9D nao existem -> FSO ASCII vira '?' (0x3F)
CP1252_HOLES = {0x81, 0x8D, 0x8F, 0x90, 0x9D}


def pack_bytes(data: bytes) -> bytes:
    """lo | hi<<8 como UTF-16LE sem BOM (o que o FSO Unicode grava por wchar)."""
    out = bytearray()
    n = len(data)
    i = 0
    while i < n:
        lo = data[i]
        hi = data[i + 1] if i + 1 < n else 0
        out.append(lo)
        out.append(hi)
        i += 2
    return bytes(out)


def unpack_file(blob: bytes, n: int) -> bytes:
    """Host: tira BOM se houver e corta no tamanho original."""
    if blob.startswith(b"\xff\xfe"):
        blob = blob[2:]
    return blob[:n]


def cp1252_lossy(data: bytes) -> bytes:
    return bytes(b if b not in CP1252_HOLES else 0x3F for b in data)


def b64_roundtrip(data: bytes) -> bytes:
    return base64.b64decode(base64.b64encode(data).decode("ascii"))


def main() -> int:
    payload = bytes(range(256))
    fail = 0

    packed = pack_bytes(payload)
    if len(packed) != 256:
        print("FAIL: packed len", len(packed))
        fail += 1
    got = unpack_file(packed, 256)
    if got != payload:
        print("FAIL: unpack sem BOM")
        fail += 1
    else:
        print("PASS: unpack sem BOM 256/256")

    got_bom = unpack_file(b"\xff\xfe" + packed, 256)
    if got_bom != payload:
        print("FAIL: unpack com BOM")
        fail += 1
    else:
        print("PASS: unpack com BOM")

    # surrogates aparecem quando hi em 0xD8..0xDF
    sur = [i | ((i + 1) << 8) for i in range(0, 256, 2)]
    surr = [v for v in sur if 0xD800 <= v <= 0xDFFF]
    if not surr:
        print("FAIL: payload 0..255 nao gera substituto UTF-16 (o teste do PE precisa deles)")
        fail += 1
    else:
        print("PASS: %d code units surrogate no empacote (risco a medir no PE)" % len(surr), hex(surr[0]))

    lost = cp1252_lossy(payload)
    holes = [i for i in CP1252_HOLES if lost[i] == 0x3F]
    if len(holes) != len(CP1252_HOLES):
        print("FAIL: mapa cp1252")
        fail += 1
    else:
        print("PASS: ascii FSO perderia", sorted(CP1252_HOLES))

    if b64_roundtrip(payload) != payload:
        print("FAIL: base64")
        fail += 1
    else:
        print("PASS: base64 256/256")

    odd = b"abc"
    p = pack_bytes(odd)
    if unpack_file(p, 3) != odd:
        print("FAIL: impar", p)
        fail += 1
    else:
        print("PASS: byte impar com padding 0")

    if fail:
        print("FAIL:", fail)
        return 1
    print("PASS: fso_unicode_pack")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
