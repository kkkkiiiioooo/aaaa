#!/bin/sh
# instala agentswarm-cli (npm). uso: sh agentswarm.sh ; depois: agentswarm
command -v agentswarm >/dev/null&&exit 0
S=;[ "$(id -u)" = 0 ]||S=sudo
$S npm i -g agentswarm-cli
