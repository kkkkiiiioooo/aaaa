#!/bin/sh
# salvar.sh - commit and push immediately, so nothing is lost with the sandbox.
#
# The sandbox is temporary: when the session ends, the credits run out, or the
# sandbox is reclaimed, uncommitted or unpushed work is gone. This script makes the
# "push it now" rule from AGENTS.md a single command.
#
# Usage:
#   scripts/salvar.sh "message"                 # stage everything not ignored
#   scripts/salvar.sh "message" path [path...]  # stage only these paths
#
# Exit 0: the remote branch points at the new commit (verified through ls-remote).
# Exit 1: nothing was published; the reason is printed.
#
# No force push. No history rewrite. Never commits ignored files.
set -u

ROOT=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd) || { echo "salvar: cannot resolve repository root" >&2; exit 1; }
cd "$ROOT" || exit 1

MSG=${1:-}
if [ -z "$MSG" ]; then
  echo "usage: scripts/salvar.sh \"message\" [path...]" >&2
  exit 1
fi
shift

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || { echo "salvar: not a git checkout" >&2; exit 1; }
if [ "$BRANCH" = "HEAD" ]; then
  echo "salvar: detached HEAD; check out the working branch first" >&2
  exit 1
fi

if [ "$#" -gt 0 ]; then
  git add -- "$@" || { echo "salvar: git add failed" >&2; exit 1; }
else
  git add -A || { echo "salvar: git add failed" >&2; exit 1; }
fi

if git diff --cached --quiet; then
  echo "salvar: nothing staged; repository already clean"
  HEAD_SHA=$(git rev-parse HEAD)
else
  # GitHub rejects individual files over 100 MiB. Fail before the push, with the fix.
  big=$(git diff --cached --name-only --diff-filter=ACM | while IFS= read -r f; do
          [ -f "$f" ] || continue
          sz=$(wc -c < "$f" | tr -d ' ')
          if [ "$sz" -gt 104857600 ]; then printf '%s (%s bytes)\n' "$f" "$sz"; fi
        done)
  if [ -n "$big" ]; then
    echo "salvar: these staged files exceed GitHub's 100 MiB limit:" >&2
    printf '  %s\n' "$big" >&2
    echo "salvar: split them into parts (see winre-1809-oficial-intacta/) or leave them out" >&2
    exit 1
  fi

  git -c user.name="${GIT_AUTHOR_NAME:-Qoder}" \
      -c user.email="${GIT_AUTHOR_EMAIL:-qoder@local}" \
      commit -q -m "$MSG" || { echo "salvar: commit failed" >&2; exit 1; }
  HEAD_SHA=$(git rev-parse HEAD)
  echo "salvar: committed $HEAD_SHA on $BRANCH"
fi

echo "salvar: pushing $BRANCH to origin"
OUT=$(mktemp "${TMPDIR:-/tmp}/salvar.XXXXXX") || OUT=/tmp/salvar.$$
if git push origin "$BRANCH" > "$OUT" 2>&1; then
  sed 's/^/  /' "$OUT"
else
  sed 's/^/  /' "$OUT"
  rm -f "$OUT"
  echo "salvar: PUSH FAILED - the work is only local and will be lost" >&2
  echo "salvar: fix credentials/network and run: git push origin $BRANCH" >&2
  exit 1
fi
rm -f "$OUT"

REMOTE_SHA=$(git ls-remote origin "refs/heads/$BRANCH" 2>/dev/null | cut -f1)
if [ "$REMOTE_SHA" != "$HEAD_SHA" ]; then
  echo "salvar: remote ref mismatch (local $HEAD_SHA, remote ${REMOTE_SHA:-none})" >&2
  echo "salvar: the work is NOT published; retry the push" >&2
  exit 1
fi

echo "salvar: published - origin/$BRANCH = $HEAD_SHA"
exit 0
