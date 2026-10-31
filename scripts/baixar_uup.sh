#!/bin/sh
# baixar_uup.sh — baixa os arquivos UUP dos servidores oficiais Microsoft.
# Retomavel (-c), paralelo quando ha aria2c, e aceita FILTRO para baixar só parte
# (economiza rede/disco: ex.: baixar só os .esd grandes para achar o WinRE).
#
# Uso:
#   sh scripts/baixar_uup.sh                      # baixa todos do .tsv mais recente
#   sh scripts/baixar_uup.sh '\.esd$'             # só os ESD
#   sh scripts/baixar_uup.sh 'Core_en-us'         # só o pacote Core
#   UUP_TSV=.work/uup/xxx.tsv sh scripts/baixar_uup.sh
#   UUP_DIR=.work/iso sh scripts/baixar_uup.sh
set -u
UUP_OUT="${UUP_OUT:-.work/uup}"
UUP_DIR="${UUP_DIR:-$UUP_OUT/files}"
FILTRO="${1:-}"
say(){ printf '[baixar] %s\n' "$*"; }

# escolhe o .tsv mais recente se nao vier explicitamente
if [ -z "${UUP_TSV:-}" ] || [ ! -s "${UUP_TSV:-}" ]; then
  UUP_TSV=$(ls -t "$UUP_OUT"/*.tsv 2>/dev/null | head -1)
fi
[ -z "${UUP_TSV:-}" ] && { say "ERRO: nenhum .tsv. Rode antes: sh scripts/uup_links.sh"; exit 1; }
say "lista: $UUP_TSV"
mkdir -p "$UUP_DIR"

# monta a lista de trabalho (url, nome, tamanho)
awk -F'\t' '!/^#/ && NF>=2 {print $1"\t"$2"\t"$3}' "$UUP_TSV" > "$UUP_OUT/fila.tsv"
if [ -n "$FILTRO" ]; then
  grep -E "$FILTRO" "$UUP_OUT/fila.tsv" > "$UUP_OUT/fila.filtrada.tsv" || true
  mv "$UUP_OUT/fila.filtrada.tsv" "$UUP_OUT/fila.tsv"
fi
n=$(wc -l < "$UUP_OUT/fila.tsv")
soma=$(awk -F'\t' '{s+=$3} END{printf "%.2f", s/1024/1024/1024}' "$UUP_OUT/fila.tsv")
say "arquivos a baixar: $n ($soma GB) -> $UUP_DIR"

if command -v aria2c >/dev/null 2>&1; then
  say "usando aria2c (paralelo, 4 conexoes/arquivo)"
  awk -F'\t' '{print $1"\n out="$2"\n dir='"$UUP_DIR"'"}' "$UUP_OUT/fila.tsv" > "$UUP_OUT/aria2.txt"
  aria2c -c -x4 -s4 -j3 --console-log-level=warn --summary-interval=60 \
         --dir="$UUP_DIR" -i "$UUP_OUT/aria2.txt" 2>&1 | tail -5
else
  say "usando wget/curl (sequencial, retomavel)"
  while IFS="$(printf '\t')" read -r url nome tam; do
    [ -z "$url" ] && continue
    dest="$UUP_DIR/$nome"
    if [ -s "$dest" ] && [ "$(stat -c%s "$dest" 2>/dev/null)" = "$tam" ]; then
      say "ja existe: $nome"; continue
    fi
    say "baixando $nome"
    if command -v wget >/dev/null 2>&1; then wget -c -q --show-progress -O "$dest" "$url"
    else curl -sL -C - -o "$dest" "$url"; fi
  done < "$UUP_OUT/fila.tsv"
fi
say "concluido. arquivos em $UUP_DIR"
du -sh "$UUP_DIR" 2>/dev/null
