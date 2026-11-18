#!/bin/sh
# build-iso.sh - build a UEFI-bootable WinRE ISO from a WIM copy (default F1).
# Uses the DVD boot template inside the WIM (bootmgfw.efi, DVD/EFI/BCD, boot.sdi).
# No tracked part is modified. Output: qemu/work/winre.iso.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK="$ROOT/qemu/work"
ISO="$ROOT/qemu/iso"
SRC="${1:-$WORK/f1.wim}"
[ -f "$SRC" ] || { echo "build-iso: source WIM not found: $SRC" >&2; exit 1; }
rm -rf "$ISO/root"
mkdir -p "$ISO/root/EFI/Boot" "$ISO/root/EFI/Microsoft/Boot" "$ISO/root/Boot" "$ISO/root/sources"
B=$(mktemp -d)
wimlib-imagex extract "$SRC" 1 \
  /Windows/Boot/EFI/bootmgfw.efi /Windows/Boot/DVD/EFI/BCD /Windows/Boot/DVD/EFI/boot.sdi \
  --dest-dir="$B" >/dev/null 2>&1
cp "$B/bootmgfw.efi" "$ISO/root/EFI/Boot/bootx64.efi"
cp "$B/BCD"          "$ISO/root/EFI/Microsoft/Boot/BCD"
cp "$B/boot.sdi"     "$ISO/root/Boot/boot.sdi"
cp "$SRC"            "$ISO/root/sources/boot.wim"
rm -rf "$B"

# FAT EFI boot image (El Torito no-emulation) containing EFI/Boot/bootx64.efi.
# The BCD must live INSIDE this ESP image, not only on the ISO9660 side: OVMF loads
# bootx64.efi from the El Torito image and bootmgfw.efi then reads its own volume for
# \EFI\Microsoft\Boot\BCD. Without it the boot stops at "Windows Boot Manager,
# File: \EFI\Microsoft\Boot\BCD, Status: 0xc000000f" before the kernel is reached.
# The BCD's \boot\boot.sdi and \sources\boot.wim paths resolve against the boot volume
# (the ISO9660 side), which is why both trees are kept.
EFIIMG="$ISO/root/EFI/Boot/efi.img"
dd if=/dev/zero of="$EFIIMG" bs=1M count=4 2>/dev/null
mformat -i "$EFIIMG" ::
mmd -i "$EFIIMG" ::/EFI
mmd -i "$EFIIMG" ::/EFI/Boot
mmd -i "$EFIIMG" ::/EFI/Microsoft
mmd -i "$EFIIMG" ::/EFI/Microsoft/Boot
mcopy -i "$EFIIMG" "$ISO/root/EFI/Boot/bootx64.efi" ::/EFI/Boot/bootx64.efi
mcopy -i "$EFIIMG" "$ISO/root/EFI/Microsoft/Boot/BCD" ::/EFI/Microsoft/Boot/BCD

xorriso -as mkisofs -iso-level 4 -J -joliet-long -R -V WINRE \
  -eltorito-alt-boot -e EFI/Boot/efi.img -no-emul-boot \
  -o "$WORK/winre.iso" "$ISO/root" >/dev/null 2>"$WORK/iso-build.log"
echo "ISO built from $SRC:"
ls -l "$WORK/winre.iso"
sha256sum "$WORK/winre.iso"
