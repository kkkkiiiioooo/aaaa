#!/bin/sh
# Monta os 2 WIM a partir das partes (os .wim ficam ignorados pelo git) e confere o hash.
# uso: sh imagens/remontar.sh
cd "$(dirname "$0")" || exit 1
cat winre-1809.wim.part-* > winre-1809.wim
cat mipad2-10586-boot.wim.part-* > mipad2-10586-boot.wim
cat winre-fabrica-10586.wim.part-* > winre-fabrica-10586.wim
sha256sum -c WIMS.sha256
