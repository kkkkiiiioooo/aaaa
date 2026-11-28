#!/bin/sh
apk add firefox-esr xvfb x11vnc openbox novnc websockify ttf-dejavu font-noto
export DISPLAY=:1
Xvfb :1 -screen 0 1024x600x24 &
sleep 2
openbox &
MOZ_DISABLE_CONTENT_SANDBOX=1 MOZ_DISABLE_GMP_SANDBOX=1 firefox-esr &
x11vnc -display :1 -passwd "${SENHA:?defina SENHA}" -forever -shared -rfbport 5900 &
exec websockify --web /usr/share/novnc 6080 localhost:5900
