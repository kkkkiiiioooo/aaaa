#!/bin/sh
# setup.sh [agente] - ponto de entrada unico. Idempotente.
# Unica variavel: GH_TOKEN=<token com escrita> (dispensavel se o git ja estiver autenticado).
# Estrutura: setup/common/ (todos) + setup/agents/<agente>.sh (so o seu ambiente). Ver setup/README.md
set -u
cd "$(dirname "$0")" || exit 1
mkdir -p .work
N=${1:-$(cat .work/agente 2>/dev/null)}
A=${N:-} sh scripts/agente.sh quem >/dev/null 2>&1; N=${N:-$(cat .work/agente)}
echo "[setup] agente=$N"
sh setup/common/credentials.sh || exit 1
sh setup/common/hooks.sh
sh setup/common/deps.sh || echo "[setup] AVISO: deps com erro - veja acima"
S=setup/agents/$N.sh; [ -f "$S" ] || S=setup/agents/default.sh
if [ -n "${T:-}" ]; then sh "$S"; else echo "[setup] modo rapido (sem instalar qemu/wimlib). Para testar: T=1 sh setup.sh"; fi
A=$N sh scripts/agente.sh entrou
sh scripts/doctor.sh
