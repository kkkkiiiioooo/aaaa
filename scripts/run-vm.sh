#!/bin/sh
# run-vm.sh — sobe a VM de teste headless em QEMU e despeja a serial no log.
# Uso: sh scripts/run-vm.sh [segundos]
# Env: DISK_MB (tam do disco, padrao 64) · NET=1 liga interface de rede (padrao 0)
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VM="$ROOT/.work/vm"; DL="$ROOT/.work/downloads"; LOG="$ROOT/.work/logs/vm.log"
TIMEOUT=${1:-120}
DISK_MB=${DISK_MB:-64}
NET=${NET:-0}
mkdir -p "$VM" "$ROOT/.work/logs"

[ -s "$DL/vmlinuz-virt" ]        || { echo "kernel ausente; rode scripts/fetch-base.sh"; exit 1; }
[ -s "$VM/initramfs.cpio.gz" ]   || { echo "initramfs ausente; rode scripts/build-initramfs.sh"; exit 1; }
[ -s "$VM/testdisk.img" ]        || qemu-img create -f raw "$VM/testdisk.img" "${DISK_MB}M" >/dev/null

ACCEL="-accel tcg"
[ -w /dev/kvm ] && ACCEL="-accel kvm"
NETDEV=""
[ "$NET" = 1 ] && NETDEV="-netdev user,id=n0 -device virtio-net-pci,netdev=n0"

echo "[run-vm] accel=$ACCEL net=$NET timeout=${TIMEOUT}s log=$LOG"
# shellcheck disable=SC2086
timeout "$TIMEOUT" qemu-system-x86_64 -m 256 -smp 1 -nographic -no-reboot \
  $ACCEL -cpu max \
  -kernel "$DL/vmlinuz-virt" -initrd "$VM/initramfs.cpio.gz" \
  -append "console=ttyS0 rdinit=/init panic=-1" \
  -drive file="$VM/testdisk.img",format=raw,if=ide \
  $NETDEV > "$LOG" 2>&1
rc=$?
echo "[run-vm] qemu rc=$rc"
cat "$LOG"
exit $rc
