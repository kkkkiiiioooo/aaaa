#!/bin/sh
apk add xpra firefox-esr
exec xpra start :100 \
  --bind-tcp=0.0.0.0:14500 \
  --html=on \
  --tcp-auth="password:value=${SENHA:?defina SENHA}" \
  --start=firefox-esr \
  --daemon=no
