#!/bin/sh
# audit.sh - fails if the harness uses a forbidden host-guest path (GOAL.md anti-cheat rules).
cd "$(dirname "$0")"; rc=0
for bad in virtfs 9p fsdev 'hostfwd' 'guestfwd' 'chardev' 'serial file' 'serial.*pipe' 'clipboard' 'vnc.*clipboard' 'spice' 'usb' 'drive.*file=fat:' 'smb='; do
  if grep -vE '^\s*#' run.sh | grep -qiE -- "$bad"; then echo "FAIL forbidden: $bad"; rc=1; fi
done
grep -q -- '-netdev user' run.sh && echo "PASS user-mode network only" || { echo "FAIL no user-mode net"; rc=1; }
[ $rc = 0 ] && echo "audit: PASS" || echo "audit: FAIL"; exit $rc
