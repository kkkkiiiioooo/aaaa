#!/bin/sh
# relatorio.sh - 1 linha por rodada, para UMA branch que so o tech lead le.
#
# Por que branch separada: na branch do projeto, todo agente pagaria tokens lendo
# rodada alheia. Numa branch orphan o relatorio fica invisivel para quem trabalha e
# o lead le sozinho. O plano do lead (PLANO.md) fica na branch do projeto, porque
# precisa chegar ate os agentes.
#
# Uso: sh scripts/relatorio.sh "<veredito>" "<prova>" "<proximo>"
# Formato: horaUTC | agente | branch | commits-locais | VEREDITO | prova | proximo
set -u
BR_REL="${BR_REL:-relatorio}"
WT=".work/wt-$BR_REL"
F="$WT/RELATORIO.md"
A=$(cat ".work/agente" 2>/dev/null)
A="${A:-$(git config user.name 2>/dev/null)}"
A="${A:-sem-nome}"
PB=$(git branch --show-current 2>/dev/null)
limpa() { printf '%s' "$1" | tr '\n|' '  ' | sed 's/  */ /g'; }
V=$(limpa "${1:-SEM-VEREDITO}" | cut -c1-60)
P=$(limpa "${2:-}" | cut -c1-70)
N=$(limpa "${3:-}" | cut -c1-50)
NC=$(git rev-list --count "origin/$PB..HEAD" 2>/dev/null)
NC="${NC:-0}"
LINHA=$(printf '%s | %s | %s | %s | %s | %s | %s' \
  "$(date -u '+%Y-%m-%dT%H:%MZ')" "$A" "$PB" "$NC" "$V" "$P" "$N" | cut -c1-240)

mkdir -p .work
if [ ! -d "$WT" ]; then
  if git rev-parse --verify "refs/heads/$BR_REL" >/dev/null 2>&1; then
    git worktree add "$WT" "$BR_REL" >/dev/null 2>&1 || exit 1
  elif git rev-parse --verify "origin/$BR_REL" >/dev/null 2>&1; then
    git worktree add --track -B "$BR_REL" "$WT" "origin/$BR_REL" >/dev/null 2>&1 || exit 1
  else
    git worktree add --orphan -b "$BR_REL" "$WT" >/dev/null 2>&1 || exit 1
  fi
fi

if [ ! -f "$F" ]; then
  { printf '# RELATORIO (branch que so o tech lead le)\n'
    printf '1 linha por rodada, <=240 chars, append-only. Agentes NAO leem esta branch.\n'
    printf 'horaUTC | agente | branch | commits-locais | VEREDITO | prova | proximo\n'
  } > "$F"
  printf 'RELATORIO.md merge=union\n' > "$WT/.gitattributes"
fi

git -C "$WT" pull -q --rebase origin "$BR_REL" 2>/dev/null \
  || git -C "$WT" rebase --abort 2>/dev/null || true

printf '%s\n' "$LINHA" >> "$F"
git -C "$WT" add -A
git -C "$WT" commit -q -m "rodada: $A | $V" || true
if git -C "$WT" push -q origin "$BR_REL"; then
  printf 'enviado: 1 linha em %s (branch %s)\n' "$F" "$BR_REL"
else
  printf 'AVISO: linha gravada local em %s; push falhou\n' "$F"
  printf '%s\n' "$LINHA" >> ".work/logs/relatorio-pendente.txt"
fi
printf '%s\n' "$LINHA"
