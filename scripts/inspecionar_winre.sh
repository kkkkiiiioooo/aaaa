#!/bin/sh
# inspecionar_winre.sh — acha e examina o WinRE (Winre.wim) de uma imagem do Windows.
# Serve para responder, com evidencia real: o WinRE 1809 tem netsh/WLAN? Tem driver Wi-Fi?
#
# Uso:
#   sh scripts/inspecionar_winre.sh <arquivo.wim|.esd|.iso|pasta> [indice]
# Exemplos:
#   sh scripts/inspecionar_winre.sh .work/iso/install.wim 1
#   sh scripts/inspecionar_winre.sh .work/uup/files/Microsoft-Windows-Client-Desktop-Required-Package.esd
#
# Saida: presenca de netsh.exe, wlanapi.dll, wlanmsm.dll, certutil.exe, dism.exe,
#        drivers de rede sem fio (.inf Net*) e o proprio Winre.wim (se aninhado).
set -u
IMG="${1:?uso: sh scripts/inspecionar_winre.sh <imagem.wim|.esd|.iso|pasta> [indice]}"
IDX="${2:-1}"
WORK="${WORK:-.work}"
say(){ printf '[winre] %s\n' "$*"; }

command -v wimlib-imagex >/dev/null 2>&1 || { say "ERRO: instale wimlib (sh scripts/ambiente.sh)"; exit 1; }

# --- se for ISO, extrai o install.wim primeiro ---
case "$IMG" in
  *.iso)
    say "ISO detectada: extraindo sources/install.wim"
    mkdir -p "$WORK/iso"
    7z e -y -o"$WORK/iso" "$IMG" sources/install.wim >/dev/null 2>&1 ||
      7z e -y -o"$WORK/iso" "$IMG" sources/install.esd >/dev/null 2>&1
    IMG=$(ls "$WORK/iso"/install.wim "$WORK/iso"/install.esd 2>/dev/null | head -1)
    [ -z "$IMG" ] && { say "ERRO: nao achei install.wim/esd na ISO"; exit 1; }
    say "imagem: $IMG";;
esac

# --- se for pasta, procura wim/esd dentro ---
if [ -d "$IMG" ]; then
  IMG=$(find "$IMG" -maxdepth 3 \( -name 'install.wim' -o -name 'install.esd' -o -name '*.wim' \) | head -1)
  [ -z "$IMG" ] && { say "ERRO: nenhum .wim na pasta"; exit 1; }
  say "imagem: $IMG"
fi

say "indice: $IDX"
say "indices disponiveis:"
wimlib-imagex info "$IMG" 2>/dev/null | grep -iE "^(Index|Name|Edition|Architecture)" | head -12

# --- procura o WinRE dentro da imagem ---
say "--- procurando Winre.wim na imagem ---"
wimlib-imagex dir "$IMG" "$IDX" 2>/dev/null | grep -iE "recovery.*winre|winre\.wim" | head -5

mkdir -p "$WORK/mnt"
EXTRAIDO=""
# tenta extrair o Winre.wim aninhado (caminho padrao do Windows)
for caminho in "Windows/System32/Recovery/Winre.wim" "windows/system32/recovery/Winre.wim"; do
  if wimlib-imagex extract "$IMG" "$IDX" "$caminho" --dest-dir="$WORK/mnt" --no-acls --no-attributes >/dev/null 2>&1; then
    if [ -s "$WORK/mnt/Winre.wim" ]; then EXTRAIDO="$WORK/mnt/Winre.wim"; break; fi
  fi
done

ALVO="$IMG"; [ -n "$EXTRAIDO" ] && ALVO="$EXTRAIDO" && say "WinRE extraido: $ALVO ($(du -h "$ALVO"|cut -f1))"
[ -z "$EXTRAIDO" ] && say "Winre.wim nao aninhado: inspecionando a propria imagem"

# --- verifica componentes-chave ---
say "--- componentes de rede sem fio no WinRE ---"
LISTA=$(wimlib-imagex dir "$ALVO" 1 2>/dev/null)
[ -z "$LISTA" ] && LISTA=$(wimlib-imagex dir "$ALVO" "$IDX" 2>/dev/null)

for item in \
  "Windows/System32/netsh.exe" \
  "Windows/System32/certutil.exe" \
  "Windows/System32/dism.exe" \
  "Windows/System32/wlanapi.dll" \
  "Windows/System32/wlanmsm.dll" \
  "Windows/System32/wlansvc.dll" \
  "Windows/System32/wlansec.dll" \
  "Windows/System32/drivers/netw*" \
  "Windows/System32/DriverStore" ; do
  base=$(echo "$item" | tr 'A-Z' 'a-z')
  if echo "$LISTA" | grep -qi -- "$(echo "$base" | sed 's#.*/##' | sed 's/\*//')"; then
    say "PRESENTE : $item"
  else
    say "AUSENTE  : $item"
  fi
done

say "--- drivers de rede sem fio (Net*.inf) ---"
echo "$LISTA" | grep -iE "net[a-z0-9]*\.inf|wireless|wlan" | head -10 || say "(nenhum listado)"

say "--- pacotes WinPE/WiFi (opcionais do ADK) ---"
echo "$LISTA" | grep -iE "winpe.*wifi|wifi.*package" | head -5 || say "(nenhum)"
say "fim."
