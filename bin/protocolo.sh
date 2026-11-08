#!/bin/sh
# protocolo.sh - estado do protocolo na branch atual: versao, cadeados vivos, pendencias.
#
# Uso: sh bin/protocolo.sh [status|claims|versao]
set -u
R=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
cd "$R" || exit 2
CMD=${1:-status}

ver() { # versao do PROTOCOLO.md numa ref
  git show "$1:PROTOCOLO.md" 2>/dev/null | sed -n 's/^Versao: *//p' | head -1
}
MINHA=$(ver HEAD); MINHA=${MINHA:-0}
BASE=$(ver origin/0 2>/dev/null || ver 0)
BASE=${BASE:-0}

case "$CMD" in
  versao)
    echo "protocolo nesta branch: v$MINHA"
    echo "protocolo na branch 0 : v$BASE"
    ;;

  claims)
    echo "== cadeados vivos (refs/claims/*) =="
    if git ls-remote origin 'refs/claims/*' 2>/dev/null | grep -q .; then
      git ls-remote origin 'refs/claims/*' 2>/dev/null | while read -r sha ref; do
        id=${ref#refs/claims/}
        dono=$(git log -1 --format='%(trailers:key=Agent-Name,valueonly)' "$sha" 2>/dev/null || echo '?')
        dono=$(printf '%s' "$dono" | tr -d '\n'); dono=${dono:-?}
        echo "  $id  $dono  ${sha%"${sha#???????}"}"
      done
    else
      echo "  nenhum (ou sem rede)"
    fi
    ;;

  status)
    echo "branch: $(git branch --show-current)  protocolo: v$MINHA (base v$BASE)"
    if [ "$MINHA" -lt "$BASE" ] 2>/dev/null; then
      echo "  ATENCAO: projeto atrasado em relacao a branch 0 — leia PROTOCOLO.md (v$BASE)"
    fi
    if [ -f .work/push-pendente ]; then
      echo "  PUSH PENDENTE: commit local nao publicado (sh bin/publicar.sh)"
    fi
    echo
    if [ -f BOARD.md ]; then sed -n '1,12p' BOARD.md; else echo "  sem BOARD.md (rode sh bin/board.sh)"; fi
    echo
    echo "proximo passo: sh bin/board.sh · sh bin/reivindicar.sh <ID> · sh bin/publicar.sh"
    ;;
  *) echo "uso: protocolo.sh [status|claims|versao]"; exit 2 ;;
esac
