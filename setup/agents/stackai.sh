#!/bin/sh
# setup/agents/stackai.sh — qemu/wimlib/mtools. Idempotente.
cd "$(dirname "$0")/../.."||exit 1
export DEBIAN_FRONTEND=noninteractive
P="qemu-system-x86 qemu-utils wimtools xorriso mtools p7zip-full squashfs-tools cpio zstd busybox-static iproute2 kmod binutils xz-utils cabextract python3-pip"
F=""; for p in $P; do dpkg -s $p >/dev/null 2>&1||F="$F $p"; done
[ -n "$F" ]&&{ echo "[env] apt:$F";apt-get update -qq >/dev/null 2>&1;apt-get install -y -qq $F >/dev/null 2>&1||echo "[env] AVISO apt falhou";}
python3 -c "import regipy,pefile" 2>/dev/null||pip3 install -q --break-system-packages regipy pefile 2>&1|tail -1
echo "[env] pronto: $(nproc) cpu, $(free -m|awk '/Mem/{print $2}') MB, kvm=$([ -e /dev/kvm ]&&echo sim||echo nao)"
for c in qemu-system-x86_64 wimlib-imagex xorriso mcopy 7z; do command -v $c >/dev/null||echo "[env] FALTA $c"; done
