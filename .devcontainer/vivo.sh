#!/bin/bash
# vivo.sh - descobre se a maquina dorme/congela ou se os processos morrem entre invocacoes.
#   bash vivo.sh start   inicia o batimento (1 linha/2s em /tmp/hb.log, via setsid)
#   bash vivo.sh         relatorio curto (lacunas = maquina parada; quedas dos tuneis)
#   bash vivo.sh stop    para o batimento
HB=/tmp/hb.log; PF=/tmp/hb.pid
now() { date +%s; }
alive() { [ -f $PF ] && kill -0 "$(cat $PF)" 2>/dev/null; }

case $1 in
  start)
    alive && { echo "batimento ja roda (pid $(cat $PF))"; exit 0; }
    cat /proc/sys/kernel/random/boot_id > /tmp/hb.boot 2>/dev/null
    nohup setsid bash -c 'while :; do date +%s >> /tmp/hb.log; sleep 2; done' >/dev/null 2>&1 &
    echo $! > $PF; echo "batimento iniciado (pid $!)"; exit 0;;
  stop) alive && kill "$(cat $PF)"; rm -f $PF; echo parado; exit 0;;
esac

echo "agora=$(date -u +%T) $(uptime -p)"
[ "$(cat /proc/sys/kernel/random/boot_id 2>/dev/null)" = "$(cat /tmp/hb.boot 2>/dev/null)" ] && echo "mesmo boot: SIM (maquina nao reiniciou)" || echo "mesmo boot: NAO (reiniciou ou sem 'start')"
alive && echo "batimento: vivo (sobreviveu entre invocacoes)" || echo "batimento: MORTO ou nao iniciado"
if [ -s $HB ]; then
  L=$(tail -1 $HB); echo "ultimo batimento ha $(( $(now) - L ))s | total $(wc -l < $HB) linhas"
  awk 'NR>1 && $1-p>6 {n++; printf "  lacuna %ds as %s\n", $1-p, strftime("%T",p)} {p=$1} END{print "lacunas >6s: " n+0}' $HB | tail -6
fi
for n in Xvnc nginx jwm cloudflared; do printf '%s=%s ' $n "$(pgrep -c -x $n)"; done; echo
for f in /tmp/cft-*.log; do
  [ -f $f ] || continue; p=${f#/tmp/cft-}; p=${p%.log}
  u=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' $f | head -1)
  c=$(curl -s -m 15 -o /dev/null -w '%{http_code}' "$u/" 2>/dev/null)
  echo "porta $p http=$c quedas=$(grep -c 'connection with edge closed' $f) ultima=$(grep -E 'Retrying|Registered' $f | tail -1 | cut -c1-19)"
done
