#!/bin/sh
apk add firefox-esr xvfb x11vnc openbox novnc websockify ttf-dejavu font-noto
cd "$(dirname "$0")"
AQUI="$(pwd)"
LARGURA="${LARGURA:-1024}"
ALTURA="${ALTURA:-640}"
ESCALA="${ESCALA:-1.5}"

mkdir -p /tmp/ff-touch
printf 'user_pref("layout.css.devPixelsPerPx", "%s");\nuser_pref("browser.uidensity", 2);\nuser_pref("general.smoothScroll", true);\nuser_pref("apz.allow_zooming", true);\n' "$ESCALA" > /tmp/ff-touch/user.js

rm -rf /tmp/web
mkdir -p /tmp/web
cp -r /usr/share/novnc/. /tmp/web/
cp "$AQUI/index.html" "$AQUI/../comum/gestos.js" /tmp/web/

export DISPLAY=:1
Xvfb :1 -screen 0 "${LARGURA}x${ALTURA}x16" &
sleep 2
openbox --config-file "$AQUI/rc.xml" &
MOZ_DISABLE_CONTENT_SANDBOX=1 MOZ_DISABLE_GMP_SANDBOX=1 firefox-esr -profile /tmp/ff-touch --no-remote &
x11vnc -display :1 -passwd "${SENHA:?defina SENHA}" -forever -shared -rfbport 5900 -noxdamage -wait 20 -defer 20 &
exec websockify --web /tmp/web 6080 localhost:5900
