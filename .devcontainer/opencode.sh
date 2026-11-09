#!/bin/sh
# instala opencode: tenta v2/install, depois /install, depois npm opencode-ai. uso: sh opencode.sh
command -v opencode >/dev/null&&exit 0
S=;[ "$(id -u)" = 0 ]||S=sudo
f=/tmp/oc.sh
for u in https://opencode.ai/v2/install https://opencode.ai/install;do
  curl -fsSL $u -o $f&&head -c2 $f|grep -q '#!'&&bash $f&&exit 0
done
$S npm i -g opencode-ai
