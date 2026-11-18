#!/bin/sh
# build-disk.sh - build a UEFI-bootable FAT32 disk image from a WIM copy.
# More robust than El Torito for WinPE: bootmgfw.efi sees a full FAT32 volume that
# contains \sources\boot.wim, \Boot\boot.sdi and \EFI\Microsoft\Boot\BCD together.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK="$ROOT/qemu/work"
SRC="${1:-$WORK/f1.wim}"
IMG="$WORK/winre.img"
[ -f "$SRC" ] || { echo "build-disk: source WIM not found: $SRC" >&2; exit 1; }
rm -f "$IMG"
dd if=/dev/zero of="$IMG" bs=1M count=600 2>/dev/null
OFF=$((2048 * 512))
# Write a minimal MBR with one FAT32-LBA (0x0C) partition at LBA 2048 (no sfdisk needed).
python3 - "$IMG" <<'PYMBR'
import sys, struct
img = sys.argv[1]
total = 600 * 1024 * 1024 // 512   # total sectors
start = 2048
size = total - start
with open(img, "r+b") as f:
    f.seek(446)
    entry = struct.pack("<B3sB3sII", 0x00, b"\x00\x02\x00", 0x0C, b"\xfe\xff\xff", start, size)
    f.write(entry)
    f.seek(510)
    f.write(b"\x55\xaa")
PYMBR
mformat -i "$IMG@@$OFF" -F -v WINRE ::
B=$(mktemp -d)
wimlib-imagex extract "$SRC" 1 \
  /Windows/Boot/EFI/bootmgfw.efi /Windows/Boot/DVD/EFI/BCD /Windows/Boot/DVD/EFI/boot.sdi \
  --dest-dir="$B" >/dev/null 2>&1
mmd -i "$IMG@@$OFF" ::/EFI
mmd -i "$IMG@@$OFF" ::/EFI/Boot
mmd -i "$IMG@@$OFF" ::/EFI/Microsoft
mmd -i "$IMG@@$OFF" ::/EFI/Microsoft/Boot
mmd -i "$IMG@@$OFF" ::/Boot
mmd -i "$IMG@@$OFF" ::/sources
mcopy -i "$IMG@@$OFF" "$B/bootmgfw.efi" ::/EFI/Boot/bootx64.efi
mcopy -i "$IMG@@$OFF" "$B/BCD"          ::/EFI/Microsoft/Boot/BCD
mcopy -i "$IMG@@$OFF" "$B/boot.sdi"     ::/Boot/boot.sdi
mcopy -i "$IMG@@$OFF" "$SRC"            ::/sources/boot.wim
rm -rf "$B"
echo "UEFI disk built from $SRC:"
ls -l "$IMG"
sha256sum "$IMG"
