#!/bin/sh
# problema.sh - quadro de problemas COMPARTILHADO entre agentes (PROBLEMAS.md, append-only).
# Linha: <id> <tipo> <agente> <data UTC> <texto>   tipo: novo | tentou | resolveu | escalou
# O estado e derivado das linhas (sem reescrever nada), entao varios agentes nao conflitam.
#
#   sh scripts/problema.sh abertos                       # leia no inicio da rodada
#   sh scripts/problema.sh buscar <termo>                # reaproveite solucao ja achada
#   sh scripts/problema.sh novo "<titulo>: <contexto + evidencia>"
#   sh scripts/problema.sh tentou <id> "<o que fez> -> <resultado>"
#   sh scripts/problema.sh resolveu <id> "<solucao reproduzivel: comando + prova>"
# P_ARQ=<arquivo> usa outro arquivo e nao commita (teste).
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
F="${P_ARQ:-$R/PROBLEMAS.md}"
A=$(cat "$R/.work/agente" 2>/dev/null || git -C "$R" config user.name 2>/dev/null || echo sem-nome)
A=$(printf '%s' "$A" | tr -d ' ')
[ -s "$R/.work/modelo" ] && A="$A/$(tr -d ' /' < "$R/.work/modelo")"   # agente/modelo
D=$(date -u +%FT%TZ)
M="${1:-}"
limpa(){ printf '%s' "$*" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-300; }
[ -f "$F" ] || printf '# PROBLEMAS (append-only; use scripts/problema.sh)\n' > "$F"

grava(){ # id tipo texto
  printf '%s %s %s %s %s\n' "$1" "$2" "$A" "$D" "$3" >> "$F"
  [ -n "${P_ARQ:-}" ] && return 0
  git -C "$R" add -- "$F" && git -C "$R" commit -q -m "problema: $1 $2" -- "$F" 2>/dev/null || true
}

case "$M" in
  abertos)
    awk '!/^#/ && NF>=5 { id=$1; t=$2; x=$0; sub(/^[^ ]+ [^ ]+ [^ ]+ [^ ]+ /,"",x)
      if(t=="novo"){ti[id]=x; ag[id]=$3; ord[++n]=id}
      else if(t=="tentou"){nt[id]++; last[id]=x}
      else if(t=="resolveu"){ok[id]=1}
      else if(t=="escalou"){es[id]=1} }
    END{ for(i=1;i<=n;i++){ id=ord[i]; if(ok[id]) continue
      printf "%s %s%s tent=%d | %s", id, (es[id]?"[LEAD] ":""), ag[id], nt[id]+0, substr(ti[id],1,160)
      if(nt[id]) printf " | ult: %s", substr(last[id],1,100)
      printf "\n" } }' "$F" | head -20
    ;;
  buscar)
    [ -n "${2:-}" ] || { echo "uso: problema.sh buscar <termo>"; exit 1; }
    grep -v '^#' "$F" | grep -i -- "$2" | cut -c1-260 | head -15
    ;;
  novo)
    [ -n "${2:-}" ] || { echo 'uso: problema.sh novo "<titulo>: <contexto + evidencia>"'; exit 1; }
    ID="p$(date -u +%d%H%M%S)$(( $$ % 100 ))"
    grava "$ID" novo "$(limpa "$2")"
    echo "$ID registrado. Cada falha: problema.sh tentou $ID \"...\". 2 falhas: scripts/escalar.sh $ID \"<pergunta>\""
    ;;
  tentou|resolveu)
    ID="${2:-}"; T="${3:-}"
    [ -n "$ID" ] && [ -n "$T" ] || { echo "uso: problema.sh $M <id> \"<texto>\""; exit 1; }
    grep -q "^$ID novo " "$F" || { echo "erro: id $ID nao existe (problema.sh abertos)"; exit 1; }
    grava "$ID" "$M" "$(limpa "$T")"
    if [ "$M" = tentou ]; then
      N=$(grep -c "^$ID tentou " "$F")
      if [ "$N" -ge 2 ] && ! grep -q "^$ID \(escalou\|resolveu\) " "$F"; then
        echo "$N tentativas sem solucao: escale com sh scripts/escalar.sh $ID \"<pergunta objetiva>\""
      fi
    fi
    ;;
  escalou)
    grava "${2:-?}" escalou "$(limpa "${3:-}")"
    ;;
  *)
    echo "uso: problema.sh abertos | buscar <termo> | novo \"...\" | tentou <id> \"...\" | resolveu <id> \"...\""; exit 1
    ;;
esac
