#!/bin/sh
# obter_imagem.sh — baixa o pacote offline da imagem 1809 (branch o rfã `imagem`).
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
WT=$REPO/.work/wt-imagem
BR=imagem
MODO=${1:---fs}

# sha256 do WIM ja remontado, medido na geracao (25 s, Boot Index 1)
WIM_SHA=f9e30ca308aa23e83d852ccefcfe7bca09a23d7c5b759ae655557612487879b8

case "$MODO" in --fs|--wim|--all) : ;; *) echo "uso: obter_imagem.sh --fs|--wim|--all"; exit 2 ;; esac

passo() { printf '\n=== %s ===\n' "$1"; }
falha() { printf '\nPARADO: %s\n' "$1"; exit 1; }

passo "buscar branch $BR (blob:none se o servidor suportar)"
git -C "$REPO" fetch --depth 1 -q origin "$BR" 2>/dev/null || git -C "$REPO" fetch -q origin "$BR" 2>/dev/null \
  || falha "fetch $BR" "a branch existe no remoto? sh scripts/dossie.sh publica o pacote"

passo "materializar em $WT sem mexer na sua branch de trabalho"
if [ -d "$WT" ]; then
  git -C "$WT" reset -q --hard FETCH_HEAD || falha "reset do worktree"
else
  git -C "$REPO" worktree add --detach -q "$WT" FETCH_HEAD || falha "worktree add"
fi

passo "verificando MANIFEST.sha256 ANTES de usar qualquer arquivo"
( cd "$WT" && sha256sum -c MANIFEST.sha256 ) || falha "verificacao de hash" \
    "arquivo corrompido no transporte — apague $WT e rode de novo; NAO use parcial"

if [ "$MODO" = --wim ] || [ "$MODO" = --all ]; then
  passo "remontando winre-1809.wim a partir das 3 partes"
  cat "$WT"/winre-1809.wim.part-0? > "$REPO/.work/winre-1809.wim"
  got=$(sha256sum "$REPO/.work/winre-1809.wim" | cut -d' ' -f1)
  [ "$got" = "$WIM_SHA" ] || { rm -f "$REPO/.work/winre-1809.wim"; falha "hash do WIM remontado"; }
  wimlib-imagex info "$REPO/.work/winre-1809.wim" 2>/dev/null | sed -n 's/^.*Boot Index: */Boot Index: /p'
  echo "WIM ok: $REPO/.work/winre-1809.wim"
fi

if [ "$MODO" = --fs ] || [ "$MODO" = --all ]; then
  passo "extraindo sistema de arquivos de inspecao (249 MB)"
  mkdir -p "$REPO/.work/fs"
  tar -xJf "$WT/subset-inspecao.tar.xz" -C "$REPO/.work/fs" || falha "extracao do subset"
  echo "fs ok: $REPO/.work/fs"
  echo "  grep -ril '<HWID>' $REPO/.work/fs/Windows/INF/"
  echo "  python3 scripts/ler_hive.py $REPO/.work/fs/Windows/System32/config/SYSTEM"
fi

passo "limpeza opcional"
echo "as partes ficam em $WT ($(du -sh "$WT" | cut -f1)); para liberar espaco:"
echo "  git -C $REPO worktree remove --force .work/wt-imagem"
