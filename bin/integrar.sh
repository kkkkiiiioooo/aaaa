#!/bin/sh
# integrar.sh - papel de Integrador: traz o trabalho dos agentes para a branch do projeto.
#
# Regra: e o UNICO caminho de escrita na branch compartilhada. Se um merge quebrar
# o teste, ele e abortado e o autor e avisado pelo nome - a branch fica sempre verde.
#
# Uso: sh bin/integrar.sh            # integra todas as refs de agente que existirem
#      sh bin/integrar.sh <agente>   # integra so uma
set -u
R=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
cd "$R" || exit 2
AG=$(cat .work/agente 2>/dev/null || git config user.name 2>/dev/null)
B=$(git branch --show-current 2>/dev/null)
case "$B" in ""|main|0|template|backup) echo "erro: rode numa branch de projeto (nao em $B)"; exit 2 ;; esac
mkdir -p .work/logs

if [ $# -ge 1 ]; then
  REFS="refs/agents/$1"
else
  REFS=$(git ls-remote origin 'refs/agents/*' 2>/dev/null | sed 's#.*refs/#refs/#')
fi
[ -n "$REFS" ] || { echo "nada a integrar: nenhuma refs/agents/* no remoto"; exit 0; }

teste() {
  if [ -f scripts/tests/run-tests.sh ]; then sh scripts/tests/run-tests.sh
  elif [ -f protocolo-lint.sh ]; then sh protocolo-lint.sh --range origin/main..HEAD
  elif [ -f .work/protocolo-lint.sh ]; then sh .work/protocolo-lint.sh --range origin/main..HEAD
  else echo "sem teste definido: integracao exige um"; return 1; fi
}

FALHOU=0
for ref in $REFS; do
  nome=${ref#refs/agents/}
  git fetch -q origin "$ref" 2>/dev/null || { echo "skip $nome (fetch)"; continue; }
  sha=$(git rev-parse FETCH_HEAD 2>/dev/null) || continue
  if git merge-base --is-ancestor "$sha" HEAD 2>/dev/null; then
    echo "ok $nome: ja integrado"
    continue
  fi
  if git merge -q --no-ff --no-edit "$sha" -m "integrar: $nome ($sha)

Agent-Name: $AG" 2>.work/logs/integrar.err; then
    if teste >.work/logs/teste.log 2>&1; then
      echo "integrado $nome -> $(git rev-parse --short HEAD) (teste verde)"
    else
      git reset -q --hard HEAD~1
      echo "RECUSADO $nome: teste falhou; merge desfeito. Saida em .work/logs/teste.log"
      FALHOU=$((FALHOU + 1))
    fi
  else
    git merge --abort 2>/dev/null
    echo "CONFLITO ao integrar $nome: resolva com o autor (ref preservada)"
    sed -n '1,3p' .work/logs/integrar.err
    FALHOU=$((FALHOU + 1))
  fi
done

if [ "$FALHOU" -eq 0 ]; then
  git push -q origin "HEAD:$B" && echo "branch $B publicada: $(git rev-parse --short HEAD)"
else
  echo "$FALHOU integracao(oes) recusada(s); branch $B nao publicada"
  exit 1
fi
