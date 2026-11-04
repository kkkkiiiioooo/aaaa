#!/bin/sh
# montar_disco_winre.sh — monta um disco GPT/ESP com o WinRE modificado, pronto para boot UEFI.
#
# Por que nao basta a ISO: medida em 2026-11-04, o OVMF (EDK2 2022) recusa a ISO El Torito
# com "BdsDxe: failed to start Boot0001 'UEFI QEMU DVD-ROM': No mapping" — a ordem de boot
# vinda do fw_cfg do QEMU gera um caminho de dispositivo SEM a particao do El Torito, e o
# loader nao e localizado. E com SeaBIOS/BIOS falta o nome ISO9660 exato que o etfsboot
# procura (o etfsboot.com do 1809 busca "BOOTMGR;1"; xorriso grava "BOOTMGR."). O disco com
# ESP/GPT nao tem nenhum desses problemas: o EDK2 monta o FAT32 da ESP e acha
# \EFI\BOOT\BOOTX64.EFI sozinho. E e tambem o formato do mundo real: maquina UEFI guarda o
# WinRE numa particao de recuperacao e o boot sai do ESP, nao de um CD.
#
# Layout da ESP (os caminhos nao sao chute: foram lidos do BCD EFI dentro do proprio WIM):
#   /EFI/BOOT/BOOTX64.EFI        = /Windows/Boot/EFI/bootmgr.efi
#   /EFI/MICROSOFT/BOOT/BCD      = /Windows/Boot/DVD/EFI/BCD
#   /BOOT/BOOT.SDI               = /Windows/Boot/DVD/EFI/boot.sdi
#   /SOURCES/BOOT.WIM            = o Winre.wim com drivers (E2) + autorun (E3)
#
# Uso: sh scripts/montar_disco_winre.sh --imagem .work/wim/Winre.lote.wim --saida .work/vm/winre-esp.img
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
IMAGEM=""; SAIDA=""; TAM="${TAM:-4G}"
while [ $# -gt 0 ]; do
  case "$1" in
    --imagem) IMAGEM="${2:-}"; shift 2;;
    --saida)  SAIDA="${2:-}"; shift 2;;
    --tamanho) TAM="${2:-}"; shift 2;;
    *) echo "uso: montar_disco_winre.sh --imagem <wim> --saida <img> [--tamanho 4G]"; exit 2;;
  esac
done
[ -n "$IMAGEM" ] && [ -f "$IMAGEM" ] || { echo "falta --imagem <wim>"; exit 2; }
[ -n "$SAIDA" ] || { echo "falta --saida <img>"; exit 2; }
case "$SAIDA" in /*) : ;; *) SAIDA="$R/$SAIDA";; esac
for c in wimlib-imagex mkfs.vfat fdisk qemu-img mcopy; do
  command -v "$c" >/dev/null 2>&1 || { echo "falta $c (sh scripts/ambiente.sh; mtools)"; exit 1; }
done
say(){ printf '[esp] %s\n' "$*"; }
W="$R/.work"; RAW="$W/esp-files"; FAT="$W/esp-fat.img"
rm -rf "$RAW"; mkdir -p "$RAW/EFI/BOOT" "$RAW/EFI/MICROSOFT/BOOT" "$RAW/BOOT" "$RAW/SOURCES"

pega(){ # pega <caminho-no-wim> <destino>
  rm -rf "$1.tmp" 2>/dev/null; mkdir -p "$1.tmp"
  if wimlib-imagex extract "$IMAGEM" 1 "$2" --dest-dir "$1.tmp" --no-acls >/dev/null 2>&1; then
    f=$(find "$1.tmp" -type f | head -1); [ -n "$f" ] && mv -f "$f" "$1" && rm -rf "$1.tmp" \
      && { say "OK $1 ($(stat -c%s "$1") bytes)"; return 0; }
  fi
  rm -rf "$1.tmp"; say "FALTA $2"; return 1
}
pega "$RAW/EFI/BOOT/BOOTX64.EFI"            /Windows/Boot/EFI/bootmgr.efi
pega "$RAW/EFI/MICROSOFT/BOOT/BCD"          /Windows/Boot/DVD/EFI/BCD
pega "$RAW/BOOT/BOOT.SDI"                   /Windows/Boot/DVD/EFI/boot.sdi
[ -s "$RAW/EFI/BOOT/BOOTX64.EFI" ] && [ -s "$RAW/EFI/MICROSOFT/BOOT/BCD" ] && [ -s "$RAW/BOOT/BOOT.SDI" ] \
  || { say "ERRO: faltam arquivos de boot EFI"; exit 1; }
say "copiando o WIM para SOURCES/BOOT.WIM"
cp "$IMAGEM" "$RAW/SOURCES/BOOT.WIM"

# --- imagem FAT32 da ESP (sem tabela de particoes: mtools escreve nela direto) ---
SECT=$(du -sk "$RAW" | cut -f1); SECT=$(( (SECT/2) + 262144 ))   # conteudo + folga de 128 MB
[ "$SECT" -lt 4194304 ] && SECT=4194304                          # >=2 GB para o mkfs aceitar FAT32
say "criando volume ESP com $((SECT/2048)) MB"
rm -f "$FAT"; mkfs.vfat -F 32 -n WINRE_ESP -C "$FAT" "$SECT" >/dev/null 2>&1 || { say "ERRO mkfs.vfat"; exit 1; }
mmd -i "$FAT" ::/EFI ::/EFI/BOOT ::/EFI/MICROSOFT ::/EFI/MICROSOFT/BOOT ::/BOOT ::/SOURCES 2>/dev/null
( cd "$RAW" && find . -type f | sed 's|^\./||' | while read -r f; do
    d=$(dirname "$f"); mmd -i "$FAT" "::/$d" 2>/dev/null
    mcopy -n "$f" -i "$FAT" "::$f" || { say "ERRO copiando $f"; exit 1; }
  done ) || exit 1
say "conteudo da ESP:"; mdir -i "$FAT" -/ :: 2>/dev/null | sed 's/^/[esp]   /' | head -8

# --- disco MBR com a ESP dentro (tipo 0x0C FAT32 LBA: o EDK2 monta o FAT e acha o loader) ---
say "criando disco MBR $SAIDA ($TAM)"
rm -f "$SAIDA"; qemu-img create -f raw "$SAIDA" "$TAM" >/dev/null || { say "ERRO qemu-img"; exit 1; }
printf 'o\nn\np\n1\n2048\n\n\nt\n0c\nw\n' | fdisk "$SAIDA" >/dev/null 2>&1 || { say "ERRO fdisk (MBR)"; exit 1; }
fdisk -l "$SAIDA" 2>/dev/null | sed 's/^/[esp]   /' | tail -4
OFF=$(fdisk -l -o Start "$SAIDA" 2>/dev/null | awk 'NR>2 && $1 ~ /^[0-9]+$/{print $1; exit}')
[ -n "$OFF" ] || { say "ERRO: offset da particao nao encontrado"; exit 1; }
say "gravando a ESP no offset de setor $OFF"
# conv=sparse: o volume FAT32 minimo (2 GB) e quase todo zero; sem sparse o dd come disco real.
if [ $((OFF % 2048)) -eq 0 ]; then
  dd if="$FAT" of="$SAIDA" bs=1M seek=$((OFF/2048)) conv=notrunc,sparse status=none || { say "ERRO dd"; exit 1; }
else
  dd if="$FAT" of="$SAIDA" bs=512 seek="$OFF" conv=notrunc,sparse status=none || { say "ERRO dd"; exit 1; }
fi
sync
say "verificando pelo fdisk + mtools (partition=1)"
printf 'mtools_skip_check=1\ndrive e:\n  file="%s"\n  partition=1\n' "$SAIDA" > "$W/esp-mtoolsrc"
MTOOLSRC="$W/esp-mtoolsrc" mdir -/ e:/ 2>/dev/null | sed 's/^/[esp]   /' | head -6
MTOOLSRC="$W/esp-mtoolsrc" mdir e:/EFI/BOOT 2>/dev/null | sed 's/^/[esp]   /' | head -6
printf '[esp] DISCO: %s\n[esp] sha256: %s\n' "$SAIDA" "$(sha256sum "$SAIDA" | cut -d' ' -f1)"
say "boot: qemu-system-x86_64 -bios OVMF_CODE.fd -hda $SAIDA  (ou FWMODE=uefi DISK_BOOT=$SAIDA sh scripts/boot-winre.sh)"
