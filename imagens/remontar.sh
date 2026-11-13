#!/bin/sh
# Monta o boot.wim 10586 a partir das partes (o .wim fica ignorado pelo git) e confere o hash.
# uso: sh imagens/remontar.sh
#
# O boot.wim esta em imagens/mipad2-10586-boot-408MB/. Os outros dois WIM
# (winre-1809 e winre-fabrica-10586) foram para a raiz do ramo `wwii`.
cd "$(dirname "$0")" || exit 1
d=mipad2-10586-boot-408MB
w=mipad2-10586-boot
# glob sem aspas: o shell precisa expandir as partes (dash nao expande dentro de "")
cat "$d/$w".wim.part-* > "$d/$w.wim"
sha256sum -c WIMS.sha256
