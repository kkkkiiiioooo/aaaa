#!/bin/sh
# iniciar.sh — ponto de entrada único de um agente. Zero contexto prévio.
#
#   sh iniciar.sh R=https://github.com/<dono>/aaaa.git A=<nome> S=<passphrase> P=wwii
#
# R é opcional (já aponta para este repo). Faz em sequência, parando na 1ª falha:
#   1 h.sh          credencial + branch do projeto + hooks + identidade
#   2 setup.sh      dependências, bate-ponto, diagnóstico T0..T4
#   3 etapa.sh      reclama a primeira etapa livre (ou retoma a que já é sua)
#   4 relatorio.sh  publica a linha que o lead lê
#
# Variáveis:
#   A  obrigatória — nome do agente (bate-ponto, git, evidência)
#   S  passphrase de t.gpg; ou S_ARQ=<arquivo>. Nunca passe S em argv num pipe.
#   P  projeto por nome (wwii, iaag); padrão: wwii
#   D 1 = dry-run: mostra o plano e não executa nada
#   E forçar uma etapa específica (padrão: primeira livre)
set -eu

# aceita A=<nome> P=<projeto> tanto como ambiente quanto como argumento posicional
# (com `curl ... | sh -s -- A=n P=p` o stdin ja esta tomado pelo proprio script)
for kv in "$@"; do
  case "$kv" in
    *=*) export "$kv" ;;
    *) echo "iniciar.sh: argumento nao-reconhecido: $kv"; exit 2 ;;
  esac
done

AQUI=$(cd "$(dirname "$0")" && pwd)
R=${R:-https://github.com/kkkkiiiioooo/aaaa.git}
P=${P:-wwii}
D=${D:-0}

[ -n "${A:-}" ] || { echo "iniciar.sh: falta A=<nome do agente>"; exit 2; }
if [ -z "${S:-}" ] && [ -n "${S_ARQ:-}" ] && [ -r "$S_ARQ" ]; then S=$(head -1 "$S_ARQ"); fi
if [ -z "${S:-}" ] && [ ! -t 0 ]; then S=$(head -1); fi
if [ -z "${S:-}" ]; then printf 'Passphrase de t.gpg: '; S=$(head -1); fi
[ -n "$S" ] || { echo "iniciar.sh: sem passphrase"; exit 2; }

passo() { printf '\n===== %s =====\n' "$1"; }
falha() { printf '\nPARADO em %s: %s\n' "$1" "${2:-}"; exit 1; }

if [ "$D" = 1 ]; then
  printf 'dry-run — faria:\n'
  printf '  1 git clone %s -> %s/aaaa ; sh h.sh (A=%s P=%s)\n' "$R" "$AQUI" "$A" "$P"
  printf '  2 sh setup.sh   (dependências + bate-ponto + doctor)\n'
  printf '  3 sh scripts/etapa.sh pegar ${E:-primeira livre}\n'
  printf '  4 sh scripts/relatorio.sh "<linha>"\n'
  exit 0
fi

# ---------------------------------------------------------------- 1 bootstrap
REPO="$AQUI/aaaa"
if [ ! -d "$REPO/.git" ]; then
  passo "1/4 clone"
  git clone "$R" "$REPO" >/dev/null 2>&1 || falha "clone"
fi
cd "$REPO"

passo "1/4 credencial + branch"
git fetch origin 0 >/dev/null 2>&1 || true
git show origin/0:h.sh > .h.tmp 2>/dev/null || git show origin/main:h.sh > .h.tmp 2>/dev/null || true
[ -s .h.tmp ] || falha "h.sh" "nao consegui extrair h.sh da branch 0"
S="$S" A="$A" P="$P" sh .h.tmp || { rm -f .h.tmp; falha "h.sh"; }
rm -f .h.tmp
echo "branch: $(git rev-parse --abbrev-ref HEAD)  as: $(git config user.name)"

# ------------------------------------------------------------------- 2 setup
passo "2/4 ambiente"
sh setup.sh || falha "setup.sh" "ambiente incompleto — leia o diagnóstico acima antes de escrever código"

# ------------------------------------------------------------ 3 reclamar etapa
passo "3/4 etapa"
sh scripts/etapa.sh status
# autoridade de estado e o etapa.sh; aqui so lemos a saida dele
ST=$(sh scripts/etapa.sh status)
MINHA=${E:-}
if [ -z "$MINHA" ]; then
  MINHA=$(printf '%s\n' "$ST" | sed -n "s/^MINHA ETAPA: \(E[0-9]*\).*/\1/p" | head -1)
  [ -n "$MINHA" ] || MINHA=$(printf '%s\n' "$ST" | sed -n "s/^LIVRES para reclamacao: //p" | head -1 | awk '{print $1}')
fi
[ -n "$MINHA" ] || falha "etapa" "nenhuma etapa livre — pergunte ao lead"
sh scripts/etapa.sh pegar "$MINHA" || falha "etapa $MINHA"

# ----------------------------------------------------------------- 4 relatório
passo "4/4 relatório do lead"
N=$(sh scripts/doctor.sh 2>/dev/null | sed -n "s/^EXECUTAVEL AGORA: //p" | head -1); [ -n "$N" ] || N="ver doctor.sh"
sh scripts/relatorio.sh "$A | $MINHA | rodando | ambiente: $N | proximo: ver ETAPAS.md" || true

cat <<EOF

PRONTO. Você está em $REPO, branch $(git rev-parse --abbrev-ref HEAD), etapa $MINHA.
  leia   : AGENTS.md -> PLANO.md -> ETAPAS.md
  trabalho: scripts/etapa.sh fechar $MINHA "<evidencia: caminho + saida>"
  status : sh scripts/etapa.sh status
EOF
