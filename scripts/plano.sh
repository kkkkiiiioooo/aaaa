#!/bin/sh
# plano.sh - imprime o PLANO.md do lead, que mora na branch `relatorio` (a unica que o
# lead acessa). Le so esse arquivo: nao faz checkout da branch nem abre o RELATORIO.md.
# Uso: sh scripts/plano.sh
B="${BR_REL:-relatorio}"
git fetch -q origin "$B" 2>/dev/null
git show "origin/$B:PLANO.md" 2>/dev/null \
  || echo "(sem PLANO do lead ainda: siga PROMPT.md e registre a escolha com relatorio.sh estado)"
