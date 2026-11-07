#!/bin/sh
# injetar_autorun.sh — grava winpeshl.ini + autorun-wwii.cmd (+ diag.cmd) no WIM.
# Uso: sh scripts/injetar_autorun.sh --imagem .work/wim/Winre.lote.wim
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
IMAGEM=""
while [ $# -gt 0 ]; do
  case "$1" in
    --imagem) IMAGEM="${2:-}"; shift 2;;
    *) echo "uso: injetar_autorun.sh --imagem <wim>"; exit 2;;
  esac
done
[ -n "$IMAGEM" ] && [ -f "$IMAGEM" ] || { echo "informe --imagem existente"; exit 2; }
command -v wimlib-imagex >/dev/null 2>&1 || { echo "falta wimlib-imagex"; exit 1; }

CMDFILE="$R/.work/injetar/autorun-cmds.txt"
mkdir -p "$R/.work/injetar"
{
  printf 'add %s /Windows/System32/winpeshl.ini\n' "$R/scripts/winpeshl.ini"
  printf 'add %s /Windows/System32/autorun-wwii.cmd\n' "$R/scripts/autorun-wwii.cmd"
  printf 'add %s /Windows/System32/diag.cmd\n' "$R/scripts/diag.cmd"
  # D2 do lead: o transporte do ESD e HTTP (cscript + WinHttpRequest). O WinRE 1809
  # nao tem certutil nem powershell, entao o download.vbs e o unico caminho.
  printf 'add %s /Windows/System32/download.vbs\n' "$R/scripts/download.vbs"
  # downloader em JScript: grava binario sem ADODB (que nao existe no WinRE 1809)
  printf 'add %s /Windows/System32/download-js.js\n' "$R/scripts/download-js.js"
} > "$CMDFILE"

echo "[autorun] atualizando $IMAGEM"
if ! wimlib-imagex update "$IMAGEM" 1 < "$CMDFILE"; then
  echo "[autorun] ERRO no update"; exit 1
fi

# verifica
LISTA=$(wimlib-imagex dir "$IMAGEM" 1 2>/dev/null)
ok=0
for p in /Windows/System32/winpeshl.ini /Windows/System32/autorun-wwii.cmd /Windows/System32/diag.cmd /Windows/System32/download.vbs /Windows/System32/download-js.js; do
  if echo "$LISTA" | grep -qi "$p"; then echo "[autorun] OK $p"; ok=$((ok+1)); else echo "[autorun] FALTA $p"; fi
done
[ "$ok" -eq 5 ] || exit 1

# confere que o INI injetado cita autorun-wwii
mkdir -p "$R/.work/verif-autorun"
wimlib-imagex extract "$IMAGEM" 1 /Windows/System32/winpeshl.ini \
  --dest-dir "$R/.work/verif-autorun" --no-acls >/dev/null
python3 - "$R/.work/verif-autorun/winpeshl.ini" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
raw = p.read_bytes()
txt = raw.decode("utf-16-le") if raw.startswith(b"\xff\xfe") else raw.decode("ascii", "replace")
assert "LaunchApps" in txt, txt
assert "autorun-wwii.cmd" in txt, txt
assert "pause" not in txt.lower()
print("[autorun] INI reextraido contem LaunchApps + autorun-wwii.cmd")
print(txt)
PY
echo "[autorun] INJECAO AUTORUN VERIFICADA"
