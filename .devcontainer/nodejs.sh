#!/bin/sh
# instala nodejs + npm (apt). uso: sh nodejs.sh
command -v npm >/dev/null&&exit 0
S=;[ "$(id -u)" = 0 ]||S=sudo
$S apt-get update -qq&&$S apt-get install -y -qq nodejs npm
