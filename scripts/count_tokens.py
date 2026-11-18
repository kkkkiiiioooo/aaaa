#!/usr/bin/env python3
"""Count tokens/chars/bytes/lines for text files (cl100k_base, o200k_base)."""
import argparse, pathlib, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    args = ap.parse_args()
    try:
        import tiktoken
    except Exception as e:
        print(f"tiktoken not available: {e}", file=sys.stderr)
        print("Run with: uv run --with tiktoken --no-project python3 scripts/count_tokens.py ...", file=sys.stderr)
        return 2
    encs = [("cl100k_base", tiktoken.get_encoding("cl100k_base")),
            ("o200k_base", tiktoken.get_encoding("o200k_base"))]
    totals = {n: 0 for n, _ in encs}
    total_bytes = total_chars = total_lines = 0
    for path in args.files:
        data = pathlib.Path(path).read_bytes()
        text = data.decode("utf-8", errors="replace")
        lines = text.count("\n")
        counts = {n: len(enc.encode(text)) for n, enc in encs}
        for n, v in counts.items():
            totals[n] += v
        total_bytes += len(data); total_chars += len(text); total_lines += lines
        print(f"== {path} ==")
        print(f"bytes={len(data)} chars={len(text)} lines={lines}")
        for n, v in counts.items():
            print(f"tokens_{n}={v}")
        print()
    if len(args.files) > 1:
        print("== TOTAL ==")
        print(f"bytes={total_bytes} chars={total_chars} lines={total_lines}")
        for n, v in totals.items():
            print(f"tokens_{n}={v}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
