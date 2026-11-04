#!/bin/sh
# enxame.sh - inicializa os arquivos do protocolo de enxame no projeto atual.
# Uso: dentro do clone, ja na branch do projeto (nunca na main): NOME=<agente> sh enxame.sh
# Idempotente: arquivos existentes sao preservados e nada e anexado a eles.
set -u
B=$(git branch --show-current 2>/dev/null)
[ -n "$B" ] && [ "$B" != main ] || { echo "erro: rode numa branch de projeto, nunca na main"; exit 1; }
NOME=${NOME:-${A_AGENTE:-agente}}
AGORA=$(date '+%Y-%m-%d %H:%M (UTC-3)')
CRIADOS=""
grava() { # grava <arquivo> <conteudo via stdin>
  if [ -f "$1" ]; then echo "preservado (ja existe): $1"; return 0; fi
  cat > "$1" && CRIADOS="$CRIADOS $1" && echo "criado: $1"
}

grava TASK.md <<'FIM1'
# TASK.md

## Problema
[Enunciado preciso do problema.]

## Criterios de aceitacao
1. [Afirmativa verificavel por teste.]
2. [Afirmativa verificavel por teste.]

## Fora do escopo
- [O que expressamente nao deve ser feito.]
FIM1

grava BOARD.md <<'FIM2'
# BOARD.md

Estados: aberta -> tomada -> em revisao -> concluida | bloqueada
Tomar uma tarefa: pull; mude o estado para "tomada" com seu nome e data+hora; commit imediato.
Toda atualizacao exige data E hora no formato YYYY-MM-DD HH:MM (UTC-3).

| ID | Tarefa | Estado | Agente | Atualizada em |
| --- | --- | --- | --- | --- |
| T1 | [primeira tarefa, decomposta pelo Explorador] | aberta | — | [YYYY-MM-DD HH:MM] |
FIM2

grava PROGRESS.md <<'FIM3'
# PROGRESS.md

Diario coletivo. Apenas anexar; nunca editar entradas anteriores.
Toda entrada exige data E hora no formato: YYYY-MM-DD HH:MM (UTC-3).

Modelo:

## YYYY-MM-DD HH:MM (UTC-3) — <NomeDoAgente> (<papel>)
<o que foi feito, decisao tomada, estado em que ficou o trabalho>
FIM3

grava HANDOFF.md <<'FIM4'
# HANDOFF.md — recado ao proximo agente

Reescrito a cada turno. Toda atualizacao exige data E hora: YYYY-MM-DD HH:MM (UTC-3).

1. Estado atual do trabalho:
2. Proximo passo sugerido:
3. Armadilhas conhecidas:
4. Pendencias humanas (arbitrio aguardado):
FIM4

grava DEBATE.md <<'FIM5'
# DEBATE.md

Arena de discordancias: replica-se, nunca se apaga.
Toda posicao e toda replica exigem data E hora no formato YYYY-MM-DD HH:MM (UTC-3).
Convergencia registrada como "revogo minha posicao", seguida de registro em PROGRESS.md.

# Pauta 1 — [assunto em disputa]
## Posicao (<agente>, <YYYY-MM-DD HH:MM>)
[posicao e justificativa]
## Replica (<agente>, <YYYY-MM-DD HH:MM>)
[replica, contraexemplo ou questionamento]
FIM5

# Entradas iniciais: apenas se o arquivo foi criado NESTA execucao (idempotencia)
case " $CRIADOS " in *" PROGRESS.md "*)
  printf '## %s — %s (Explorador)\nProtocolo de enxame inicializado por enxame.sh.\n' "$AGORA" "$NOME" >> PROGRESS.md ;;
esac
case " $CRIADOS " in *" HANDOFF.md "*)
  printf 'Ultima atualizacao: %s — %s\n' "$AGORA" "$NOME" >> HANDOFF.md ;;
esac

if [ -n "$CRIADOS" ]; then
  git add $CRIADOS; git add enxame.sh 2>/dev/null
  git commit -qm "enxame: protocolo inicializado ($AGORA)

Agent-Name: $NOME" && echo "commit ok"
  git push -q origin "$B" || echo "AVISO: push falhou em $B (refaca o push manualmente)"
else
  echo "nada a criar; protocolo ja presente neste projeto"
fi
