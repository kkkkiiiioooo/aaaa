#!/bin/sh
# instala kilo: instalador oficial; se falhar, npm @kilocode/cli. uso: sh kilo.sh
command -v kilo >/dev/null&&exit 0
S=;[ "$(id -u)" = 0 ]||S=sudo
f=/tmp/kilo.sh;curl -fsSL https://kilo.ai/cli/install -o $f&&head -c2 $f|grep -q '#!'&&bash $f||$S npm i -g @kilocode/cli
