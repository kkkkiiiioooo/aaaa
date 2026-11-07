#!/bin/sh
# quem-primeiro.sh - quem (agente/modelo) mencionou um termo PRIMEIRO. Uso do dono: avaliar modelos.
#
#   sh scripts/quem-primeiro.sh "<termo ou regex>" [...]   # mostra as 5 primeiras mencoes de cada termo
# Fontes: historico git de TODAS as branches (-G, ignora maiusculas) + MURAL.md + PROBLEMAS.md.
# O modelo vem do trailer "Agente: nome (modelo)" dos commits e da coluna agente/modelo do mural.
# Commits antigos nao tem trailer: aparecem so com o nome do agente (modelo "?").
set -u
R=$(cd "$(dirname "$0")/.." && pwd); cd "$R" || exit 1
[ $# -ge 1 ] || { sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
for t in "$@"; do
  echo "== \"$t\""
  git log --all --no-merges -i -G"$t" --reverse --date=format:'%Y-%m-%dT%H:%MZ' \
    --format='%ad|%an|%h|%(trailers:key=Agente,valueonly,separator=)|%s' 2>/dev/null \
    | sort -t'|' -k1,1 | awk -F'|' '{m=($4==""?"?":$4); printf "git   %s %s modelo=%s %s %s\n",$1,$2,m,$3,substr($5,1,70)}' | head -5
  for f in MURAL.md PROBLEMAS.md; do
    [ -f "$f" ] || continue
    grep -v '^#' "$f" | grep -i -- "$t" | awk -v f="$f" '{printf "%-5s %s %s %s\n", (f=="MURAL.md"?"mural":"prob"), $4, $3, substr($0,1,0)}' | sort -k2 | head -2
  done
done
