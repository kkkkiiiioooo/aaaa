#!/bin/bash
# kasmweb.sh - Windows (dockur) no navegador por 4 portas. Roda DENTRO do container.
#   8006 noVNC do dockur (ja existe, DISPLAY=vnc)   6901 KasmVNC direto (HTTP/ws)
#   3000 nginx HTTP -> 6901                          3001 nginx HTTPS (cert autoassinado) -> 6901
# Uso: bash /workspaces/windows/.devcontainer/kasmweb.sh      (idempotente)
export DEBIAN_FRONTEND=noninteractive
V=1.5.2
A=$(dpkg --print-architecture)
K=:1   # display do KasmVNC (env DISPLAY do container e "vnc", entao sempre explicito)

# 1) pacotes (so se faltar algo)
need=0; for c in Xvnc nginx openssl xtigervncviewer openbox; do command -v $c >/dev/null || need=1; done
if [ $need = 1 ]; then
  apt-get update -qq
  command -v Xvnc >/dev/null || {
    curl -fsSLo /tmp/kasm.deb "https://github.com/kasmtech/KasmVNC/releases/download/v$V/kasmvncserver_debian_trixie_${V}_$A.deb" \
      && apt-get install -y -qq --no-install-recommends /tmp/kasm.deb
  }
  apt-get install -y -qq --no-install-recommends tigervnc-viewer openbox nginx openssl
fi

# 2) KasmVNC (Xvnc) em 6901, sem SSL/auth (o nginx/tunel cuida disso)
pgrep -x Xvnc >/dev/null || nohup Xvnc $K \
  -PublicIP 127.0.0.1 -disableBasicAuth -SecurityTypes None -AlwaysShared \
  -http-header Cross-Origin-Embedder-Policy=require-corp \
  -http-header Cross-Origin-Opener-Policy=same-origin \
  -geometry 1280x720 -sslOnly 0 -RectThreads 0 -websocketPort 6901 -interface 0.0.0.0 \
  >/tmp/kasm.log 2>&1 &

# 3) certificado autoassinado para a 3001
[ -f /etc/nginx/kasm.crt ] || openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
  -subj /CN=localhost -keyout /etc/nginx/kasm.key -out /etc/nginx/kasm.crt 2>/dev/null

# 4) nginx: bloco de proxy compartilhado + 2 servers (3000 HTTP, 3001 HTTPS)
mkdir -p /etc/nginx/snippets
rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/snippets/kasm-proxy.conf <<'EOF'
location / {
  proxy_http_version      1.1;
  proxy_set_header        Host $host;
  proxy_set_header        Upgrade $http_upgrade;
  proxy_set_header        Connection "upgrade";
  proxy_set_header        X-Real-IP $remote_addr;
  proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header        X-Forwarded-Proto $scheme;
  proxy_set_header        Cookie "";
  proxy_read_timeout      3600s;
  proxy_send_timeout      3600s;
  add_header              'Access-Control-Allow-Origin' '*' always;
  add_header              'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
  add_header              'Access-Control-Allow-Headers' 'Authorization,Content-Type,Accept,Origin,User-Agent,DNT,Cache-Control,X-Mx-ReqToken,Keep-Alive,X-Requested-With,If-Modified-Since';
  add_header              'Access-Control-Allow-Credentials' 'true';
  add_header              'Cross-Origin-Embedder-Policy' 'require-corp';
  add_header              'Cross-Origin-Opener-Policy' 'same-origin';
  add_header              'Cross-Origin-Resource-Policy' 'same-site';
  proxy_pass              http://127.0.0.1:6901;
  proxy_buffering         off;
}
EOF
cat > /etc/nginx/conf.d/kasm.conf <<'EOF'
server {
  listen 3000 default_server;
  listen [::]:3000 default_server;
  include /etc/nginx/snippets/kasm-proxy.conf;
}
server {
  listen 3001 ssl default_server;
  listen [::]:3001 ssl default_server;
  ssl_certificate     /etc/nginx/kasm.crt;
  ssl_certificate_key /etc/nginx/kasm.key;
  include /etc/nginx/snippets/kasm-proxy.conf;
}
EOF
nginx -t >/dev/null 2>&1 || { nginx -t; exit 1; }
if pgrep -x nginx >/dev/null; then nginx -s reload; else nginx; fi

# 5) janela do Windows dentro do KasmVNC: openbox + viewer em loop (QEMU VNC em 5900)
sleep 2
pgrep -x openbox >/dev/null || DISPLAY=$K nohup openbox >/tmp/openbox.log 2>&1 &
pgrep -f xtigervncviewer >/dev/null || nohup bash -c "while :; do
  DISPLAY=$K xtigervncviewer localhost:5900 -FullScreen -SecurityTypes None -Shared
  sleep 3
done" >/tmp/viewer.log 2>&1 &

# 6) resumo
sleep 2
p() { (exec 3<>/dev/tcp/127.0.0.1/$1) 2>/dev/null && echo OK || echo FECHADA; }
echo "8006 (noVNC dockur)  http://localhost:8006   $(p 8006)"
echo "6901 (KasmVNC)       http://localhost:6901   $(p 6901)"
echo "3000 (nginx HTTP)    http://localhost:3000   $(p 3000)"
echo "3001 (nginx HTTPS)   https://localhost:3001  $(p 3001)  (aceite o aviso do cert)"
echo "Logs: /tmp/kasm.log /tmp/viewer.log"
