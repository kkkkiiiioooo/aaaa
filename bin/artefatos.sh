#!/bin/sh
# artefatos.sh - baixa artefatos grandes de GitHub Releases, fora do historico do git.
#
# Motivo: um blob de 100 MB no repo e pago por TODO agente em TODO clone. Release
# aceita 2 GB por arquivo, tem URL estavel e nao infla o .git.
#
# Manifesto: artefatos/manifest.tsv  ->  <nome> <TAB> <url> <TAB> <sha256>
#
# Uso: sh bin/artefatos.sh listar
#      sh bin/artefatos.sh baixar <nome>     # -> .work/downloads/<nome>, sha256 conferido
#      sh bin/artefatos.sh conferir          # valida tudo que ja foi baixado
#      sh bin/artefatos.sh publicar <arquivo> <nome>   (exige gh autenticado)
set -u
R=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
cd "$R" || exit 2
M="$R/artefatos/manifest.tsv"
D="$R/.work/downloads"
mkdir -p "$D"

linha() { grep -P "^\\Q$1\\E\t" "$M" 2>/dev/null | head -1 || awk -F'\t' -v n="$1" '$1==n' "$M" 2>/dev/null | head -1; }

case "${1:-listar}" in
  listar)
    [ -f "$M" ] || { echo "sem $M"; echo "formato: <nome> <TAB> <url> <TAB> <sha256>"; exit 0; }
    printf '%-24s %-10s %s\n' NOME ESTADO URL
    while IFS='	' read -r n u h; do
      [ -n "${n:-}" ] || continue
      case "$n" in \#*) continue ;; esac
      if [ -f "$D/$n" ] && [ "$(sha256sum "$D/$n" 2>/dev/null | cut -d' ' -f1)" = "$h" ]; then e=ok; else e=ausente; fi
      printf '%-24s %-10s %s\n' "$n" "$e" "$u"
    done < "$M"
    ;;
  baixar)
    n=${2:-}; [ -n "$n" ] || { echo "uso: artefatos.sh baixar <nome>"; exit 2; }
    l=$(linha "$n"); [ -n "$l" ] || { echo "artefato desconhecido: $n"; exit 2; }
    u=$(printf '%s' "$l" | cut -f2); h=$(printf '%s' "$l" | cut -f3)
    if [ -f "$D/$n" ] && [ "$(sha256sum "$D/$n" | cut -d' ' -f1)" = "$h" ]; then
      echo "ja presente e conferido: $D/$n"; exit 0
    fi
    echo "baixando $n ..."
    curl -fL --retry 3 -C - -o "$D/$n" "$u" || { echo "falhou: $u"; exit 1; }
    got=$(sha256sum "$D/$n" | cut -d' ' -f1)
    if [ -n "$h" ] && [ "$got" != "$h" ]; then
      echo "SHA256 DIVERGENTE — descartando $D/$n"; echo "  esperado: $h"; echo "  obtido  : $got"
      mv "$D/$n" "$D/$n.bad"; exit 1
    fi
    echo "ok: $D/$n  sha256=$got"
    ;;
  conferir)
    [ -f "$M" ] || { echo "sem manifesto"; exit 0; }
    fail=0
    while IFS='	' read -r n u h; do
      [ -f "$D/$n" ] || continue
      got=$(sha256sum "$D/$n" | cut -d' ' -f1)
      if [ "$got" = "$h" ]; then echo "ok      $n"; else echo "CORRUPTO $n"; fail=$((fail+1)); fi
    done < "$M"
    exit $fail
    ;;
  publicar)
    f=${2:-}; n=${3:-$(basename "${2:-}")}
    [ -f "$f" ] || { echo "uso: artefatos.sh publicar <arquivo> [nome]"; exit 2; }
    command -v gh >/dev/null 2>&1 || { echo "gh ausente: instale e autentique para publicar"; exit 1; }
    gh release view artefatos >/dev/null 2>&1 || gh release create artefatos --title artefatos --notes "binarios fora do historico"
    gh release upload artefatos "$f" --clobber || exit 1
    echo "enviado. registre no manifesto:"
    printf '%s\t%s\t%s\n' "$n" "$(gh release view artefatos --json assets -q ".assets[]|select(.name==\"$n\")|.url")" "$(sha256sum "$f" | cut -d' ' -f1)"
    ;;
  *) echo "uso: artefatos.sh listar|baixar <nome>|conferir|publicar <arquivo> [nome]"; exit 2 ;;
esac
