#!/bin/sh
apk add firefox-esr ttyd
wget -O /usr/local/bin/browsh "${BROWSH_URL:?defina BROWSH_URL}"
chmod +x /usr/local/bin/browsh
exec ttyd -p 7681 -c "usuario:${SENHA:?defina SENHA}" browsh
