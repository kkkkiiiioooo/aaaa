#!/bin/bash
# KasmVNC (webtop) usa DISPLAY=:1 por padrao; desktop-lite usa :1 tambem -> separar.
export DISPLAY_LITE=:2
( DISPLAY=$DISPLAY_LITE /usr/local/share/desktop-init.sh sleep infinity >/tmp/desktop-lite.log 2>&1 & ) 
# s6-overlay precisa ser PID 1
exec /init "$@"
