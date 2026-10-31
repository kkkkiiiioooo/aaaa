#!/bin/sh
# build-initramfs.sh — monta o initramfs de teste (busybox estatico + modulos + suite).
# Uso: sh scripts/build-initramfs.sh   (depende de: busybox, cpio, gzip, unsquashfs)
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VM="$ROOT/.work/vm"
DL="$ROOT/.work/downloads"
BB=$(command -v busybox || true)
[ -x "$BB" ] || { echo "[build-initramfs] busybox ausente. Rode: sh scripts/env-setup.sh"; exit 1; }

rm -rf "$VM/initrd"
mkdir -p "$VM/initrd/bin" "$VM/initrd/dev" "$VM/initrd/proc" "$VM/initrd/sys" \
         "$VM/initrd/tmp" "$VM/initrd/mnt/winre" "$VM/initrd/recovery"
cp "$BB" "$VM/initrd/bin/busybox"

# applets usados pelos testes
for a in sh mount umount cat echo ls mkdir dd tar gzip ip fdisk poweroff reboot \
         sleep dmesg mountpoint grep sed awk cut sync wc find ln head tail \
         modprobe insmod; do
  ln -sf busybox "$VM/initrd/bin/$a"
done

# modulos do kernel: sd_mod (disco) + deps, extraidos do modloop
MODSRC="$VM/modloop"
if [ ! -d "$MODSRC/modules" ] && [ -s "$DL/modloop-virt" ] && command -v unsquashfs >/dev/null 2>&1; then
  rm -rf "$MODSRC"; unsquashfs -f -d "$MODSRC" "$DL/modloop-virt" >/dev/null 2>&1 || true
fi
if [ -d "$MODSRC/modules" ]; then
  MODVER=$(ls "$MODSRC/modules" | head -n1)
  MDIR="$MODSRC/modules/$MODVER"
  mkdir -p "$VM/initrd/lib/modules/$MODVER"
  cp "$MDIR/modules.dep" "$VM/initrd/lib/modules/$MODVER/" 2>/dev/null || true
  # alvos + dependencias transitivas (sd_mod=disco, virtio_net=rede)
  targets="kernel/drivers/scsi/sd_mod.ko kernel/drivers/net/virtio_net.ko"
  more=1
  while [ "$more" = 1 ]; do
    more=0
    for t in $targets; do
      for x in $(grep -E "^$t:" "$MDIR/modules.dep" 2>/dev/null | sed 's/^[^:]*://'); do
        case " $targets " in *" $x "*) ;; *) targets="$targets $x"; more=1 ;; esac
      done
    done
  done
  for m in $targets; do
    [ -f "$MDIR/$m" ] || continue
    mkdir -p "$VM/initrd/lib/modules/$MODVER/$(dirname "$m")"
    cp "$MDIR/$m" "$VM/initrd/lib/modules/$MODVER/$m"
  done
  echo "[build-initramfs] modulos incluidos ($MODVER): $(echo $targets | wc -w)"
else
  echo "[build-initramfs] aviso: modloop ausente -> disco/rede podem nao aparecer na VM"
fi

cp "$ROOT/scripts/tests/in-vm-tests.sh" "$VM/initrd/run-tests.sh"
chmod +x "$VM/initrd/run-tests.sh"

cat > "$VM/initrd/init" <<'EOF'
#!/bin/busybox sh
/bin/busybox mount -t proc   none /proc 2>/dev/null
/bin/busybox mount -t sysfs  none /sys  2>/dev/null
/bin/busybox mount -t devtmpfs none /dev 2>/dev/null
export PATH=/bin
echo "=== INITRAMFS-TESTE: inicio ==="
modprobe sd_mod 2>/dev/null          # "injeta" o driver de disco (analogo ao driver Wi-Fi)
modprobe virtio_net 2>/dev/null      # "injeta" o driver de rede (so aparece se houver NIC)
sh /run-tests.sh; rc=$?
echo "=== INITRAMFS-TESTE: fim rc=$rc ==="
sync
/bin/busybox poweroff -f
EOF
chmod +x "$VM/initrd/init"

( cd "$VM/initrd" && find . | cpio -o -H newc 2>/dev/null | gzip -9 > "$VM/initramfs.cpio.gz" )
echo "[build-initramfs] ok: $VM/initramfs.cpio.gz ($(wc -c <"$VM/initramfs.cpio.gz") bytes)"
