#!/bin/sh
# instala git (apt). uso: sh git.sh
command -v git >/dev/null&&exit 0
S=;[ "$(id -u)" = 0 ]||S=sudo
$S apt-get update -qq&&$S apt-get install -y -qq git
