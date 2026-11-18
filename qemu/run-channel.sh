#!/bin/bash
# run-channel.sh - M1: prove >=1 KB crosses the simulated boundary through QEMU
# user-mode networking. Host serves qemu/http-root on 127.0.0.1:8000; the guest
# reaches it at 10.0.2.2 (default user-mode NAT). No hostfwd, no host sharing.
# audit.sh must pass before the guest boots.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
GUEST="$ROOT/qemu/guest"
HTTPROOT="$ROOT/qemu/http-root"
KERNEL=/boot/vmlinuz-5.15.0-203-generic
PORT=8000
[ -f "$GUEST/initrd.img" ] || { echo "run-channel: run make-guest.sh first" >&2; exit 1; }

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$HTTPROOT" >/tmp/httpd.log 2>&1 &
HTTPD=$!
trap 'kill "$HTTPD" 2>/dev/null || true' EXIT
sleep 1

QEMU=(qemu-system-x86_64 -machine pc -cpu qemu64 -smp 2 -m 1024
  -kernel "$KERNEL" -initrd "$GUEST/initrd.img"
  -append "console=ttyS0 panic=-1"
  -netdev user,id=n0 -device e1000,netdev=n0
  -display none -serial stdio -monitor none -no-reboot)

echo "== anti-cheat audit of the QEMU command line"
sh "$ROOT/qemu/audit.sh" "${QEMU[@]}"
echo "== boot guest (TCG; no KVM in this sandbox)"
timeout 150 "${QEMU[@]}"
echo "== channel run finished (exit=$?)"
