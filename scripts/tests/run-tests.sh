#!/bin/sh
# run-tests.sh — orquestra os testes de host: garante base+initramfs, roda a VM e valida.
# Uso: sh scripts/tests/run-tests.sh
set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
LOG="$ROOT/.work/logs/vm.log"

sh "$ROOT/scripts/env-setup.sh" >/dev/null 2>&1 || true
command -v qemu-system-x86_64 >/dev/null 2>&1 || { echo "SKIP: qemu ausente (rode scripts/env-setup.sh)"; exit 2; }

sh "$ROOT/scripts/fetch-base.sh"      || exit 1
sh "$ROOT/scripts/build-initramfs.sh" || exit 1

sh "$ROOT/scripts/run-vm.sh" 120 >/dev/null 2>&1 || true

echo "--- avaliacao ---"
if ! grep -q "=== INITRAMFS-TESTE: fim" "$LOG" 2>/dev/null; then
  echo "SUITE: FAIL (VM nao concluiu)"; tail -n 40 "$LOG" 2>/dev/null; exit 1
fi
grep -E "\[(PASS|FAIL)\]|RESULTADO:" "$LOG" | sed 's/^/  /'
if grep -q "RESULTADO: PASS" "$LOG"; then
  echo "SUITE: PASS"; exit 0
else
  echo "SUITE: FAIL"; exit 1
fi
