#!/bin/bash
# Diagnostico. Roda DENTRO do container. Nao altera nada.
# Uso: bash /workspaces/windows/.devcontainer/diag.sh   (cole a saida inteira no chat)
KEY=x3JJHMbDL1EzLkh9GBhXDw==

porta() { (exec 3<>/dev/tcp/127.0.0.1/$1) 2>/dev/null && echo aberta || echo FECHADA; }
http()  { curl -s -o /dev/null --max-time 4 -w '%{http_code}' "http://127.0.0.1:$1$2" 2>/dev/null; }
ws()    { curl -si --max-time 3 -H 'Connection: Upgrade' -H 'Upgrade: websocket' \
            -H 'Sec-WebSocket-Version: 13' -H "Sec-WebSocket-Key: $KEY" \
            "http://127.0.0.1:$1$2" 2>/dev/null | head -1 | tr -d '\r'; }

echo "== env: DISPLAY=$DISPLAY VERSION=$VERSION BROWSER=$BROWSER"
echo "== processos"
for p in qemu-system-x86 Xvnc nginx openbox xtigervncviewer cloudflared websocketd; do
  printf '%-18s %s\n' "$p" "$(pgrep -x "$p" >/dev/null && echo rodando || (pgrep -f "$p" >/dev/null && echo rodando || echo NAO))"
done

echo "== portas (tcp)"
for n in 5900 8006 6901 3000; do printf '%-5s %s\n' "$n" "$(porta $n)"; done

echo "== HTTP (esperado 200)"
printf '8006 /           %s\n' "$(http 8006 /)"
printf '6901 /           %s\n' "$(http 6901 /)"
printf '3000 /           %s\n' "$(http 3000 /)"

echo "== websocket (esperado: HTTP/1.1 101 Switching Protocols)"
printf '8006 /websockify %s\n' "$(ws 8006 /websockify)"
printf '6901 /websockify %s\n' "$(ws 6901 /websockify)"
printf '3000 /websockify %s\n' "$(ws 3000 /websockify)"

echo "== sockets unix do dockur"
ls -l /run/shm/*.sock /storage/*.sock 2>/dev/null || echo "nenhum encontrado em /run/shm ou /storage"

echo "== tunnel"
grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/cft.log 2>/dev/null | tail -1 || true

echo "== logs (ultimas linhas)"
for f in /tmp/kasm.log /tmp/viewer.log /tmp/cft.log; do
  [ -f "$f" ] && { echo "-- $f"; tail -n 5 "$f"; }
done
