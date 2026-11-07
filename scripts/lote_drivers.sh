#!/bin/sh
# lote_drivers.sh — E2: um .cab oficial por fabricante, INF conferido, injetado, hash.
#
#   sh scripts/lote_drivers.sh            # baixa + injeta se o WIM existir
#   sh scripts/lote_drivers.sh --so intel,broadcom
#   sh scripts/lote_drivers.sh --so-download   # so o catalogo (sem WIM)
#   sh scripts/lote_drivers.sh --injetar       # usa cabs ja baixados
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
cd "$R"
SO=""
SO_DL=0
SO_INJ=0
while [ $# -gt 0 ]; do
  case "$1" in
    --so) SO="${2:-}"; shift 2;;
    --so-download) SO_DL=1; shift;;
    --injetar) SO_INJ=1; shift;;
    -h|--help) sed -n '2,12p' "$0"; exit 0;;
    *) echo "uso: lote_drivers.sh [--so fab,fab] [--so-download|--injetar]"; exit 2;;
  esac
done

EV="$R/docs/evidence/drivers-lote.md"
LOG="$R/.work/logs/lote-drivers.log"
WIM="$R/.work/winre-1809.wim"
OUT="$R/.work/drivers"
VER="$R/.work/verif-lote"
mkdir -p "$R/.work/logs" "$OUT" "$VER"

say(){ printf '[lote] %s\n' "$*"; echo "[lote] $*" >> "$LOG"; }

if [ "$SO_INJ" != 1 ]; then
  say "baixando catalogo Microsoft Update"
  extra=""
  [ -n "$SO" ] && extra="--so $SO"
  python3 "$R/scripts/buscar_driver.py" lote --tabela "$R/scripts/drivers-1809.tsv" \
      --dir "$OUT" --cache "$R/.work/driver-cache" $extra | tee -a "$LOG"
  [ -f "$OUT/lote.json" ] || { say "ERRO: lote.json nao gerado"; exit 1; }
fi

if [ "$SO_DL" = 1 ]; then
  say "so download, parando"
  exit 0
fi

# WIM: tenta obter se faltar
if [ ! -f "$WIM" ]; then
  if command -v wimlib-imagex >/dev/null 2>&1; then
    say "WIM ausente, tentando scripts/obter_imagem.sh --wim"
    sh "$R/scripts/obter_imagem.sh" --wim >> "$LOG" 2>&1 || say "obter_imagem falhou (seguindo se houver outro WIM)"
  fi
fi
[ -f "$WIM" ] || WIM="$R/.work/wim/Winre.wim"
if [ ! -f "$WIM" ]; then
  say "sem Winre.wim — cabs conferidos, injecao adiada"
  exit 3
fi

command -v wimlib-imagex >/dev/null 2>&1 || { say "sem wimlib-imagex"; exit 1; }

# copia de trabalho para nao destruir o original
WORKWIM="$R/.work/wim/Winre.lote.wim"
mkdir -p "$R/.work/wim"
if [ ! -f "$WORKWIM" ]; then
  say "copiando WIM de trabalho"
  cp -f "$WIM" "$WORKWIM"
fi

# injeta cada fabricante que tem extracted/
ok_inj=0
fail_inj=0
: > "$VER/hashes.tsv"
printf 'fab\tinf\torig16\treex16\tstatus\n' > "$VER/hashes.tsv"

for fabdir in "$OUT"/*; do
  [ -d "$fabdir" ] || continue
  fab=$(basename "$fabdir")
  case "$fab" in driver-cache|extracted) continue;; esac
  src="$fabdir/extracted"
  [ -d "$src" ] || src="$fabdir"
  infs=$(find "$src" -maxdepth 3 -iname '*.inf' 2>/dev/null | head -1)
  [ -n "$infs" ] || { say "skip $fab (sem inf)"; continue; }
  say "injetando $fab de $src"
  if sh "$R/scripts/injetar_driver.sh" --imagem "$WORKWIM" --driver "$src" --saida "$WORKWIM.bak-$fab" \
        >> "$LOG" 2>&1; then
    say "injecao $fab OK"
    ok_inj=$((ok_inj+1))
  else
    say "injecao $fab FALHOU (ver log)"
    fail_inj=$((fail_inj+1))
    continue
  fi
  # reextrai INF e SYS e compara hash
  mkdir -p "$VER/$fab"
  find "$src" -maxdepth 3 \( -iname '*.inf' -o -iname '*.sys' -o -iname '*.cat' \) | while read -r f; do
    base=$(basename "$f")
    orig=$(sha256sum "$f" | awk '{print substr($1,1,16)}')
    # tenta extrair o caminho correspondente
    case "$base" in
      *.inf) destpath="/Windows/INF/$base";;
      *.sys) destpath="/Windows/System32/drivers/$base";;
      *) destpath="";;
    esac
    [ -n "$destpath" ] || continue
    if wimlib-imagex extract "$WORKWIM" 1 "$destpath" --dest-dir="$VER/$fab" --no-acls >/dev/null 2>&1; then
      got=$(find "$VER/$fab" -name "$base" | head -1)
      if [ -n "$got" ]; then
        reex=$(sha256sum "$got" | awk '{print substr($1,1,16)}')
        st=IGUAL
        [ "$orig" = "$reex" ] || st=DIFERE
        printf '%s\t%s\t%s\t%s\t%s\n' "$fab" "$base" "$orig" "$reex" "$st" >> "$VER/hashes.tsv"
        say "hash $fab $base $st $orig"
      fi
    fi
  done
done

say "injetados ok=$ok_inj falha=$fail_inj"
echo "----- hashes -----"
cat "$VER/hashes.tsv"
igual=$(awk -F'\t' 'NR>1 && $5=="IGUAL"{c++} END{print c+0}' "$VER/hashes.tsv")
difere=$(awk -F'\t' 'NR>1 && $5=="DIFERE"{c++} END{print c+0}' "$VER/hashes.tsv")
say "hashes IGUAL=$igual DIFERE=$difere"
[ "$ok_inj" -ge 1 ] && [ "$difere" -eq 0 ] && [ "$igual" -ge 1 ]
