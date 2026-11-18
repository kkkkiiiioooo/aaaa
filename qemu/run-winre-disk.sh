#!/bin/bash
# run-winre-disk.sh - E1: attempt to boot the WinRE F1/F2 UEFI FAT32 disk under
# OVMF in QEMU. TCG only (no KVM), bounded attempt. Evidence: framebuffer
# screendumps + monitor status. No host sharing/hostfwd/serial-file. audit.sh gates.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK="$ROOT/qemu/work"
CODE=/usr/share/OVMF/OVMF_CODE.fd
VARS=/usr/share/OVMF/OVMF_VARS.fd
BUDGET="${BUDGET:-200}"
[ -f "$WORK/winre.img" ] || { echo "run-winre-disk: run build-disk.sh first" >&2; exit 1; }
cp "$VARS" "$WORK/OVMF_VARS.fd"
MON="$WORK/mon.sock"
rm -f "$MON" "$WORK"/disk-screen-*.ppm

# MEM: o ramdisk do WinRE precisa caber na RAM da VM. As imagens deste repo descomprimem
# para 2.02 GiB (1809) e 2.08 GiB (10586), entao -m 2048 nunca bootou nenhuma delas.
QEMU=(qemu-system-x86_64 -machine pc -cpu ${CPU:-max} -smp 2 -m ${MEM:-4096}
  -drive if=pflash,format=raw,readonly=on,file="$CODE"
  -drive if=pflash,format=raw,file="$WORK/OVMF_VARS.fd"
  -drive file="$WORK/winre.img",format=raw
  -netdev user,id=n0 -device e1000,netdev=n0
  -vga std -display none -serial null
  -monitor unix:"$MON",server=on,wait=off -no-reboot -boot c)

echo "== anti-cheat audit of the QEMU command line"
sh "$ROOT/qemu/audit.sh" "${QEMU[@]}"
echo "== boot WinRE UEFI disk (OVMF, TCG); budget ${BUDGET}s"
"${QEMU[@]}" >/tmp/winre-disk-qemu.log 2>&1 &
QPID=$!
trap 'kill "$QPID" 2>/dev/null || true' EXIT
for i in $(seq 1 30); do [ -S "$MON" ] && break; sleep 1; done
elapsed=0
while [ "$elapsed" -lt "$BUDGET" ]; do
  sleep 20; elapsed=$((elapsed + 20))
  python3 "$ROOT/qemu/mon.py" "$MON" "screendump $WORK/disk-screen-${elapsed}.ppm" >/dev/null 2>&1 || true
  st=$(python3 "$ROOT/qemu/mon.py" "$MON" "info status" 2>/dev/null | tr -d '\r' | grep -i 'VM status' || true)
  echo "t=${elapsed}s ${st:-status-unavailable}"
  if ! kill -0 "$QPID" 2>/dev/null; then echo "QEMU exited early at t=${elapsed}s"; break; fi
done
echo "== final status"
python3 "$ROOT/qemu/mon.py" "$MON" "info status" 2>/dev/null | tr -d '\r' | grep -i 'VM status' || true
kill "$QPID" 2>/dev/null || true
echo "== screendumps captured:"
ls -l "$WORK"/disk-screen-*.ppm 2>/dev/null || echo "none"
echo "== WinRE disk boot attempt finished"
