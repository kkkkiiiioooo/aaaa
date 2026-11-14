#!/bin/sh
# build-iso.sh <wim> <out.iso>  - BIOS (PCAT) WinPE boot ISO from a WinRE WIM. Work in /tmp, never in tracked files.
set -eu
W=$1; O=$2; T=$(mktemp -d)
mkdir -p "$T/boot" "$T/sources"
wimlib-imagex extract "$W" 1 /Windows/Boot/PCAT/bootmgr --dest-dir="$T" >/dev/null
wimlib-imagex extract "$W" 1 /Windows/Boot/DVD/PCAT/BCD /Windows/Boot/DVD/PCAT/boot.sdi /Windows/Boot/DVD/PCAT/etfsboot.com --dest-dir="$T/boot" >/dev/null
mv "$T"/boot/BCD "$T"/boot/boot.sdi "$T"/boot/etfsboot.com "$T"/boot/ 2>/dev/null || true
cp "$W" "$T/sources/boot.wim"
genisoimage -quiet -o "$O" -b boot/etfsboot.com -no-emul-boot -boot-load-size 8 -iso-level 3 -udf -allow-limited-size -D -N -joliet-long -V WINRE "$T"
rm -rf "$T"
