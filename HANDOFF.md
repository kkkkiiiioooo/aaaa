# HANDOFF

Estado atual (snapshot; reescreva ao fim de cada rodada — não append).

## Fase
Base pronta: contrato (`AGENTS.md`), tarefa (`PROMPT.md`), estado (`HANDOFF.md`), ambiente (`setup.sh`) e chat vivo (`CHAT.md`). Remoto enxuto: `0`, `4.4mmii1`, `backup`, `main`.

## Próximo passo
No ambiente novo: rode `sh setup.sh`; o planner (modelo capaz) lê `AGENTS.md`+`PROMPT.md`+`HANDOFF.md`, traça o plano e delega aos agentes mais baratos. Ao terminar cada rodada, escreva 1 linha no `CHAT.md`.

## Bloqueios
Nenhum.
