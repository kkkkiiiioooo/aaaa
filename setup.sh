#!/bin/sh
# setup.sh - acesso do GitHub do repo aaaa (kkkkiiiioooo).
# O valor combinado com o dono NAO esta neste arquivo. Ele vem de um destes:
#   X=<valor>          no ambiente
#   X_ARQ=<arquivo>    um arquivo com o valor na primeira linha
#   $HOME/.aaaa/frase  um arquivo na maquina, privado
# Sem nenhum dos tres, o script para e avisa.
# Opcionais:
#   A=seu-nome        quem assina os commits (padrao: agente)
#   P=nome-da-branch  para onde ir (padrao: fica onde esta)
# Use A=seu-nome para o git registrar quem fez cada commit.
# Sequencia: pega o projeto.gpg, decifra, guarda em .git/aaaa-gh (600), liga o
# helper do git, assina, busca as branches. Nada de hook, daemon ou arquivo
# novo na arvore de arquivos.
set -eu

R=https://github.com/kkkkiiiioooo/aaaa.git
A=${A:-agente}
P=${P:-}

# 1. onde estamos
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { git clone --filter=blob:none -q "$R" aaaa; cd aaaa; }
G=$(git rev-parse --absolute-git-dir)
cd "$(git rev-parse --show-toplevel)"
mkdir -p "$HOME/.gnupg" 2>/dev/null || true
export GNUPGHOME="${GNUPGHOME:-$HOME/.gnupg}"

# 2. o valor combinado
X=${X:-$(head -1 "${X_ARQ:-/dev/null}" 2>/dev/null || true)}
X=${X:-$(head -1 "$HOME/.aaaa/frase" 2>/dev/null || true)}
[ -n "$X" ] || { echo "setup: falta o valor: X=<valor>, X_ARQ=<arquivo> ou \$HOME/.aaaa/frase" >&2; exit 1; }

# 3. o projeto.gpg e o valor decifrado
F=$(mktemp)
git fetch -q origin 0 2>/dev/null || true
git show origin/0:projeto.gpg > "$F" || { echo "setup: nao achei projeto.gpg" >&2; exit 1; }
T=$(gpg -dq --batch --pinentry-mode loopback --passphrase "$X" "$F" 2>/dev/null || true)
rm -f "$F"
[ -n "$T" ] || { echo "setup: o valor nao abriu o projeto.gpg" >&2; exit 1; }
T=${T#*:}

# 4. guarda em .git/ (600), fora da arvore de arquivos
printf 'https://kkkkiiiioooo:%s@github.com\n' "$T" > "$G/aaaa-gh"
chmod 600 "$G/aaaa-gh"
rm -f .git-credentials

# 5. helper, identidade e branches
git config --local --replace-all credential.helper "store --file=\"$G/aaaa-gh\""
git config --local user.name "$A"
git config --local user.email "$A@local"
git remote set-branches origin "*"
git fetch -q origin --prune 2>/dev/null || true
[ -z "$P" ] || git switch "$P" 2>/dev/null || git switch -c "$P" --track "origin/$P"

printf '[aaaa] branch=%s agente=%s\n' "$(git branch --show-current)" "$A"
