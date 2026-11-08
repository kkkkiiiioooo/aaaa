#!/bin/bash
# cft.sh - Cloudflare Quick Tunnel, uma URL publica por porta. Roda DENTRO do container.
# Pode rodar quantas vezes quiser: derruba os tuneis antigos (esperando de verdade) e recria.
# Uso: bash /workspaces/windows/.devcontainer/cft.sh [portas...]   padrao: 8006 3000 6901 3001
#      bash /workspaces/windows/.devcontainer/cft.sh stop          derruba tudo
P=${*:-8006 3000 6901 3001}
A=$(dpkg --print-architecture)

command -v cloudflared >/dev/null || {
  curl -fsSLo /usr/local/bin/cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$A" \
    && chmod +x /usr/local/bin/cloudflared
}

parar() {
  pkill -x cloudflared 2>/dev/null
  for i in $(seq 20); do pgrep -x cloudflared >/dev/null || return 0; sleep 0.5; done
  pkill -9 -x cloudflared 2>/dev/null; sleep 1
}

[ "$1" = stop ] && { parar; echo "tuneis parados"; exit 0; }

parar
: > /tmp/cft.log
ABRIU=

for p in $P; do
  S=http://localhost:$p; X=
  [ "$p" = 3001 ] && { S=https://localhost:$p; X=--no-tls-verify; }   # 3001 e HTTPS autoassinado
  L=/tmp/cft-$p.log
  U=
  for t in 1 2 3 4; do
    setsid nohup cloudflared tunnel --no-autoupdate --protocol http2 $X --url "$S" >"$L" 2>&1 &
    pid=$!
    for i in $(seq 40); do
      if grep -q 'Registered tunnel connection' "$L"; then
        U=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$L" | head -1)
        [ -n "$U" ] && break
      fi
      kill -0 $pid 2>/dev/null || break
      sleep 1
    done
    [ -n "$U" ] && break
    kill $pid 2>/dev/null; sleep $((t * 3))    # espera crescente (limite de criacao de tuneis)
  done
  if [ -n "$U" ]; then
    echo "$p  $U" | tee -a /tmp/cft.log
    [ -z "$ABRIU" ] && { "${BROWSER:-xdg-open}" "$U" >/dev/null 2>&1 & ABRIU=1; }
  else
    echo "$p  FALHOU (veja $L)" | tee -a /tmp/cft.log
  fi
  sleep 2
done
