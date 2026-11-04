#!/bin/sh
# montar_iso_winre.sh — gera uma ISO inicializável a partir do Winre.wim JÁ MODIFICADO.
#
# Por que isto existe: converter_iso.sh exige baixar os UUP inteiros (~5 GB) da Microsoft
# para ter uma ISO que arranque. O WinRE 1809 traz DENTRO de si os arquivos de inicialização
# de um DVD de recuperação (/Windows/Boot/DVD/...), então a ISO pode ser montada só com o
# próprio WIM — nada de rede, nada de ADK, roda em qualquer sandbox.
#
# Os caminhos que a ISO precisa satisfazer não são chute: foram lidos do BCD extraído do
# próprio WIM (ver `--bcd`), que aponta o ramdisk para \boot\boot.sdi e o osdevice para
# \sources\boot.wim.
#
# Uso:
#   sh scripts/montar_iso_winre.sh --imagem .work/wim/Winre.lote.wim --saida .work/iso/winre-wwii.iso
#   sh scripts/montar_iso_winre.sh --bcd .work/wim/Winre.lote.wim      # só mostra os caminhos do BCD
#
# Regras de zero-tecla: bootfix.bin (o "Press any key" da MS) e lido do WIM, mas NUNCA
# copiado para a ISO. Sem ele, o etfsboot cai direto no bootmgr, sem exigir tecla.
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
IMAGEM=""; SAIDA=""; BCD_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --imagem) IMAGEM="${2:-}"; shift 2;;
    --saida)  SAIDA="${2:-}"; shift 2;;
    --bcd)    IMAGEM="${2:-.work/wim/Winre.lote.wim}"; BCD_ONLY=1; shift 2;;
    *) echo "uso: montar_iso_winre.sh --imagem <wim> --saida <iso> | --bcd [<wim>]"; exit 2;;
  esac
done
[ -n "$IMAGEM" ] && [ -f "$IMAGEM" ] || { echo "falta --imagem <wim existente>"; exit 2; }
command -v wimlib-imagex >/dev/null 2>&1 || { echo "falta wimlib-imagex (sh scripts/ambiente.sh)"; exit 1; }
command -v xorriso >/dev/null 2>&1 || { echo "falta xorriso (sh scripts/ambiente.sh)"; exit 1; }

W="$R/.work"; RAW="$W/raw-boot"; STAGE="$W/iso/stage"
say(){ printf '[iso] %s\n' "$*"; }
pega(){ # pega <caminho-no-wim> <destino>
  rm -rf "$2.tmp" 2>/dev/null; mkdir -p "$2.tmp"
  if wimlib-imagex extract "$IMAGEM" 1 "$1" --dest-dir "$2.tmp" --no-acls >/dev/null 2>&1; then
    f=$(find "$2.tmp" -type f | head -1); [ -n "$f" ] && { mkdir -p "$(dirname "$2")"; mv -f "$f" "$2"; rm -rf "$2.tmp"; say "OK $(basename "$2") $(stat -c%s "$2") bytes"; return 0; }
  fi
  rm -rf "$2.tmp"; say "FALTA $1 (opcional?)"; return 1
}

if [ "$BCD_ONLY" = 1 ]; then
  mkdir -p "$RAW"
  pega /Windows/Boot/DVD/PCAT/BCD "$RAW/bcd-pcat.dat"
  pega /Windows/Boot/DVD/EFI/BCD  "$RAW/bcd-efi.dat"
  python3 - "$RAW/bcd-pcat.dat" "$RAW/bcd-efi.dat" <<'PY'
import re, sys
for path in sys.argv[1:]:
    raw = open(path, 'rb').read()
    paths = sorted({m.group().decode('utf-16-le', 'ignore')
                    for m in re.finditer(rb'(?:[\x20-\x7e]\x00){4,}', raw)
                    if '\\' in m.group().decode('utf-16-le', 'ignore')})
    print('##', path)
    for s in paths:
        if s.startswith('\\'):
            print('   ', s)
PY
  exit 0
fi

[ -n "$SAIDA" ] || { echo "falta --saida <iso>"; exit 2; }
case "$SAIDA" in /*) : ;; *) SAIDA="$R/$SAIDA";; esac

say "verificando Boot Index do WIM"
wimlib-imagex info "$IMAGEM" 2>/dev/null | sed -n 's/^.*Boot Index: */[iso] Boot Index: /p'

say "extraindo os arquivos de inicializacao do proprio WIM"
rm -rf "$STAGE"; mkdir -p "$STAGE/boot" "$STAGE/efi/microsoft/boot" "$STAGE/sources" "$RAW"
pega /Windows/Boot/DVD/PCAT/BCD            "$STAGE/boot/BCD"
pega /Windows/Boot/DVD/PCAT/boot.sdi       "$STAGE/boot/boot.sdi"
pega /Windows/Boot/DVD/PCAT/etfsboot.com   "$STAGE/boot/etfsboot.com"
pega /Windows/Boot/DVD/EFI/BCD             "$STAGE/efi/microsoft/boot/BCD"
# efisys_noprompt.bin = a mesma imagem de boot EFI SEM o "Press any key to boot from CD".
# Com efisys.bin o OVMF espera a tecla, da timeout no BdsDxe e cai em PXE (visto 2026-11-04).
pega /Windows/Boot/DVD/EFI/en-US/efisys_noprompt.bin "$STAGE/efi/microsoft/boot/efisys.bin" \
  || pega /Windows/Boot/DVD/EFI/en-US/efisys.bin     "$STAGE/efi/microsoft/boot/efisys.bin"
pega /Windows/Boot/EFI/bootmgr.efi         "$STAGE/efi/boot/bootmgfw.efi"
# bootmgr de BIOS (PCAT) EXISTE no Winre.wim em /Windows/Boot/PCAT/bootmgr — ele e que vai na
# RAIZ da ISO com nome ISO9660 "BOOTMGR.;1", que e exatamente o nome que o etfsboot.com procura.
# Sem esse arquivo na raiz, o SeaBIOS carrega o etfsboot e para em "CDBOOT: Couldn't find BOOTMGR".
pega /Windows/Boot/PCAT/bootmgr            "$STAGE/bootmgr"
# BOOTX64.EFI e o mesmo bootmgr.efi com o nome de fallback da spec UEFI. Sem ele o OVMF,
# quando o boot parte da ordem do QEMU (-boot order=d), monta a opcao "UEFI QEMU DVD-ROM"
# como caminho SEM Partition() e falha com "BdsDxe: failed to start ... : No mapping"
# (visto 2026-11-04). Com o arquivo na raiz ISO9660 /EFI/BOOT/ o EDK2 acha o loader.
[ -s "$STAGE/efi/boot/bootmgfw.efi" ] && cp "$STAGE/efi/boot/bootmgfw.efi" "$STAGE/efi/boot/bootx64.efi" \
  && say "efi/boot/bootx64.efi = fallback UEFI do bootmgr"
# bootmgr de BIOS (PCAT) NAO existe dentro do Winre.wim 1809 — so o .efi. Sem ele o El Torito
# BIOS carrega o etfsboot e para em "CDBOOT: Couldn't find BOOTMGR". Se voce tiver o arquivo
# (ADK/midia de instalacao), passe BOOTMGR_PCAT=/caminho/bootmgr que ele vai para a raiz da ISO.
[ -n "${BOOTMGR_PCAT:-}" ] && [ -s "${BOOTMGR_PCAT:-}" ] && { cp "$BOOTMGR_PCAT" "$STAGE/bootmgr" && say "bootmgr PCAT adicionado a raiz (boot de BIOS habilitado)"; }
[ -s "$STAGE/boot/BCD" ] && [ -s "$STAGE/boot/boot.sdi" ] && [ -s "$STAGE/efi/microsoft/boot/efisys.bin" ] \
  || { say "ERRO: faltam arquivos obrigatorios de boot"; exit 1; }

say "colocando o WIM como sources/boot.wim"
cp "$IMAGEM" "$STAGE/sources/boot.wim"
sha256sum "$IMAGEM" | awk '{print $1}' > "$W/iso/boot-wim.sha256"
sha256sum "$STAGE/sources/boot.wim" | awk '{print $1}' > "$W/iso/stage-wim.sha256"
cmp -s "$IMAGEM" "$STAGE/sources/boot.wim" || { say "ERRO: boot.wim difere do WIM de origem"; exit 1; }
say "boot.wim identico a $IMAGEM (byte a byte)"

say "gravando ISO (El Torito: BIOS etfsboot + EFI efisys_noprompt; sem bootfix = zero tecla)"
mkdir -p "$(dirname "$SAIDA")"
rm -f "$SAIDA"
# -boot-load-size 8 = 4096 bytes, o tamanho real do etfsboot.com do 1809. Com 4 (2048) o
# SeaBIOS le a metade e morre em "CDBOOT: Cannot boot from CD - Code: 5" (visto 2026-11-04).
( cd "$STAGE" && xorriso -as mkisofs -o "$SAIDA" \
    -V "WWII_WINRE" -iso-level 3 -R -J --joliet-long \
    -b boot/etfsboot.com -c boot.cat -no-emul-boot -boot-load-size 8 \
    -eltorito-alt-boot -e efi/microsoft/boot/efisys.bin -no-emul-boot \
    . ) 2>&1 | tail -6
[ -s "$SAIDA" ] || { say "ERRO: ISO nao gerada"; exit 1; }

say "conferindo a ISO"
# O etfsboot.com do 1809 procura o identificador ISO9660 exato "BOOTMGR;1". O xorriso grava
# "BOOTMGR." (com ponto, sem versao) e o SeaBIOS para em "CDBOOT: Couldn't find BOOTMGR" —
# medido 2026-11-04. Corrigimos o identificador no registro do diretorio raiz, sem mover
# nenhum byte de dados: o campo e de tamanho variavel e sobra padding no mesmo registro.
python3 - "$SAIDA" <<'PY' || say "AVISO: patch BOOTMGR;1 falhou (boot de BIOS pode falhar)"
import struct, sys
p = sys.argv[1]
blob = open(p, 'rb').read()
pvd = blob[16*2048:17*2048]
assert pvd[1:6] == b'CD001', 'PVD nao encontrado'
loc, size = struct.unpack('<I', pvd[158:162])[0], struct.unpack('<I', pvd[166:170])[0]
buf = bytearray(blob[loc*2048:loc*2048+size])
i, hit = 0, False
while i < len(buf):
    rl = buf[i]
    if rl == 0:
        break
    il = buf[i+32]
    ident = bytes(buf[i+33:i+33+il])
    if ident.startswith(b'BOOTMGR') and ident != b'BOOTMGR;1':
        new = b'BOOTMGR;1'
        assert len(new) <= rl - 33, 'registro pequeno demais'
        buf[i+32] = len(new)
        buf[i+33:i+33+len(new)] = new
        hit = True
        print('[iso]   identificador %r -> BOOTMGR;1' % ident)
    elif ident == b'BOOTMGR;1':
        hit = True
    i += rl
assert hit, 'registro BOOTMGR nao encontrado na raiz'
with open(p, 'r+b') as f:
    f.seek(loc*2048); f.write(bytes(buf))
print('[iso]   identificador da raiz corrigido para BOOTMGR;1')
PY
xorriso -indev "$SAIDA" -report_el_torito as_mkisofs 2>/dev/null | sed 's/^/[iso]   /'
say "conteudo da raiz:"
xorriso -indev "$SAIDA" -find / -maxdepth 2 -type f 2>/dev/null | sed 's/^/[iso]   /' | head -14
printf '[iso] ISO: %s\n[iso] tamanho: %s bytes\n[iso] sha256: %s\n' \
  "$SAIDA" "$(stat -c%s "$SAIDA")" "$(sha256sum "$SAIDA" | cut -d' ' -f1)"
say "bootavel: qemu-system-x86_64 -cdrom $SAIDA  (ver scripts/boot-winre.sh)"
