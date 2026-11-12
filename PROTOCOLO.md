# PROTOCOLO — cooperação entre agentes via repositório

Versao: 3
Este arquivo é a **única** fonte da mecânica. Se outro documento descrever o protocolo
de forma diferente, este vence. Prosa de motivação: `AGENTS.md`. Atalho de decisão:
`DECISAO-RAPIDA.md`.

## Princípios

1. O repositório é o canal. Um arquivo lido é uma mensagem recebida; o histórico é a
   transcrição. Não existe coordenador.
2. Escrita é privada; leitura é pública. Cada agente escreve só no que é dele
   (`events/<agente>.jsonl`, `refs/agents/<agente>`) e ninguém disputa arquivo.
3. Estado é evento, visão é gerada. `BOARD.md` e `PROGRESS.md` são **saída** de
   `bin/board.sh`, nunca editados à mão.
4. Cadeado é do servidor, não da máquina. `flock` não atravessa hosts; criação de ref
   atravessa.
5. Alegação sem teste é opinião. Fechar tarefa exige evidência (caminho + saída).

## Papéis

| Papel | Escreve em | Não faz |
|---|---|---|
| Explorador | `TASK.md` (decompõe), `events/` | implementar |
| Implementador | código, `events/`, `docs/evidence/` | merge na branch do projeto |
| Crítico | `DEBATE.md`, `events/` (abre correção) | corrigir diretamente |
| Integrador | branch do projeto (`bin/integrar.sh`) | editar trabalho alheio |

Todo commit leva `Agent-Name: <nome>` (o trailer é o carimbo; o hook o escreve de
`.work/agente`). Todo evento leva data **e** hora em UTC (`date -u +%FT%TZ`).

## Arquivos

| Arquivo | Dono | Regra |
|---|---|---|
| `TASK.md` | humano | problema + critérios verificáveis; agente não edita |
| `events/<agente>.jsonl` | o agente | append-only, um arquivo por agente, uma linha JSON por evento |
| `BOARD.md` | gerado | `sh bin/board.sh`; só o Integrador commita a visão |
| `PROGRESS.md` | gerado | idem |
| `HANDOFF/<agente>.md` | o agente | snapshot do próprio turno (nunca conflita) |
| `DEBATE.md` | todos | discordância datada; converge com "revogo minha posição" |
| `docs/evidence/` | o agente | prova de cada alegação |

Formato do evento (uma linha):

```json
{"ts":"2026-11-09T02:40:00Z","ag":"Coder","tipo":"claim","id":"E2","texto":"curto"}
```

`tipo` ∈ `claim` · `note` · `close` · `release`.

## Turno

```sh
S=<passphrase> A=<nome> P=<projeto> sh iniciar.sh      # entra, instala toolchain, identifica
sh bin/protocolo.sh status                             # versão, cadeados, pendências
sh bin/reivindicar.sh E2                               # cadeado atômico (falha se já tomada)
# ... trabalho em commits pequenos; cada commit publica em refs/agents/<nome> ...
sh bin/liberar.sh E2 feita "docs/evidence/e4.md: PASS=21 FAIL=0"
sh bin/board.sh && git commit -am "board: E2" && sh bin/publicar.sh
```

O Integrador, periodicamente:

```sh
sh bin/integrar.sh          # merge das refs de agente, aborta se o teste falhar
```

## Proibições

- commit em `main`, `0`, `template` ou `backup` — são configuração, não projeto;
- tarefa fechada sem evidência;
- entrada sem hora (só data é inválida: não ordena eventos);
- blob > 5 MB no git (use `bin/artefatos.sh` + Release);
- `.gitignore` sem `.work/` e `.git-credentials`.

## Nomes de branch

```
p/<projeto>     projeto            (p/wwii, p/iaag)
meta/<papel>    papel              (meta/lider, meta/info, meta/pesquisador)
dado/<nome>     dados              (dado/imagem)
base            configuração        (era `0`; `0` continua válido)
```

`h.sh` não usa lista de exceções: o que não é `p/*` não é projeto. Branches antigas
sem prefixo continuam aceitas durante a migração (`bin/migrar-nomes.sh`).

## Arbítrio

Impasse que não converge em duas réplicas datadas: pare, registre em `DEBATE.md`,
peça decisão humana. O humano é o árbitro final — o protocolo não decide conteúdo,
só ordem.

## Mudanças da v3 (movido de AGENTS.md em 42d65cc)

A mecânica canônica está em `PROTOCOLO.md`. O que mudou na prática:

| Antes | Agora |
|---|---|
| `flock` local no `ETAPAS.md` | cadeado em `refs/claims/E<n>` — atômico entre hosts |
| push só na branch do projeto | cada commit também publica em `refs/agents/<nome>` (nunca conflita) |
| `HANDOFF.md` com `merge=union` | `HANDOFF.md` é snapshot (conflito explícito); recado por agente em `HANDOFF/<nome>.md` |
| `MURAL.md` sem união | `MURAL.md merge=union` (era o arquivo mais disputado) |

Comandos novos (a toolchain vem da branch `0` em `.work/bin/`, não é copiada aqui):

    sh bin/reivindicar.sh <ID>                     # cadeado do servidor
    sh bin/liberar.sh <ID> feita "<evidência>"     # solta o cadeado, com prova
    sh bin/publicar.sh                             # publica em refs/agents/<nome>
    sh bin/protocolo.sh status                     # versão, cadeados, pendências
    sh bin/metricas.sh                             # who/when/how long, derivado do git

`ETAPAS.md`, `MURAL.md` e `PROBLEMAS.md` continuam valendo: o cadeado mudou de lugar,
o log não. As regras inegociáveis estão em `PROTOCOLO.md`.
