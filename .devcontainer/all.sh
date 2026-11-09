#!/bin/sh
# roda todos os instaladores em ordem (git e nodejs primeiro). uso: sh all.sh
d=$(dirname "$0")
for s in git nodejs kilo opencode agentswarm;do
  echo ">> $s";sh "$d/$s.sh"||echo "FALHOU: $s"
done
