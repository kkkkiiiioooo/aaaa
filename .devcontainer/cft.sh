#!/bin/bash
# Manual, faz tudo: setup.sh (KasmVNC+nginx+visualizador) + Cloudflare Tunnel (3000) + abre no $BROWSER.
# Uso: bash /workspaces/windows/.devcontainer/cft.sh
D=$(dirname "$(readlink -f "$0")")
bash "$D/setup.sh"

A=$(dpkg --print-architecture)
command -v cloudflared >/dev/null || {
  curl -fsSLo /usr/local/bin/cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$A" \
    && chmod +x /usr/local/bin/cloudflared
}

pkill -x cloudflared 2>/dev/null
nohup cloudflared tunnel --url http://localhost:3000 >/tmp/cft.log 2>&1 &

for i in $(seq 60); do
  U=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/cft.log | head -1)
  [ -n "$U" ] && break
  sleep 1
done
[ -n "$U" ] || { echo "sem URL do tunnel; veja /tmp/cft.log"; exit 1; }

echo "$U"
"${BROWSER:-xdg-open}" "$U"
