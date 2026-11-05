#!/bin/sh
# registrar_ambiente.sh <agente> - mede ESTE ambiente e grava ambientes/<agente>.md. Cada agente tem o seu; nunca copie o de outro.
# Idempotente (sobrescreve so a parte medida; notas manuais ficam depois da marca "## Notas do agente").
A=${1:-${A:-agente}}; cd "$(dirname "$0")/.."||exit 1; F="ambientes/$A.md"; mkdir -p ambientes
N=""; [ -f "$F" ]&&N=$(sed -n '/^## Notas do agente/,$p' "$F")
{
echo "# Ambiente do agente: $A"
echo "Medido em $(date -u +%FT%TZ) por $A. **So vale para este agente.** Outro agente tem outro ambiente: nao misture."
echo; echo "## Maquina"
. /etc/os-release 2>/dev/null; echo "- SO: ${PRETTY_NAME:-?} | kernel: $(uname -sr) | arq: $(uname -m) | usuario: $(id -un)"
echo "- CPUs: $(nproc) | RAM: $(free -m|awk '/Mem/{print $2}') MB | disco livre: $(df -m .|awk 'NR==2{print $4}') MB | KVM: $([ -e /dev/kvm ]&&echo sim||echo NAO)"
echo "- modulo vfat no kernel: $(grep -qw vfat /proc/filesystems&&echo sim||echo NAO)"
echo; echo "## Ferramentas (OK = presente, -- = ausente)"
for c in qemu-system-x86_64 wimlib-imagex xorriso mcopy 7z unsquashfs cpio zstd xz python3 pip3 node npm gcc make git curl wget jq objdump strings ip busybox depmod xxd file fdisk sfdisk parted mkfs.vfat ntfs-3g cabextract hivexsh reglookup chntpw bsdtar genisoimage smbclient tftp;do p=$(command -v $c 2>/dev/null);[ -n "$p" ]&&printf 'OK:%s ' $c||printf -- '--:%s ' $c;done;echo
echo "- qemu: $(qemu-system-x86_64 --version 2>/dev/null|head -1)"
echo "- wimlib: $(wimlib-imagex --version 2>&1|head -1)"
echo "- python: $(python3 --version 2>&1) | modulos: $(for m in regipy pefile requests;do python3 -c "import $m" 2>/dev/null&&printf '%s ' $m;done)"
echo; echo "## Rede (HTTP, 6 s de limite)"
for h in dl-cdn.alpinelinux.org archive.ubuntu.com github.com pypi.org registry.npmjs.org catalog.s.download.windowsupdate.com uupdump.net learn.microsoft.com www.catalog.update.microsoft.com;do c=$(curl -s -o /dev/null -m 6 -w '%{http_code}' -I https://$h 2>/dev/null);echo "- $h: ${c:-000}"; done
echo; echo "## Limitacoes medidas"
[ -e /dev/kvm ]||echo "- sem KVM: QEMU so em TCG (boot do WinRE leva dezenas de minutos)"
grep -qw vfat /proc/filesystems||echo "- sem vfat: ler disco FAT so por mtools"
echo "- cada teste de boot e limitado pelos CPUs/RAM acima"
echo; if [ -n "$N" ];then echo "$N";else echo "## Notas do agente"; echo "(escreva aqui o que so voce descobriu sobre este ambiente: limites, falhas, jeitos de contornar)"; fi
} > "$F"
echo "[ambiente] gravado $F"
