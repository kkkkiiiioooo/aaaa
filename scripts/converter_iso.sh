#!/bin/sh
# converter_iso.sh — monta a ISO do Windows a partir dos arquivos UUP ja baixados.
# Usa o conversor oficial do projeto uup-dump (baseado em wimlib: roda em Linux/macOS/Windows).
# So e necessario se voce quer a ISO COMPLETA; para inspecionar o WinRE,
# `inspecionar_winre.sh` costuma bastar (e gasta muito menos rede/disco).
#
# Uso: sh scripts/converter_iso.sh [dir_dos_uup] [dir_de_saida]
set -u
SRC="${1:-${UUP_DIR:-.work/uup/files}}"
OUT="${2:-.work/iso}"
CONV="${CONV:-.work/converter}"
say(){ printf '[converter] %s\n' "$*"; }

command -v wimlib-imagex >/dev/null 2>&1 || { say "ERRO: wimlib ausente (sh scripts/ambiente.sh)"; exit 1; }
[ -d "$SRC" ] || { say "ERRO: sem arquivos em $SRC (rode baixar_uup.sh)"; exit 1; }

if [ ! -d "$CONV/.git" ]; then
  say "baixando conversor uup-dump"
  if command -v git >/dev/null 2>&1; then
    git clone -q --depth 1 https://github.com/uup-dump/converter.git "$CONV" 2>&1 | tail -2
  else
    mkdir -p "$CONV" && curl -sL https://github.com/uup-dump/converter/archive/refs/heads/master.tar.gz \
      | tar xz -C "$CONV" --strip-components=1
  fi
fi

# o conversor espera os UUP ao lado dos seus scripts
say "preparando $SRC -> $CONV"
for f in "$SRC"/*; do [ -f "$f" ] || continue; ln -sf "$(cd "$(dirname "$f")" && pwd)/$(basename "$f")" "$CONV/$(basename "$f")" 2>/dev/null || cp -n "$f" "$CONV/"; done

say "scripts disponiveis no conversor:"
ls "$CONV" | grep -iE 'convert|uup' | head -10

# escolhe o entrypoint conforme a plataforma
entry=""
for c in convert.sh uup-converter-wimlib convert-wimlib.sh ./convert; do
  [ -f "$CONV/$c" ] && entry="$c" && break
done
if [ -z "$entry" ]; then
  say "AVISO: entrypoint nao encontrado; inspecione $CONV e rode manualmente"
  say "       (conversor Windows-only? use inspecionar_winre.sh, que nao precisa de ISO)"
  exit 2
fi

mkdir -p "$OUT"
say "convertendo (pode demorar) — log em .work/logs/converter.log"
cd "$CONV" && sh "$entry" 2>&1 | tee ../../.work/logs/converter.log | tail -15
say "ISO em: $(ls -1 "$OUT"/*.iso 2>/dev/null || echo '(verifique a pasta do conversor)')"
