#!/bin/sh
# agente.sh — identidade do agente + registro de presenca.
#
# O problema que isto resolve: o h.sh fixa user.name=claude para TODOS os agentes,
# entao `git log` nao distingue quem fez o que. Aqui o agente se identifica uma vez
# (A=<nome>) e o resto fica automatico: identidade vai para o git config (os commits
# passam a ter o nome real) e cada evento vira 1 linha em PRESENCA.md.
#
# Uso:
#   A=mavis sh scripts/agente.sh              # entra e registra (evento: entrou)
#   sh scripts/agente.sh trabalhando          # proximo evento, usando a identidade salva
#   sh scripts/agente.sh quem                 # imprime quem sou eu nesta maquina
#
# A identidade fica em .work/agente (fora do git). Cada chamada de tool e um shell
# novo: sem esse arquivo, o agente teria que repetir A= em todo comando.
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
F="$R/PRESENCA.md"
mkdir -p "$R/.work" "$R/.work/logs"

# --- identidade: A > arquivo salvo > gerada ---
A="${A:-$(cat "$R/.work/agente" 2>/dev/null || true)}"
if [ -z "${A:-}" ]; then
  A="agente-$(printf '%s-%s' "$(hostname)" "$$" | tr -cd 'a-zA-Z0-9' | cut -c1-12)"
fi
printf '%s\n' "$A" > "$R/.work/agente"

# --- identidade real no git: e isto que faz `git log` responder "quem trabalhou" ---
git -C "$R" config user.name "$A"
git -C "$R" config user.email "$(printf '%s' "$A" | tr -cd 'a-zA-Z0-9._-')@agents.local"

EV="${1:-entrou}"
if [ "$EV" = quem ]; then
  printf 'agente=%s\nbranch=%s\nhost=%s\n' "$A" "$(git -C "$R" branch --show-current)" "$(hostname)"
  exit 0
fi

[ -f "$F" ] || printf '# PRESENCA\n\nQuem entrou e quem trabalhou. Append-only (merge=union): nao reescreva.\nUTC | agente | evento | branch | host | HEAD\n' > "$F"

printf '%s | %s | %s | %s | %s | %s\n' \
  "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$A" "$EV" \
  "$(git -C "$R" branch --show-current 2>/dev/null || echo -)" \
  "$(hostname)" \
  "$(git -C "$R" rev-parse --short HEAD 2>/dev/null || echo -)" >> "$F"

printf 'ok agente=%s evento=%s branch=%s\n' "$A" "$EV" "$(git -C "$R" branch --show-current 2>/dev/null || echo -)"
