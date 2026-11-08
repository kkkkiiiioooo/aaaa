#!/bin/bash
# Roda DENTRO do container do dockur (Debian trixie), via postStartCommand.
# QEMU (DISPLAY=vnc) expoe o Windows como VNC puro em localhost:5900.
# Aqui: KasmVNC (Xvnc) serve a web na 6901 e um visualizador VNC em tela cheia mostra o Windows nele.
export DEBIAN_FRONTEND=noninteractive
V=1.5.2
A=$(dpkg --print-architecture)
K=:1   # display X do KasmVNC. Atencao: o env DISPLAY do container e "vnc" (config do dockur), por isso sempre explicito abaixo.

if ! command -v Xvnc >/dev/null; then
  apt-get update -qq
  curl -fsSLo /tmp/kasm.deb "https://github.com/kasmtech/KasmVNC/releases/download/v$V/kasmvncserver_debian_trixie_${V}_$A.deb"
  apt-get install -y -qq --no-install-recommends /tmp/kasm.deb tigervnc-viewer openbox
fi

# mesmas flags do svc-kasmvnc do webtop: HTTP puro, sem SSL/auth, websocket na 6901
pgrep -x Xvnc >/dev/null || nohup Xvnc $K -disableBasicAuth -SecurityTypes None -AlwaysShared \
  -sslOnly 0 -RectThreads 0 -websocketPort 6901 -interface 0.0.0.0 -geometry 1280x720 \
  >/tmp/kasm.log 2>&1 &
sleep 2
pgrep -x openbox >/dev/null || DISPLAY=$K nohup openbox >/tmp/openbox.log 2>&1 &

# visualizador em loop: reconecta ate o QEMU subir (instalacao do Windows pode demorar)
pgrep -f xtigervncviewer >/dev/null || nohup bash -c "while :; do
  DISPLAY=$K xtigervncviewer localhost:5900 -FullScreen -SecurityTypes None -Shared
  sleep 3
done" >/tmp/viewer.log 2>&1 &

echo "KasmVNC na porta 6901 (logs: /tmp/kasm.log /tmp/viewer.log)"
