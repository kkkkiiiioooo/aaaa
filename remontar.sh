#!/bin/sh
# Monta os 2 WIM a partir das partes (os .wim ficam ignorados pelo git) e confere o hash.
# uso: sh remontar.sh
#
# Cada WIM tem sua pasta na raiz do repo, com o tamanho no titulo.
# Os arquivos dentro mantem o nome do WIM, sem o sufixo de tamanho:
#   winre-1809-254MB/winre-1809.wim.part-* -> winre-1809-254MB/winre-1809.wim
cd "$(dirname "$0")" || exit 1
for d in winre-1809-254MB winre-fabrica-10586-424MB; do
  w=$(echo "$d" | sed 's/-[0-9]*MB$//')
  # glob sem aspas: o shell precisa expandir as partes (dash nao expande dentro de "")
  cat "$d/$w".wim.part-* > "$d/$w.wim"
done
sha256sum -c WIMS.sha256
