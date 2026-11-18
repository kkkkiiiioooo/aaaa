#!/bin/sh
# verify-images.sh - join the split WIMs and prove them in one line each.
#
# Reads no long hash file in the conversation: every check is done here and the
# output is one line per image plus a verdict. Exit 0 only if all images pass.
#
# Usage:
#   scripts/verify-images.sh                 # both tracked images
#   scripts/verify-images.sh DIR [DIR...]    # selected image folders
#   KEEP=1 scripts/verify-images.sh          # keep the joined WIMs and print paths
#
# What it checks per image folder:
#   1. every part against SHA256SUMS            (parts are what git stores)
#   2. the parts joined in order                (byte count)
#   3. the joined WIM against SHA256SUMS.reassembled
#   4. the joined WIM against the expected digest and, with wimlib, build/counts
#   5. for winre-1809-oficial-intacta: the official ESD when it was downloaded
#
# Requires: sha256sum, cat, wc, awk. wimlib-imagex is optional.
set -u

ROOT=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd) || { echo "verify-images: cannot resolve repository root" >&2; exit 1; }
cd "$ROOT" || exit 1

if [ "$#" -eq 0 ]; then
  set -- winre-1809-oficial-intacta winre-fabrica-10586-424MB
fi

FAILED=0
PASSED=0
TMP=""
cleanup() {
  if [ -n "$TMP" ] && [ -d "$TMP" ] && [ "${KEEP:-0}" != "1" ]; then rm -rf "$TMP"; fi
}
trap cleanup EXIT INT TERM
TMP=$(mktemp -d "${TMPDIR:-/tmp}/verify-images.XXXXXX") || { echo "verify-images: no temp dir" >&2; exit 1; }

# Expected final artifact per folder: label, base name, bytes, sha256, build, files, dirs
expect() {
  case "$1" in
    winre-1809-oficial-intacta)
      E_LABEL=1809; E_BASE=winre-1809-oficial.wim; E_BYTES=266283224
      E_SHA=232199c585111bfae71ff00dbdcabe5c75195fc9b431eb4d1711b8a7e471eb6c
      E_BUILD=17763; E_FILES=17669; E_DIRS=3560 ;;
    winre-fabrica-10586-424MB)
      E_LABEL=10586; E_BASE=winre-fabrica-10586.wim; E_BYTES=444858791
      E_SHA=152addc420748815c2cad90d382229e249ec853d3842531ddcc2b9998248067a
      E_BUILD=10586; E_FILES=21867; E_DIRS=4593 ;;
    *)
      E_LABEL=$(basename "$1"); E_BASE=""; E_BYTES=""; E_SHA=""; E_BUILD=""; E_FILES=""; E_DIRS="" ;;
  esac
}

ok()   { PASSED=$((PASSED + 1)); printf 'OK    %s\n' "$1"; }
bad()  { FAILED=$((FAILED + 1)); IMG_FAIL=1; printf 'FAIL  %s\n' "$1"; }

for d in "$@"; do
  IMG_FAIL=0
  [ -d "$d" ] || { bad "$d: folder not found"; continue; }
  expect "$d"

  set -- "$d"/*.wim.part-00
  [ -f "$1" ] || { bad "$E_LABEL: no *.wim.part-00 in $d"; continue; }
  base=$(basename "$1"); base=${base%.part-00}
  nparts=$(ls "$d" | grep -c "^$base\.part-")
  if [ "$nparts" -lt 2 ]; then bad "$E_LABEL: only $nparts part(s)"; continue; fi

  if ! ( cd "$d" && sha256sum -c --quiet SHA256SUMS ) >/dev/null 2>&1; then
    bad "$E_LABEL: part checksum mismatch in $d/SHA256SUMS"
    continue
  fi

  out="$TMP/$base"; : > "$out"
  missing=""
  i=0
  while [ "$i" -lt "$nparts" ]; do
    p=$(printf '%s/%s.part-%02d' "$d" "$base" "$i")
    if [ -f "$p" ]; then cat "$p" >> "$out" || { missing="$p"; break; }; else missing="$p"; break; fi
    i=$((i + 1))
  done
  if [ -n "$missing" ]; then bad "$E_LABEL: missing part $missing"; continue; fi

  bytes=$(wc -c < "$out" | tr -d ' ')
  got=$(sha256sum "$out" | cut -d' ' -f1)

  manifest="$d/SHA256SUMS.reassembled"
  if [ ! -f "$manifest" ]; then
    bad "$E_LABEL: $manifest missing"
  else
    want=$(awk 'NR==1{print $1}' "$manifest")
    if [ "$got" != "$want" ]; then bad "$E_LABEL: joined WIM does not match SHA256SUMS.reassembled"; fi
  fi
  if [ -n "$E_SHA" ] && [ "$got" != "$E_SHA" ]; then bad "$E_LABEL: joined WIM digest differs from the recorded one"; fi
  if [ -n "$E_BYTES" ] && [ "$bytes" != "$E_BYTES" ]; then bad "$E_LABEL: joined WIM is $bytes bytes (expected $E_BYTES)"; fi

  extra=""
  if [ -n "$E_BUILD" ] && command -v wimlib-imagex >/dev/null 2>&1; then
    inf=$(wimlib-imagex info "$out" 2>/dev/null)
    b=$(printf '%s\n' "$inf" | awk -F': *' '/^Build:/{print $2; exit}' | tr -cd '0-9')
    f=$(printf '%s\n' "$inf" | awk -F': *' '/^File Count:/{print $2; exit}' | tr -cd '0-9')
    dd=$(printf '%s\n' "$inf" | awk -F': *' '/^Directory Count:/{print $2; exit}' | tr -cd '0-9')
    [ "$b" = "$E_BUILD" ] || bad "$E_LABEL: build ${b:-?} (expected $E_BUILD)"
    [ "$f" = "$E_FILES" ] || bad "$E_LABEL: ${f:-?} files (expected $E_FILES)"
    [ "$dd" = "$E_DIRS" ] || bad "$E_LABEL: ${dd:-?} directories (expected $E_DIRS)"
    extra="  build $b, $f files, $dd dirs"
  fi

  esd_note=""
  if [ "$E_LABEL" = "1809" ] && [ -f "$d/Core_en-us.esd" ]; then
    if ( cd "$d" && sha1sum -c --quiet SHA1SUMS ) >/dev/null 2>&1; then
      esd_note=", ESD SHA-1 OK"
    else
      bad "1809: Core_en-us.esd does not match SHA1SUMS"
    fi
  fi

  if [ "$IMG_FAIL" -eq 0 ]; then
    ok "$E_LABEL  $bytes bytes  ${got%??????????????????????}…$extra$esd_note"
    [ "${KEEP:-0}" = "1" ] && printf '      joined WIM: %s\n' "$out"
  fi
done

printf '== %s image(s) verified, %s failure(s)\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ] || exit 1
exit 0
