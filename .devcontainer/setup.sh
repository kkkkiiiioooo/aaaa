#!/bin/bash
# Roda DENTRO do container do dockur (Debian trixie).
# QEMU (DISPLAY=vnc) expoe o Windows como VNC puro em localhost:5900.
# Aqui: KasmVNC (Xvnc :1, ws 6901) + nginx na 3000 (igual ao webtop) + visualizador em tela cheia.
export DEBIAN_FRONTEND=noninteractive
V=1.5.2
A=$(dpkg --print-architecture)
K=:1   # display X do KasmVNC (o env DISPLAY do container e "vnc", por isso sempre explicito)

if ! command -v Xvnc >/dev/null || ! command -v nginx >/dev/null; then
  apt-get update -qq
  curl -fsSLo /tmp/kasm.deb "https://github.com/kasmtech/KasmVNC/releases/download/v$V/kasmvncserver_debian_trixie_${V}_$A.deb"
  apt-get install -y -qq --no-install-recommends /tmp/kasm.deb tigervnc-viewer openbox nginx
fi

# Xvnc: mesmas flags do svc-kasmvnc do webtop (sem -drinode/-hw3d: container sem GPU)
pgrep -x Xvnc >/dev/null || nohup Xvnc $K \
  -PublicIP 127.0.0.1 -disableBasicAuth -SecurityTypes None -AlwaysShared \
  -http-header Cross-Origin-Embedder-Policy=require-corp \
  -http-header Cross-Origin-Opener-Policy=same-origin \
  -geometry 1280x720 -sslOnly 0 -RectThreads 0 -websocketPort 6901 -interface 0.0.0.0 \
  >/tmp/kasm.log 2>&1 &

# nginx: copia do default.conf do webtop (porta 3000, HTTP, Upgrade, Cookie "", COOP/COEP/CORS).
# Diferenca: "/" tambem vai para 6901, pois nao ha kclient (6900, audio/upload) aqui.
rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/conf.d/kasm.conf <<'EOF'
server {
  listen 3000 default_server;
  listen [::]:3000 default_server;
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
}
EOF
if pgrep -x nginx >/dev/null; then nginx -s reload; else nginx; fi

sleep 2
pgrep -x openbox >/dev/null || DISPLAY=$K nohup openbox >/tmp/openbox.log 2>&1 &

# visualizador em loop: reconecta ate o QEMU subir (instalacao do Windows pode demorar)
pgrep -f xtigervncviewer >/dev/null || nohup bash -c "while :; do
  DISPLAY=$K xtigervncviewer localhost:5900 -FullScreen -SecurityTypes None -Shared
  sleep 3
done" >/tmp/viewer.log 2>&1 &

echo "KasmVNC: http://localhost:3000 (direto: 6901). Logs: /tmp/kasm.log /tmp/viewer.log"
