#!/usr/bin/env python3
"""HTTP para E5 no QEMU slirp: o convidado ve o host em 10.0.2.2.

    python3 scripts/servir_e5.py [--porta 8000] [--dir DIR]

Rotas:
  /wwii-teste.bin       fixture ASCII (legacy N3)
  /wwii-256.bin         256 bytes 0x00..0xFF (gate da escrita binaria)
  /wwii-256.bin.b64     o mesmo, base64 (caminho sem ResponseBody)
  /health
Range (bytes=) suportado. Ctrl+C encerra.
"""
from __future__ import annotations

import argparse
import base64
import http.server
import os
import sys

PAYLOAD256 = bytes(range(256))
TESTE_ASCII = b"wwii-teste\n" + (b"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\n" * 128)


class Handler(http.server.BaseHTTPRequestHandler):
    directory = os.getcwd()

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("[e5http] " + (fmt % args) + "\n")

    def _body(self, path: str) -> bytes | None:
        if path == "/health":
            return b"ok\n"
        if path == "/wwii-256.bin":
            return PAYLOAD256
        if path == "/wwii-256.bin.b64":
            return base64.b64encode(PAYLOAD256) + b"\n"
        if path == "/wwii-teste.bin":
            return TESTE_ASCII
        rel = path.lstrip("/")
        fp = os.path.join(self.directory, rel)
        if os.path.isfile(fp):
            with open(fp, "rb") as f:
                return f.read()
        return None

    def do_HEAD(self) -> None:
        self._send(head_only=True)

    def do_GET(self) -> None:
        self._send(head_only=False)

    def _send(self, head_only: bool) -> None:
        data = self._body(self.path.split("?", 1)[0])
        if data is None:
            self.send_error(404)
            return
        start, end = 0, len(data)
        rng = self.headers.get("Range")
        status = 200
        if rng and rng.startswith("bytes="):
            spec = rng.split("=", 1)[1].split(",")[0]
            a, _, b = spec.partition("-")
            try:
                start = int(a) if a else 0
                end = int(b) + 1 if b else len(data)
            except ValueError:
                start, end = 0, len(data)
            start = max(0, start)
            end = min(len(data), end)
            if start > 0 or end < len(data):
                status = 206
        chunk = data[start:end]
        self.send_response(status)
        self.send_header("Content-Length", str(len(chunk)))
        self.send_header("Accept-Ranges", "bytes")
        if status == 206:
            self.send_header("Content-Range", f"bytes {start}-{end-1}/{len(data)}")
        ctype = "text/plain" if self.path.endswith(".b64") else "application/octet-stream"
        self.send_header("Content-Type", ctype)
        self.end_headers()
        if not head_only:
            self.wfile.write(chunk)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--porta", type=int, default=8000)
    ap.add_argument("--dir", default=".")
    args = ap.parse_args()
    Handler.directory = os.path.abspath(args.dir)
    http.server.ThreadingHTTPServer.allow_reuse_address = True
    srv = http.server.ThreadingHTTPServer(("0.0.0.0", args.porta), Handler)
    print(f"[e5http] 0.0.0.0:{args.porta} dir={Handler.directory}", flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
