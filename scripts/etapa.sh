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
LOCK="$R/.work/etapa.lock"
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


# --- cadeado de verdade: ref no servidor -------------------------------------
# O flock abaixo so vale nesta maquina. A criacao de refs/claims/<etapa> e atomica
# no GitHub: dois agentes, dois hosts, um ganha e o outro recebe rejeicao.
claim_dono() { # $1=etapa ; deixa FETCH_HEAD no claim e imprime o dono
  git ls-remote origin "refs/claims/$1" 2>/dev/null | grep -q . || return 0
  git fetch -q origin "refs/claims/$1" 2>/dev/null || return 0
  git log -1 --format='%(trailers:key=Agent-Name,valueonly)' FETCH_HEAD 2>/dev/null | tr -d '\n'
}
claim_idade() { # minutos desde o commit do claim
  ts=$(git log -1 --format=%ct FETCH_HEAD 2>/dev/null) || return 1
  [ -n "$ts" ] || return 1
  echo $(( ( $(date -u +%s) - ts ) / 60 ))
}
pega_ref() {
  # lease expirado: o ref ainda existe. force-with-lease vazio so cria ref novo.
  old=$(git ls-remote origin "refs/claims/$1" 2>/dev/null | awk '{print $1}')
  if [ -n "$old" ]; then
    git push -q --force-with-lease="refs/claims/$1:$old" origin "HEAD:refs/claims/$1" 2>/dev/null
  else
    git push -q --force-with-lease="refs/claims/$1:" origin "HEAD:refs/claims/$1" 2>/dev/null
  fi
}
solta_ref() { git push -q origin ":refs/claims/$1" 2>/dev/null; }

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
    dono=$(claim_dono "$ET")
    if [ -n "$dono" ] && [ "$dono" != "$A" ]; then
      idade=$(claim_idade)
      if [ -n "${idade:-}" ] && [ "$idade" -gt "$LEASE_MIN" ]; then
        echo "$ET estava com $dono mas o lease venceu (${idade}min) - tomando"
      else
        echo "$ET esta com $dono (${idade:-?}min). Escolha outra frente."
        exit 1
      fi
    elif [ "$dono" = "$A" ]; then
      echo "$ET ja e sua"; exit 0
    fi
    if ! pega_ref "$ET"; then
      echo "$ET: outra reclamacao venceu a corrida (cadeado do servidor). Escolha outra."
      exit 1
    fi
    (flock -x 9; printf '%s | %s | %s | ativa | -\n' "$ET" "$A" "$NOW" >> "$F") 9>"$LOCK"
    echo "reclamada: $ET por $A as $NOW (lease ${LEASE_MIN}min, cadeado remoto)"
    ;;
  fechar)
    dono=$(claim_dono "$ET")
    [ -z "$dono" ] || [ "$dono" = "$A" ] || [ -n "${FORCAR:-}" ] || {
      echo "$ET esta com $dono, nao com voce. Combine, ou FORCAR=1 se for deliberado."; exit 1; }
    solta_ref "$ET"
    (flock -x 9; printf '%s | %s | %s | feita | %s\n' "$ET" "$A" "$NOW" "${3:-ver docs/evidence/}" >> "$F") 9>"$LOCK"
    echo "fechada: $ET por $A"
    ;;
  liberar)
    dono=$(claim_dono "$ET")
    [ -z "$dono" ] || [ "$dono" = "$A" ] || [ -n "${FORCAR:-}" ] || {
      echo "$ET esta com $dono, nao com voce. Combine, ou FORCAR=1 se for deliberado."; exit 1; }
    solta_ref "$ET"
    (flock -x 9; printf '%s | %s | %s | liberada | %s\n' "$ET" "$A" "$NOW" "${3:-sem progresso}" >> "$F") 9>"$LOCK"
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
