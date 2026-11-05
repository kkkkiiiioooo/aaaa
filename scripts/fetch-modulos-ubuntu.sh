#!/bin/sh
# fetch-modulos-ubuntu.sh - fallback do modloop: monta .work/vm/modloop/modules/<ver> com modulos do kernel Ubuntu (apt).
# build-initramfs.sh ja entende esse layout. Idempotente. Uso: sh scripts/fetch-modulos-ubuntu.sh
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd); D="$ROOT/.work/vm/modloop"
[ -d "$D/modules" ] && { echo "[modulos] ja existe"; exit 0; }

command -v zstd >/dev/null 2>&1 || apt-get install -y -qq zstd >/dev/null 2>&1
T=$(mktemp -d); cd "$T" || exit 1
P=$(apt-cache depends linux-image-virtual 2>/dev/null|sed -n 's/.*Depends: linux-image-\(.*\)/\1/p'|head -1)
apt-get download "linux-modules-$P" >/dev/null 2>&1 || { echo "[modulos] falha apt download linux-modules-$P"; exit 1; }
dpkg-deb -x linux-modules-*.deb x||exit 1
V=$(ls x/lib/modules|head -1); S="x/lib/modules/$V"
for d in scsi net block virtio; do find "$S/kernel/drivers/$d" -name '*.ko.zst' -exec zstd -dq --rm {} + 2>/dev/null; done
find "$S/kernel/net" "$S/kernel/lib" "$S/kernel/fs" -name '*.ko.zst' -exec zstd -dq --rm {} + 2>/dev/null
depmod -b x "$V" 2>/dev/null; sed -i 's/\.ko\.zst/.ko/g' "$S/modules.dep"
mkdir -p "$D/modules" && mv "$S" "$D/modules/$V" && echo "[modulos] ok: $D/modules/$V ($(find "$D/modules/$V" -name '*.ko'|wc -l) .ko)"
rm -rf "$T"
