# AGENTS

Regras padrão do repositório. Valem para tudo.

## Como agir
- Receber o link do repo já é instrução suficiente: não espere mais nada.
- Trabalhe na branch do projeto; nunca altere `main` nem `0`.
- AUTORIZAÇÃO TOTAL: use terminal, instale dependências, crie/edite arquivos, commit e push sem pedir permissão. **Não pergunte nada a ninguém** (ver "Autonomia total").
- Proativo e exaustivo: esgote opções, teste alternativas, registre falhas.
- Não pare cedo nem entregue só análise estática: execute o projeto.

## Persistência (a tarefa é possível)
- Existe um caminho: **nunca** conclua "impossível"/"não viável" por dificuldade. Trate cada restrição como desafio a vencer, não como barreira final.
- Esgote caminhos oficiais **e** criativos (contornos, fontes alternativas, engenharia reversa, recursos já presentes no ambiente). Vá além do óbvio.
- Declare bloqueio só com tentativas registradas E um caminho alternativo proposto; "não dá" sem isso é resposta inválida.
- Documente as barreiras, mas **nunca pare**: sempre siga para o próximo caminho.
- O problema é solucionável: não descarte o objetivo. Falta um dado? Derive-o sozinho ou assuma uma premissa, registre e siga.

## Autonomia total (sem depender de ninguém)
- O dono **não está disponível** e não fará nada: sem foto, sem rodar comando, sem responder, sem senha. Nenhum agente espera humano nem outro agente.
- **Proibido** escrever "o dono precisa X" como próximo passo ou bloqueio. Dado faltante (ex.: `VEN_/DEV_` do Wi-Fi) → obtenha no próprio ambiente (imagem WinRE, catálogo MS, logs, simulação) **ou cubra todas as hipóteses** (ex.: empacote drivers de todos os chips Wi-Fi/Bluetooth comuns e deixe o PnP escolher).
- Dúvida → adote a hipótese mais provável, registre em `HANDOFF.md` (seção Premissas) e avance; troque se a evidência contrariar.
- O entregável deve ser **autoexecutável** na máquina do dono: imagem/script que roda sozinho (sem digitar nada, sem entrada manual), detecta o hardware, tenta todos os caminhos e grava log. Tudo no repo, pronto para uso.
- Push: `h.sh` já configura o acesso com o que o ambiente fornece. Commit local não basta: se o push falhar, diagnostique, corrija e repita até passar.

## Ciclo mínimo
1. Inspecionar a árvore de arquivos.
2. Identificar stack e execução (`Makefile`, `Dockerfile`, `package.json`, testes).
3. Instalar, rodar, corrigir erros e repetir até validar.

## Ambiente de teste (novo a cada conversa)
- Cada rodada nasce num ambiente limpo: prepare-o com `sh setup.sh` (idempotente) antes de testar; não assuma estado herdado.
- Rode o que demora (baixar ISO, subir VM/serviço) **em segundo plano** com log: `nohup <cmd> > .work/logs/<nome>.log 2>&1 &`. Nunca fique travado esperando — acompanhe com `tail -f` e siga trabalhando.
- Detecte o que existe (qemu, kvm, docker, virtualbox) e adapte; se faltar, instale ou proponha alternativa.
- Se não der para simular o cenário real (ex.: driver Wi-Fi), simule o mais próximo possível e documente a diferença.

## Concluir apenas quando
- o problema estiver resolvido, OU
- o projeto estiver validado, OU
- houver bloqueio externo comprovado com evidência.

## Evidência
- Monte um ambiente de teste real e execute; documente comandos, saídas, erros e correções no repo.
- Pesquise a fundo (docs oficiais, fóruns) antes de concluir "impossível"; registre fontes.

## Escopo de leitura (contexto do planner)
- Leia sempre e nesta ordem: `PLANO.md` (direcao do lead) + `AGENTS.md` (contrato) +
  `PROMPT.md` (tarefa) + `HANDOFF.md` (estado atual). Fixo, ~15 KB, lido 1x por rodada.
- `PLANO.md` manda em caso de duvida de prioridade. Se estiver vazio/desatualizado, siga o `PROMPT.md` e registre a escolha no relatorio.
- `PROGRESS.md`, `CHAT.md` e `docs/evidence/` são append-only e crescem: nunca leia inteiro, só o fim (tail, ~20 linhas).
- `HANDOFF.md` é snapshot: reescreva-o ao **fim de cada rodada** (fase, próximo passo, bloqueios); não faça append.
- **Nunca leia a branch `relatorio` nem `RELATORIO.md`**: e o inbox do lead: escreva so pelo `relatorio.sh`, nunca leia. Voce nao
  precisa do que os outros relataram para trabalhar; ler custa contexto e contamina prioridade.
- Mantenha o repo mínimo: sempre que der para economizar contexto **sem perder qualidade nem fluxo**, enxugue e proponha a melhoria.

## Isolamento (não se contaminar)
- Trabalhe só neste diretório e nesta branch. Ignore outras branches e outros clones.
- Não leia `_archived/` nem arquivos compactados (`.bundle`, `.tar.gz`).
- Se o clone trouxer branches antigas, não as leia: use apenas a branch do projeto.

## Registro
- Nada só no chat: registre descobertas, decisões, estado e dúvidas nos docs do repo; sempre no fim, sem reescrever nem duplicar (máx. 500 caracteres por entrada).
- Chat vivo entre agentes (`CHAT.md`): escreva **1 linha só ao terminar a rodada** — `HH:MM <agente> <tag> msg` (tags `+` feito · `D` descoberta · `?` hipótese assumida · `!` bloqueio externo comprovado). Só append, nunca reescreva; leia só o fim (`tail -5 CHAT.md`). Vários agentes ao mesmo tempo não conflitam (`merge=union`). Se o push falhar, repita até passar.
- **RELATORIO.md = resumo executivo** (branch `relatorio`, so o lead le): desafio + estado + problemas dificeis + perguntas, <=2 KB. Atualize CONFORME os problemas surgirem com `sh scripts/relatorio.sh problema|pergunta|estado`; o lead le so isso, inteiro, sem investigar o repo.
- Identifique-se na entrada: `A=<nome> sh setup.sh` (sem isso o commit sai anonimo e o lead
  nao atribui o trabalho a ninguem).
- `PLANO.md` e do lead: o hook recusa edicao sem `LEAD=1`. Responda ao lead pelo relatorio.
- Mudou a base (este repo-template)? Espelhe na branch `backup` (ver skill `iniciar-projeto`).
- Responda em português. Commits pequenos e imediatos.

## Ritual de rodada (obrigatorio — e o que torna a orquestracao real)

```
# entrada (o iniciar.sh faz 1-3 sozinho)
sh iniciar.sh A=<nome> P=wwii S_ARQ=<arquivo-da-passphrase>
sh scripts/etapa.sh status            # o que ja esta tomado por quem
# trabalho: NUNCA edite etapa de outra pessoa nem PRESENCA.md a mao
sh scripts/etapa.sh fechar E<n> "<evidencia: caminho + saida>"
sh scripts/relatorio.sh estado "<status> + <obstaculo> + <proximo>"
A=<nome> sh scripts/agente.sh saiu    # bate-ponto de saida
```

Regras de convivencia:
- Etapa sem `fechar` com evidencia = nao concluida. O lead nao aceita "pronto".
- Duas reclamações simultaneas: a primeira no log ganha (lease de 90 min).
- `RELOGIO-SUSPEITO` no status = seu relogio esta adiantado/atrasado; ajuste antes de fechar.
- Obstaculo novo que ninguém previu: registre em `ETAPAS.md` (append) e siga — nao congele.

## Dever da imagem (regra de difusao)

Quem conseguir obter os executaveis da imagem **roda `sh scripts/dossie.sh` e comita
`docs/imagem/` antes de qualquer outra coisa**. O script anuncia sozinho na branch
`relatorio`. Motivo: a imagem demora ~4 min para baixar e nao persiste no sandbox;
sem o dossier, cada agente gasta a rodada dele descobrindo o que ja foi descoberto.
Se voce esta preso na E1, leia `docs/imagem/DOSSIE.md` e avance no raciocinio — a
E1 e infra, e o dossier existe justamente para voce nao esperar por ela.
