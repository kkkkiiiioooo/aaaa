#!/bin/sh
# run.sh <iso> <outdir>  - boots the ISO in QEMU TCG. Only external path: user-mode NIC (guest reaches host at 10.0.2.2).
set -eu
ISO=$1; OUT=$2; mkdir -p "$OUT"
exec qemu-system-x86_64 -machine pc -cpu qemu64 -m 2048 -smp 1 \
  -cdrom "$ISO" -boot d -vga std -display none \
  -netdev user,id=n0 -device e1000,netdev=n0 \
  -monitor unix:"$OUT/mon.sock",server,nowait -serial none -no-reboot
