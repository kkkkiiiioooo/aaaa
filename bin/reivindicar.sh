#!/bin/sh
# reivindicar.sh - toma uma tarefa/etapa com cadeado atomico do lado do servidor.
#
# O flock local nao atravessa maquinas. A criacao de uma ref e atomica no GitHub:
# se dois agentes tentarem ao mesmo tempo, um push e aceito e o outro e rejeitado.
# A ref aponta para o commit do evento de reclamacao (com autor e hora), entao ela
# carrega o proprio comprovante de quem reclamou.
#
# Uso: sh bin/reivindicar.sh <ID> [texto]
#   ID: E2, T1, D3... (letra + numero)
set -u
R=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
cd "$R" || exit 2
AG=$(cat .work/agente 2>/dev/null || git config user.name 2>/dev/null)
AG=${AG:-sem-nome}
ID=${1:-}
[ -n "$ID" ] || { echo "uso: reivindicar.sh <ID> [texto]"; exit 2; }
printf '%s' "$ID" | grep -qE '^[A-Z][A-Za-z]?[0-9]+$' || { echo "ID invalido: $ID (ex.: E2, T1)"; exit 2; }
case "$ID" in */*) echo "ID invalido: $ID"; exit 2 ;; esac

mkdir -p events .work/logs
LOG="events/$AG.jsonl"
TS=$(date -u +%FT%TZ)
ANTES=$(git rev-parse HEAD)
TXT=${2:-reclamada por $AG}

# 1) registra a reclamacao no log de eventos deste agente (arquivo privado: nunca conflita)
printf '{"ts":"%s","ag":"%s","tipo":"claim","id":"%s","texto":"%s"}\n' \
  "$TS" "$AG" "$ID" "$(printf '%s' "$TXT" | tr -d '"\\' | cut -c1-200)" >> "$LOG"
git add "$LOG" && git commit -q -m "claim: $ID ($AG)

Agent-Name: $AG" || { echo "erro: commit do evento falhou"; exit 1; }

# 2) cadeado: so aceita se refs/claims/<ID> ainda nao existir (force-with-lease vazio)
if git push -q --force-with-lease="refs/claims/$ID:" origin "HEAD:refs/claims/$ID" 2>.work/logs/claim.err; then
  echo "reivindicada: $ID por $AG as $TS"
  echo "  evidencia obrigatoria ao fechar: caminho do arquivo + saida do comando"
  exit 0
fi

# 3) perdeu a corrida ou falta rede: desfaz SO o evento de claim e explica
git reset -q --hard "$ANTES"
if grep -qiE 'stale info|already exists|fetch first|non-fast-forward' .work/logs/claim.err 2>/dev/null; then
  echo "JA REIVINDICADA: $ID tem outra reclamacao viva. Escolha outra ou veja: sh bin/protocolo.sh claims"
else
  echo "FALHA DE REDE/CREDENCIAL ao reivindicar $ID:"
  sed -n '1,4p' .work/logs/claim.err
  echo "  sem cadeado nao ha posse: repita quando a rede voltar (nada foi perdido)"
fi
exit 1
