Execute o arquivo helper h.sh.
Cada projeto é uma branch com o NOME do projeto, sem número (ex.: wwii, iaag, loja).
A main não é projeto.
Escolha a branch do projeto pelo nome. Números não são mais aceitos: P=4 responde com a lista.
Commit na main é bloqueado.
OK=1 só se o usuário pedir.
Se precisar da senha, peça ao usuário e guarde em S.
Se faltar o projeto, peça o nome (ex.: loja) e guarde em P; sem P o h.sh não entra na branch do projeto.
Exemplo: S=senha P=loja sh h.sh
Projeto novo só com criação explícita: NEW=1 P=loja sh h.sh (sem isso, nome
desconhecido é erro — assim dois agentes nunca abrem ramos paralelos sem querer).

## Regras da branch 0 (configuração)

- A branch 0 nunca deve ser apagada: ela é a configuração inicial e a base de tudo.
- A `main` nunca recebe commit — nem do setup. O `h.sh` antigo cometava `.agentignore` na
  `main` porque instalava o guard depois do commit; isso está corrigido aqui.
- A branch 0 nunca deve ser duplicada: ela possui os arquivos de configuração principal (AGENTS.md, h.sh, t.gpg).
- A main nunca deve ser alterada.

## Protocolo de enxame: vários agentes resolvendo juntos

O repositório é o canal de comunicação entre agentes: um arquivo lido equivale a uma
mensagem inserida no seu contexto; o histórico do git é a transcrição da conversa.
Não há coordenador: há um protocolo idêntico para todo agente, de qualquer provedor.

### Turno de trabalho (todo agente, sempre)

1. Entre no projeto: S=<senha> P=<nome> sh h.sh
2. Leia, nesta ordem: TASK.md, as últimas 20 linhas de PROGRESS.md, BOARD.md, HANDOFF.md.
3. Se o projeto ainda não tiver esses arquivos, rode:
   git show 0:enxame.sh > enxame.sh && NOME=<seu nome> sh enxame.sh
   (o script copia a si próprio ao projeto, cria os cinco arquivos num único
   commit com data e hora e faz o push).
4. Reivindique uma tarefa em BOARD.md: pull, marque "tomada" com seu nome e data+hora,
   commit imediato. O commit é o cadeado; se o push falhar por conflito, outro agente
   chegou primeiro: refaça o pull e verifique o BOARD.md.
5. Trabalhe em commits pequenos; cada commit publica automaticamente (hook post-commit).
6. Se discordar de outro agente, escreva uma réplica em DEBATE.md; nunca sobrescreva
   trabalho alheio.
7. Ao encerrar o turno: anexe uma entrada em PROGRESS.md e reescreva HANDOFF.md.

### Data e hora — obrigatórias

Toda entrada em PROGRESS.md, HANDOFF.md, BOARD.md e DEBATE.md deve ter data E hora,
no formato: YYYY-MM-DD HH:MM (UTC-3). Use: date '+%Y-%m-%d %H:%M'
Entrada sem hora é inválida: sem a hora, o próximo agente não consegue reconstruir
a ordem dos eventos entre turnos.

### Semântica dos arquivos do projeto

- TASK.md: o problema e critérios de aceitação verificáveis. Somente o humano edita.
- BOARD.md: quadro de tarefas: aberta -> tomada -> em revisão -> concluída | bloqueada.
- PROGRESS.md: diário coletivo. Apenas anexar; nunca editar o passado.
- HANDOFF.md: recado ao próximo agente; reescrito a cada turno.
- DEBATE.md: discordâncias com posições datadas; convergência registrada como
  "revogo minha posição" (nunca apagar a posição anterior).
- tests/: critério de verdade — toda alegação ("funciona", "está correto") exige um
  teste que qualquer outro agente consiga executar. Alegação sem teste é opinião.

### Identidade e papéis

- Assine todo commit com o trailer Agent-Name: <seu nome>; nunca finja ser outro agente.
- Declare seu papel na entrada de PROGRESS.md do turno: Explorador (decompõe o problema
  em tarefas), Implementador (código), Crítico (revisa e abre correções; nunca corrige
  diretamente), Integrador (único que faz merge, sempre com testes verdes).

### Arbítrio

Se um debate não convergir em duas réplicas: pare, registre o impasse em DEBATE.md e
aguarde a decisão humana. O humano é o árbitro final.

## Ramos que NÃO são projeto (o h.sh não os lista)
- `main` (só README), `0` (esta configuração), `backup` (arquivo morto), `imagem` (dados da imagem do Windows).
- `lider`: só o líder escreve o plano (`PLANO-DO-LIDER.md`); antiga `relatorio`.
- `info`: só `README.md`, o contexto completo para o modelo mais capaz (só pensa, não executa).
- `pesquisador`: só `PROMPT-PESQUISA.md` e o `RESULTADO-PESQUISA.md` de quem pesquisa.

## Regras para todo agente, em qualquer projeto
- **Trabalhe até se esgotar.** Não pare por conta própria: terminou uma tarefa, pegue a próxima. Só pare por limite do SEU ambiente ou com todas as alternativas viáveis já tentadas e registradas.
- **Ambiente é por agente.** Cada agente mede e anota o seu (`ambientes/<nome>.md` no projeto). Nunca atribua a um agente a medida de outro.
- Registre no repositório o que descobriu; nada fica só no chat.
