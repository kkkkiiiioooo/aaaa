#!/bin/sh
# setup/common/hooks.sh - ativa os hooks versionados (main protegida, push e presenca). Idempotente.
cd "$(dirname "$0")/../.." || exit 1
git config --local core.hooksPath hooks && echo "[hooks] core.hooksPath=hooks"
for h in hooks/*; do [ -f "$h" ] && [ ! -x "$h" ] && chmod +x "$h" && echo "[hooks] +x $h"; done; exit 0
