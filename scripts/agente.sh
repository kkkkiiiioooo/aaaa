#!/bin/sh
# agente.sh - identidade do agente + presenca em PRESENCA.md (linha `nome inicio <data UTC>`; a linha `push` e do post-commit).
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

# registra inicio e encerra sessao anterior com duracao
NOW=$(date -u +%FT%TZ)
NOW_S=$(date +%s)

# calcula duracao da sessao anterior (se existir)
PREV_LINE=$(grep "^$A inicio " "$F" 2>/dev/null | tail -1)
if [ -n "$PREV_LINE" ]; then
  PREV_TS=$(printf '%s' "$PREV_LINE" | awk '{print $3}')
  PREV_S=$(date -d "$PREV_TS" +%s 2>/dev/null) || PREV_S=0
  if [ "$PREV_S" -gt 0 ]; then
    DUR=$(( (NOW_S - PREV_S) / 60 ))
    (flock -x 9; printf '%s fim %s duracao=%smin\n' "$A" "$NOW" "$DUR" >> "$F") 9>"$R/.work/presenca.lock"
  fi
fi

(flock -x 9; printf '%s inicio %s\n' "$A" "$NOW" >> "$F") 9>"$R/.work/presenca.lock"
printf 'ok %s\n' "$A"
