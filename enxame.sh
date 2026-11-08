#!/bin/sh
# enxame.sh - inicializa o protocolo v3 num projeto que ainda nao o tem.
# Idempotente: nunca sobrescreve arquivo existente, nunca reescreve o passado.
#
# Uso: A=<nome> sh enxame.sh        (dentro do clone, na branch do projeto)
set -u
B=$(git branch --show-current 2>/dev/null)
[ -n "$B" ] || { echo "erro: fora de um repositorio git"; exit 1; }
case "$B" in main|0|base|template|backup) echo "erro: '$B' e configuracao, nao projeto"; exit 1 ;; esac
AG=${A:-${A_AGENTE:-$(cat .work/agente 2>/dev/null || git config user.name 2>/dev/null || echo agente)}}
TS=$(date -u +%FT%TZ)
CRIADOS=""

grava() { # grava <arquivo> ; conteudo vem do stdin
  if [ -e "$1" ]; then echo "preservado: $1"; return 0; fi
  mkdir -p "$(dirname "$1")"; cat > "$1" && CRIADOS="$CRIADOS $1" && echo "criado: $1"
}

grava TASK.md <<'FIM'
# TASK.md — o problema e o aceite (somente o humano edita)

## Problema
[Enunciado preciso, sem solucao embutida.]

## Criterios de aceitacao (verificaveis por teste)
1. [Afirmativa que um comando comprova.]
2. [Idem.]

## Fora do escopo
- [O que expressamente nao deve ser feito.]
FIM

grava DEBATE.md <<'FIM'
# DEBATE.md — discordancia datada; nunca apague a posicao anterior

Convergencia se registra como "revogo minha posicao" + entrada em events/.

## Pauta 1 — [assunto]
### Posicao (<agente>, YYYY-MM-DDTHH:MM:SSZ)
[posicao e justificativa]
### Replica (<agente>, YYYY-MM-DDTHH:MM:SSZ)
[contraexemplo, medicao ou questionamento]
FIM

grava "HANDOFF/README.md" <<'FIM'
# HANDOFF/

Um arquivo por agente: `HANDOFF/<seu-nome>.md`. Snapshot do seu turno; ninguem mais
escreve nele, entao nunca conflita. Formato:

    Ultima atualizacao: YYYY-MM-DDTHH:MM:SSZ — <agente>
    1. Estado atual:
    2. Proximo passo:
    3. Armadilhas conhecidas:
    4. Pendencias humanas (arbitrio aguardado):
FIM

grava "events/.gitkeep" < /dev/null
printf '{"ts":"%s","ag":"%s","tipo":"note","id":"T0","texto":"protocolo v3 inicializado"}\n' "$TS" "$AG" \
  >> "events/$AG.jsonl"
CRIADOS="$CRIADOS events/$AG.jsonl"
echo "criado: events/$AG.jsonl"

# visoes geradas (BOARD/PROGRESS) — so o integrador as commita depois
if [ -f .work/bin/board.sh ]; then sh .work/bin/board.sh >/dev/null 2>&1 && echo "gerado: BOARD.md PROGRESS.md"
elif [ -f bin/board.sh ]; then sh bin/board.sh >/dev/null 2>&1 && echo "gerado: BOARD.md PROGRESS.md"
else echo "aviso: bin/board.sh ausente (rode sh h.sh para instalar a toolchain)"; fi

if [ -n "$CRIADOS" ]; then
  git add $CRIADOS 2>/dev/null
  git add BOARD.md PROGRESS.md 2>/dev/null
  git commit -qm "enxame: protocolo v3 inicializado ($TS)

Agent-Name: $AG" && echo "commit ok"
  git push -q --force-with-lease origin "HEAD:refs/agents/$AG" 2>/dev/null \
    && echo "publicado: refs/agents/$AG" \
    || echo "aviso: push falhou (sh bin/publicar.sh)"
else
  echo "nada a criar: protocolo ja presente"
fi
