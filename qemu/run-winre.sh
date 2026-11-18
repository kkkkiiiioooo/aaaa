#!/bin/bash
# run-winre.sh - E1: attempt to boot the WinRE F1/F2 ISO under OVMF (UEFI) in QEMU.
# TCG only (no KVM in this sandbox), so boot is slow; this is a bounded attempt.
# Evidence: periodic framebuffer screendumps + monitor status. No host sharing,
# no hostfwd, no serial file transfer. audit.sh must pass before boot.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK="$ROOT/qemu/work"
CODE=/usr/share/OVMF/OVMF_CODE.fd
VARS=/usr/share/OVMF/OVMF_VARS.fd
BUDGET="${BUDGET:-200}"
[ -f "$WORK/winre.iso" ] || { echo "run-winre: run build-iso.sh first" >&2; exit 1; }
cp "$VARS" "$WORK/OVMF_VARS.fd"
MON="$WORK/mon.sock"
rm -f "$MON" "$WORK"/screen-*.ppm

# MEM: o ramdisk do WinRE precisa caber na RAM da VM; 2048 nao comporta nenhuma das
# imagens deste repo (2.02 GiB / 2.08 GiB descomprimidas). Veja experiments/E1-winre-boot-tcg.md.
QEMU=(qemu-system-x86_64 -machine pc -cpu ${CPU:-qemu64} -smp 2 -m ${MEM:-4096}
  -drive if=pflash,format=raw,readonly=on,file="$CODE"
  -drive if=pflash,format=raw,file="$WORK/OVMF_VARS.fd"
  -cdrom "$WORK/winre.iso"
  -netdev user,id=n0 -device e1000,netdev=n0
  -vga std -display none -serial null
  -monitor unix:"$MON",server=on,wait=off -no-reboot -boot d)

echo "== anti-cheat audit of the QEMU command line"
sh "$ROOT/qemu/audit.sh" "${QEMU[@]}"
echo "== boot WinRE ISO (OVMF, TCG); budget ${BUDGET}s"
"${QEMU[@]}" >/tmp/winre-qemu.log 2>&1 &
QPID=$!
trap 'kill "$QPID" 2>/dev/null || true' EXIT
# wait for monitor socket
for i in $(seq 1 30); do [ -S "$MON" ] && break; sleep 1; done
elapsed=0
while [ "$elapsed" -lt "$BUDGET" ]; do
  sleep 20; elapsed=$((elapsed + 20))
  python3 "$ROOT/qemu/mon.py" "$MON" "screendump $WORK/screen-${elapsed}.ppm" >/dev/null 2>&1 || true
  st=$(python3 "$ROOT/qemu/mon.py" "$MON" "info status" 2>/dev/null | tr -d '\r' | grep -i 'VM status' || true)
  echo "t=${elapsed}s ${st:-status-unavailable}"
  if ! kill -0 "$QPID" 2>/dev/null; then echo "QEMU exited early at t=${elapsed}s"; break; fi
done
echo "== final status"
python3 "$ROOT/qemu/mon.py" "$MON" "info status" 2>/dev/null | tr -d '\r' | grep -i 'VM status' || true
python3 "$ROOT/qemu/mon.py" "$MON" "info block" 2>/dev/null | tr -d '\r' | head -6 || true
kill "$QPID" 2>/dev/null || true
echo "== screendumps captured:"
ls -l "$WORK"/screen-*.ppm 2>/dev/null || echo "none"
echo "== WinRE boot attempt finished"
