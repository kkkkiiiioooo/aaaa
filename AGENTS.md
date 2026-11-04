# AGENTS

Contrato único. Receber o repo já é a ordem: execute, não espere nada.

## Regras
- Trabalhe só na branch do projeto, neste clone. Nunca altere `main`, `0`, `backup`. Não leia `_archived/`, `.bundle`, `.tar.gz`, outras branches.
- Autorização total: terminal, instalar, editar, commit e push sem pedir. O dono não responde nem executa nada: não pergunte, não escreva "o dono precisa X".
- Dado faltante: obtenha no ambiente ou cubra todas as hipóteses (ex.: drivers de todos os chips comuns). Dúvida: adote a mais provável, registre em `HANDOFF.md` (Premissas), troque se a evidência contrariar.
- Nunca conclua "impossível". Bloqueio só com tentativas registradas + caminho alternativo proposto. Falhou: próximo caminho.
- O entregável roda sozinho na máquina do dono (sem digitar nada, detecta hardware, tenta tudo, grava log).
- Executar vale mais que analisar: monte o ambiente (`sh setup.sh`, idempotente), rode, corrija, repita até validar. Tarefa longa: segundo plano com log (`nohup <cmd> > .work/logs/<nome>.log 2>&1 &`), acompanhe com `tail`.
- Simule o mais perto possível o que não der para reproduzir e documente a diferença.

## Leitura (contexto mínimo, nesta ordem, ~9 KB)
`PLANO.md` (lead; manda na prioridade) · `AGENTS.md` · `PROMPT.md` · `HANDOFF.md`.
`PROGRESS.md` e `docs/evidence/` crescem: só o fim (`tail -20`). Nunca leia a branch `relatorio` nem `RELATORIO.md`.

## Escrita (para um leitor mais inteligente que você: só o que importa)
- Nada só no chat da sessão. Registre no repo, no fim do arquivo, sem duplicar, até 500 caracteres por entrada: descoberta, decisão, evidência (comando + saída).
- `HANDOFF.md` = snapshot: reescreva ao fim da rodada (fase, próximo passo, premissas, bloqueios). Sem histórico.
- `RELATORIO.md` = resumo executivo do lead (até 2 KB), só via `sh scripts/relatorio.sh estado|problema|pergunta`. Atualize quando o problema surgir.
- `PLANO.md` é do lead: o hook recusa sem `LEAD=1`. Fale com o lead pelo relatório.

## Rodada
```
sh iniciar.sh A=<nome> P=<projeto> S_ARQ=<arquivo-da-passphrase>   # entra e registra inicio
sh scripts/etapa.sh status                                          # quem tem o quê
sh scripts/etapa.sh pegar E<n>                                      # reclama (lease 90 min)
sh scripts/etapa.sh fechar E<n> "<evidencia: caminho + saida>"      # sem evidência não está feita
sh scripts/relatorio.sh estado "<provado + obstáculo + próximo>"
```
Commits pequenos e imediatos. O hook envia o push sozinho e grava em `PRESENCA.md`: `nome inicio <data UTC>` (ao entrar) e `nome push <data UTC> <sha>` (a cada push ok). Não edite `PRESENCA.md`. Push falhou (`.work/logs/push.log`): corrija e repita até passar; commit local não é entrega.
Duas reclamações da mesma etapa: vale a primeira. Obstáculo imprevisto: registre em `ETAPAS.md` (append) e siga.

## Imagem
Quem obtiver a imagem roda `sh scripts/dossie.sh` e comita `docs/imagem/` antes de tudo. Sem a imagem em disco: `docs/imagem/DOSSIE.md` e `zcat docs/imagem/winre-caminhos.txt.gz | grep -i <x>`.

## Concluir apenas quando
Resolvido, ou validado, ou bloqueio externo comprovado com evidência. Responda em português.
