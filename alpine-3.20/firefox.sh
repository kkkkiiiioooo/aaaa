#!/bin/sh
set -e
V="${ALPINE_V:-v3.20}"
M="${MIRROR:-https://dl-cdn.alpinelinux.org/alpine}"
CANAL="${CANAL:-estavel}"

printf '%s\n' "$M/$V/main" "$M/$V/community" > /etc/apk/repositories
if [ "$CANAL" = "edge" ]; then
  printf '%s\n' "@edge $M/edge/community" >> /etc/apk/repositories
fi

apk update
if [ "$CANAL" = "edge" ]; then
  apk add firefox@edge
else
  apk add firefox
fi

ln -sf "$(command -v firefox)" /usr/local/bin/firefox-esr
apk policy firefox
firefox --version
