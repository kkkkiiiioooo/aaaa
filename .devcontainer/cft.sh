#!/bin/bash
# cft.sh - Cloudflare Quick Tunnel, uma URL publica por porta. Portatil, idempotente.
# Uso: bash cft.sh [portas...]  (padrao: portas do kasmweb.sh em /tmp/kasm.env + 8006 se aberta)
#      bash cft.sh stop         derruba tudo
# So cria tunel para porta que esta escutando (evita URL com erro 502).
[ -f /tmp/kasm.env ] && . /tmp/kasm.env
SSLP=${SP:-3001}
busy() { ss -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]$1\$" || (exec 3<>/dev/tcp/127.0.0.1/$1) 2>/dev/null; }
P=${*:-${HP:-3000} ${KP:-6901} $SSLP 8006}

case $(uname -m) in x86_64) A=amd64;; aarch64|arm64) A=arm64;; armv7l|armv6l) A=arm;; i?86) A=386;; *) A=$(dpkg --print-architecture 2>/dev/null);; esac
R=; [ "$(id -u)" = 0 ] || R=$(command -v sudo)
command -v curl >/dev/null || { echo "precisa de curl"; exit 1; }
if ! command -v cloudflared >/dev/null; then
  T=/tmp/cloudflared.$$
  curl -fsSL --retry 3 -o $T "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$A" || { echo "falha ao baixar cloudflared"; exit 1; }
  chmod +x $T
  if $R mv $T /usr/local/bin/cloudflared 2>/dev/null; then :; else mkdir -p ~/.local/bin && mv $T ~/.local/bin/cloudflared && export PATH=$PATH:~/.local/bin; fi
fi

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
  if ! busy $p; then echo "$p  porta fechada, ignorada" | tee -a /tmp/cft.log; continue; fi
  S=http://localhost:$p; X=
  [ "$p" = "$SSLP" ] && { S=https://localhost:$p; X=--no-tls-verify; }   # HTTPS autoassinado
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
    [ -z "$ABRIU" ] && command -v "${BROWSER:-xdg-open}" >/dev/null && { "${BROWSER:-xdg-open}" "$U" >/dev/null 2>&1 & ABRIU=1; }
  else
    echo "$p  FALHOU (veja $L)" | tee -a /tmp/cft.log
  fi
  sleep 2
done
