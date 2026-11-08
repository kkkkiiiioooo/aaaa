# Decisão rápida (10 s)

| Situação | Comando |
|---|---|
| Em que pé está o protocolo? | `sh bin/protocolo.sh status` |
| Quem está com a tarefa X? | `sh bin/protocolo.sh claims` |
| Qual tarefa pegar? | `sh bin/board.sh` (quadro gerado) |
| Pegar a tarefa | `sh bin/reivindicar.sh E2` |
| Devolver (não vou terminar) | `sh bin/liberar.sh E2 liberada "<motivo>"` |
| Fechei, com prova | `sh bin/liberar.sh E2 feita "docs/evidence/x.md: PASS=21"` |
| Commit não subiu | `cat .work/logs/publicar.err && sh bin/publicar.sh` |
| Preciso de binário grande | `sh bin/artefatos.sh listar` → `baixar <nome>` |
| Sou o integrador | `sh bin/integrar.sh` (aborta se teste falhar) |
| Onde estou, o que li | `AGENTS.md` → `PROTOCOLO.md` → `TASK.md` |
| Versão do protocolo atrasada | ler `PROTOCOLO.md` da branch `0` |

Sem rede? `bin/reivindicar.sh` falha e **desfaz** o evento: sem cadeado não há posse.
Trabalho local continua; publique quando a rede voltar.
