#!/bin/sh
# fetch-base.sh — baixa a base minima de boot (kernel Linux) para os testes.
# Idempotente: nao rebaixa se o arquivo ja existe. Uso: sh scripts/fetch-base.sh
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DL="$ROOT/.work/downloads"
ALPINE_VER=${ALPINE_VER:-v3.20}
BASE_URL=${BASE_URL:-https://dl-cdn.alpinelinux.org/alpine/$ALPINE_VER/releases/x86_64/netboot}
KERNEL="$DL/vmlinuz-virt"

mkdir -p "$DL"
if [ -s "$KERNEL" ]; then
  echo "[fetch-base] kernel ja baixado: $KERNEL ($(wc -c <"$KERNEL") bytes)"
else
  echo "[fetch-base] baixando kernel de $BASE_URL/vmlinuz-virt ..."
  if curl -fSL --retry 3 -o "$KERNEL.part" "$BASE_URL/vmlinuz-virt"; then
    mv "$KERNEL.part" "$KERNEL"
    echo "[fetch-base] kernel ok ($(wc -c <"$KERNEL") bytes)"
  else
    echo "[fetch-base] Alpine inacessivel; fallback: kernel Ubuntu via apt (archive.ubuntu.com)"; rm -f "$KERNEL.part"
    T=$(mktemp -d) && ( cd "$T" && P=$(apt-cache depends linux-image-virtual 2>/dev/null | sed -n 's/.*Depends: \(linux-image-.*\)/\1/p' | head -1) \
      && apt-get download "$(echo "$P" | sed 's/linux-image-/linux-image-unsigned-/')" >/dev/null 2>&1 \
      && dpkg-deb -x linux-image-*.deb x ) \
      && cp "$T"/x/boot/vmlinuz-* "$KERNEL" && echo "[fetch-base] kernel Ubuntu ok ($(wc -c <"$KERNEL") bytes)" \
      || { echo "[fetch-base] falha no download do kernel (rede/proxy?)"; exit 1; }
    rm -rf "$T"
  fi
fi

# modloop = imagem squashfs com os modulos do kernel (sd_mod etc.)
MODLOOP="$DL/modloop-virt"
if [ -s "$MODLOOP" ]; then
  echo "[fetch-base] modloop ja baixado: $MODLOOP ($(wc -c <"$MODLOOP") bytes)"
else
  echo "[fetch-base] baixando modloop de $BASE_URL/modloop-virt ..."
  if curl -fSL --retry 3 -o "$MODLOOP.part" "$BASE_URL/modloop-virt"; then
    mv "$MODLOOP.part" "$MODLOOP"
    echo "[fetch-base] modloop ok ($(wc -c <"$MODLOOP") bytes)"
  else
    echo "[fetch-base] aviso: modloop indisponivel (disco da VM pode nao aparecer)"
    rm -f "$MODLOOP.part"; sh "$ROOT/scripts/fetch-modulos-ubuntu.sh"
  fi
fi
