#!/bin/sh
# protocolo-smoke.sh - prova que o cadeado e atomico entre dois agentes e que as
# visoes sao geradas a partir de eventos. Sem rede: usa um repositorio bare local.
#
# Uso: sh tests/protocolo-smoke.sh
set -u
AQUI=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d 2>/dev/null) || { echo "sem mktemp"; exit 2; }
trap 'rm -rf "$TMP"' EXIT INT TERM
FALHAS=0
ok()   { printf 'ok   %s\n' "$1"; }
nao()  { printf 'FALHA %s\n' "$1"; FALHAS=$((FALHAS + 1)); }
espera() { # espera <saida> <codigo-diferente-de-0>
  printf '%s' "$1" | grep -q "$2" && return 0 || return 1
}

git init -q --bare "$TMP/origin.git" || exit 2
git clone -q "$TMP/origin.git" "$TMP/semente" 2>/dev/null || exit 2
cd "$TMP/semente" || exit 2
git config user.name semente; git config user.email s@local
printf 'README\n' > README.md; git add .; git commit -qm inicial
git push -q origin HEAD:main
git push -q origin HEAD:p/teste
cd "$TMP" || exit 2

prepara() { # prepara <dir> <agente>
  git clone -q "$TMP/origin.git" "$TMP/$1" 2>/dev/null || exit 2
  cd "$TMP/$1" || exit 2
  git config user.name "$2"; git config user.email "$2@local"
  git switch -q p/teste
  cp -r "$AQUI/bin" .; cp "$AQUI/protocolo-lint.sh" .
  mkdir -p .work; printf '%s\n' "$2" > .work/agente
  sh -n bin/reivindicar.sh && sh -n bin/liberar.sh || return 1
}

echo "== cadeado entre dois agentes =="
prepara a Alfa
OUT=$(sh bin/reivindicar.sh E2 "primeira"); rc=$?
[ $rc -eq 0 ] && ok "Alfa reivindica E2" || nao "Alfa reivindica E2: $OUT"

OUT=$(sh bin/reivindicar.sh E2); rc=$?
[ $rc -eq 0 ] && ok "idempotente para o mesmo dono" || nao "idempotente: $OUT"

prepara b Beta
OUT=$(sh bin/reivindicar.sh E2 "corrida"); rc=$?
[ $rc -ne 0 ] && espera "$OUT" 'JA REIVINDICADA' \
  && ok "Beta recusado (cadeado de Alfa)" || nao "Beta deveria falhar: rc=$rc $OUT"

echo
echo "== dono do cadeado =="
OUT=$(sh bin/liberar.sh E2 feita "b.md: PASS=1"); rc=$?
[ $rc -ne 0 ] && ok "Beta nao fecha tarefa de Alfa" || nao "Beta fechou tarefa alheia: $OUT"

cd "$TMP/a" || exit 2
OUT=$(sh bin/liberar.sh E2 liberada); rc=$?
[ $rc -ne 0 ] && ok "'liberada' sem motivo e recusado" || nao "aceitou liberar sem motivo"

OUT=$(sh bin/liberar.sh E2 feita "docs/e2.md: PASS=2"); rc=$?
[ $rc -eq 0 ] && ok "Alfa fecha E2 com evidencia" || nao "Alfa nao fechou: $OUT"

git ls-remote --exit-code origin refs/claims/E2 >/dev/null 2>&1 \
  && nao "cadeado de E2 deveria ter sumido" || ok "cadeado removido ao fechar"

echo
echo "== visoes geradas =="
OUT=$(sh bin/board.sh); rc=$?
[ $rc -eq 0 ] && ok "board.sh roda" || nao "board.sh: rc=$rc"
grep -q '| E2 | concluida | Alfa |' BOARD.md 2>/dev/null \
  && ok "BOARD.md mostra E2 concluida por Alfa" || nao "BOARD.md sem E2 concluida: $(head -8 BOARD.md 2>/dev/null)"
grep -q 'close E2' PROGRESS.md 2>/dev/null \
  && ok "PROGRESS.md tem o evento de fechamento" || nao "PROGRESS.md sem close E2"
OUT=$(sh bin/board.sh --check 2>&1); rc=$?
[ $rc -eq 0 ] && ok "board --check: visao em dia" || nao "board --check deveria passar: $OUT"

echo
echo "== metricas =="
OUT=$(sh bin/metricas.sh 2 2>&1)
espera "$OUT" 'commit' >/dev/null 2>&1 || printf '%s' "$OUT" | grep -qi 'agente\|sem commits' \
  && ok "metricas.sh roda" || nao "metricas.sh: $(printf '%s' "$OUT" | head -2)"

echo
if [ "$FALHAS" -eq 0 ]; then echo "PASS"; exit 0; fi
echo "FAIL ($FALHAS)"; exit 1
