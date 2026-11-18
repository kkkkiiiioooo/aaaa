#!/bin/bash
# run-keyboard-transfer.sh - prove a payload enters the guest as TEXT typed on the
# simulated touch-screen keyboard (QEMU sendkey), with NO network connection at all.
# The guest reconstructs the binary from hex (xxd -r -p) and hashes it. The host
# compares the guest hash to the source. This is the constraint-consistent channel:
# the device has no working network (Wi-Fi = error 10); only typed text gets in.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK="$ROOT/qemu/work"
GUEST="$ROOT/qemu/guest-kbd"
KERNEL=/boot/vmlinuz-5.15.0-203-generic
MON="$WORK/kbd-mon.sock"
LOG="$WORK/kbd-serial.log"
HEX="$WORK/payload.hex"
PAYLOAD="${1:-$ROOT/drivers/nvram-delta/4356r2nvram.txt}"
mkdir -p "$WORK"
[ -f "$GUEST/initrd.img" ] || { echo "run make-guest-kbd.sh first" >&2; exit 1; }
[ -f "$PAYLOAD" ] || { echo "payload not found: $PAYLOAD" >&2; exit 1; }

python3 -c "import sys;open(sys.argv[2],'w').write(open(sys.argv[1],'rb').read().hex())" "$PAYLOAD" "$HEX"
echo "== host payload: $PAYLOAD ($(wc -c < "$PAYLOAD") bytes, $(wc -c < "$HEX") hex chars)"

rm -f "$MON" "$LOG"
QEMU=(qemu-system-x86_64 -machine pc -cpu qemu64 -smp 1 -m 512
  -kernel "$KERNEL" -initrd "$GUEST/initrd.img"
  -append "console=tty0 console=ttyS0 panic=-1"
  -display none -serial stdio -monitor unix:"$MON",server,nowait -no-reboot)

echo "== anti-cheat audit (note: NO -netdev/-device network at all)"
sh "$ROOT/qemu/audit.sh" "${QEMU[@]}"
echo "== boot guest (TCG; keyboard-only input)"
"${QEMU[@]}" </dev/null >"$LOG" 2>&1 &
QPID=$!
trap 'kill "$QPID" 2>/dev/null || true' EXIT

for i in $(seq 1 90); do grep -q KEYBOARD-TRANSFER-READY "$LOG" 2>/dev/null && break; sleep 1; done
grep -q KEYBOARD-TRANSFER-READY "$LOG" 2>/dev/null || { echo "guest not ready"; tail -20 "$LOG"; exit 1; }
echo "== guest ready; typing payload via simulated keyboard"
python3 "$ROOT/qemu/sendhex.py" "$MON" "$HEX" 256 "$LOG"
for i in $(seq 1 180); do grep -q KEYBOARD-TRANSFER-DONE "$LOG" 2>/dev/null && break; sleep 1; done
wait "$QPID" 2>/dev/null || true
trap - EXIT

echo "== guest serial output:"; grep -E 'KEYBOARD-TRANSFER|guest-reconstructed' "$LOG" || tail -20 "$LOG"
echo "== host source sha256:"; sha256sum "$PAYLOAD"
GUESTSHA=$(grep -oE 'guest-reconstructed-sha256=[0-9a-f]{64}' "$LOG" | head -1 | cut -d= -f2)
HOSTSHA=$(sha256sum "$PAYLOAD" | cut -d' ' -f1)
if [ -n "$GUESTSHA" ] && [ "$GUESTSHA" = "$HOSTSHA" ]; then
  echo "== RESULT: PASS - payload reconstructed in-guest from typed text, hash matches (no network used)"
else
  echo "== RESULT: FAIL - guest='$GUESTSHA' host='$HOSTSHA'"; exit 1
fi
