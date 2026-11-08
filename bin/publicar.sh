#!/bin/sh
# publicar.sh - publica o trabalho na ref privada do agente. Nunca conflita:
# nenhum outro agente escreve em refs/agents/<nome>.
#
# Uso: sh bin/publicar.sh [--tudo]
#   padrao  : empurra HEAD e encerra
#   --tudo  : empurra HEAD e depois todas as refs de agente (usado pelo integrador)
set -u
R=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
cd "$R" || exit 2
AG=$(cat .work/agente 2>/dev/null || git config user.name 2>/dev/null)
AG=${AG:-sem-nome}
mkdir -p .work/logs

if git push -q --force-with-lease origin "HEAD:refs/agents/$AG" 2>.work/logs/publicar.err; then
  rm -f .work/push-pendente
  echo "publicado: refs/agents/$AG -> $(git rev-parse --short HEAD)"
else
  : > .work/push-pendente
  echo "NAO PUBLICADO (commit local nao e entrega):"
  sed -n '1,4p' .work/logs/publicar.err
  exit 1
fi

[ "${1:-}" = "--tudo" ] || exit 0
echo "--- refs de agente no remoto ---"
git ls-remote origin 'refs/agents/*' | sed 's#refs/agents/#  #'
