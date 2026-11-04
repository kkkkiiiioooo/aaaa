#!/bin/sh
# watchdog.sh — verifica etapas com lease expirado e libera automaticamente.
#
# Uso: sh scripts/watchdog.sh           (roda uma vez e sai)
#      sh scripts/watchdog.sh --loop    (loop a cada 5 min, em background)
#      sh scripts/watchdog.sh --daemon  (nohup loop -> .work/logs/watchdog.log)
#
# Nao altera etapas feitas nem liberadas — so "ativa" com lease expirado.
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
LEASE_MIN=${LEASE_MIN:-90}
LOG="$R/.work/logs/watchdog.log"
mkdir -p "$R/.work/logs"

ts(){ date -u '+%Y-%m-%dT%H:%MZ'; }

check_once() {
  NOW_S=$(date +%s)
  printf '[%s] watchdog verificando etapas...\n' "$(ts)"
  for ET in E1 E2 E3 E4 E5 E6; do
    REC=$(awk -F' *\\| *' -v e="$ET" '$1==e {a=$2;i=$3;s=$4} END{if(a!=""&&s=="ativa")print i}' "$R/ETAPAS.md" 2>/dev/null)
    [ -z "$REC" ] && continue
    INI_S=$(date -d "${REC}" +%s 2>/dev/null) || continue
    AGE_MIN=$(( (NOW_S - INI_S) / 60 ))
    if [ "$AGE_MIN" -gt "$LEASE_MIN" ]; then
      printf '[%s] LEASE EXPIRADO: %s (%s min) — liberando\n' "$(ts)" "$ET" "$AGE_MIN"
      sh "$R/scripts/etapa.sh" liberar "$ET" "lease expirado apos ${AGE_MIN}min (watchdog)" 2>&1 || true
    else
      printf '[%s] %s OK (%s/%s min)\n' "$(ts)" "$ET" "$AGE_MIN" "$LEASE_MIN"
    fi
  done
}

case "${1:-}" in
  --daemon)
    nohup sh "$0" --loop >> "$LOG" 2>&1 &
    echo "watchdog em background (PID $!) -> $LOG"
    ;;
  --loop)
    while true; do check_once; sleep 300; done
    ;;
  *)
    check_once
    ;;
esac
