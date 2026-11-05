#!/bin/sh
# chovar-qemu.sh — E4: varre configurações de QEMU/TCG e diz qual delas deixa o WinRE chegar
# no autorun, com tempo e veredito por linha.
#
# Por que existe: o PE com drivers+autorun injetados dá bugcheck (SYSTEM_THREAD_EXCEPTION_
# NOT_HANDLED, tela laranja) em ~200 s de emulação. O WIM original, sem nada injetado, dá a
# MESMA tela laranja — logo a falha não é (só) da injeção, é do ambiente de teste. Trocar uma
# variável por vez e medir é o único jeito de achar qual.
#
# Classificação da tela é medida, não suposição: o frame VNC é lido por scripts/vncshot.py e
# contado por amostragem 64x48; "laranja" = >60% das amostras na faixa do bugscreen 1809
# (R>150, 60<G<160, B<60). Isso foi calibrado contra frames reais do BSOD e da tela de logo.
#
# Uso: sh scripts/chovar-qemu.sh --rotulo smp1 --extra "-smp 1" [--iso <iso>] [--timeout 420]
#      [--mem 4096] [--cpu max] [--porta 5910]
# Resultado: uma linha em .work/chovar/resultados.tsv  (rotulo | extra | segundos | veredito)
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
ISO=${ISO:-$R/.work/iso/winre-wwii-raw.iso}
ROTULO=${ROTULO:-teste}
EXTRA=${EXTRA:-}
TIMEOUT=${TIMEOUT:-420}
MEM=${MEM:-4096}
CPUS=${CPUS:-3}
CPU=${CPU:-qemu64}
PORTA=${PORTA:-5910}
while [ $# -gt 0 ]; do
  case "$1" in
    --rotulo) ROTULO="$2"; shift 2;; --extra) EXTRA="$2"; shift 2;;
    --iso) ISO="$2"; shift 2;; --timeout) TIMEOUT="$2"; shift 2;;
    --mem) MEM="$2"; shift 2;; --cpus) CPUS="$2"; shift 2;;
    --cpu) CPU="$2"; shift 2;; --porta) PORTA="$2"; shift 2;;
    *) echo "opcao desconhecida: $1"; exit 2;;
  esac
done
D="$R/.work/chovar/$ROTULO"
mkdir -p "$D"
TSV="$R/.work/chovar/resultados.tsv"
DISK="$D/dados.img"
MON="$D/monitor.sock"
DISPNUM=$((PORTA - 5900))   # --porta 5910 -> display :10 e TCP 5910
say(){ printf '[chove %s] %s %s\n' "$ROTULO" "$(date -u +%H:%M:%S)" "$*"; }

# disco de dados próprio por configuração (VMs concorrentes nunca compartilham .img cru)
if [ ! -s "$DISK" ]; then
  qemu-img create -f raw "$DISK" 3G >/dev/null || { say "falha qemu-img"; exit 1; }
  printf 'o\nn\np\n1\n2048\n\n\nt\n0c\nw\n' | fdisk "$DISK" >/dev/null 2>&1
  LOOP=$(losetup -f -P --show "$DISK") || { say "falha losetup"; exit 1; }
  mkfs.vfat -F 32 -n WWIIDS "${LOOP}p1" >/dev/null 2>&1
  losetup -d "$LOOP" 2>/dev/null
fi
MTS="$D/mtoolsrc"
printf 'mtools_skip_check=1\ndrive t:\n  file="%s"\n  partition=1\n' "$DISK" > "$MTS"
export MTOOLSRC="$MTS"

setsid sh -c "exec qemu-system-x86_64 -name chovar-$ROTULO -pidfile $D/qemu.pid \
  -m $MEM -smp $CPUS -cpu $CPU $EXTRA \
  -boot order=d -cdrom $ISO -hdb $DISK \
  -display vnc=127.0.0.1:$DISPNUM \
  -serial file:$D/serial.log \
  -monitor unix:$MON,server,nowait" > "$D/qemu.log" 2>&1 < /dev/null &
sleep 8
QP=$(cat "$D/qemu.pid" 2>/dev/null || pgrep -f "chovar-$ROTULO" | head -1)
[ -n "$QP" ] || { tail -20 "$D/qemu.log"; say "qemu nao subiu"; exit 1; }
say "qemu pid=$QP extra='$EXTRA' porta=$PORTA"

classe(){ # classe <png> -> bsod | logo | texto | vazio
  python3 - "$1" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert('RGB')
w, h = im.size
px = list(im.resize((64, 48)).getdata())
n = len(px)
laranja = sum(1 for p in px if p[0] > 150 and 60 < p[1] < 160 and p[2] < 60)
claro = sum(1 for p in px if sum(p) > 480)
if laranja * 5 > n * 3:
    print('bsod')
elif claro * 20 > n:
    print('logo')
elif w == 720:
    print('texto')
else:
    print('vazio')
PY
}
temlog(){ mtype t:/wwii.log > "$D/wwii.log" 2>/dev/null && [ -s "$D/wwii.log" ]; }

START=$(date +%s); VERDITO="timeout"; T=0
while :; do
  EL=$(( $(date +%s) - START ))
  [ "$EL" -gt "$TIMEOUT" ] && { VERDITO="timeout-sem-tela-de-erro"; break; }
  kill -0 "$QP" 2>/dev/null || { VERDITO="qemu-saiu"; break; }
  if temlog; then VERDITO="LOG ($(wc -l < "$D/wwii.log") linhas) em ${EL}s"; break; fi
  if python3 "$R/scripts/vncshot.py" --porta "$PORTA" --saida "$D/tela.png" >/dev/null 2>&1; then
    C=$(classe "$D/tela.png")
    [ "$EL" = "$T" ] || say "${EL}s tela=$C"
    T=$EL
    [ "$C" = bsod ] && { VERDITO="BSOD"; cp -f "$D/tela.png" "$D/bsod.png"; break; }
  fi
  sleep 12
done
kill -TERM "$QP" 2>/dev/null; sleep 2; kill -KILL "$QP" 2>/dev/null
printf '%s\t%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$ROTULO" "${EXTRA:-padrao}" "$VERDITO" >> "$TSV"
say "VEREDITO: $VERDITO (${T}s) -> $TSV"
