#!/bin/sh
# Monta os 3 WIM a partir das partes (os .wim ficam ignorados pelo git) e confere o hash.
# uso: sh imagens/remontar.sh
# Cada WIM tem sua pasta: as partes ficam ao lado do .wim remontado.
cd "$(dirname "$0")" || exit 1
for d in winre-1809 mipad2-10586-boot winre-fabrica-10586; do
  cat "$d/$d.wim.part-*" > "$d/$d.wim"
done
sha256sum -c WIMS.sha256
