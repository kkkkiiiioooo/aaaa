#!/bin/sh
# evals.sh - avanco REAL medido (so le; nada e escrito). Criterios e pegadinhas: EVALS.md.
#
#   sh scripts/evals.sh            # etapas, problemas, requisitos, placar por modelo, commits
set -u
R=$(cd "$(dirname "$0")/.." && pwd); cd "$R" || exit 1

echo "== ETAPAS (gate = evidencia, nao reclamacao)"
sh scripts/etapa.sh status 2>/dev/null | awk '/^E[0-9]/{
  e=($0~/ feita/)?"feita":($0~/EXPIRADA/)?"expirada":($0~/LIVRE/)?"livre":"ativa"; c[e]++; printf "  %s %s\n",$1,e}
  END{printf "  total: feita=%d ativa=%d expirada=%d livre=%d\n",c["feita"],c["ativa"],c["expirada"],c["livre"]}'

echo "== PROBLEMAS"
grep -v '^#' PROBLEMAS.md 2>/dev/null | awk 'NF>=5{ if($2=="novo")n[$1]=1; if($2=="resolveu")r[$1]=1; if($2=="escalou")e[$1]=1; if($2=="tentou")t++ }
  END{for(i in n)N++; for(i in r)if(i in n)R++; for(i in e)if(!(i in r))E++
  printf "  abertos=%d resolvidos=%d escalados_sem_resposta=%d tentativas=%d\n",N-R,R,E,t}'

echo "== REQUISITOS (nivel maximo provado; tabela em EVALS.md)"
grep -E '^\| R[1-5] ' EVALS.md 2>/dev/null | awk -F'|' '{gsub(/ +/," ",$2);gsub(/ +/," ",$3);gsub(/ +/," ",$4);printf "  %s -> %s (%s)\n",$2,$3,$4}'

echo "== MURAL por modelo (propostas, achados, apoios e refutas recebidos)"
grep -v '^#' MURAL.md 2>/dev/null | awk '
  {id=$1; t=$2; split($3,a,"/"); m=a[2]; if(m=="")m="?"; mo[id]=m
   if(t=="proposta"){p[m]++} else if(t=="achado"){h[m]++}
   else if(t=="apoio"){ap[mo[$5]]++} else if(t=="refuta"){rf[mo[$5]]++} else if(t=="critica"){cr[mo[$5]]++}
   seen[m]=1}
  END{for(m in seen) printf "  %-22s propostas=%d achados=%d apoios=%d criticas=%d refutas=%d\n",m,p[m],h[m],ap[m],cr[m],rf[m]}' | sort
[ -f MURAL.md ] && [ "$(grep -vc '^#' MURAL.md)" -gt 0 ] || echo "  (mural vazio: nenhum agente participou ainda)"

echo "== COMMITS por autor (todas as branches)"
git shortlog -sn --all --no-merges 2>/dev/null | head -8 | sed 's/^/  /'
echo "== PRESENCA (ultimo push por agente)"
grep ' push ' PRESENCA.md 2>/dev/null | sort -k1,1 -k3,3 | awk '{u[$1]=$3} END{for(a in u)printf "  %s %s\n",a,u[a]}' | sort
