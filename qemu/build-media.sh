#!/bin/sh
# build-media.sh - reassemble the tracked firmware WIM and build the F1/F2 copies.
#
# F1 = firmware baseline (as-is). F2 = firmware copy + injected 2017 PCIe target
# package (synthetic working state). No tracked WIM part is modified; all work is
# under qemu/work/. See docs/04-fidelidade-mimetizacao.md.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK="$ROOT/qemu/work"
FAB="$ROOT/winre-fabrica-10586-424MB"
TARGET="$ROOT/drivers/estado-dispositivo/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9"
FR='/Windows/System32/DriverStore/FileRepository'
mkdir -p "$WORK"

echo "== reassemble firmware (F1 base)"
cat "$FAB"/winre-fabrica-10586.wim.part-* > "$WORK/firmware.wim"
sha256sum "$WORK/firmware.wim"
cp "$WORK/firmware.wim" "$WORK/f1.wim"

echo "== build F2: inject the 2017 PCIe target package into a copy"
cp "$WORK/firmware.wim" "$WORK/f2.wim"
wimlib-imagex update "$WORK/f2.wim" 1 \
  --command="add $TARGET $FR/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9"

echo "== F2 DriverStore: injected 2017 package"
wimlib-imagex dir "$WORK/f2.wim" 1 \
  --path="$FR/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9"
echo "== done: $WORK/f1.wim (F1), $WORK/f2.wim (F2 synthetic)"
