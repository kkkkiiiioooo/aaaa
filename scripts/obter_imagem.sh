#!/bin/sh
# obter_imagem.sh — obtem o pacote offline da imagem 1809 (subset em imagens/, WIM no ramo wwii).
#
#   sh scripts/obter_imagem.sh --fs     # sistema de arquivos de inspecao (62 MB)
#   sh scripts/obter_imagem.sh --wim    # WIM do WinRE montavel (254 MB)
#   sh scripts/obter_imagem.sh --all
#
# Para quem? Para o agente que NAO consegue rodar emulacao nenhuma: com --fs ele
# inspeciona INF, hives e drivers de verdade, e para de raciocinar no escuro.
#
# Ordem obrigatoria: verificar hash -> remontar -> extrair. Nunca o contrario:
# se a parte chegou truncada, descobrir isso antes de gastar tempo com o conteudo.
set -eu

AQUI=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$AQUI/.." && pwd)
WT=$REPO/imagens
MODO=${1:---fs}

# sha256 do WIM ja remontado, medido na geracao (25 s, Boot Index 1)
WIM_SHA=f9e30ca308aa23e83d852ccefcfe7bca09a23d7c5b759ae655557612487879b8

case "$MODO" in --fs|--wim|--all) : ;; *) echo "uso: obter_imagem.sh --fs|--wim|--all"; exit 2 ;; esac

passo() { printf '\n=== %s ===\n' "$1"; }
falha() { printf '\nPARADO: %s\n' "$1"; exit 1; }

passo "usando imagens/ do proprio repo (ramo extras)"
[ -f "$WT/inspecao-62MB/subset-inspecao.tar.xz" ] || falha "imagens/inspecao-62MB/subset-inspecao.tar.xz ausente" "git pull; ou git checkout extras -- imagens"

passo "verificando MANIFEST.sha256 ANTES de usar qualquer arquivo"
( cd "$WT" && sha256sum -c MANIFEST-imagem.sha256 ) || falha "verificacao de hash" \
    "arquivo corrompido no transporte — rode git checkout -- imagens e tente de novo; NAO use parcial"

if [ "$MODO" = --wim ] || [ "$MODO" = --all ]; then
  WIM1809=$REPO/winre-1809-254MB
  if [ ! -d "$WIM1809" ]; then
    # a pasta foi para a raiz do ramo wwii: busca de la
    passo "winre-1809-254MB nao esta neste ramo: buscando no ramo wwii"
    git -C "$REPO" fetch -q origin wwii 2>/dev/null || true
    git -C "$REPO" archive origin/wwii winre-1809-254MB 2>/dev/null | tar -x -C "$REPO" \
      || falha "winre-1809-254MB ausente" "git fetch origin wwii; ou git checkout wwii -- winre-1809-254MB"
    WIM1809=$REPO/winre-1809-254MB
  fi
  passo "verificando as partes do winre-1809"
  ( cd "$WIM1809" && sha256sum -c SHA256SUMS ) || falha "verificacao de hash das partes" "NAO use parcial"
  passo "remontando winre-1809.wim a partir das 3 partes"
  cat "$WIM1809"/winre-1809.wim.part-0? > "$REPO/.work/winre-1809.wim"
  got=$(sha256sum "$REPO/.work/winre-1809.wim" | cut -d' ' -f1)
  [ "$got" = "$WIM_SHA" ] || { rm -f "$REPO/.work/winre-1809.wim"; falha "hash do WIM remontado"; }
  wimlib-imagex info "$REPO/.work/winre-1809.wim" 2>/dev/null | sed -n 's/^.*Boot Index: */Boot Index: /p'
  echo "WIM ok: $REPO/.work/winre-1809.wim"
fi

if [ "$MODO" = --fs ] || [ "$MODO" = --all ]; then
  passo "extraindo sistema de arquivos de inspecao (249 MB)"
  mkdir -p "$REPO/.work/fs"
  tar -xJf "$WT/inspecao-62MB/subset-inspecao.tar.xz" -C "$REPO/.work/fs" || falha "extracao do subset"
  echo "fs ok: $REPO/.work/fs"
  echo "  grep -ril '<HWID>' $REPO/.work/fs/Windows/INF/"
  echo "  python3 scripts/ler_hive.py $REPO/.work/fs/Windows/System32/config/SYSTEM"
fi
