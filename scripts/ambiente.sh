#!/bin/sh
# ambiente.sh — prepara o ambiente de trabalho (idempotente e adaptável).
# Detecta SO, gerenciador de pacotes e privilégios; instala só o que falta.
# Uso: sh scripts/ambiente.sh
set -u
say(){ printf '[ambiente] %s\n' "$*"; }

# --- privilégios ---
SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO=sudo

# --- gerenciador de pacotes ---
PM=""
for p in apt-get dnf yum apk pacman zypper brew; do
  command -v "$p" >/dev/null 2>&1 && { PM="$p"; break; }
done
[ -z "$PM" ] && say "aviso: nenhum gerenciador conhecido; assumindo dependencias ja presentes"
say "gerenciador: ${PM:-nenhum}"

# --- nomes de pacotes por gerenciador (ferramenta -> pacote) ---
pkg_name(){
  case "$PM" in
    apt-get|apt)
      case "$1" in
        wimlib-imagex) echo wimtools;;
        7z|7za) echo p7zip-full;;
        aria2c) echo aria2;;
        python3) echo python3;;
        qemu-system-x86_64) echo qemu-system-x86;;
        qemu-img) echo qemu-utils;;
        busybox) echo busybox-static;;
        unsquashfs) echo squashfs-tools;;
        *) echo "$1";;
      esac ;;
    dnf|yum|zypper)
      case "$1" in
        wimlib-imagex) echo wimlib-utils;;
        7z|7za) echo p7zip-plugins;;
        *) echo "$1";;
      esac ;;
    apk)
      case "$1" in
        wimlib-imagex) echo wimlib;;
        7z|7za) echo p7zip;;
        *) echo "$1";;
      esac ;;
    pacman)
      case "$1" in
        wimlib-imagex) echo wimlib;;
        7z|7za) echo p7zip;;
        *) echo "$1";;
      esac ;;
    *) echo "$1";;
  esac
}

instalar(){
  for tool in "$@"; do
    command -v "$tool" >/dev/null 2>&1 && { say "ok: $tool"; continue; }
    [ -z "$PM" ] && { say "FALTA: $tool (instale manualmente)"; continue; }
    p=$(pkg_name "$tool")
    say "instalando $tool (pacote $p)"
    case "$PM" in
      apt-get)   $SUDO apt-get update -qq && $SUDO apt-get install -y -qq "$p" >/dev/null 2>&1;;
      dnf|yum)   $SUDO $PM install -y -q "$p" >/dev/null 2>&1;;
      zypper)    $SUDO zypper -n install -q "$p" >/dev/null 2>&1;;
      apk)       $SUDO apk add -q "$p" >/dev/null 2>&1;;
      pacman)    $SUDO pacman -S --noconfirm -q "$p" >/dev/null 2>&1;;
      brew)      brew install -q "$p" >/dev/null 2>&1;;
    esac
    command -v "$tool" >/dev/null 2>&1 && say "ok: $tool" || say "FALTA: $tool (instale manualmente)"
  done
}

instalar curl wget wimlib-imagex 7z aria2c python3 \
         qemu-system-x86_64 qemu-img busybox unsquashfs cpio gzip

# --- diretórios de trabalho (ignorados pelo git) ---
for d in .work .work/logs .work/uup .work/iso .work/mnt .work/vm .work/downloads; do mkdir -p "$d"; done

# --- recursos do ambiente (útil para decidir o que da para rodar) ---
say "disco livre: $(df -h . 2>/dev/null | awk 'NR==2{print $4}')"
say "memoria: $(free -h 2>/dev/null | awk 'NR==2{print $2}')"
# KVM so conta se /dev/kvm for ESCREVEL. O pacote qemu instala o binario /usr/bin/kvm,
# e um `command -v kvm` ingenuo dava "virtualizacao: kvm" mesmo sem o modulo carregado
# (kvm: Could not access KVM kernel module) - falso positivo que empurra o agente para
# um caminho de teste que nao existe.
if [ -w /dev/kvm ]; then say "virtualizacao: kvm (acelerada)"; else say "virtualizacao: sem kvm - QEMU usara TCG (emulacao, lenta)"; fi
for v in docker qemu-system-x86_64 virtualbox; do
  command -v "$v" >/dev/null 2>&1 && say "virtualizacao: $v"
done
say "pronto."
