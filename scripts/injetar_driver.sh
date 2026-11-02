#!/bin/sh
# injetar_driver.sh — injeta um driver de dispositivo dentro de uma imagem Windows/WinRE (WIM/ESD).
#
# Equivalente Linux (offline) do passo do runbook no Windows:
#     dism /Mount-Image /ImageFile:R:\Recovery\WindowsRE\Winre.wim /Index:1 /MountDir:C:\mnt
#     dism /Image:C:\mnt /Add-Driver /Driver:<pasta> /Recurse
#     dism /Unmount-Image /MountDir:C:\mnt /Commit
#
# Aqui nao ha DISM (nem Windows), entao a injecao e feita com wimlib-imagex, gravando os
# arquivos do driver nos mesmos caminhos que o DISM usa:
#     /Windows/INF/<inf>.inf                                   (INF registrado)
#     /Windows/System32/DriverStore/FileRepository/<inf>.inf_amd64_<hash>/*  (pacote do driver)
#     /Windows/System32/drivers/<sys>                          (binario carregado no boot)
#
# O que ISTO nao faz (so o DISM/Windows faz): registrar o driver no hive (SYSTEM/SOFTWARE),
# atualizar o catalogo de assinaturas e o setupapi.dev.log. Por isso, no Windows real, o
# passo continua sendo o DISM — este script serve para preparar/verificar a imagem e para
# provar que o pacote e injetavel.
#
# Uso:
#   sh scripts/injetar_driver.sh --imagem <wim|esd> --driver <pasta> [--indice 1] [--inf <arquivo>]
#   sh scripts/injetar_driver.sh --imagem <wim|esd> --listar
#
# Exemplos:
#   sh scripts/injetar_driver.sh --imagem .work/wim/Winre.wim --driver .work/drivers/extracted
#   sh scripts/injetar_driver.sh --imagem .work/wim/Winre.wim --listar
set -u

WORK="${WORK:-.work}"
IMAGEM=""; DRIVER=""; INDICE=1; INF_ESPEC=""; LISTAR=0
SAIDA=""

say(){ printf '[injetar] %s\n' "$*"; }
die(){ printf '[injetar] ERRO: %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --imagem) IMAGEM="${2:-}"; shift 2;;
    --driver) DRIVER="${2:-}"; shift 2;;
    --indice) INDICE="${2:-1}"; shift 2;;
    --inf)    INF_ESPEC="${2:-}"; shift 2;;
    --listar) LISTAR=1; shift;;
    --saida)  SAIDA="${2:-}"; shift 2;;
    -h|--help) sed -n '2,30p' "$0"; exit 0;;
    *) die "argumento desconhecido: $1";;
  esac
done

command -v wimlib-imagex >/dev/null 2>&1 || die "wimlib-imagex ausente (rode scripts/ambiente.sh)"

# ------------------------------------------------------------------ modo listar
if [ "$LISTAR" = 1 ]; then
  [ -n "$IMAGEM" ] || die "informe --imagem"
  say "imagem: $IMAGEM (indice $INDICE)"
  wimlib-imagex info "$IMAGEM" "$INDICE" 2>/dev/null | grep -iE "^(Index|Name|Edition ID|Build|File Count)" || true
  say "--- drivers presentes (INF em /Windows/INF) ---"
  wimlib-imagex dir "$IMAGEM" "$INDICE" 2>/dev/null \
    | grep -iE "^/Windows/INF/.*\.inf$" \
    | sed 's#.*/##; s#\.inf$##' \
    | grep -iE '^(net|ndis|wifi|wlan|wireless|rtl|bc|ath|int|mar|mt|netwtw|netb|netwl)' \
    | head -40 || true
  say "--- DriverStore/FileRepository ---"
  wimlib-imagex dir "$IMAGEM" "$INDICE" 2>/dev/null | grep -iE "DriverStore/FileRepository/[^/]+$" | head -40
  exit 0
fi

[ -n "$IMAGEM" ] || die "informe --imagem"
[ -n "$DRIVER" ] || die "informe --driver"
[ -f "$IMAGEM" ] || die "imagem nao encontrada: $IMAGEM"
[ -d "$DRIVER" ] || die "pasta de driver nao encontrada: $DRIVER"

# ------------------------------------------------------------------ escolhe o INF
INFS=""
if [ -n "$INF_ESPEC" ]; then
  [ -f "$INF_ESPEC" ] || die "inf nao encontrado: $INF_ESPEC"
  INFS="$INF_ESPEC"
else
  INFS=$(find "$DRIVER" -maxdepth 3 -iname '*.inf' | sort)
fi
[ -n "$INFS" ] || die "nenhum .inf em $DRIVER (extraia o .cab antes)"

# ------------------------------------------------- monta os comandos do wimlib
# wimlib update aceita varios comandos; montamos um arquivo de comandos.
CMDFILE="$WORK/injetar/comandos.txt"
mkdir -p "$WORK/injetar"
: > "$CMDFILE"

n_inf=0
for inf in $INFS; do
  base=$(basename "$inf" | tr 'A-Z' 'a-z')
  dir=$(dirname "$inf")
  [ "$base" = "$(basename "$inf")" ] && base=$(basename "$inf")

  # hash deterministico para o nome da pasta do DriverStore (o Windows usa um hash proprio;
  # qualquer identificador unico serve, desde que nao colida com o existente)
  hash=$(sha1sum "$inf" 2>/dev/null | cut -c1-16)
  repo="/Windows/System32/DriverStore/FileRepository/${base%.inf}.inf_amd64_${hash}"

  say "INF: $inf"
  say "  -> /Windows/INF/$base"
  printf 'add %s /Windows/INF/%s\n' "$inf" "$base" >> "$CMDFILE"

  # pacote do driver no DriverStore: inf + .sys + .cat + .dll da mesma pasta
  # (o comando "add" do wimlib cria os diretorios intermediarios, nao ha "mkdir")
  say "  -> $repo/"
  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    case "$f" in
      *.inf|*.sys|*.cat|*.dll|*.exe|*.inf_loc) ;;
      *) continue;;
    esac
    fb=$(basename "$f")
    printf 'add %s %s/%s\n' "$f" "$repo" "$fb" >> "$CMDFILE"
    # o .sys do driver tambem vai para System32/drivers (e o que o boot carrega)
    case "$fb" in
      *.sys)
        printf 'add %s /Windows/System32/drivers/%s\n' "$f" "$fb" >> "$CMDFILE";;
    esac
  done
  n_inf=$((n_inf+1))
done
say "arquivos a injetar: $(grep -c '^add ' "$CMDFILE") (de $n_inf INF)"

# ------------------------------------------------------------------ copia de seguranca
if [ -z "$SAIDA" ]; then
  SAIDA="$IMAGEM.injetado.wim"
fi
say "backup: $SAIDA"
cp -f "$IMAGEM" "$SAIDA"

# ------------------------------------------------------------------ aplica
say "injetando na imagem (pode demorar)..."
if wimlib-imagex update "$IMAGEM" "$INDICE" --command="add /tmp/.nonexistent" >/dev/null 2>&1; then
  : # apenas checa que a ferramenta responde
fi
if ! wimlib-imagex update "$IMAGEM" "$INDICE" < "$CMDFILE" > "$WORK/injetar/update.log" 2>&1; then
  say "ERRO na injeção. log:"
  tail -20 "$WORK/injetar/update.log"
  exit 1
fi

# ------------------------------------------------------------------ verifica
say "verificando..."
LISTA=$(wimlib-imagex dir "$IMAGEM" "$INDICE" 2>/dev/null)
falha=0
for inf in $INFS; do
  base=$(basename "$inf")
  if echo "$LISTA" | grep -qi "/Windows/INF/$base"; then
    say "  [OK] /Windows/INF/$base"
  else
    say "  [FALTA] /Windows/INF/$base"; falha=1
  fi
done
# o .sys tem que estar em System32/drivers
while IFS= read -r f; do
  fb=$(basename "$f")
  if echo "$LISTA" | grep -qi "/Windows/System32/drivers/$fb"; then
    say "  [OK] /Windows/System32/drivers/$fb"
  else
    say "  [FALTA] /Windows/System32/drivers/$fb"; falha=1
  fi
done <<EOF
$(find "$DRIVER" -maxdepth 3 -iname '*.sys' | sort)
EOF

say "resultado: $([ $falha -eq 0 ] && echo 'INJECAO VERIFICADA' || echo 'INCOMPLETO')"
say "imagem atualizada: $IMAGEM (backup em $SAIDA)"
exit $falha
