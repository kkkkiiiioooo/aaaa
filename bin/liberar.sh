#!/bin/sh
# liberar.sh - solta o cadeado de uma tarefa/etapa (fechar ou devolver).
#
# Uso: sh bin/liberar.sh <ID> [feita|liberada] [evidencia]
#   feita    -> a ref some e o evento fica como "close"
#   liberada -> a ref some e o evento fica como "release" (devolve para o quadro)
set -u
R=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
cd "$R" || exit 2
AG=$(cat .work/agente 2>/dev/null || git config user.name 2>/dev/null)
AG=${AG:-sem-nome}
ID=${1:-}
TIPO=${2:-liberada}
EV=${3:-ver docs/evidence/}
[ -n "$ID" ] || { echo "uso: liberar.sh <ID> [feita|liberada] [evidencia]"; exit 2; }
case "$TIPO" in feita|liberada) ;; *) echo "tipo invalido: $TIPO (feita|liberada)"; exit 2 ;; esac

# fechar exige evidencia: a regra do projeto e "sem evidencia nao esta feito"
if [ "$TIPO" = feita ] && [ "$EV" = "ver docs/evidence/" ]; then
  echo "recusado: 'feita' exige evidencia (arquivo + saida do comando)."
  echo "  ex.: sh bin/liberar.sh $ID feita \"docs/evidence/e4.md: PASS=21 FAIL=0\""
  exit 1
fi

mkdir -p events .work/logs
LOG="events/$AG.jsonl"
TS=$(date -u +%FT%TZ)
case "$TIPO" in feita) C=close ;; *) C=release ;; esac
printf '{"ts":"%s","ag":"%s","tipo":"%s","id":"%s","texto":"%s"}\n' \
  "$TS" "$AG" "$C" "$ID" "$(printf '%s' "$EV" | tr -d '"\\' | cut -c1-300)" >> "$LOG"
git add "$LOG" && git commit -q -m "$C: $ID ($AG)

Agent-Name: $AG" || { echo "erro: commit do evento falhou"; exit 1; }

if git push -q origin ":refs/claims/$ID" 2>.work/logs/liberar.err; then
  echo "$ID: $TIPO por $AG as $TS"
else
  # a ref pode nao existir (reclamacao antiga em arquivo) ou faltar rede
  if grep -qiE 'remote ref does not exist|couldn.t find remote ref' .work/logs/liberar.err 2>/dev/null; then
    echo "$ID: evento registrado ($TIPO) — nao havia cadeado ativo"
  else
    echo "$ID: evento registrado, mas o cadeado nao foi removido:"
    sed -n '1,3p' .work/logs/liberar.err
    echo "  repita: git push origin :refs/claims/$ID"
  fi
fi
