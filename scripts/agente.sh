#!/bin/sh
# agente.sh - identidade do agente + presenca (nome data) em PRESENCA.md.
#
# Uso:
#   A=vibe sh scripts/agente.sh   # identifica e registra presenca
#   sh scripts/agente.sh quem     # quem sou eu nesta maquina
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
F="$R/PRESENCA.md"
mkdir -p "$R/.work" "$R/.work/logs"

# identidade: A > arquivo salvo > gerada
A="${A:-$(cat "$R/.work/agente" 2>/dev/null || true)}"
if [ -z "${A:-}" ]; then
  A="agente-$(printf '%s-%s' "$(hostname)" "$$" | tr -cd 'a-zA-Z0-9' | cut -c1-12)"
fi
printf '%s\n' "$A" > "$R/.work/agente"
git -C "$R" config user.name "$A"
git -C "$R" config user.email "$(printf '%s' "$A" | tr -cd 'a-zA-Z0-9._-')@agents.local"

if [ "${1:-}" = quem ]; then
  printf 'agente=%s\nbranch=%s\nhost=%s\n' "$A" "$(git -C "$R" branch --show-current)" "$(hostname)"
  exit 0
fi

printf '%s %s\n' "$A" "$(date -u +%F)" >> "$F"
printf 'ok %s\n' "$A"
