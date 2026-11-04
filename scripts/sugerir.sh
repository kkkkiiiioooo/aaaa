#!/bin/sh
# sugerir.sh - registra sugestao de melhoria do PROCESSO (SUGESTOES.md, append-only).
# Escreva, nao leia: quem consome e o dono, para evoluir o repo e gastar menos.
#
#   sh scripts/sugerir.sh perda "<onde a rodada gastou sem necessidade + custo estimado>"
#   sh scripts/sugerir.sh ideia "<mudanca que economizaria tokens, tempo ou rodadas>"
# Linha: <data UTC> <agente> <tipo> <texto ate 240 caracteres>
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
F="$R/SUGESTOES.md"
T="${1:-}"; X="${2:-}"
case "$T" in perda|ideia) ;; *) echo 'uso: sugerir.sh perda|ideia "<texto>"'; exit 1;; esac
[ -n "$X" ] || { echo 'uso: sugerir.sh perda|ideia "<texto>"'; exit 1; }
A=$(cat "$R/.work/agente" 2>/dev/null || git -C "$R" config user.name 2>/dev/null || echo sem-nome)
A=$(printf '%s' "$A" | tr -d ' ')
[ -f "$F" ] || printf '# SUGESTOES (append-only; use scripts/sugerir.sh; agentes so escrevem)\n' > "$F"
printf '%s %s %s %s\n' "$(date -u +%FT%TZ)" "$A" "$T" "$(printf '%s' "$X" | tr '\n' ' ' | cut -c1-240)" >> "$F"
git -C "$R" add -- "$F" && git -C "$R" commit -q -m "sugestao: $T" -- "$F" 2>/dev/null || true
echo "registrado em SUGESTOES.md"
