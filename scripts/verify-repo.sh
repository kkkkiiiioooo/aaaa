#!/bin/sh
# verify-repo.sh - offline validation of the Mi Pad 2 recovery challenge repository.
#
# Exit 0: every check passed.
# Exit 1: at least one check failed.
#
# No network access. Tracked files are only read. The WIM parts are reassembled
# into a temporary directory (never inside the work tree), then removed.
#
# Usage:
#   scripts/verify-repo.sh              # full verification
#   VERIFY_WIM=0 scripts/verify-repo.sh # skip WIM reassembly and content checks
#   KEEP=1 scripts/verify-repo.sh       # keep the temporary reassembly directory
#
# Requires: sha256sum, cat, grep, awk, wc, sed.
# WIM inspection uses wimlib-imagex when available, otherwise 7z/7za/7zr.
set -u

ROOT=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd) || { echo "verify: cannot resolve repository root" >&2; exit 1; }
cd "$ROOT" || exit 1

FAILED=0
PASSED=0
SKIPPED=0
WIM_TMP=""

pass() { PASSED=$((PASSED + 1)); printf 'PASS  %s\n' "$1"; }
fail() { FAILED=$((FAILED + 1)); printf 'FAIL  %s\n' "$1"; }
skip() { SKIPPED=$((SKIPPED + 1)); printf 'SKIP  %s\n' "$1"; }
info() { printf '      %s\n' "$1"; }

cleanup() {
  if [ -n "$WIM_TMP" ] && [ -d "$WIM_TMP" ]; then
    if [ "${KEEP:-0}" = "1" ]; then
      info "reassembly kept at $WIM_TMP"
    else
      rm -rf "$WIM_TMP"
    fi
  fi
}
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------------------
# Expected values (single source of truth for this repository)
# ---------------------------------------------------------------------------
FAB_DIR=winre-fabrica-10586-424MB
FAB_BASE=winre-fabrica-10586.wim
FAB_PARTS=5
FAB_SHA=152addc420748815c2cad90d382229e249ec853d3842531ddcc2b9998248067a
FAB_TOTALBYTES=444856529
FAB_FILE_BYTES=444858791
FAB_BUILD=10586
FAB_FILECOUNT=21867
FAB_DIRCOUNT=4593
FAB_FR_CHILDREN=751

W18_DIR=winre-1809-254MB
W18_BASE=winre-1809.wim
W18_PARTS=3
W18_SHA=f9e30ca308aa23e83d852ccefcfe7bca09a23d7c5b759ae655557612487879b8
W18_TOTALBYTES=266281208
W18_FILE_BYTES=266283250
W18_BUILD=17763
W18_FILECOUNT=17669
W18_DIRCOUNT=3560
W18_FR_CHILDREN=895

TARGET_WIFI=bcmwdidhdpcie.inf_amd64_977dcc915465b0e9
TARGET_HD=bcmdhd64.inf_amd64_e0bae6831f60ea5f
TARGET_FN2=bcmfn2.inf_amd64_5ebadf201c5b5845
NVRAM_SRC=drivers/mipad2-oficial/wifi/bcm94356wlpagbl_P3_150828M.txt
NVRAM_DELTA=drivers/nvram-delta/4356r2nvram.txt
NVRAM_SHA=a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667
NVRAM_BYTES=5361

echo "== Repository: $ROOT"
echo

# ---------------------------------------------------------------------------
# 1. Required layout
# ---------------------------------------------------------------------------
echo "-- layout"
for f in GOAL.md AGENTS.md ANOTACOES-IMPORTANTES.md README.md \
         docs/00-visao-geral.md docs/01-restricoes.md docs/02-estado-do-dispositivo.md \
         docs/03-driver-wifi-erro-10.md docs/04-fidelidade-mimetizacao.md docs/05-offline-servicing.md \
         experiments/README.md experiments/templates/experimento.md \
         drivers/README.md drivers/nvram-delta/README.md; do
  if [ -f "$f" ]; then pass "present: $f"; else fail "missing: $f"; fi
done
for d in drivers/estado-dispositivo drivers/mipad2-oficial "$FAB_DIR" "$W18_DIR"; do
  if [ -d "$d" ]; then pass "present: $d/"; else fail "missing: $d/"; fi
done

# ---------------------------------------------------------------------------
# 2. Checksum manifests
# ---------------------------------------------------------------------------
echo
echo "-- manifests"
for m in drivers/estado-dispositivo drivers/mipad2-oficial/bt-uart \
         drivers/mipad2-oficial/wifi "$W18_DIR" "$FAB_DIR"; do
  if [ ! -f "$m/SHA256SUMS" ]; then fail "manifest missing: $m/SHA256SUMS"; continue; fi
  n=$(wc -l < "$m/SHA256SUMS")
  if ( cd "$m" && sha256sum -c --quiet SHA256SUMS ) >/dev/null 2>&1; then
    pass "$m/SHA256SUMS ($n entries)"
  else
    fail "$m/SHA256SUMS ($n entries)"
    ( cd "$m" && sha256sum -c SHA256SUMS 2>&1 | grep -v ': OK$' | sed 's/^/      /' ) | head -10
  fi
done

# ---------------------------------------------------------------------------
# 3. WIM parts, reassembly, hashes and metadata
# ---------------------------------------------------------------------------
wim_tool() {
  if command -v wimlib-imagex >/dev/null 2>&1; then echo wimlib-imagex; return 0; fi
  for t in 7z 7za 7zr; do
    if command -v "$t" >/dev/null 2>&1; then echo "$t"; return 0; fi
  done
  return 1
}

# List a WIM to stdout. $1 = wim path
wim_list() {
  case "$WIM_TOOL" in
    wimlib-imagex) wimlib-imagex dir "$1" 1 2>/dev/null ;;
    *)             "$WIM_TOOL" l "$1" 2>/dev/null ;;
  esac
}

# Metadata field from the WIM header. $1 = wim path, $2 = tag (e.g. BUILD)
wim_meta() {
  case "$WIM_TOOL" in
    wimlib-imagex)
      case "$2" in
        BUILD)      wimlib-imagex info "$1" 2>/dev/null | awk -F': *' '/^Build:/{print $2; exit}' ;;
        FILECOUNT)  wimlib-imagex info "$1" 2>/dev/null | awk -F': *' '/^File Count:/{print $2; exit}' ;;
        DIRCOUNT)   wimlib-imagex info "$1" 2>/dev/null | awk -F': *' '/^Directory Count:/{print $2; exit}' ;;
        TOTALBYTES) wimlib-imagex info "$1" 2>/dev/null | awk -F': *' '/^Size:/{print $2; exit}' ;;
      esac ;;
    *)
      # The WIM-level TOTALBYTES lives outside the <IMAGE> block, and its position
      # differs between images (before for 10586, after for 1809). The IMAGE block
      # is stripped only for that tag: DIRCOUNT/FILECOUNT/BUILD live inside it.
      "$WIM_TOOL" l "$1" 2>/dev/null | tr -d '\0' | awk -v tag="$2" '
        {
          line = $0
          if (tag == "TOTALBYTES") { gsub(/<IMAGE[^>]*>.*<\/IMAGE>/, "", line) }
          if (tag == "BUILD"      && match(line, /<BUILD>[0-9]+<\/BUILD>/))       { s = substr(line, RSTART, RLENGTH); gsub(/[^0-9]/, "", s); print s; exit }
          if (tag == "FILECOUNT"  && match(line, /<FILECOUNT>[0-9]+/))            { s = substr(line, RSTART, RLENGTH); gsub(/[^0-9]/, "", s); print s; exit }
          if (tag == "DIRCOUNT"   && match(line, /<DIRCOUNT>[0-9]+/))             { s = substr(line, RSTART, RLENGTH); gsub(/[^0-9]/, "", s); print s; exit }
          if (tag == "TOTALBYTES" && match(line, /<TOTALBYTES>[0-9]+<\/TOTALBYTES>/)) { s = substr(line, RSTART, RLENGTH); gsub(/[^0-9]/, "", s); print s; exit }
        }' ;;
  esac
}

# Number of entries directly under FileRepository. $1 = wim path
wim_fr_children() {
  wim_list "$1" | tr '\\' '/' | grep -oE 'FileRepository/[^ ]+' | sort -u | wc -l | tr -d ' '
}

# Reassemble a split WIM from tracked parts. $1 = dir, $2 = base name, $3 = part count
reassemble() {
  d=$1; base=$2; n=$3; out="$WIM_TMP/$base"
  : > "$out"
  i=0
  while [ "$i" -lt "$n" ]; do
    p=$(printf '%s/%s.part-%02d' "$d" "$base" "$i")
    if [ ! -f "$p" ]; then echo "missing part $p" >&2; return 1; fi
    cat "$p" >> "$out" || return 1
    i=$((i + 1))
  done
  echo "$out"
}

echo
echo "-- WIM 10586 ($FAB_DIR)"
if [ "${VERIFY_WIM:-1}" = "0" ]; then
  skip "WIM reassembly disabled (VERIFY_WIM=0)"
else
  WIM_TOOL=$(wim_tool) || WIM_TOOL=""
  if [ -z "$WIM_TOOL" ]; then
    skip "no WIM tool (wimlib-imagex or 7z); hashes still checked"
  fi
  WIM_TMP=$(mktemp -d "${TMPDIR:-/tmp}/verify-repo.XXXXXX") || { fail "cannot create temp dir"; WIM_TMP=""; }

  if [ -n "$WIM_TMP" ]; then
    # part count
    pc=$(ls "$FAB_DIR" 2>/dev/null | grep -c 'wim\.part-')
    if [ "$pc" = "$FAB_PARTS" ]; then pass "10586 part count ($pc)"; else fail "10586 part count: $pc (expected $FAB_PARTS)"; fi

    FAB_WIM=$(reassemble "$FAB_DIR" "$FAB_BASE" "$FAB_PARTS")
    if [ -n "$FAB_WIM" ] && [ -f "$FAB_WIM" ]; then
      WIM="$FAB_WIM"
      sz=$(wc -c < "$WIM")
      if [ "$sz" = "$FAB_FILE_BYTES" ]; then pass "10586 file size ($sz)"; else fail "10586 file size: $sz (expected $FAB_FILE_BYTES)"; fi
      sh=$(sha256sum "$WIM" | cut -d' ' -f1)
      if [ "$sh" = "$FAB_SHA" ]; then pass "10586 SHA-256 ($sh)"; else fail "10586 SHA-256: $sh (expected $FAB_SHA)"; fi

      if [ -n "$WIM_TOOL" ]; then
        b=$(wim_meta "$WIM" BUILD)
        if [ "$b" = "$FAB_BUILD" ]; then pass "10586 build ($b)"; else fail "10586 build: '${b:-none}' (expected $FAB_BUILD)"; fi
        tb=$(wim_meta "$WIM" TOTALBYTES)
        if [ "$tb" = "$FAB_TOTALBYTES" ]; then pass "10586 header TOTALBYTES ($tb)"; else fail "10586 header TOTALBYTES: '${tb:-none}' (expected $FAB_TOTALBYTES)"; fi
        fc=$(wim_meta "$WIM" FILECOUNT)
        if [ "$fc" = "$FAB_FILECOUNT" ]; then pass "10586 file count ($fc)"; else fail "10586 file count: '${fc:-none}' (expected $FAB_FILECOUNT)"; fi
        dc=$(wim_meta "$WIM" DIRCOUNT)
        if [ "$dc" = "$FAB_DIRCOUNT" ]; then pass "10586 directory count ($dc)"; else fail "10586 directory count: '${dc:-none}' (expected $FAB_DIRCOUNT)"; fi

        lst="$WIM_TMP/fabrica.lst"
        wim_list "$WIM" > "$lst"

        if grep -qi 'bcmwdidhdpcie' "$lst"; then
          fail "10586 must not contain bcmwdidhdpcie"
        else
          pass "10586 has no bcmwdidhdpcie"
        fi
        for inf in bcmdhd.inf bcmdhd64.inf bcmfn.inf bcmfn2.inf; do
          if grep -qi "$inf" "$lst"; then pass "10586 contains $inf"; else fail "10586 missing $inf"; fi
        done
        if grep -qi 'nvram' "$lst"; then fail "10586 must not contain an nvram file"; else pass "10586 has no nvram file"; fi
        if [ -n "$WIM_TOOL" ]; then
          fr=$(grep -oE 'FileRepository/[^ ]+' "$lst" | sort -u | wc -l | tr -d ' ')
          if [ "$fr" = "$FAB_FR_CHILDREN" ]; then pass "10586 FileRepository entries ($fr)"; else fail "10586 FileRepository entries: $fr (expected $FAB_FR_CHILDREN)"; fi
        fi
      fi
    else
      fail "10586 reassembly failed"
    fi
  fi
fi

echo
echo "-- WIM 1809 ($W18_DIR)"
if [ "${VERIFY_WIM:-1}" = "0" ]; then
  skip "WIM reassembly disabled (VERIFY_WIM=0)"
else
  [ -n "${WIM_TOOL:-}" ] || WIM_TOOL=$(wim_tool) || WIM_TOOL=""
  if [ -z "${WIM_TMP:-}" ]; then
    WIM_TMP=$(mktemp -d "${TMPDIR:-/tmp}/verify-repo.XXXXXX") || { fail "cannot create temp dir"; WIM_TMP=""; }
  fi
  if [ -n "${WIM_TMP:-}" ]; then
    pc=$(ls "$W18_DIR" 2>/dev/null | grep -c 'wim\.part-')
    if [ "$pc" = "$W18_PARTS" ]; then pass "1809 part count ($pc)"; else fail "1809 part count: $pc (expected $W18_PARTS)"; fi

    W18_WIM=$(reassemble "$W18_DIR" "$W18_BASE" "$W18_PARTS")
    if [ -n "$W18_WIM" ] && [ -f "$W18_WIM" ]; then
      WIM="$W18_WIM"
      sz=$(wc -c < "$WIM")
      if [ "$sz" = "$W18_FILE_BYTES" ]; then pass "1809 file size ($sz)"; else fail "1809 file size: $sz (expected $W18_FILE_BYTES)"; fi
      sh=$(sha256sum "$WIM" | cut -d' ' -f1)
      if [ "$sh" = "$W18_SHA" ]; then pass "1809 SHA-256 ($sh)"; else fail "1809 SHA-256: $sh (expected $W18_SHA)"; fi

      if [ -n "${WIM_TOOL:-}" ]; then
        b=$(wim_meta "$WIM" BUILD)
        if [ "$b" = "$W18_BUILD" ]; then pass "1809 build ($b)"; else fail "1809 build: '${b:-none}' (expected $W18_BUILD)"; fi
        tb=$(wim_meta "$WIM" TOTALBYTES)
        if [ "$tb" = "$W18_TOTALBYTES" ]; then pass "1809 header TOTALBYTES ($tb)"; else fail "1809 header TOTALBYTES: '${tb:-none}' (expected $W18_TOTALBYTES)"; fi
        fc=$(wim_meta "$WIM" FILECOUNT)
        if [ "$fc" = "$W18_FILECOUNT" ]; then pass "1809 file count ($fc)"; else fail "1809 file count: '${fc:-none}' (expected $W18_FILECOUNT)"; fi
        dc=$(wim_meta "$WIM" DIRCOUNT)
        if [ "$dc" = "$W18_DIRCOUNT" ]; then pass "1809 directory count ($dc)"; else fail "1809 directory count: '${dc:-none}' (expected $W18_DIRCOUNT)"; fi

        lst="$WIM_TMP/1809.lst"
        wim_list "$WIM" > "$lst"
        if grep -qi "$TARGET_WIFI" "$lst"; then
          pass "1809 contains $TARGET_WIFI"
        else
          fail "1809 must contain $TARGET_WIFI"
        fi
        for f in bcmwdidhdpcie.inf bcmpciedhd63.sys 4356a2rtecdc.bin 43596a0rtecdc.bin; do
          if grep -qi "$f" "$lst"; then pass "1809 contains $f"; else fail "1809 missing $f"; fi
        done
        fr=$(grep -oE 'FileRepository/[^ ]+' "$lst" | sort -u | wc -l | tr -d ' ')
        if [ "$fr" = "$W18_FR_CHILDREN" ]; then pass "1809 FileRepository entries ($fr)"; else fail "1809 FileRepository entries: $fr (expected $W18_FR_CHILDREN)"; fi
      fi
    else
      fail "1809 reassembly failed"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 4. Target DriverStore state
# ---------------------------------------------------------------------------
echo
echo "-- target state (drivers/estado-dispositivo)"
ts=drivers/estado-dispositivo
for d in "$TARGET_WIFI" "$TARGET_HD" "$TARGET_FN2"; do
  if [ -d "$ts/$d" ]; then pass "target folder: $d"; else fail "target folder missing: $d"; fi
done
extra=$(ls -1 "$ts" | grep -vE "^($TARGET_WIFI|$TARGET_HD|$TARGET_FN2|README\.md|SHA256SUMS)$" | head -5)
if [ -z "$extra" ]; then pass "no unexpected entries in target state"; else fail "unexpected entries in target state: $extra"; fi

if [ -d "$ts/$TARGET_WIFI" ]; then
  n=$(ls -1 "$ts/$TARGET_WIFI" | wc -l | tr -d ' ')
  if [ "$n" = "4" ]; then pass "target Wi-Fi folder has 4 files"; else fail "target Wi-Fi folder has $n files (expected 4)"; fi
  if ls -1 "$ts/$TARGET_WIFI" | grep -qi 'nvram'; then fail "target Wi-Fi folder must not contain nvram"; else pass "target Wi-Fi folder has no nvram"; fi
  for f in bcmwdidhdpcie.inf bcmpciedhd63.sys 4356a2rtecdc.bin 43596a0rtecdc.bin; do
    if [ -f "$ts/$TARGET_WIFI/$f" ]; then pass "target file: $f"; else fail "target file missing: $f"; fi
  done
fi
n=$(ls -1 "$ts/$TARGET_HD" 2>/dev/null | wc -l | tr -d ' ')
if [ "$n" = "5" ]; then pass "target bcmdhd64 folder has 5 files"; else fail "target bcmdhd64 folder has $n files (expected 5)"; fi
n=$(ls -1 "$ts/$TARGET_FN2" 2>/dev/null | wc -l | tr -d ' ')
if [ "$n" = "2" ]; then pass "target bcmfn2 folder has 2 files"; else fail "target bcmfn2 folder has $n files (expected 2)"; fi

# ---------------------------------------------------------------------------
# 5. Driver packages and versions
# ---------------------------------------------------------------------------
echo
echo "-- driver packages"
# INF files may be UTF-16LE; strip NULs so ASCII patterns match either encoding.
inf_text() { tr -d '\000' < "$1"; }

if [ -f "$ts/$TARGET_WIFI/bcmwdidhdpcie.inf" ]; then
  inf="$ts/$TARGET_WIFI/bcmwdidhdpcie.inf"
  if inf_text "$inf" | grep -aqE 'DriverVer=04/21/2017, *1\.558\.53\.25'; then pass "2017 package DriverVer 04/21/2017, 1.558.53.25"; else fail "2017 package DriverVer mismatch"; fi
  for dev in DEV_43EC DEV_4355; do
    if inf_text "$inf" | grep -aqi "$dev"; then pass "2017 package covers $dev"; else fail "2017 package missing $dev"; fi
  done
  if inf_text "$inf" | grep -aqi 'nvram'; then fail "2017 package must not reference nvram"; else pass "2017 package has no nvram line"; fi
else
  fail "cannot check 2017 package: bcmwdidhdpcie.inf missing"
fi

oem=drivers/mipad2-oficial/wifi/oem25.inf
if [ -f "$oem" ]; then
  if inf_text "$oem" | grep -aqE 'DriverVer=12/23/2015, *1\.558\.14\.0'; then pass "OEM package DriverVer 12/23/2015, 1.558.14.0"; else fail "OEM package DriverVer mismatch"; fi
  if inf_text "$oem" | grep -aqi 'DEV_43EC'; then pass "OEM package covers DEV_43EC"; else fail "OEM package missing DEV_43EC"; fi
  if inf_text "$oem" | grep -aqF '4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6'; then pass "OEM package references the board nvram"; else fail "OEM package nvram line missing"; fi
else
  fail "OEM package missing: $oem"
fi

# ---------------------------------------------------------------------------
# 6. nvram payload
# ---------------------------------------------------------------------------
echo
echo "-- nvram"
if [ -f "$NVRAM_SRC" ]; then
  sz=$(wc -c < "$NVRAM_SRC" | tr -d ' ')
  if [ "$sz" = "$NVRAM_BYTES" ]; then pass "nvram source size ($sz)"; else fail "nvram source size: $sz (expected $NVRAM_BYTES)"; fi
  sh=$(sha256sum "$NVRAM_SRC" | cut -d' ' -f1)
  if [ "$sh" = "$NVRAM_SHA" ]; then pass "nvram source SHA-256"; else fail "nvram source SHA-256: $sh (expected $NVRAM_SHA)"; fi
else
  fail "nvram source missing: $NVRAM_SRC"
fi
if [ -f "$NVRAM_DELTA" ] && [ -f "$NVRAM_SRC" ]; then
  if cmp -s "$NVRAM_SRC" "$NVRAM_DELTA"; then pass "nvram delta copy is byte-identical to source"; else fail "nvram delta copy differs from source"; fi
else
  fail "nvram delta copy missing: $NVRAM_DELTA"
fi

# ---------------------------------------------------------------------------
# 7. Documentation invariants
# ---------------------------------------------------------------------------
echo
echo "-- documentation"
if [ -f ANOTACOES-IMPORTANTES.md ]; then
  for pat in 'no USB' 'cannot send files out' 'error 10'; do
    if grep -qi "$pat" ANOTACOES-IMPORTANTES.md; then pass "notes mention: $pat"; else fail "notes do not mention: $pat"; fi
  done
fi
if [ -f AGENTS.md ]; then
  for pat in 'Do not commit unless explicitly requested' 'Do not present a QEMU result as hardware proof'; do
    if grep -qF "$pat" AGENTS.md; then pass "agents rule: $pat"; else fail "agents rule missing: $pat"; fi
  done
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "== summary: $PASSED passed, $FAILED failed, $SKIPPED skipped"
if [ "$FAILED" -ne 0 ]; then
  echo "== result: FAIL"
  exit 1
fi
echo "== result: PASS"
exit 0
