#!/bin/sh
# setupenvagentaccio.sh — ambiente do agente Programador nesta arvore.
# Chamado depois do setup.sh do repo (que cuida da credencial).
# Uso:  sh setupenvagentaccio.sh [branch]
set -eu

REPO_URL="https://github.com/kkkkiiiioooo/aaaa.git"
REPO_DIR="${REPO_DIR:-aaaa}"
BRANCH="${1:-${P:-0}}"
AGENTE="${A:-Programador}"
EMAIL="${A_EMAIL:-programador@local}"

log()   { echo "env: $*"; }
falha() { echo "env: $*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || falha "git ausente"

# 1. estar no repo (clona se preciso) ----------------------------------------
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  cd "$(git rev-parse --show-toplevel)"
elif [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR"
else
  git clone -q "$REPO_URL" "$REPO_DIR" || falha "clone falhou"
  cd "$REPO_DIR"
fi

# 2. credencial: o conector do repo e a fonte da verdade ---------------------
if [ -f setup.sh ]; then
  sh ./setup.sh >/dev/null 2>&1 || falha "setup.sh do repo falhou"
  log "credencial aplicada pelo setup.sh"
else
  log "AVISO: setup.sh ausente; push pode falhar"
fi

# 3. branch de trabalho -------------------------------------------------------
git fetch -q origin || true
git switch -q "$BRANCH" 2>/dev/null \
  || git switch -q -c "$BRANCH" "origin/$BRANCH" \
  || falha "nao consegui ir para a branch $BRANCH"

# 4. identidade e defaults ----------------------------------------------------
git config user.name "$AGENTE"
git config user.email "$EMAIL"
git config pull.rebase true
git config push.autoSetupRemote true
git config fetch.prune true
git config alias.sync '!git add -A && git commit -m "chore(sync): atualiza arvore" && git push'
git config alias.st 'status --short --branch'

# 5. verificar ----------------------------------------------------------------
if git push --dry-run -q origin HEAD >/dev/null 2>&1; then W=OK; else W=FALHOU; fi
log "repo=$(pwd) branch=$(git rev-parse --abbrev-ref HEAD) push=$W"
[ "$W" = OK ] || falha "push nao autorizado"
log "OK"
