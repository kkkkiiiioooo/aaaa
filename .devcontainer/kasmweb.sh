#!/bin/bash
# kasmweb.sh - KasmVNC + nginx (3000 HTTP, 3001 HTTPS) + viewer do QEMU/VNC. Idempotente e portatil:
# Debian/Ubuntu, amd64/arm64, root ou sudo, escolhe portas/display livres automaticamente.
# Env opcionais: KP=6901 HP=3000 SP=3001 VNC=localhost:5900 GEOM=1280x720 V=1.5.2
# Grava as escolhas em /tmp/kasm.env (lido por jwm.sh e cft.sh).
export DEBIAN_FRONTEND=noninteractive
V=${V:-1.5.2}; GEOM=${GEOM:-1280x720}; VNC=${VNC:-localhost:5900}
ENVF=/tmp/kasm.env
R=; [ "$(id -u)" = 0 ] || { command -v sudo >/dev/null && R=sudo || { echo "precisa de root ou sudo"; exit 1; }; }
. /etc/os-release
A=$(dpkg --print-architecture)

busy() { ss -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]$1\$" || (exec 3<>/dev/tcp/127.0.0.1/$1) 2>/dev/null; }
freeport() { local p=$1; while busy $p; do p=$((p+1)); done; echo $p; }

# 1) pacotes (so se faltar algo)
need=0; for c in curl nginx openssl xtigervncviewer openbox; do command -v $c >/dev/null || need=1; done
dpkg -s kasmvncserver >/dev/null 2>&1 || need=1
if [ $need = 1 ]; then
  $R apt-get update -qq
  $R apt-get install -y -qq --no-install-recommends curl ca-certificates openssl nginx tigervnc-viewer openbox || { echo "falha apt (base)"; exit 1; }
  if ! dpkg -s kasmvncserver >/dev/null 2>&1; then
    case $ID in ubuntu) L="ubuntu_${VERSION_CODENAME} ubuntu_noble ubuntu_jammy";; *) L="debian_${VERSION_CODENAME} debian_trixie debian_bookworm";; esac
    ok=
    for d in $L; do
      curl -fsSLo /tmp/kasm.deb "https://github.com/kasmtech/KasmVNC/releases/download/v$V/kasmvncserver_${d}_${V}_$A.deb" && { ok=$d; break; }
    done
    [ -n "$ok" ] || { echo "nao achei .deb do KasmVNC para $ID $VERSION_CODENAME $A"; exit 1; }
    echo "KasmVNC: $ok"
    $R apt-get install -y -qq --no-install-recommends /tmp/kasm.deb || { echo "falha ao instalar KasmVNC"; exit 1; }
  fi
fi

# 2) portas e display livres (reaproveita se o nosso Xvnc ja roda)
[ -f $ENVF ] && . $ENVF
if pgrep -af 'Xvnc.*websocketPort' >/dev/null && [ -n "$KP" ] && [ -n "$K" ]; then
  RUN=1
else
  RUN=
  KP=$(freeport ${KP:-6901})
  n=1; while [ -e /tmp/.X11-unix/X$n ] || [ -e /tmp/.X$n-lock ]; do n=$((n+1)); done; K=:$n
fi
# nginx proprio (se ja existe, para antes para liberar 3000/3001)
[ -f /etc/nginx/conf.d/kasm.conf ] && pgrep -x nginx >/dev/null && { $R nginx -s stop; sleep 1; }
HP=$(freeport ${HP:-3000}); SP=$(freeport ${SP:-3001})
[ "$SP" = "$HP" ] && SP=$(freeport $((HP+1)))

# 3) KasmVNC (Xvnc) sem SSL/auth (nginx/tunel cuidam disso)
[ -n "$RUN" ] || {
  nohup setsid Xvnc $K \
    -PublicIP 127.0.0.1 -disableBasicAuth -SecurityTypes None -AlwaysShared \
    -http-header Cross-Origin-Embedder-Policy=require-corp \
    -http-header Cross-Origin-Opener-Policy=same-origin \
    -geometry $GEOM -sslOnly 0 -RectThreads 0 -websocketPort $KP -interface 0.0.0.0 \
    >/tmp/kasm.log 2>&1 &
  for i in $(seq 20); do busy $KP && break; sleep 1; done
  busy $KP || { echo "Xvnc nao subiu:"; head -5 /tmp/kasm.log; exit 1; }
}

# 4) certificado autoassinado + nginx
[ -f /etc/nginx/kasm.crt ] || $R openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
  -subj /CN=localhost -keyout /etc/nginx/kasm.key -out /etc/nginx/kasm.crt 2>/dev/null
$R mkdir -p /etc/nginx/snippets /etc/nginx/conf.d
$R rm -f /etc/nginx/sites-enabled/default
$R tee /etc/nginx/snippets/kasm-proxy.conf >/dev/null <<'EOF'
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
  proxy_pass              http://127.0.0.1:__KP__;
  proxy_buffering         off;
}
EOF
$R sed -i "s/__KP__/$KP/" /etc/nginx/snippets/kasm-proxy.conf
$R tee /etc/nginx/conf.d/kasm.conf >/dev/null <<EOF
server {
  listen $HP default_server;
  listen [::]:$HP default_server;
  include /etc/nginx/snippets/kasm-proxy.conf;
}
server {
  listen $SP ssl default_server;
  listen [::]:$SP ssl default_server;
  ssl_certificate     /etc/nginx/kasm.crt;
  ssl_certificate_key /etc/nginx/kasm.key;
  include /etc/nginx/snippets/kasm-proxy.conf;
}
EOF
$R nginx -t >/dev/null 2>&1 || { $R nginx -t; exit 1; }
$R nginx || { echo "nginx falhou"; exit 1; }

printf 'K=%s\nKP=%s\nHP=%s\nSP=%s\nVNC=%s\n' "$K" "$KP" "$HP" "$SP" "$VNC" > $ENVF

# 5) janela do Windows dentro do KasmVNC: openbox + viewer em loop (QEMU VNC)
sleep 1
pgrep -x openbox >/dev/null || pgrep -x jwm >/dev/null || DISPLAY=$K nohup setsid openbox >/tmp/openbox.log 2>&1 &
cat > /tmp/viewer-loop.sh <<EOF
#!/bin/bash
while :; do
  DISPLAY=$K xtigervncviewer $VNC -FullScreen -SecurityTypes None -Shared
  sleep 3
done
EOF
chmod +x /tmp/viewer-loop.sh
pgrep -f viewer-loop.sh >/dev/null || nohup setsid /tmp/viewer-loop.sh >/tmp/viewer.log 2>&1 &

# 6) resumo
sleep 2
p() { busy $1 && echo OK || echo FECHADA; }
echo "KasmVNC  display $K  porta $KP   $(p $KP)   http://localhost:$KP"
echo "nginx HTTP         porta $HP   $(p $HP)   http://localhost:$HP"
echo "nginx HTTPS        porta $SP   $(p $SP)   https://localhost:$SP (cert autoassinado)"
echo "noVNC dockur       porta 8006  $(p 8006)"
echo "Logs: /tmp/kasm.log /tmp/viewer.log | portas em $ENVF"
