# Arquitetura de cooperação (wwii)

Os agentes não precisam ler este arquivo. Ele é para o dono e para quem evolui o repositório.

## Quem escreve, quem lê

| Arquivo (onde) | Escreve | Lê | Função |
|---|---|---|---|
| `PLANO-DO-LIDER.md` (branch `relatorio`) | lead | agentes, via `scripts/plano.sh` | direção, frentes e respostas por id |
| `PROTOCOLO-DO-LIDER.md` (branch `relatorio`) | dono | lead | protocolo estável do lead |
| `INDICE-PARA-O-LIDER.md` (branch `relatorio`) | `relatorio.sh`, `escalar.sh` | só o lead | índice com até 2 KB |
| `casos/<id>.md` (branch `relatorio`) | `escalar.sh` | só o lead | dossiê de decisão, até 1,5 KB |
| `PROBLEMAS.md` | agentes, via `problema.sh` | agentes (`abertos`, `buscar`) | cooperação entre pares |
| `SUGESTOES.md` | agentes, via `sugerir.sh` | dono | evolução do processo e custo |
| painel (`sh scripts/painel.sh`) | ninguem (so le) | dono e Claude, no inicio de cada conversa | uma pagina: etapas, parados, problemas, presença, sugestões, capacidade |
| `PRESENCA.md` | hooks | dono | `inicio` e `push` com data UTC |
| `HANDOFF.md` | agente, ao fim da rodada | agentes | snapshot do estado |
| `ETAPAS.md` | `etapa.sh` | agentes | etapas com evidência |
| `PROGRESS.md` | agentes | só o fim (`tail -20`) | conquistas |

## Fluxo de um problema

1. O agente trava, roda `problema.sh buscar`, depois `novo` e `tentou` a cada falha.
2. Outro agente vê o problema em `abertos` e pode resolver (`resolveu`), e todos reaproveitam com `buscar`.
3. Com 2 tentativas sem solução, `escalar.sh` leva o dossiê ao lead. A linha ganha `[LEAD]` e ninguém escala de novo.
4. O lead responde no `PLANO-DO-LIDER.md` por id. O agente aplica e fecha com `resolveu`.

## Princípios de custo

- O lead só entra na branch `relatorio`: índice, depois só os dossiês listados.
- Escalar exige 2 tentativas registradas, para o lead não gastar com o que o agente resolveria.
- Entradas curtas (até 300 caracteres), estado derivado das linhas, nada reescrito.
- Leitura obrigatória dos agentes: `plano.sh`, `AGENTS.md`, `PROMPT.md`, `HANDOFF.md`.
- Toda perda de rodada vira linha em `SUGESTOES.md`; o dono lê o fim dele a cada conversa e aplica.
