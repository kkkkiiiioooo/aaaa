#!/bin/sh
# protocolo-lint.sh - verifica as regras do protocolo de enxame no historico e no indice.
# Feito para rodar em CI e no pre-push. POSIX sh; so usa git, awk, grep.
#
# Uso:
#   sh protocolo-lint.sh                     # commits de origin/main..HEAD + indice
#   sh protocolo-lint.sh --range A..B        # intervalo explicito
#   sh protocolo-lint.sh --repo /caminho     # outro clone
#   sh protocolo-lint.sh --max-bytes 5000000 # limite de blob (padrao 5 MB)
#
# Codigos: 0 ok, 1 violacao encontrada, 2 uso/ambiente.
set -u

RANGE=""
REPO="."
MAXB=5000000
while [ $# -gt 0 ]; do
  case "$1" in
    --range) [ $# -ge 2 ] || { echo "falta valor em --range" >&2; exit 2; }; RANGE=$2; shift 2 ;;
    --repo)  [ $# -ge 2 ] || { echo "falta valor em --repo" >&2;  exit 2; }; REPO=$2;  shift 2 ;;
    --max-bytes) [ $# -ge 2 ] || { echo "falta valor em --max-bytes" >&2; exit 2; }; MAXB=$2; shift 2 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

cd "$REPO" 2>/dev/null || { echo "repo inacessivel: $REPO" >&2; exit 2; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "nao e um repositorio git: $REPO" >&2; exit 2; }

PADRAO=0
[ -n "$RANGE" ] || { RANGE="origin/main..HEAD"; PADRAO=1; }
# As checagens de arvore olham a PONTA do intervalo, nao o working tree: em CI a
# arvore pode estar em main enquanto o intervalo aponta para a branch do PR.
TIP=${RANGE##*..}; TIP=${TIP:-HEAD}
git rev-parse -q --verify "$TIP" >/dev/null 2>&1 || TIP=HEAD
BR=$(git rev-parse --abbrev-ref "$TIP" 2>/dev/null)
N=0

falha() { N=$((N + 1)); printf 'VIOLACAO %-3s %s\n' "$1" "$2"; }

# ---------------------------------------------------------------- 1 autoria
# Regra: todo commit traz o trailer de autoria (Agent-Name: ou Agente:).
# Sem isso, "quem fez" e palpite e o arbitrio humano perde a base.
for c in $(git rev-list "$RANGE" 2>/dev/null); do
  if ! git log -1 --format='%B' "$c" | grep -qiE '^(Agent-Name|Agente): *[^ ]'; then
    falha A1 "$(git log -1 --format='%h %s' "$c") — sem trailer 'Agent-Name:'/'Agente:'"
  fi
done

# ---------------------------------------------------------------- 2 branch
# Regra: main e 0 sao configuracao; nao recebem commit de trabalho.
case "$BR" in
  main|0) falha B1 "commit em '$BR' (branch de configuracao); use uma branch de projeto" ;;
esac

# ---------------------------------------------------------------- 3 data/hora
# Regra: entrada em log coletivo tem data E hora. Aceita ISO-8601 UTC e YYYY-MM-DD HH:MM.
TS='[0-9]{4}-[0-9]{2}-[0-9]{2}([ T][0-9]{2}:[0-9]{2}(:[0-9]{2})?(Z|[+-][0-9]{2}:?[0-9]{2})?)?'
# Diario (PROGRESS/DEBATE/HANDOFF): so o cabecalho de entrada carrega a data; o corpo
# e continuacao. Log de eventos (MURAL/PROBLEMAS/PRESENCA): a propria linha e o evento.
for f in PROGRESS.md DEBATE.md MURAL.md PROBLEMAS.md SUGESTOES.md PRESENCA.md; do
  git cat-file -e "$TIP:$f" 2>/dev/null || continue
  git diff -U0 "$RANGE" -- "$f" 2>/dev/null | grep '^+' | grep -v '^+++' | sed 's/^+//' |
  while IFS= read -r linha; do
    [ -n "$linha" ] || continue
    case "$f:$linha" in
      *:'## '*) ;;                      # cabecalho de entrada: exige data+hora
      *:'#'*) continue ;;               # outro titulo: nao e entrada
      *:*) case "$f" in
             PROGRESS.md|DEBATE.md) continue ;;   # corpo: nao exige data
           esac ;;
    esac
    printf '%s\n' "$linha" | grep -qE "$TS" || \
      printf 'VIOLACAO T1 %s: entrada sem data+hora: %s\n' "$f" "$(printf '%s' "$linha" | cut -c1-60)"
  done
done > .lint-tmp.$$ 2>/dev/null
if [ -s .lint-tmp.$$ ]; then cat .lint-tmp.$$; N=$((N + $(wc -l < .lint-tmp.$$))); fi
rm -f .lint-tmp.$$

# HANDOFF.md e snapshot: nao tem entradas datadas, tem UM carimbo de atualizacao.
git cat-file -e "$TIP:HANDOFF.md" 2>/dev/null && {
  git show "$TIP:HANDOFF.md" | grep -qiE "(ultima (atualizacao|reescrita)|atualizado em).*$TS" || \
    falha T2 "HANDOFF.md sem linha 'Ultima atualizacao: <data> <hora>'"
}

# ---------------------------------------------------------------- 4 estado
# Regra: estado de etapa pertence ao vocabulario fechado.
# ETAPAS/BOARD: linhas de log (sem '|' inicial) carregam estado; a tabela de definicao
# de etapas no topo (com '|') nao carrega.
for f in ETAPAS.md BOARD.md; do
  git cat-file -e "$TIP:$f" 2>/dev/null || continue
  git show "$TIP:$f" 2>/dev/null | grep -E '^(E[0-9]|T[0-9])[^|]*\|' | while IFS= read -r l; do
    printf '%s\n' "$l" | grep -qiE 'ativa|feita|liberada|aberta|tomada|revisao|concluida|bloqueada' || \
      printf 'VIOLACAO E1 %s: estado fora do vocabulario: %s\n' "$f" "$(printf '%s' "$l" | cut -c1-70)"
  done
done > .lint-tmp.$$ 2>/dev/null
if [ -s .lint-tmp.$$ ]; then cat .lint-tmp.$$; N=$((N + $(wc -l < .lint-tmp.$$))); fi
rm -f .lint-tmp.$$

# ---------------------------------------------------------------- 5 peso
# Regra: binario grande nao entra no git (clone de todo agente paga a conta).
git rev-list --objects "$RANGE" 2>/dev/null |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' 2>/dev/null |
  awk -v lim="$MAXB" '$1=="blob" && $3>lim {printf "VIOLACAO S1 arquivo grande (%d bytes): %s\n", $3, $4}' > .lint-tmp.$$ 2>/dev/null
if [ -s .lint-tmp.$$ ]; then cat .lint-tmp.$$; N=$((N + $(wc -l < .lint-tmp.$$))); fi
rm -f .lint-tmp.$$

# ---------------------------------------------------------------- 6 higiene
git cat-file -e "$TIP:.gitignore" 2>/dev/null && {
  for pat in '.work/' '.git-credentials'; do
    git show "$TIP:.gitignore" | grep -qxF "$pat" || falha H1 ".gitignore sem '$pat'"
  done
} || falha H1 ".gitignore ausente"

# ---------------------------------------------------------------- 7 protocolo
git cat-file -e "$TIP:PROTOCOLO.md" 2>/dev/null || \
  falha P1 "sem PROTOCOLO.md versionado (protocolo existe so como prosa em AGENTS.md)"

echo
if [ "$N" -eq 0 ]; then
  echo "protocolo: OK ($RANGE)"
  exit 0
fi
echo "protocolo: $N violacao(oes) em $RANGE"
exit 1
