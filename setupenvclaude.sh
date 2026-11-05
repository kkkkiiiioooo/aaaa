#!/bin/sh
# setupenvclaude.sh - setup do agente "claude" (executor wwii). Idempotente, sem ler nada: sh setupenvclaude.sh
# Deixa o sandbox pronto para testar: qemu, wimlib, ISO, hive, rede, kernel+modulos (fallback Ubuntu se Alpine cair).
cd "$(dirname "$0")"||exit 1
export DEBIAN_FRONTEND=noninteractive
P="qemu-system-x86 wimtools xorriso mtools p7zip-full squashfs-tools cpio zstd busybox-static iproute2 kmod binutils xz-utils ovmf ipxe-qemu python3-pip"
F=""; for p in $P; do dpkg -s $p >/dev/null 2>&1||F="$F $p"; done
[ -n "$F" ]&&{ echo "[env] apt:$F";apt-get update -qq >/dev/null 2>&1;apt-get install -y -qq $F >/dev/null 2>&1||echo "[env] AVISO apt falhou";}
python3 -c "import regipy,pefile" 2>/dev/null||pip3 install -q --break-system-packages regipy pefile 2>&1|tail -1
sh scripts/registrar_ambiente.sh claude >/dev/null 2>&1
mkdir -p .work/logs .work/downloads .work/vm
sh scripts/fetch-base.sh >/dev/null 2>&1||echo "[env] AVISO fetch-base falhou"
sh scripts/fetch-modulos-ubuntu.sh >/dev/null 2>&1
git config core.hooksPath hooks 2>/dev/null
echo "[env] pronto: $(nproc) cpu, $(free -m|awk '/Mem/{print $2}') MB, kvm=$([ -e /dev/kvm ]&&echo sim||echo nao), qemu=$(qemu-system-x86_64 --version 2>/dev/null|sed -n '1s/.*version //p'|cut -d' ' -f1)"
for c in qemu-system-x86_64 wimlib-imagex xorriso mcopy 7z unsquashfs ip objdump busybox;do command -v $c >/dev/null||echo "[env] FALTA $c";done
python3 -c "import regipy,pefile;print('[env] py: regipy pefile ok')" 2>/dev/null||echo "[env] FALTA regipy/pefile"
ls .work/downloads/vmlinuz-virt >/dev/null 2>&1&&echo "[env] kernel ok"||echo "[env] FALTA kernel"
ls -d .work/vm/modloop/modules/* >/dev/null 2>&1&&echo "[env] modulos ok"||echo "[env] aviso: sem modulos (so para suite PAN)"
