# AGENTS

Regras padrão do repositório. Valem para tudo.

## Como agir
- Receber o link do repo já é instrução suficiente: não espere mais nada.
- Trabalhe na branch do projeto; nunca altere `main` nem `0`.
- AUTORIZAÇÃO TOTAL: use terminal, instale dependências, crie/edite arquivos, commit e push sem pedir permissão. Pergunte apenas o que depende do dono (hardware, preferências, dados reais).
- Proativo e exaustivo: esgote opções, teste alternativas, registre falhas.
- Não pare cedo nem entregue só análise estática: execute o projeto.

## Persistência (a tarefa é possível)
- Existe um caminho: **nunca** conclua "impossível"/"não viável" por dificuldade. Trate cada restrição como desafio a vencer, não como barreira final.
- Esgote caminhos oficiais **e** criativos (contornos, fontes alternativas, engenharia reversa, recursos já presentes no ambiente). Vá além do óbvio.
- Declare bloqueio só com tentativas registradas E um caminho alternativo proposto; "não dá" sem isso é resposta inválida.
- O dono conhece o problema e sabe que é solucionável: não descarte o objetivo — pergunte o que falta e siga.

## Ciclo mínimo
1. Inspecionar a árvore de arquivos.
2. Identificar stack e execução (`Makefile`, `Dockerfile`, `package.json`, testes).
3. Instalar, rodar, corrigir erros e repetir até validar.

## Concluir apenas quando
- o problema estiver resolvido, OU
- o projeto estiver validado, OU
- houver bloqueio externo comprovado com evidência.

## Evidência
- Monte um ambiente de teste real e execute; documente comandos, saídas, erros e correções no repo.
- Pesquise a fundo (docs oficiais, fóruns) antes de concluir "impossível"; registre fontes.

## Escopo de leitura (contexto do planner)
- Leia sempre: `AGENTS.md` (contrato) + `PROMPT.md` (tarefa) + `HANDOFF.md` (estado atual). Fixo, ~2,5 KB.
- `PROGRESS.md` e `docs/evidence/` são append-only e crescem: nunca leia inteiro, só o fim (tail, ~20 linhas).
- `HANDOFF.md` é snapshot: reescreva-o ao **fim de cada rodada** (fase, próximo passo, bloqueios); não faça append.
- Mantenha o repo mínimo: sempre que der para economizar contexto **sem perder qualidade nem fluxo**, enxugue e proponha a melhoria.

## Isolamento (não se contaminar)
- Trabalhe só neste diretório e nesta branch. Ignore outras branches e outros clones.
- Não leia `_archived/` nem arquivos compactados (`.bundle`, `.tar.gz`).
- Se o clone trouxer branches antigas, não as leia: use apenas a branch do projeto.

## Registro
- Nada só no chat: registre descobertas, decisões, estado e dúvidas nos docs do repo; sempre no fim, sem reescrever nem duplicar (máx. 500 caracteres por entrada).
- Mudou a base (este repo-template)? Espelhe na branch `backup` (ver skill `iniciar-projeto`).
- Responda em português. Commits pequenos e imediatos.
