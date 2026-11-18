#!/usr/bin/env python3
"""Bundle project markdown documentation into a single prompt-ready file.

Excludes .git and .opencode/node_modules. Skips symlinks that duplicate content.
"""
import argparse, os, pathlib

EXCLUDE_DIRS = {'.git', 'node_modules'}  # node_modules anywhere (e.g. .opencode/node_modules)

def should_skip(path: pathlib.Path, root: pathlib.Path) -> bool:
    parts = path.relative_to(root).parts
    if any(p in EXCLUDE_DIRS for p in parts):
        return True
    # skip symlinked markdown duplicates
    if path.is_symlink():
        return True
    return False

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-o', '--output', default='docs/DOCS-BUNDLE.md')
    ap.add_argument('--root', default='.')
    args = ap.parse_args()
    root = pathlib.Path(args.root).resolve()
    out = (root / args.output).resolve()
    files = sorted(p for p in root.rglob('*.md') if p.is_file() and not should_skip(p, root) and p.resolve() != out)
    out.parent.mkdir(parents=True, exist_ok=True)
    total_bytes = 0
    with out.open('w', encoding='utf-8') as w:
        w.write('# Project documentation bundle\n\n')
        w.write(f'Generated from {len(files)} markdown files (excluding .git, node_modules, symlinks).\n\n')
        w.write('---\n\n')
        for p in files:
            rel = p.relative_to(root).as_posix()
            data = p.read_bytes()
            text = data.decode('utf-8', errors='replace')
            total_bytes += len(data)
            w.write(f'## FILE: {rel}\n\n')
            w.write(text)
            if not text.endswith('\n'):
                w.write('\n')
            w.write('\n---\n\n')
    print(f'wrote {out} ({len(files)} files, {out.stat().st_size} bytes, source {total_bytes} bytes)')
    for p in files:
        print(p.relative_to(root).as_posix())
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
