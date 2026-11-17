#!/bin/sh
# setup.sh — bootstrap de credencial e identidade do repo aaaa.
# Uso:  sh setup.sh
# Opcional (ambiente):  X=<frase>  X_ARQ=<arquivo>  A=<agente>  P=<branch>
set -eu

REPO_URL="https://github.com/kkkkiiiioooo/aaaa.git"
REPO_DIR="aaaa"
AGENTE="${A:-agente}"
EMAIL="${A_EMAIL:-agente@local}"
BRANCH="${P:-}"

falha() { echo "setup: $*" >&2; exit 1; }

# ---- 1. estar dentro do repo (ou clonar) -------------------------------------
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  cd "$(git rev-parse --show-toplevel)"
else
  command -v git >/dev/null 2>&1 || falha "git nao encontrado"
  [ -d "$REPO_DIR/.git" ] || git clone -q "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi
TOPO="$(pwd)"
GITDIR="$(git rev-parse --absolute-git-dir)"

# ---- 2. HOME e GNUPGHOME: criar o que faltar, falhar alto se nao der -------
: "${HOME:=$GITDIR/.home}"
export HOME
if [ ! -d "$HOME" ]; then
  mkdir -p "$HOME" 2>/dev/null || falha "nao consegui criar HOME ($HOME) — defina HOME para um caminho gravavel"
fi
export GNUPGHOME="${GNUPGHOME:-$HOME/.gnupg}"
mkdir -p "$GNUPGHOME" 2>/dev/null || falha "nao consegui criar GNUPGHOME ($GNUPGHOME)"
chmod 700 "$GNUPGHOME" 2>/dev/null || true
[ -w "$GNUPGHOME" ] || falha "GNUPGHOME sem permissao de escrita ($GNUPGHOME)"

# ---- 3. frase: X -> X_ARQ -> $HOME/.aaaa/frase -> embutida ----------------
FRASE=""
[ -n "${X:-}" ] && FRASE="$X"
if [ -z "$FRASE" ] && [ -n "${X_ARQ:-}" ] && [ -r "$X_ARQ" ]; then
  FRASE="$(head -n 1 "$X_ARQ" | tr -d '\r\n')"
fi
if [ -z "$FRASE" ] && [ -r "$HOME/.aaaa/frase" ]; then
  FRASE="$(head -n 1 "$HOME/.aaaa/frase" | tr -d '\r\n')"
fi
[ -n "$FRASE" ] || FRASE="@podepublicar"

# ---- 4. buscar o projeto.gpg e decifrar ------------------------------------
git fetch -q origin 0 2>/dev/null || true
ARQ_GPG=""
for origem in "$GITDIR/projeto.gpg" "$TOPO/projeto.gpg"; do
  if [ -f "$origem" ]; then ARQ_GPG="$origem"; break; fi
done
[ -n "$ARQ_GPG" ] || ARQ_GPG="$(git show origin/0:projeto.gpg 2>/dev/null > "$GITDIR/.projeto.gpg.tmp" && echo "$GITDIR/.projeto.gpg.tmp")" || falha "nao achei projeto.gpg (nenhum arquivo local e origin/0 nao devolveu)"

TOKEN="$(gpg -dq --batch --yes --pinentry-mode loopback --passphrase "$FRASE" "$ARQ_GPG" 2>/dev/null | tr -d '\r\n')" || TOKEN=""
[ -n "$TOKEN" ] && [ "$TOKEN" != "$FRASE" ] || falha "nao consegui decifrar o projeto.gpg (a frase nao abre)"

# ---- 5. gravar credencial fora da arvore de arquivos ----------------------
printf 'https://kkkkiiiioooo:%s@github.com\n' "$TOKEN" > "$GITDIR/aaaa-gh.tmp"
grep -q 'ioooo:[^@]' "$GITDIR/aaaa-gh.tmp" || { rm -f "$GITDIR/aaaa-gh.tmp"; falha "token com formato inesperado"; }
mv "$GITDIR/aaaa-gh.tmp" "$GITDIR/aaaa-gh"
chmod 600 "$GITDIR/aaaa-gh"
rm -f "$GITDIR/.projeto.gpg.tmp"

# ---- 6. configurar helper e identidade -----------------------------------
git config --replace-all credential.helper ""
git config --add credential.helper "store --file=\"$GITDIR/aaaa-gh\""
git config user.name "$AGENTE"
git config user.email "$EMAIL"

# ---- 7. autenticar gh cli (silencioso, sem vazar token) -------------------
if command -v gh >/dev/null 2>&1; then
  echo "$TOKEN" | gh auth login --with-token >/dev/null 2>&1 || true
fi

# ---- 7. branch de trabalho (opcional) -------------------------------------
if [ -n "$BRANCH" ]; then
  git fetch -q origin "$BRANCH" 2>/dev/null || falha "nao consegui buscar a branch $BRANCH"
  git switch -q "$BRANCH" 2>/dev/null || git switch -q -c "$BRANCH" "origin/$BRANCH" || falha "nao consegui ir para a branch $BRANCH"
fi

# ---- 8. verificar ----------------------------------------------------------
git push --dry-run -q origin HEAD >/dev/null 2>&1 && ESCRITA=OK || ESCRITA=FALHOU
echo "setup: repo=$TOPO branch=$(git rev-parse --abbrev-ref HEAD) agente=$AGENTE <$EMAIL>"
echo "setup: credencial em $GITDIR/aaaa-gh (600) | push=$ESCRITA"
[ "$ESCRITA" = "OK" ] || falha "push de teste nao autorizou — token invalido ou sem permissao na branch"
echo "setup: OK"
