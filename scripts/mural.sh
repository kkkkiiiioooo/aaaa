#!/bin/sh
# mural.sh - praca comum dos agentes (MURAL.md, append-only). Raciocinio coletivo:
# proponha, apoie, critique, refute. Cada linha leva agente/modelo (quem teve a ideia).
#
#   sh scripts/mural.sh ler                                  # inicio da rodada: ultimos posts + pendencias
#   sh scripts/mural.sh proposta "<ideia>" [R1,R3] [N0..N4]  # solucao nova (reqs e nivel de evidencia)
#   sh scripts/mural.sh achado   "<fato medido + onde>"
#   sh scripts/mural.sh pergunta "<pergunta objetiva>"
#   sh scripts/mural.sh resposta|apoio|critica|refuta <id> "<texto>"   # replica a um post
#   sh scripts/mural.sh resumo                               # digest (<=1,5 KB) para o lead
# Niveis: N0 hipotese | N1 offline medido | N2 emulado/VM | N3 PE bootado com log | N4 maquina real.
# Linha: <id> <tipo> <agente>/<modelo> <data UTC> <ref|-> <reqs|nivel|-> <texto ate 400>
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
F="${M_ARQ:-$R/MURAL.md}"
A=$(cat "$R/.work/agente" 2>/dev/null || git -C "$R" config user.name 2>/dev/null || echo sem-nome)
MO=$(cat "$R/.work/modelo" 2>/dev/null || echo modelo-desconhecido)
AG="$(printf %s "$A" | tr -d ' /')/$(printf %s "$MO" | tr -d ' /')"
D=$(date -u +%FT%TZ)
T="${1:-}"
limpa(){ printf '%s' "$*" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-400; }
[ -f "$F" ] || printf '# MURAL (append-only; use scripts/mural.sh)\n' > "$F"
grava(){ # tipo ref attrs texto
  ID="m$(date -u +%d%H%M%S)$(( $$ % 100 ))"
  printf '%s %s %s %s %s %s %s\n' "$ID" "$1" "$AG" "$D" "$2" "$3" "$(limpa "$4")" >> "$F"
  echo "$ID registrado por $AG"
  [ -n "${M_ARQ:-}" ] && return 0
  git -C "$R" add -- "$F" && git -C "$R" commit -q -m "mural: $ID $1" -- "$F" 2>/dev/null || true
}
uso(){ sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

case "$T" in
  ler)
    echo "== ULTIMOS POSTS"
    grep -v '^#' "$F" | tail -15 | awk '{x=$0; sub(/^[^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ /,"",x); printf "%s %s %s ref=%s %s | %s\n",$1,$2,$3,$5,$6,substr(x,1,170)}'
    echo "== PENDENTES (responda ou revise ao menos 1 por rodada)"
    grep -v '^#' "$F" | awk '
      { id=$1; t=$2; au[id]=$3; tp[id]=t; ord[++n]=id
        x=$0; sub(/^[^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ /,"",x); tx[id]=x
        if(t=="resposta"||t=="apoio"||t=="critica"||t=="refuta"){ if($5!="-" && $3!=au[$5]) rv[$5]++ } }
      END{ for(i=1;i<=n;i++){ id=ord[i]
        if((tp[id]=="pergunta"||tp[id]=="proposta") && !rv[id]) printf "%s %s %s sem revisao | %s\n",id,tp[id],au[id],substr(tx[id],1,150) } }' | tail -8
    ;;
  proposta|achado|pergunta)
    [ -n "${2:-}" ] || uso
    ATTR="-"
    if [ "$T" = proposta ]; then
      RQ="${3:--}"; NV="${4:-N0}"
      case "$NV" in N0|N1|N2|N3|N4) ;; *) echo "nivel invalido: $NV (N0..N4)"; exit 1;; esac
      ATTR="$RQ|$NV"
    fi
    grava "$T" - "$ATTR" "$2"
    ;;
  resposta|apoio|critica|refuta)
    ID="${2:-}"; X="${3:-}"
    [ -n "$ID" ] && [ -n "$X" ] || uso
    grep -q "^$ID " "$F" || { echo "erro: id $ID nao existe (mural.sh ler)"; exit 1; }
    grava "$T" "$ID" "-" "$X"
    ;;
  resumo)
    grep -v '^#' "$F" | awk '
      { id=$1; t=$2; x=$0; sub(/^[^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ /,"",x)
        if(t=="proposta"){ au[id]=$3; at[id]=$6; tx[id]=x; ord[++n]=id }
        else if(t=="apoio") ap[$5]++
        else if(t=="critica") cr[$5]++
        else if(t=="refuta") rf[$5]++ }
      END{ for(i=1;i<=n;i++){ id=ord[i]; s=ap[id]-rf[id]
        printf "%d\t%s %s %s +%d -%d(c%d/r%d) | %s\n", s+100, id, au[id], at[id], ap[id], cr[id]+rf[id], cr[id], rf[id], substr(tx[id],1,140) } }' \
      | sort -rn | cut -f2- | head -6 | head -c 1500
    ;;
  *) uso ;;
esac
