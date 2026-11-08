#!/bin/sh
# migrar-nomes.sh - renomeia branches para o namespace p/ meta/ dado/ (PROTOCOLO.md).
#
# Seguro por padrao: sem --aplicar so mostra o plano. Renomear branch no remoto
# e operacao destrutiva (apaga a ref antiga), por isso exige confirmacao explicita.
#
# Uso: sh bin/migrar-nomes.sh            # plano, nao muda nada
#      sh bin/migrar-nomes.sh --aplicar  # cria a nova ref e apaga a antiga
set -u
R=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
cd "$R" || exit 2
APLICAR=0
[ "${1:-}" = "--aplicar" ] && APLICAR=1

# papel -> meta/<papel> · dado -> dado/<nome> · resto (nome livre) -> p/<nome>
papel() {
  case "$1" in
    lider|info|pesquisador) echo "meta/$1" ;;
    imagem|ddee) echo "dado/$1" ;;
    main|0|base|template|backup) echo "" ;;
    *) echo "p/$1" ;;
  esac
}

PLANO=""
for b in $(git ls-remote --heads origin 2>/dev/null | sed 's#.*refs/heads/##' | sort); do
  destino=$(papel "$b")
  [ -n "$destino" ] || continue
  [ "$destino" = "$b" ] && continue
  PLANO="$PLANO$b $destino
"
done

[ -n "$PLANO" ] || { echo "nada a migrar: todas as branches ja estao no namespace"; exit 0; }
printf '%-14s -> %s\n' BRANCH NOVA
printf '%s' "$PLANO" | while read -r de para; do printf '%-14s -> %s\n' "$de" "$para"; done

if [ "$APLICAR" -eq 0 ]; then
  echo
  echo "plano apenas. Para executar: sh bin/migrar-nomes.sh --aplicar"
  echo "Antes: cada projeto deve declarar a versao 3 em PROTOCOLO.md e o h.sh aceita nomes antigos."
  exit 0
fi

printf '%s' "$PLANO" | while read -r de para; do
  [ -n "$de" ] || continue
  if git ls-remote --heads origin "$para" 2>/dev/null | grep -q .; then
    echo "pulado $de -> $para (destino ja existe)"; continue
  fi
  git fetch -q origin "$de" && git push -q origin "refs/remotes/origin/$de:refs/heads/$para" \
    && echo "criada $para" || { echo "falhou $de -> $para"; continue; }
  git push -q origin ":refs/heads/$de" && echo "removida $de"
done
echo
echo "feito. Atualize os clones: git fetch --prune origin"
