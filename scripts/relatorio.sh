#!/bin/sh
# relatorio.sh - mantem INDICE-PARA-O-LIDER.md (branch relatorio) como RESUMO EXECUTIVO
# compacto (<=2 KB): o lead le SO este arquivo, inteiro, sem investigar o repo.
# Atualize CONFORME os problemas surgirem - nao so no fim da rodada.
#
# Uso:
#   sh scripts/relatorio.sh estado    "<provado + onde + proximo>"
#   sh scripts/relatorio.sh problema   "P<n>: <contexto + evidencia + tentado>"
#   sh scripts/relatorio.sh problema   -P<n>        # resolvido: sai do resumo
#   sh scripts/relatorio.sh pergunta  "Q<n>: <pergunta concreta>"
#   sh scripts/relatorio.sh pergunta  -Q<n>        # respondida no PLANO: sai
#   sh scripts/relatorio.sh "<veredito>" "<prova>" "<proximo>"   # legado = estado
set -u
BR_REL="${BR_REL:-relatorio}"
WT=".work/wt-$BR_REL"
F="$WT/INDICE-PARA-O-LIDER.md"
MODO="${1:-}"

limpa() { printf '%s' "$1" | tr '\n|' '  ' | sed 's/  */ /g; s/^ //' | cut -c1-300; }

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
  { printf '# RELATORIO (resumo executivo p/ o lead; <=2 KB; agentes NAO lem)\n'
    printf 'Desafio: <1 linha do desafio>\n'
    printf 'Estado: <provado + onde + proximo>\n'
    printf 'Problemas dificeis (contexto + evidencia + tentado):\n'
    printf 'Perguntas ao lead:\n'
  } > "$F"
fi

git -C "$WT" pull -q --rebase origin "$BR_REL" 2>/dev/null \
  || git -C "$WT" rebase --abort 2>/dev/null || true

case "$MODO" in
  problema|pergunta)
    ARG="${2:-}"
    SEC='Problemas dificeis'
    [ "$MODO" = pergunta ] && SEC='Perguntas ao lead'
    if [ "${ARG#-}" != "$ARG" ]; then
      ID=${ARG#-}
      sed -i "/^- $ID:/d" "$F"
    else
      ID=$(printf '%s' "$ARG" | cut -d: -f1 | tr -cd 'A-Za-z0-9')
      TX=$(limpa "$(printf '%s' "$ARG" | sed 's/^[^:]*://')")
      sed -i "/^- $ID:/d" "$F"
      sed -i "/^$SEC/a- $ID: $TX" "$F"
    fi
    ;;
  estado)
    sed -i "s|^Estado:.*|Estado: $(limpa "${2:-?}")|" "$F"
    ;;
  *)
    A=$(cat .work/agente 2>/dev/null || git config user.name 2>/dev/null || echo sem-nome)
    V=$(limpa "${1:-SEM-VEREDITO}" | cut -c1-60)
    P=$(limpa "${2:-}" | cut -c1-70)
    N=$(limpa "${3:-}" | cut -c1-50)
    sed -i "s|^Estado:.*|Estado: $A | $V | prova: $P | proximo: $N|" "$F"
    ;;
esac

git -C "$WT" add -A
git -C "$WT" commit -q -m "resumo: $MODO" || true
if git -C "$WT" push -q origin "$BR_REL"; then
  printf 'resumo atualizado (branch %s)\n' "$BR_REL"
else
  printf 'AVISO: push falhou; diagnostique e repita\n'
fi
SZ=$(wc -c < "$F")
[ "$SZ" -gt 2000 ] && printf 'AVISO: resumo com %s bytes (>2 KB): enxugue\n' "$SZ"
exit 0
