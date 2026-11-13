#!/bin/sh
# uso: sh scripts/mem.sh "texto curto"
# Anexa 1 linha ao diario de docs/MEMORIA.md e faz commit; o hook post-commit envia ao GitHub.
# Rode a cada etapa concluida ou descoberta (nao espere o fim da conversa). Nunca grave segredos.
set -e
R=$(git rev-parse --show-toplevel)
F="$R/docs/MEMORIA.md"
[ -n "$1" ] || { echo 'uso: sh scripts/mem.sh "texto"'; exit 1; }
printf -- '- %s %s\n' "$(date -u +%Y-%m-%dT%H:%MZ)" "$*" >> "$F"
git -C "$R" add "$F"
git -C "$R" commit -q -m "memoria: $(printf %s "$*" | cut -c1-60)" -- "$F"
