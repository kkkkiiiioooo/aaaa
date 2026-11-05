#!/bin/sh
# dossie.sh — inventario da imagem do Windows baixada, para quem AINDA NAO tem a
# imagem. Roda no sandbox de quem baixou e escreve docs/imagem/. Nada aqui pede
# decisao: e leitura e contagem.
#
#   sh scripts/dossie.sh            # regenera docs/imagem/ a partir de .work/uup
#
# Pre-condicao: .work/uup/files/ existir (baixar_uup.sh). Sem isso, sai 3 e nao
# escreve nada — o dossie antigo continua valido.
set -eu

AQUI=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$AQUI/.." && pwd)
UUP=${UUP:-$REPO/.work/uup}
OUT=$REPO/docs/imagem
TSV=$(ls "$UUP"/*.tsv 2>/dev/null | head -1)

[ -d "$UUP/files" ] || { echo "dossie.sh: sem $UUP/files — rode scripts/baixar_uup.sh primeiro"; exit 3; }
[ -n "$TSV" ] || { echo "dossie.sh: sem .tsv de download em $UUP (nao dá para verificar sha1)"; exit 3; }

mkdir -p "$OUT"

# ---------------------------------------------------------- 1. manifest (sem URL)
# as URLs do UUP vem assinadas com token e expiram: nao vao para o git.
{
  echo '# manifest da imagem — gerado por scripts/dossie.sh'
  echo '# fonte: <uuid>_<edicao>.tsv do UUP dump; URL removida (token assinado, expira)'
  echo 'nome|bytes|sha1'
  awk -F'\t' 'NR>1 && NF>=4 {printf "%s|%s|%s\n", $2, $3, $4}' "$TSV" | sort
} > "$OUT/manifest.txt"

TOT=$(awk -F'\t' 'NR>1 && NF>=4 {s+=$3} END {printf "%.2f", s/1073741824}' "$TSV")
NR=$(awk -F'\t' 'NR>1 && NF>=4' "$TSV" | wc -l)
NF=$(ls "$UUP/files" | wc -l)

# ------------------------------------------------- 2. verificacao sha1 do que existe
echo 'checagem sha1 (so dos arquivos presentes):' > "$OUT/sha1.txt"
OK=0; FALTA=0; RUIM=0
awk -F'\t' 'NR>1 && NF>=4 {print $2"\t"$4}' "$TSV" | while IFS="$(printf '\t')" read -r nome esperado; do
  f="$UUP/files/$nome"
  if [ ! -f "$f" ]; then echo "FALTA  $nome" >> "$OUT/sha1.txt"; continue; fi
  real=$(sha1sum "$f" 2>/dev/null | cut -c1-40)
  if [ "$real" = "$esperado" ]; then echo "OK     $nome" >> "$OUT/sha1.txt"; else echo "DIFERE $nome ($real != $esperado)" >> "$OUT/sha1.txt"; fi
done
cnt() { grep -c "^$1" "$OUT/sha1.txt" 2>/dev/null || true; }
OK=$(cnt OK); RUIM=$(cnt DIFERE); FALTA=$(cnt FALTA)

# -------------------------------------------------------------- 3. indices dos ESDs
CORE=$(ls "$UUP/files"/Core*.esd 2>/dev/null | head -1)
{
  echo '# indices dos ESDs — wimlib-imagex info'
  for f in "$UUP"/files/*.esd "$UUP"/files/*.img; do
    [ -e "$f" ] || continue
    echo "## $(basename "$f")  ($(du -h "$f" | cut -f1))"
    wimlib-imagex info "$f" 2>/dev/null | awk '
      /^Index:/ {idx=$2} /^Name:/ {name=substr($0,index($0,":")+1)}
      /^File Count:/ {fc=$3} /^Total Bytes:/ {printf "  indice %s |%s | arquivos=%s | bytes=%s\n", idx, name, fc, $3}'
    echo
  done
} > "$OUT/indices.txt"

# --------------------------------------------- 4. lista completa do WinRE (indice 2)
if [ -n "$CORE" ]; then
  # 2,1 MB de caminhos viram ~200 KB em gzip: o dossier tem de ser leve para
  # quem ainda nao tem imagem nenhuma e so quer comecar a pensar.
  wimlib-imagex dir "$CORE" 2 | gzip -9 > "$OUT/winre-caminhos.txt.gz" || true
  wimlib-imagex dir "$CORE" 1 | gzip -9 > "$OUT/setupmedia-caminhos.txt.gz" || true
fi

# --------------------------------------------------------------- 5. anunciar
# Quem baixa a imagem tem o dever de avisar; quem ainda nao tem tem o direito de
# saber o que ha nela. O aviso e efeito colateral do generate, nao uma etapa
# separada que alguem esquece de fazer.
if [ -f "$REPO/scripts/relatorio.sh" ]; then
  ( cd "$REPO" && sh scripts/relatorio.sh "${A:-agente} | imagem | disponivel | $NF arquivos, sha1 OK=$OK/$NF | WinRE sem wcmsvc.dll, com drvload | leia docs/imagem/DOSSIE.md" ) >/dev/null 2>&1 \
    && echo "  anuncio: publicado em branch lider (o lead ve) e no git log" || echo "  anuncio: FALHOU - avise manualmente"
fi

cat <<EOF
dossie.sh: $NF arquivos em $(du -h "$UUP/files" | cut -f1) ($TOT GiB declarados)
  manifest : $OUT/manifest.txt ($NR linhas)
  sha1     : $OUT/sha1.txt — OK=$OK DIFERE=$RUIM FALTA=$FALTA
  indices  : $OUT/indices.txt
  caminhos: $OUT/winre-caminhos.txt.gz ($(zcat "$OUT/winre-caminhos.txt.gz" | wc -l) caminhos, $(du -h "$OUT/winre-caminhos.txt.gz" | cut -f1))
EOF
