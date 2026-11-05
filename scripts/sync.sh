#!/bin/sh
# sync.sh - liga lead <-> executores sem ninguem rodar nada. Chamado pelo hook post-commit e por iniciar.sh.
#   DESCE: PLANO-DO-LIDER.md (origin/lider) -> .work/PLANO-DO-LIDER.md; avisa SO quando mudou.
#   SOBE : docs/retorno/<ID>.md -> lider:RETORNO/<ID>.md + linha "Retornos" no INDICE-PARA-O-LIDER.md.
# O lead so escreve PLANO-DO-LIDER.md na branch lider. Silencioso se nada mudou. Nunca falha (exit 0).
B="${BR_REL:-lider}"
R=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$R" || exit 0
mkdir -p .work
git fetch -q origin "$B" 2>/dev/null || exit 0

# ---- DESCE
N=$(git rev-parse -q --verify "origin/$B:PLANO-DO-LIDER.md" 2>/dev/null)
if [ -n "$N" ] && [ "$N" != "$(cat .work/plano.sha 2>/dev/null)" ]; then
  if git show "origin/$B:PLANO-DO-LIDER.md" > .work/plano.new 2>/dev/null; then
    echo ">>> PLANO DO LIDER MUDOU: leia .work/PLANO-DO-LIDER.md e siga a prioridade dele."
    [ -f .work/PLANO-DO-LIDER.md ] && diff .work/PLANO-DO-LIDER.md .work/plano.new \
      | sed -n 's/^> /  novo: /p' | cut -c1-200 | head -15
    mv .work/plano.new .work/PLANO-DO-LIDER.md && printf '%s\n' "$N" > .work/plano.sha
  fi
fi

# ---- SOBE
ls docs/retorno/*.md 2>/dev/null | grep -qv 'MODELO.md' || exit 0
WT=".work/wt-$B"
if [ ! -d "$WT" ]; then
  if git rev-parse -q --verify "refs/heads/$B" >/dev/null 2>&1; then
    git worktree add "$WT" "$B" >/dev/null 2>&1 || exit 0
  else
    git worktree add --track -B "$B" "$WT" "origin/$B" >/dev/null 2>&1 || exit 0
  fi
fi
git -C "$WT" pull -q --rebase origin "$B" 2>/dev/null || { git -C "$WT" rebase --abort 2>/dev/null; exit 0; }
for f in docs/retorno/*.md; do
  i=$(basename "$f" .md)
  [ "$i" = MODELO ] && continue
  mkdir -p "$WT/RETORNO"
  cmp -s "$f" "$WT/RETORNO/$i.md" || cp "$f" "$WT/RETORNO/$i.md"
done
F="$WT/INDICE-PARA-O-LIDER.md"
if [ -f "$F" ]; then
  L=""
  for f in "$WT"/RETORNO/*.md; do
    [ -f "$f" ] || continue
    v=$(sed -n '/^## Veredito/{n;s/ .*//;p;q;}' "$f")
    L="$L $(basename "$f" .md)=${v:-?}"
  done
  sed -i '/^Retornos/d' "$F"
  printf 'Retornos (RETORNO/<id>.md):%s\n' "$L" >> "$F"
fi
git -C "$WT" add -A
git -C "$WT" diff --cached --quiet && exit 0
git -C "$WT" commit -q --no-verify -m "retorno: sync automatico"
if git -C "$WT" push -q origin "$B" 2>/dev/null; then
  echo ">>> retornos enviados ao lider (branch $B)"
else
  echo ">>> AVISO: push dos retornos falhou; sera tentado no proximo commit"
fi
exit 0
