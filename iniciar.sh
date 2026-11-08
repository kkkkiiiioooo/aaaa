#!/bin/sh
# iniciar.sh - ponto de entrada de um agente. Zero contexto previo.
#
#   A=<nome> P=<projeto> S_ARQ=<arquivo-da-passphrase> sh iniciar.sh
#   curl -fsSL .../0/iniciar.sh | sh -s -- A=<nome> P=<projeto> S_ARQ=<arquivo>
#
# Variaveis:
#   A     obrigatoria — nome do agente (assinatura dos commits, eventos, PRESENCA)
#   P     projeto por nome (wwii, iaag); sem P, lista os existentes
#   S     passphrase (preferir S_ARQ: argv aparece em `ps`)
#   D     1 = dry-run
set -eu

for kv in "$@"; do
  case "$kv" in
    *=*) export "$kv" ;;
    *) echo "iniciar.sh: argumento nao-reconhecido: $kv"; exit 2 ;;
  esac
done

AQUI=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
R=${R:-https://github.com/kkkkiiiioooo/aaaa.git}
P=${P:-}
D=${D:-0}

[ -n "${A:-}" ] || { echo "iniciar.sh: falta A=<nome do agente>"; exit 2; }
if [ -z "${S:-}" ] && [ -n "${S_ARQ:-}" ] && [ -r "$S_ARQ" ]; then S=$(head -1 "$S_ARQ"); fi
if [ -z "${S:-}" ] && [ ! -t 0 ]; then S=$(head -1); fi
if [ -z "${S:-}" ]; then printf 'Passphrase do t.gpg: '; S=$(head -1); fi
[ -n "$S" ] || { echo "iniciar.sh: sem passphrase"; exit 2; }

passo() { printf '\n===== %s =====\n' "$1"; }
falha() { printf '\nPARADO em %s: %s\n' "$1" "${2:-}"; exit 1; }

if [ "$D" = 1 ]; then
  printf 'dry-run — faria:\n'
  printf '  1 clone --filter=blob:none %s -> %s/aaaa\n' "$R" "$AQUI"
  printf '  2 h.sh  (credencial + branch %s + toolchain .work/bin + identidade A=%s)\n' "${P:-<lista>}" "$A"
  printf '  3 setup.sh (se o projeto tiver; senao, nada)\n'
  printf '  4 bin/protocolo.sh status\n'
  exit 0
fi

REPO="$AQUI/aaaa"
if [ ! -d "$REPO/.git" ]; then
  passo "1/3 clone"
  git clone -q --filter=blob:none "$R" "$REPO" 2>/dev/null || git clone -q "$R" "$REPO" || falha "clone"
fi

passo "1/3 credencial + branch + toolchain"
git -C "$REPO" fetch -q origin 0 >/dev/null 2>&1 || true
git -C "$REPO" show origin/0:h.sh > "$AQUI/.h.tmp" 2>/dev/null || falha "h.sh" "nao consegui extrair h.sh da branch 0"
# A_AGENTE e o nome que o h.sh le. Antes passavamos so A: identidade nunca era definida.
( cd "$AQUI" && S="$S" A_AGENTE="$A" P="$P" sh .h.tmp ) || { rm -f "$AQUI/.h.tmp"; falha "h.sh"; }
rm -f "$AQUI/.h.tmp"
cd "$REPO"
[ "$(git config user.name)" = "$A" ] || falha "identidade" "git user.name != $A (commits sairiam sem assinatura)"
echo "branch: $(git rev-parse --abbrev-ref HEAD)  como: $A"

passo "2/3 ambiente"
if [ -f setup.sh ]; then sh setup.sh || echo "[aviso] setup.sh retornou erro — leia a saida acima antes de codar"
else echo "sem setup.sh neste projeto (nada a instalar)"; fi

passo "3/3 estado"
[ -f .work/bin/protocolo.sh ] && sh .work/bin/protocolo.sh status || {
  echo "toolchain ausente em .work/bin — rode de novo: sh h.sh"; }

cat <<EOF

PRONTO. $REPO, branch $(git rev-parse --abbrev-ref HEAD), agente $A.
  ler    : PROTOCOLO.md -> TASK.md -> sh bin/protocolo.sh status
  pegar  : sh bin/reivindicar.sh <ID>
  fechar : sh bin/liberar.sh <ID> feita "<evidencia: caminho + saida>"
  publicar: sh bin/publicar.sh   (commit ja publica em refs/agents/$A)
EOF
