#!/bin/sh
# make-guest-kbd.sh - build a minimal Linux guest that receives a payload as TEXT
# typed on the virtual keyboard (the touch-screen keyboard analog). NO network is
# configured: the only input channel is the keyboard. The guest reads a hex line
# from tty0, reconstructs the binary with busybox printf+sed (hex -> \xHH bytes),
# and hashes it. Models the device's only constraint-consistent inbound channel.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
GUEST="$ROOT/qemu/guest-kbd"
BB=$(command -v busybox)
rm -rf "$GUEST/root"
mkdir -p "$GUEST/root/bin" "$GUEST/root/dev" "$GUEST/root/proc" "$GUEST/root/sys" "$GUEST/root/tmp"
cp "$BB" "$GUEST/root/bin/busybox"
cat > "$GUEST/root/init" <<'INIT'
#!/bin/busybox sh
/bin/busybox mount -t devtmpfs devtmpfs /dev
/bin/busybox mount -t proc proc /proc
/bin/busybox mount -t sysfs sysfs /sys
exec /bin/busybox setsid /bin/busybox sh /kbd-transfer.sh
INIT
cat > "$GUEST/root/kbd-transfer.sh" <<'SCRIPT'
#!/bin/busybox sh
# Acquire tty0 as controlling terminal so the virtual keyboard delivers keystrokes.
exec </dev/tty0 >/dev/tty0 2>&1
/bin/busybox echo "KEYBOARD-TRANSFER-READY" > /dev/ttyS0
# Decode each line immediately and append (no O(n^2) string concatenation, which
# made the guest fall behind and drop keystrokes). hex -> bytes via printf+sed.
: > /tmp/payload.bin
N=0; TOTAL=0
while :; do
  read -r LINE || break
  [ "$LINE" = "end" ] && break
  FMT=$(printf '%s' "$LINE" | /bin/busybox sed 's/../\\x&/g')
  /bin/busybox printf "$FMT" >> /tmp/payload.bin
  N=$((N+1)); TOTAL=$((TOTAL+${#LINE}))
  /bin/busybox echo "ACK $N" > /dev/ttyS0
done
/bin/busybox echo "read-lines=$N read-len=$TOTAL" > /dev/ttyS0
/bin/busybox echo -n "guest-reconstructed-bytes=" > /dev/ttyS0
/bin/busybox wc -c < /tmp/payload.bin > /dev/ttyS0
/bin/busybox echo -n "guest-reconstructed-sha256=" > /dev/ttyS0
/bin/busybox sha256sum /tmp/payload.bin > /dev/ttyS0
/bin/busybox echo "KEYBOARD-TRANSFER-DONE" > /dev/ttyS0
/bin/busybox poweroff -f
SCRIPT
chmod +x "$GUEST/root/init" "$GUEST/root/kbd-transfer.sh"
( cd "$GUEST/root" && find . | cpio -o -H newc --quiet | gzip -9 ) > "$GUEST/initrd.img"
echo "kbd guest initrd built: $GUEST/initrd.img ($(wc -c < "$GUEST/initrd.img") bytes)"
