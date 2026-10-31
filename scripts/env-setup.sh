#!/bin/sh
# env-setup.sh — prepara o ambiente de TESTE (idempotente).
# Detecta a distro, instala QEMU + utilitários e reporta a virtualização disponível.
# Uso: sh scripts/env-setup.sh
set -u

echo "[env-setup] detectando ambiente..."
have() { command -v "$1" >/dev/null 2>&1; }

# Pacotes por gerenciador
apt_pkgs="qemu-system-x86 qemu-utils busybox-static cpio gzip squashfs-tools curl wget xz-utils unzip ca-certificates"
dnf_pkgs="qemu-system-x86 qemu-img edk2-ovmf cpio curl wget xz unzip ca-certificates"
pac_pkgs="qemu-full qemu-img edk2-ovmf cpio curl wget xz unzip ca-certificates"

instalar() {
  [ "$(id -u)" = 0 ] || { echo "[env-setup] sem root: pule a instalação de pacotes"; return 1; }
  if have apt-get; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null 2>&1
    # shellcheck disable=SC2086
    apt-get install -y -qq $apt_pkgs >/dev/null 2>&1
  elif have dnf; then
    # shellcheck disable=SC2086
    dnf install -y -q $dnf_pkgs >/dev/null 2>&1
  elif have pacman; then
    pacman -Sy --noconfirm --needed $pac_pkgs >/dev/null 2>&1
  else
    echo "[env-setup] gerenciador de pacotes nao reconhecido"; return 1
  fi
}

if have qemu-system-x86_64 && have qemu-img; then
  echo "[env-setup] QEMU ja instalado."
else
  echo "[env-setup] instalando QEMU e dependencias..."
  instalar || echo "[env-setup] instale manualmente: qemu-system-x86, qemu-img"
fi

# Relatorio do ambiente
echo "[env-setup] qemu: $(command -v qemu-system-x86_64 || echo ausente)"
echo "[env-setup] qemu-img: $(command -v qemu-img || echo ausente)"
echo "[env-setup] cpio: $(command -v cpio || echo ausente)"
if [ -w /dev/kvm ]; then
  echo "[env-setup] aceleracao: KVM disponivel (/dev/kvm)"
else
  echo "[env-setup] aceleracao: SEM KVM -> emulacao TCG (lenta, use -cpu max e timeout maior)"
fi
echo "[env-setup] pronto."
