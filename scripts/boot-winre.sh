#!/bin/sh
# boot-winre.sh — E4: dá boot na ISO do WinRE em QEMU e LÊ o log que o autorun gravou em disco.
#
# O gate da E4 não é "a ISO existe": é provar que o PE subiu SOZINHO (sem tecla), rodou
# autorun-wwii.cmd e gravou wwii.log num volume. Este script faz os três:
#   1. cria um disco de dados (MBR + FAT32) — o PE mostra como C: e o autorun copia
#      X:\wwii.log para C:\wwii.log
#   2. sobe QEMU em segundo plano (TCG, sem KVM), com monitor unix e serial em arquivo
#   3. a cada POLL s: screendump (prova visual) + leitura de C:\wwii.log PELO HOST, sem
#      montar nada (mtools lê a partição direto do .img via `partition=1` no ~/.mtoolsrc;
#      o kernel deste sandbox não tem o módulo vfat, então mount NÃO é opção)
#   4. sai sozinho quando o log traz "autorun-wwii end" ou quando estoura o TIMEOUT
#
# Uso: sh scripts/boot-winre.sh [--iso .work/iso/winre-wwii.iso] [--disk .work/vm/dados.img]
#          [--timeout 1800] [--poll 20] [--mem 4096] [--cpus 2]
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
ISO=${ISO:-$R/.work/iso/winre-wwii.iso}
DISK=${DISK:-$R/.work/vm/dados.img}
VM=$R/.work/vm
TIMEOUT=${TIMEOUT:-1800}
POLL=${POLL:-20}
MEM=${MEM:-4096}
CPUS=${CPUS:-2}
while [ $# -gt 0 ]; do
  case "$1" in
    --iso) ISO="$2"; shift 2;; --disk) DISK="$2"; shift 2;;
    --timeout) TIMEOUT="$2"; shift 2;; --poll) POLL="$2"; shift 2;;
    --mem) MEM="$2"; shift 2;; --cpus) CPUS="$2"; shift 2;;
    *) echo "opcao desconhecida: $1"; exit 2;;
  esac
done
case "$ISO" in /*) : ;; *) ISO="$R/$ISO";; esac
case "$DISK" in /*) : ;; *) DISK="$R/$DISK";; esac
say(){ printf '[boot] %s %s\n' "$(date -u +%H:%M:%S)" "$*"; }
die(){ say "ERRO: $*"; exit 1; }

command -v qemu-system-x86_64 >/dev/null 2>&1 || die "falta qemu-system-x86_64 (sh scripts/ambiente.sh)"
command -v mtype >/dev/null 2>&1 || die "falta mtools (apt-get install -y mtools)"
command -v socat >/dev/null 2>&1 || die "falta socat (para o monitor do QEMU)"
[ -s "$ISO" ] || die "ISO ausente: $ISO (sh scripts/montar_iso_winre.sh)"
mkdir -p "$VM" "$(dirname "$DISK")"

# --- mtools enxergando a particao 1 do arquivo-bruto (sem loop, sem mount) ---
MTSRC="$VM/mtoolsrc"
printf 'mtools_skip_check=1\ndrive t:\n  file="%s"\n  partition=1\n' "$DISK" > "$MTSRC"
export MTOOLSRC="$MTSRC"   # mdir/mtype/mcopy/mrm passam a ver t:/ = particao 1 do disco

# --- disco de dados: MBR + 1 particao FAT32 (>=2G para o mkfs aceite FAT32 de verdade) ---
if [ ! -s "$DISK" ]; then
  say "criando disco de dados $DISK (3G, MBR + 1 particao FAT32)"
  qemu-img create -f raw "$DISK" 3G >/dev/null || die "qemu-img create"
  printf 'o\nn\np\n1\n2048\n\n\nt\n0c\nw\n' | fdisk "$DISK" >/dev/null 2>&1 || die "fdisk"
  losetup -a 2>/dev/null | grep -F "$DISK" | cut -d: -f1 | while read -r l; do losetup -d "$l" 2>/dev/null; done
  LOOP=$(losetup -f -P --show "$DISK") || die "losetup"
  mkfs.vfat -F 32 -n WWIIDS "${LOOP}p1" >/dev/null 2>&1 || die "mkfs.vfat"
  losetup -d "$LOOP" 2>/dev/null
fi
mdir t:/ >/dev/null 2>&1 || die "sem FAT na particao 1 de $DISK (recrie o disco)"
mrm t:/wwii.log >/dev/null 2>&1
printf 'host gravou isto ANTES do boot (%s)\n' "$(date -u +%FT%TZ)" > "$VM/marca-host.txt"
mcopy "$VM/marca-host.txt" t:/host_marker.txt >/dev/null 2>&1 && say "host_marker.txt gravado no disco"

# --- QEMU ---
# Firmware: UEFI (OVMF) por padrao. Motivo, medido em 2026-11-04: o Winre.wim 1809 traz
# bootmgr.efi, mas NAO traz o bootmgr de BIOS (PCAT) — com SeaBIOS o etfsboot roda e para em
# "CDBOOT: Couldn't find BOOTMGR". BIOS so funciona com BOOTMGR_PCAT apontando para o arquivo
# (midia de instalacao/ADK). Para o teste do autorun isso e irrelevante: o que se quer provar
# e que o PE sobe sem tecla e grava log, e o mesmo winpeshl.ini vale para os dois firmwares.
MON="$VM/monitor.sock"; PIDF="$VM/qemu.pid"; SERIAL="$VM/serial.log"; LOG="$VM/qemu.log"
rm -f "$MON" "$SERIAL" "$LOG"
[ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null
FWMODE=${FWMODE:-uefi}
FW=""
if [ "$FWMODE" = uefi ]; then
  CODE=${OVMF_CODE:-/usr/share/OVMF/OVMF_CODE_4M.fd}
  VARS_T=/usr/share/OVMF/OVMF_VARS_4M.fd
  VARS="$VM/ovmf-vars.fd"
  [ -s "$CODE" ] || die "sem OVMF_CODE em $CODE (apt-get install -y ovmf) ou use FWMODE=bios"
  cp -f "$VARS_T" "$VARS"
  FW="-drive if=pflash,format=raw,readonly=on,file=$CODE -drive if=pflash,format=raw,file=$VARS"
fi
say "subendo QEMU TCG ($FWMODE) mem=${MEM}MB cpus=${CPUS} timeout=${TIMEOUT}s"
setsid qemu-system-x86_64 \
  -name wwii-e4 -pidfile "$PIDF" \
  -m "$MEM" -smp "$CPUS" -cpu qemu64 \
  $FW \
  -boot order=d -cdrom "$ISO" -hda "$DISK" \
  -netdev user,id=n0,dhcpstart=10.0.2.15 -device e1000,netdev=n0,mac=52:54:00:00:04:04 \
  -display none -vga std \
  -serial "file:$SERIAL" \
  -monitor "unix:$MON,server,nowait" \
  > "$LOG" 2>&1 < /dev/null &
sleep 8
QP=$(cat "$PIDF" 2>/dev/null || pgrep -f 'wwii-e4' | head -1)
[ -n "$QP" ] || { tail -20 "$LOG"; die "qemu nao subiu"; }
say "qemu pid=$QP"

mon(){ printf '%s\n' "$1" | socat - UNIX-CONNECT:"$MON" 2>/dev/null; }
shot(){ # shot <rotulo> -> arquivo .ppm (QEMU 6.x so grava PPM)
  rm -f "$VM/shot-$1.ppm"
  mon "screendump $VM/shot-$1.ppm" >/dev/null 2>&1
  [ -s "$VM/shot-$1.ppm" ]
}
readlog(){ # readlog <rotulo> -> .work/vm/wwii-<rotulo>.log
  rm -f "$VM/wwii-$1.log"
  mtype t:/wwii.log > "$VM/wwii-$1.log" 2>/dev/null && [ -s "$VM/wwii-$1.log" ]
}

START=$(date +%s); N=0; FOUND=0
while :; do
  EL=$(( $(date +%s) - START ))
  [ "$EL" -gt "$TIMEOUT" ] && { say "timeout de ${TIMEOUT}s atingido"; break; }
  kill -0 "$QP" 2>/dev/null || { say "qemu encerrou sozinho em ${EL}s"; break; }
  N=$((N+1)); T=$(printf '%03d' "$N")
  shot "$T" && say "${EL}s: tela capturada (shot-$T.ppm)"
  if readlog "$T"; then
    FOUND=1
    say "${EL}s: wwii.log LIDO DO DISCO ($(wc -l < "$VM/wwii-$T.log") linhas)"
    grep -q 'autorun-wwii end' "$VM/wwii-$T.log" && { say "${EL}s: autorun concluido"; break; }
  fi
  sleep "$POLL"
done

mon "system_power" >/dev/null 2>&1
kill -TERM "$QP" 2>/dev/null; sleep 3; kill -KILL "$QP" 2>/dev/null
sleep 1
readlog final && say "LOG FINAL: .work/vm/wwii-final.log" || say "sem wwii.log no disco"
mdir t:/ 2>/dev/null | sed 's/^/[boot] disco: /'
say "evidencia: $VM (shot-*.ppm, serial.log, wwii-*.log, qemu.log)"
[ "$FOUND" = 1 ] || exit 1
exit 0
