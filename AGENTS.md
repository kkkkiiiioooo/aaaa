# AGENTS — regras (a mecânica está em PROTOCOLO.md)

Você é um agente do enxame. Receber o repositório **é** a ordem: trabalhe.

## Entrada (uma linha)

```sh
S=<passphrase> A=<seu-nome> P=<projeto> sh iniciar.sh
```

Sem `P`, o `h.sh` lista os projetos. Projeto novo só com `NEW=1` explícito.
A passphrase pode vir por arquivo: `S_ARQ=<caminho>`. Nunca por `argv` em pipe.

## Ordem de leitura (orçamento: 12 KB)

1. `PROTOCOLO.md` (uma vez; é a fonte da mecânica)
2. `TASK.md` (o problema e o aceite — só o humano edita)
3. `sh bin/protocolo.sh status` (versão, cadeados, pendências)
4. `HANDOFF/<seu-nome>.md` dos outros agentes, se existir

Não leia `_archived/`, `.bundle`, nem outras branches de projeto.

## Regras duras

- **Nunca** commite em `main`, `0`, `template` ou `backup`. Trabalho é na branch do projeto.
- **Assine** todo commit (`Agent-Name:`); o hook escreve de `.work/agente`. Não finja ser outro.
- **Data e hora** em toda entrada: `date -u +%FT%TZ`. Só data é inválido — não ordena.
- **Fechar tarefa exige evidência**: caminho do arquivo + saída do comando. Sem isso não está feito.
- **Escrita privada**: você escreve em `events/<seu-nome>.jsonl` e `HANDOFF/<seu-nome>.md`.
  `BOARD.md`/`PROGRESS.md` são gerados (`bin/board.sh`) e só o Integrador os commita.
- **Cadeado**: `bin/reivindicar.sh <ID>`; se já está tomada, escolha outra — nunca espere.
  Lease de 90 min; vencido, é reclamável.
- **Registre no repositório**, não no chat. Nada que importe fica só na conversa.
- **Ambiente é por agente**: meça e anote o seu (`ambientes/<nome>.md`); nunca atribua
  a outro agente a medida do seu sandbox.
- **Nunca conclua "impossível"**: bloqueio exige tentativas registradas + caminho alternativo.

## Trabalhe até se esgotar

Terminou uma tarefa, pegue a próxima. Só pare por limite do **seu** ambiente ou com
todas as alternativas viáveis tentadas e registradas. "Pronto" com problema aberto é parada precoce.

## Se algo travar

```sh
sh bin/protocolo.sh claims      # quem está com o quê
sh bin/liberar.sh E2 liberada "<motivo>"   # devolve o que não vai terminar
```

Falha técnica concreta vai para `PROBLEMAS.md`/`events/` com comando e saída.
Discordância vai para `DEBATE.md`, datada, sem apagar a posição anterior.

## Publicação

Commit já publica em `refs/agents/<seu-nome>` (post-commit). Se o push falhar, o
marcador `.work/push-pendente` avisa: commit local **não** é entrega. Repita com
`sh bin/publicar.sh`. A branch do projeto é atualizada só por `bin/integrar.sh`.
