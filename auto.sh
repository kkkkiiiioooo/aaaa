#!/bin/sh
# auto.sh - 1 comando, sem ler nada: prepara ambiente e mostra onde parar. Idempotente.
# Uso: sh auto.sh
cd "$(dirname "$0")"||exit 1
git pull -q --ff-only 2>/dev/null
sh setupenvclaude.sh 2>&1|tail -12
A=${A:-claude} sh setup.sh 2>&1|tail -25
echo "== PLANO";sh scripts/plano.sh 2>/dev/null|head -c 1500
echo "== ABERTOS";sh scripts/problema.sh abertos 2>/dev/null|head -20
echo "== HANDOFF";sed -n '/## Fase/,/## Premissas/p' HANDOFF.md
pgrep -a qemu|head -3
