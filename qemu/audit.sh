#!/bin/sh
# audit.sh - anti-cheat gate for the Mi Pad 2 QEMU harness.
#
# Audits a proposed QEMU command line against the constraints in
# docs/01-restricoes.md and GOAL.md. The only simulated external path is a local
# HTTP endpoint reached through QEMU user-mode NAT (guest -> 10.0.2.2). No host
# filesystem sharing, no host-forwarded ports, no serial file transfer, no
# clipboard, no hidden proxy.
#
# Usage:
#   qemu/audit.sh <qemu-argv...>        # audit the given arguments
#   qemu/audit.sh --file <cmdfile>      # audit a file holding one command line
#
# Exit 0: command line is clean (PASS).
# Exit 1: a forbidden construct was found (FAIL).
#
# This gate must pass before any QEMU experiment is considered valid.
set -u

if [ "${1:-}" = "--file" ]; then
  [ -f "${2:-}" ] || { echo "audit: cannot read ${2:-}" >&2; exit 1; }
  CMD=$(tr '\n' ' ' < "$2")
else
  CMD="$*"
fi

[ -n "$CMD" ] || { echo "audit: empty command line" >&2; exit 1; }

FAILED=0
# Each entry: extended regex | human-readable reason.
check() {
  if printf '%s' "$CMD" | grep -qE -- "$1"; then
    printf 'FAIL  forbidden: %s\n' "$2"
    FAILED=$((FAILED + 1))
  fi
}

check '(^|[[:space:]])-virtfs([[:space:]]|=)'                 '-virtfs host filesystem sharing'
check 'virtio-9p|virtfs-9p|9pnet'                             '9p paravirtual filesystem'
check '(^|[[:space:]])-fsdev[[:space:]]+local'                '-fsdev local (9p host passthrough)'
check 'hostfwd='                                              'host-forwarded ports (hostfwd)'
check 'guestfwd='                                             'guest-forwarded ports (guestfwd / hidden proxy)'
check '(^|[[:space:]])-serial[[:space:]]+file:'               'serial file transfer (-serial file:)'
check '(^|[[:space:]])-chardev[[:space:]]+file'               'chardev file transfer (-chardev file)'
check 'vdagent|qemu-vdagent|clipboard'                        'clipboard / SPICE vdagent integration'
check '(^|[[:space:]])-netdev[[:space:]]+(tap|bridge|hubport)' 'host network tap/bridge/hubport (use user-mode NAT only)'
check 'smb=|smbserver'                                        'built-in SMB host sharing'

if [ "$FAILED" -ne 0 ]; then
  printf '== audit: FAIL (%d forbidden construct(s))\n' "$FAILED"
  exit 1
fi
echo "== audit: PASS (user-mode NAT only; no host sharing, hostfwd, serial file, clipboard, or proxy)"
exit 0
