#!/bin/sh
# escalar.sh - leva um problema DIFICIL ao lead com um dossie de decisao.
# O lead so acessa a branch `relatorio`: o dossie vai para casos/<id>.md la e o indice
# (INDICE-PARA-O-LIDER.md) ganha 1 linha apontando para ele. Exige >=2 tentativas registradas.
#
#   sh scripts/escalar.sh <id> "<pergunta objetiva ao lead>" ["<hipoteses que nao deu para testar>"]
# DRY=1 imprime o dossie sem gravar nem enviar. FORCA=1 dispensa as 2 tentativas (diga o motivo na pergunta).
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
F="${P_ARQ:-$R/PROBLEMAS.md}"
ID="${1:-}"; Q="${2:-}"; H="${3:-nenhuma}"
[ -n "$ID" ] && [ -n "$Q" ] || { echo 'uso: escalar.sh <id> "<pergunta objetiva>" ["<hipoteses>"]'; exit 1; }
grep -q "^$ID novo " "$F" || { echo "erro: id $ID nao existe em PROBLEMAS.md"; exit 1; }
grep -q "^$ID resolveu " "$F" && { echo "ja resolvido: nada a escalar"; exit 0; }
NT=$(grep -c "^$ID tentou " "$F")
[ "$NT" -ge 2 ] || [ -n "${FORCA:-}" ] || { echo "recusado: $NT tentativa(s). Registre >=2 (problema.sh tentou) ou use FORCA=1"; exit 1; }

corpo(){
  printf '# %s\nPergunta ao lead: %s\n' "$ID" "$Q"
  printf 'Problema e evidencia:\n'; grep "^$ID novo " "$F" | sed 's/^[^ ]* [^ ]* //'
  printf 'Tentativas (agente data texto):\n'; grep "^$ID tentou " "$F" | sed 's/^[^ ]* [^ ]* //'
  printf 'Hipoteses nao testadas: %s\n' "$H"
  printf 'Resposta esperada: causa/decisao + passos exatos + aceite mensuravel + plano B, no PLANO-DO-LIDER.md (Respostas), por id.\n'
}
if [ -n "${DRY:-}" ]; then corpo | head -c 1500; exit 0; fi

BR="${BR_REL:-relatorio}"; WT="$R/.work/wt-$BR"
mkdir -p "$R/.work"
if [ ! -d "$WT" ]; then
  if git -C "$R" rev-parse --verify "refs/heads/$BR" >/dev/null 2>&1; then
    git -C "$R" worktree add "$WT" "$BR" >/dev/null 2>&1 || exit 1
  else
    git -C "$R" worktree add --track -B "$BR" "$WT" "origin/$BR" >/dev/null 2>&1 || exit 1
  fi
fi
mkdir -p "$WT/casos"
corpo | head -c 1500 > "$WT/casos/$ID.md"
TI=$(grep "^$ID novo " "$F" | sed 's/^[^ ]* [^ ]* [^ ]* [^ ]* //; s/:.*//' | cut -c1-80)
cd "$R" && sh scripts/relatorio.sh problema "$ID: $TI | pergunta: $Q | casos/$ID.md"
sh scripts/problema.sh escalou "$ID" "ao lead: $Q"
