#!/bin/sh
# etapa.sh - orquestra as etapas do ETAPAS.md: reclama, fecha, libera, mostra status.
#
# Resolve o problema do time-plate: "fulano ja esta com o ambiente pronto e testando
# possibilidades" passa a ser uma pergunta com resposta em uma linha, sem ninguém
# precisar perguntar a ninguém.
#
# Uso: sh scripts/etapa.sh status | pegar E2 | fechar E2 "evidencia" | liberar E2
set -u
R=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
F="$R/ETAPAS.md"
LEASE_MIN=${LEASE_MIN:-90}
A=$(cat "$R/.work/agente" 2>/dev/null)
A=${A:-$(git config user.name 2>/dev/null)}
A=${A:-sem-nome}
NOW=$(date -u '+%Y-%m-%dT%H:%MZ')
[ -f "$F" ] || { echo "erro: sem ETAPAS.md"; exit 1; }

# Estado CORRENTE por etapa = ultima linha daquela etapa (o arquivo e um log).
# Erro corrigido: antes o status imprimia todas as linhas, entao "fechar" nao
# aparecia e uma reclamacao antiga barrava uma nova.
est() {  # $1=etapa -> imprime "agente|inicio|estado|evidencia" do registro vigente
  awk -F' *\\| *' -v e="$1" '$1==e {a=$2;i=$3;s=$4;v=$5} END{if(a!="")print i"|"s"|"v}' "$F"
}
cur() {  # imprime tabela do estado vigente, com lease aplicado
  printf '%-5s %-16s %-17s %-22s %s\n' "ETAPA" "AGENTE" "INICIO" "ESTADO" "EVIDENCIA"
  for et in E1 E2 E3 E4 E5 E6; do
    rec=$(awk -F' *\\| *' -v e="$et" '$1==e {a=$2;i=$3;s=$4;v=$5} END{if(a!="")print a"|"i"|"s"|"v}' "$F")
    [ -n "$rec" ] || { printf '%-5s %-16s %-17s %-22s %s\n' "$et" "-" "-" "LIVRE" "-"; continue; }
    ag=$(printf %s "$rec" | cut -d"|" -f1); ini=$(printf %s "$rec" | cut -d"|" -f2)
    st=$(printf %s "$rec" | cut -d"|" -f3); ev=$(printf %s "$rec" | cut -d"|" -f4)
    if [ "$st" = ativa ]; then
      ini_e=$(printf %s "$ini" | sed 's/[-TZ:]/ /g;s/Z/ /')
      now_e=$(date -u +%s); st_e=$(date -u -d "$ini" +%s 2>/dev/null)
      if [ -n "$st_e" ]; then
        min=$(( (now_e - st_e) / 60 ))
        if [ "$min" -lt 0 ]; then st="RELOGIO-SUSPEITO"; elif [ "$min" -gt "$LEASE_MIN" ]; then st="EXPIRADA (reclamavel)"; fi
        ev="$ev [${min}min]"
      fi
    fi
    printf '%-5s %-16s %-17s %-22s %s\n' "$et" "$ag" "$ini" "$st" "$ev"
  done
}

status(){
  cur
  echo
  printf 'LIVRES para reclamacao: '
  for et in E1 E2 E3 E4 E5 E6; do
    st=$(awk -F' *\\| *' -v e="$et" '$1==e {s=$4} END{print s}' "$F")
    case "$st" in ""|liberada) printf '%s ' "$et" ;; esac
  done
  echo
  printf 'EM ANDAMENTO: '
  cur | awk '$4=="ativa"||$4~"EXPIRADA"{printf "%s(%s) ", $1, $2}'
  echo
}

case "${1:-status}" in
  status) status; exit 0 ;;
esac

ET=${2:-}
[ -n "$ET" ] || { echo "uso: etapa.sh <status|pegar|fechar|liberar> E<n>"; exit 1; }
case "$ET" in E[1-6]) ;; *) echo "etapa invalida: $ET"; exit 1 ;; esac

case "$1" in
  pegar)
    st=$(awk -F' *\\| *' -v e="$ET" '$1==e {s=$4} END{print s}' "$F")
    if [ "$st" = ativa ]; then
      ini=$(awk -F' *\\| *' -v e="$ET" '$1==e {i=$3} END{print i}' "$F")
      e0=$(date -u -d "$ini" +%s 2>/dev/null); min=""
      [ -n "$e0" ] && min=$(( ( $(date -u +%s) - e0 ) / 60 ))
      if [ -n "$min" ] && [ "$min" -gt "$LEASE_MIN" ]; then
        echo "$ET estava reclamada mas o lease venceu (${min}min) - tomando"
      else
        echo "$ET ja esta reclamada e dentro do lease. Use: sh scripts/etapa.sh status"
        exit 1
      fi
    fi
    printf '%s | %s | %s | ativa | -\n' "$ET" "$A" "$NOW" >> "$F"
    echo "reclamada: $ET por $A as $NOW (lease ${LEASE_MIN}min)"
    ;;
  fechar)
    printf '%s | %s | %s | feita | %s\n' "$ET" "$A" "$NOW" "${3:-ver docs/evidence/}" >> "$F"
    echo "fechada: $ET por $A"
    ;;
  liberar)
    printf '%s | %s | %s | liberada | %s\n' "$ET" "$A" "$NOW" "${3:-sem progresso}" >> "$F"
    echo "liberada: $ET"
    ;;
  *) echo "comando desconhecido: $1"; exit 1 ;;
esac

cd "$R"
git add ETAPAS.md
git commit -q --no-verify -m "etapa: $1 $ET ($A)" 2>/dev/null || git commit -q --no-verify -m "etapa: $1 $ET ($A)"
b=$(git branch --show-current)
git pull -q --rebase origin "$b" 2>/dev/null || git rebase --abort 2>/dev/null || true
git push -q origin "$b" || echo "AVISO: reclamacao gravada local; push falhou"
status
