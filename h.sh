#!/bin/sh
# h.sh - helper do repositorio. PROJETO = NOME, sem numero (wwii, iaag, loja).
#
# Uso:
#   S=<passphrase> P=<nome> sh h.sh        # entra num projeto existente
#   S=<passphrase> NEW=1 P=<nome> sh h.sh  # cria projeto novo (explicito, sem adivinhar)
#
# Correcoes em relacao a versao antiga (cada uma custou rodadas de agente):
#   - nao cria ramal por engano: nome que nao casa = erro com a lista, nunca "6.<nome>"
#   - nao faz cd em /home/claude (caminho fixo): trabalha onde o clone esta
#   - nao comita .agentignore na main (violava "main nunca deve ser alterada")
#   - instalar o guard da main ANTES de qualquer commit
#   - tenta a passphrase como veio, e depois as variantes: nao mutila senha em silencio
set -u
S=${1:-${S:-${SENHA:-}}}
P=${2:-${P:-${PROJETO:-}}}
AQUI=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
URL=${URL:-https://github.com/kkkkiiiioooo/aaaa}
DIR=${DIR:-$AQUI/aaaa}
RAW=${RAW:-https://raw.githubusercontent.com/kkkkiiiioooo/aaaa/0/t.gpg}

[ -n "$S" ] || { echo "erro: falta S=<passphrase>. Ex.: S=senha P=wwii sh h.sh"; exit 1; }

# 1) credencial: tenta a forma informada e variantes, sem alterar em silencio
blob=$(curl -fsSL "$RAW" 2>/dev/null)
[ -n "$blob" ] || { echo "erro: rede/URL indisponivel para baixar t.gpg"; exit 1; }
t=""
for cand in "$S" "$(printf %s "$S" | tr A-Z a-z)" "$(printf %s "$S" | tr A-Z a-z | tr -cd a-z)"; do
  [ -n "$cand" ] || continue
  t=$(printf %s "$blob" | gpg -dq --batch --passphrase "$cand" 2>/dev/null) && [ -n "$t" ] && break
  t=""
done
[ -n "$t" ] || { echo "erro: passphrase nao abriu o t.gpg (confira S)"; exit 1; }
git config --global credential.helper store
printf 'protocol=https\nhost=github.com\nusername=x\npassword=%s\n\n' "$t" | git credential approve
chmod 600 ~/.git-credentials

# 2) clone no diretorio deste script (antes: /home/claude fixo)
[ -d "$DIR/.git" ] || git clone -q "$URL" "$DIR" || { echo "erro: clone falhou em $DIR"; exit 1; }
cd "$DIR" || exit 1
[ -n "${A_AGENTE:-}" ] && { git config user.name "$A_AGENTE"; git config user.email "$(printf %s "$A_AGENTE" | tr -cd 'a-zA-Z0-9._-')@agents.local"; }
git config push.autoSetupRemote true
git config core.hooksPath hooks

# 4) projeto: por NOME. Sem nome -> lista e para. Sem match -> para (nao inventa ramal).
git fetch -q origin --prune
LISTA=$(git branch -r | sed 's#.*origin/##' | grep -Ev '^HEAD$|^_archived$|^0$|^main$|^backup$|^relatorio$' | sort -u)
if [ -z "$P" ]; then
  echo "qual projeto? existentes: $(printf %s "$LISTA" | tr '\n' ' ')"
  echo "uso: S=<passphrase> P=<nome> sh h.sh"
  exit 1
fi
case $P in
  *[!0-9]*) ;;
  *) echo "erro: projetos nao usam mais numero. Use o nome. Existentes: $(printf %s "$LISTA" | tr '\n' ' ')"; exit 1 ;;
esac
alvo=$(printf %s "$LISTA" | grep -ixF "$P" | head -1)
[ -n "$alvo" ] || alvo=$(printf %s "$LISTA" | sed 's/^[0-9][0-9]*[._-]*//' | grep -ixF "$P" | head -1)
if [ -z "$alvo" ]; then
  if [ -n "${NEW:-}" ]; then
    alvo=$P
    git switch -qc "$alvo" --no-track origin/main || exit 1
    echo "criado projeto novo: $alvo"
  else
    echo "erro: nao existe projeto \"$P\". Existentes: $(printf %s "$LISTA" | tr '\n' ' ')"
    echo "para criar um novo, diga explicitamente: NEW=1 P=$P sh h.sh"
    exit 1
  fi
fi
git switch -q "$alvo" 2>/dev/null || git switch -qc "$alvo" --no-track "origin/$alvo" || exit 1
# 5) hooks: usa os versionados da branch; so escreve os minimos se nao existirem
#    (a versao antiga gravava hooks/ antes do switch e fazia o switch abortar em
#     "untracked working tree files would be overwritten")
git config core.hooksPath hooks
if [ ! -f hooks/pre-commit ]; then
  mkdir -p hooks
  printf '#!/bin/sh\n[ "$(git branch --show-current)" = main ] && [ -z "${OK:-}" ] && { echo "main: use uma branch de projeto (ou OK=1)"; exit 1; }\nexit 0\n' > hooks/pre-commit
  printf '#!/bin/sh\n[ -n "${MM_GUARDA:-}" ] && exit 0\nMM_GUARDA=1; export MM_GUARDA\nb=$(git branch --show-current)\ngit pull -q --rebase origin "$b" || { git rebase --abort 2>/dev/null; echo "CONFLITO: resolva antes de enviar"; exit 1; }\ngit push -q origin "$b" || echo "AVISO: push falhou em $b"\n' > hooks/post-commit
  chmod 755 hooks/pre-commit hooks/post-commit
fi
[ "$(git branch --show-current)" = main ] || {
  git ls-files --error-unmatch .agentignore >/dev/null 2>&1 || { echo "t.gpg" > .agentignore; git add .agentignore; git commit -qm "agentignore"; }
}
echo "ok $(git branch --show-current) em $PWD"
echo "projetos: $(printf %s "$LISTA" | tr '\n' ' ')"
