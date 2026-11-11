#!/bin/sh
# setup/common/credentials.sh - unica variavel do setup: GH_TOKEN (token com escrita no repo).
# Sem GH_TOKEN usa a credencial ja salva. Nunca imprime o token. Idempotente.
cd "$(dirname "$0")/../.." || exit 1
git config --local credential.helper store
if [ -n "${GH_TOKEN:-}" ]; then
  F=${HOME:-/root}/.git-credentials; touch "$F"; chmod 600 "$F"
  grep -v '@github.com$' "$F" > "$F.tmp" 2>/dev/null; mv "$F.tmp" "$F"
  printf 'https://x-access-token:%s@github.com\n' "$GH_TOKEN" >> "$F"
  echo "[credentials] token gravado em $F"
fi
git ls-remote -q --exit-code origin HEAD >/dev/null 2>&1 || { echo "[credentials] ERRO: sem leitura no origin (rede?)"; exit 1; }
if git push --dry-run --no-verify -q origin HEAD >/dev/null 2>&1; then echo "[credentials] escrita no origin: OK"
else echo "[credentials] ERRO: sem escrita. Rode: GH_TOKEN=<token> sh setup.sh"; exit 1; fi
