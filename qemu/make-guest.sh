#!/bin/sh
# make-guest.sh - build a minimal Linux guest (busybox + e1000) used ONLY to prove
# the M1 simulated external channel: a guest fetches the 1 KB payload from the host
# HTTP endpoint through QEMU user-mode NAT (10.0.2.2). This is a channel-mechanics
# proof, not WinRE and not the BCM4356 radio. No host filesystem is shared.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
GUEST="$ROOT/qemu/guest"
KVER=5.15.0-203-generic
MOD="/lib/modules/$KVER/kernel/drivers/net/ethernet/intel/e1000/e1000.ko"
BB=$(command -v busybox)
rm -rf "$GUEST/root"
mkdir -p "$GUEST/root/bin" "$GUEST/root/lib/modules" "$GUEST/root/dev" \
         "$GUEST/root/proc" "$GUEST/root/sys" "$GUEST/root/tmp"
cp "$BB" "$GUEST/root/bin/busybox"
cp "$MOD" "$GUEST/root/lib/modules/e1000.ko"
cat > "$GUEST/root/init" <<'INIT'
#!/bin/busybox sh
/bin/busybox mount -t proc proc /proc
/bin/busybox mount -t sysfs sysfs /sys
/bin/busybox insmod /lib/modules/e1000.ko
/bin/busybox ip link set eth0 up
/bin/busybox ip addr add 10.0.2.15/24 dev eth0
/bin/busybox ip route add default via 10.0.2.2
echo "CHANNEL-TEST-START"
/bin/busybox wget -q -O /tmp/payload.bin http://10.0.2.2:8000/payload.bin
echo "wget-exit=$?"
echo -n "guest-payload-bytes="; /bin/busybox wc -c < /tmp/payload.bin
echo -n "guest-payload-sha256="; /bin/busybox sha256sum /tmp/payload.bin
echo "CHANNEL-TEST-END"
/bin/busybox poweroff -f
INIT
chmod +x "$GUEST/root/init"
( cd "$GUEST/root" && find . | cpio -o -H newc --quiet | gzip -9 ) > "$GUEST/initrd.img"
echo "guest initrd built: $GUEST/initrd.img ($(wc -c < "$GUEST/initrd.img") bytes)"
