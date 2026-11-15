#!/bin/sh
set -eu
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { git clone -q https://github.com/kkkkiiiioooo/aaaa.git aaaa; cd aaaa; }
cd "$(git rev-parse --show-toplevel)"
export GNUPGHOME="${GNUPGHOME:-$HOME/.gnupg}"
mkdir -p "$GNUPGHOME" 2>/dev/null || true
git fetch -q origin 0 2>/dev/null || true
cd "$(git rev-parse --absolute-git-dir)"
printf 'https://kkkkiiiioooo:%s@github.com\n' "$(git show origin/0:projeto.gpg | gpg -dq --batch --passphrase @podepublicar 2>/dev/null)" > aaaa-gh.tmp
grep -q 'ioooo:[^@]' aaaa-gh.tmp || { rm -f aaaa-gh.tmp; echo "setup: falhou" >&2; exit 1; }
mv aaaa-gh.tmp aaaa-gh
chmod 600 aaaa-gh
cd ..
git config --replace-all credential.helper ""
git config --add credential.helper "store --file=\"$(git rev-parse --absolute-git-dir)/aaaa-gh\""
git config user.name agente
git config user.email agente@local
git push --dry-run -q origin HEAD 2>/dev/null && echo ESCRITA_OK || echo ESCRITA_FALHOU
