#!/bin/sh
# h.sh - helper do repositorio. PROJETO = NOME (p/wwii, wwii, iaag, loja).
#
# Uso:
#   S=<passphrase> P=<nome> sh h.sh        # entra num projeto existente
#   S=<passphrase> NEW=1 P=<nome> sh h.sh  # cria projeto novo (explicito, sem adivinhar)
#   A=<nome> S=<passphrase> P=<nome> sh h.sh   # entra e assina como <nome>
#
# Correcoes desta versao (v3, ver PROTOCOLO.md):
#   - identidade: aceita A= (o iniciar.sh sempre passou A, o h.sh so lia A_AGENTE:
#     todo mundo entrava pelo caminho oficial e commitava sem nome)
#   - credencial: helper LOCAL ao clone, escopo https://github.com, token em
#     .work/token (600, gitignored). Fim do ~/.git-credentials em texto plano global.
#   - passphrase: tentativa unica. Variantes (minusculas, so-letras) mutilavam a
#     senha em silencio e mascaravam passphrase fraca.
#   - clone: --filter=blob:none (2 s / 748 KB medidos, contra 23 s / 319 MB). Os
#     blobs da branch de dados continuam acessiveis sob demanda.
#   - projeto novo: nasce do template, nao da main (que so tem README).
#   - toolchain e hooks vem da branch 0 para .work/ (uma fonte, sem deriva).
#   - lista de projetos sem lista de excecoes: p/* e projeto, o resto nao e.
set -u
S=${1:-${S:-${SENHA:-}}}
P=${2:-${P:-${PROJETO:-}}}
A=${A_AGENTE:-${A:-}}
AQUI=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
URL=${URL:-https://github.com/kkkkiiiioooo/aaaa.git}
if [ -n "${DIR:-}" ]; then :
elif [ -d "$AQUI/.git" ]; then DIR="$AQUI"
else DIR="$AQUI/aaaa"; fi
RAW=${RAW:-https://raw.githubusercontent.com/kkkkiiiioooo/aaaa/0/projeto.gpg}

[ -n "$S" ] || [ -n "${S_ARQ:-}" ] || { echo "erro: falta S=<passphrase> (ou S_ARQ=<arquivo>)."; exit 1; }
if [ -z "$S" ] && [ -r "${S_ARQ:-/nonexistent}" ]; then S=$(head -1 "$S_ARQ"); fi
if [ -z "$S" ] && [ -r "$HOME/.aaaa/frase" ]; then S=$(head -1 "$HOME/.aaaa/frase"); fi

# ------------------------------------------------------------------ 1 credencial
t=""
abre() { # $1 = blob cifrado
  printf '%s' "$1" | gpg -dq --batch --passphrase "$S" 2>/dev/null
}
if [ -d "$DIR/.git" ] && git -C "$DIR" rev-parse -q --verify origin/0 >/dev/null 2>&1; then
  blob=$(git -C "$DIR" show origin/0:projeto.gpg 2>/dev/null)
fi
[ -n "${blob:-}" ] || blob=$(curl -fsSL "$RAW" 2>/dev/null)
[ -n "${blob:-}" ] || { echo "erro: sem acesso ao projeto.gpg (nem local em origin/0, nem $RAW)"; exit 1; }
t=$(abre "$blob")
[ -n "$t" ] || { echo "erro: passphrase nao abriu o projeto.gpg. Confira S (uma tentativa, sem variantes)."; exit 1; }

# ------------------------------------------------------------------ 2 clone
if [ ! -d "$DIR/.git" ]; then
  git clone -q --filter=blob:none "$URL" "$DIR" 2>/dev/null \
    || git clone -q "$URL" "$DIR" \
    || { echo "erro: clone falhou em $DIR"; exit 1; }
fi
cd "$DIR" || exit 1

# token fora do historico e do home: .work/ e gitignored
mkdir -p .work .work/logs
printf '%s\n' "$t" > .work/token
git config core.fileMode false 2>/dev/null
git config credential."https://github.com".helper "!f() { test \"\$1\" = get || exit 0; echo username=x; echo password=\$(cat '$DIR/.work/token'); }; f"
git config push.autoSetupRemote true

[ -n "$A" ] && {
  git config user.name "$A"
  git config user.email "$(printf %s "$A" | tr -cd 'a-zA-Z0-9._-')@agents.local"
  printf '%s\n' "$A" > .work/agente
}

# ------------------------------------------------------------------ 3 ramos
git fetch -q origin --prune 2>/dev/null || echo "aviso: fetch falhou (seguindo com as refs locais)"
REF0=""
for r in 0 origin/0; do git rev-parse -q --verify "$r" >/dev/null 2>&1 && { REF0=$r; break; }; done
[ -n "$REF0" ] || { echo "erro: branch 0 ausente — ela e a base do protocolo"; exit 1; }

# p/* e projeto. Nomes antigos (sem prefixo) seguem aceitos na migracao.
LISTA=$(git branch -r | sed 's#.*origin/##' \
  | grep -Ev '^HEAD$|^$|^main$|^0$|^base$|^template$|^backup$|^meta/|^dado/' | sort -u)

if [ -z "$P" ]; then
  echo "qual projeto? existentes: $(printf %s "$LISTA" | tr '\n' ' ')"
  echo "uso: S=<passphrase> A=<nome> P=<nome> sh h.sh"
  exit 1
fi
case $P in
  *[!0-9]*) ;;
  *) echo "erro: projetos usam nome, nao numero. Existentes: $(printf %s "$LISTA" | tr '\n' ' ')"; exit 1 ;;
esac

alvo=$(printf '%s\n' "$LISTA" | grep -ixF "$P" | head -1)
[ -n "$alvo" ] || alvo=$(printf '%s\n' "$LISTA" | grep -ixF "p/$P" | head -1)
[ -n "$alvo" ] || alvo=$(printf '%s\n' "$LISTA" | sed 's/^p\///; s/^[0-9][0-9]*[._-]*//' | grep -ixF "$P" | head -1)

if [ -z "$alvo" ]; then
  if [ -n "${NEW:-}" ]; then
    alvo=$P
    case $alvo in p/*) ;; *) alvo="p/$P" ;; esac
    BASE=template
    git rev-parse -q --verify "origin/$BASE" >/dev/null 2>&1 || BASE=$REF0
    git switch -qc "$alvo" --no-track "origin/$BASE" 2>/dev/null \
      || git switch -qc "$alvo" --no-track "$(git rev-parse "origin/$BASE" 2>/dev/null || echo "$REF0")" \
      || { echo "erro: nao consegui criar $alvo a partir de $BASE"; exit 1; }
    echo "criado projeto novo: $alvo (base: $BASE)"
  else
    echo "erro: nao existe projeto \"$P\". Existentes: $(printf %s "$LISTA" | tr '\n' ' ')"
    echo "para criar um novo, diga explicitamente: NEW=1 P=$P sh h.sh"
    exit 1
  fi
fi
git switch -q "$alvo" 2>/dev/null || git switch -qc "$alvo" --no-track "origin/$alvo" || exit 1

# ------------------------------------------------------------------ 4 toolchain
# Uma fonte so: bin/ e protocolo-lint.sh vem da branch 0 para .work/ (gitignored).
# Assim corrigir um script e um commit, nao N commits em N branches.
TB="$DIR/.work/bin"
mkdir -p "$TB"
for f in $(git ls-tree --name-only "$REF0:bin" 2>/dev/null); do
  git show "$REF0:bin/$f" > "$TB/$f" 2>/dev/null && chmod 755 "$TB/$f"
done
git show "$REF0:protocolo-lint.sh" > "$DIR/.work/protocolo-lint.sh" 2>/dev/null && chmod 755 "$DIR/.work/protocolo-lint.sh"

if [ -f hooks/pre-commit ]; then
  git config core.hooksPath hooks            # projeto tem hooks versionados: usa os dele
else
  mkdir -p .work/hooks
  for h in pre-commit prepare-commit-msg post-commit pre-push; do
    git show "$REF0:hooks/$h" > ".work/hooks/$h" 2>/dev/null && chmod 755 ".work/hooks/$h"
  done
  git config core.hooksPath .work/hooks
fi

# ------------------------------------------------------------------ 5 avisos
VER0=$(git show "$REF0:PROTOCOLO.md" 2>/dev/null | sed -n 's/^Versao: *//p' | head -1)
VERA=$(git show "HEAD:PROTOCOLO.md" 2>/dev/null | sed -n 's/^Versao: *//p' | head -1)
[ -n "$VER0" ] && [ "$VER0" != "${VERA:-0}" ] && \
  echo "aviso: protocolo v$VER0 na branch 0, v${VERA:-0} aqui — leia PROTOCOLO.md antes de trabalhar"

[ "$(git branch --show-current)" = main ] || {
  git ls-files --error-unmatch .agentignore >/dev/null 2>&1 || {
    echo "projeto.gpg" > .agentignore; git add .agentignore; git commit -qm "agentignore"; }
}

echo "ok $(git branch --show-current) como ${A:-$(git config user.name || echo '?')} em $PWD"
echo "projetos: $(printf %s "$LISTA" | tr '\n' ' ')"
echo "toolchain: .work/bin ($(ls "$TB" 2>/dev/null | wc -l) scripts) · protocolo v${VERA:-?}"
