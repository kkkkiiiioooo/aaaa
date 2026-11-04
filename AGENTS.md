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

## Leitura (contexto mínimo, nesta ordem, ~10 KB)
`sh scripts/plano.sh` (PLANO do lead, vive na branch `relatorio`; manda na prioridade) · `AGENTS.md` · `PROMPT.md` · `HANDOFF.md`.
`PROGRESS.md` e `docs/evidence/` crescem: só o fim (`tail -20`). Da branch `relatorio` só o PLANO, via `plano.sh`; nunca abra `RELATORIO.md`.

## Escrita (para um leitor mais inteligente que você: só o que importa)
- Nada só no chat da sessão. Registre no repo, no fim do arquivo, sem duplicar, até 500 caracteres por entrada: descoberta, decisão, evidência (comando + saída).
- `HANDOFF.md` = snapshot: reescreva ao fim da rodada (fase, próximo passo, premissas, bloqueios). Sem histórico.
- `RELATORIO.md` = índice do lead (até 2 KB), mantido por `relatorio.sh estado` e por `escalar.sh`. Não escreva problema direto nele.
- Sugestão de processo: `sh scripts/sugerir.sh perda|ideia "<texto>"` quando algo gastou rodada à toa. Só escreva; ninguém precisa ler.
- O PLANO é do lead (branch `relatorio`, só ele escreve). O lead só acessa essa branch: fale com ele pelo relatório.

## Cooperação (quadro único: PROBLEMAS.md)
- Início da rodada: `sh scripts/problema.sh abertos`. Destravar o que outro travou vale tanto quanto avançar a sua etapa.
- Travou? Antes de gastar: `problema.sh buscar <termo>` (reuse solução existente). Nada achado: `problema.sh novo "<título>: <contexto + evidência>"`.
- Cada falha: `problema.sh tentou <id> "<o que fez> -> <resultado>"`. Achou o caminho: `problema.sh resolveu <id> "<comando + prova>"`, para os outros reaproveitarem.
- 2 tentativas sem solução e sem `[LEAD]`: `sh scripts/escalar.sh <id> "<pergunta objetiva>" "<hipóteses não testadas>"`. Gera o dossiê do lead. A resposta vem no PLANO (seção Respostas), por id.

## Rodada
```
sh iniciar.sh A=<nome> P=<projeto> S_ARQ=<arquivo-da-passphrase>   # entra e registra inicio
sh scripts/plano.sh                                                 # direção do lead
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

## Decisão rápida (fluxograma — 10 s)

```
Qual é o estado do ambiente?  → sh scripts/doctor.sh --env
Qual etapa está livre?         → sh scripts/etapa.sh status
Estou bloqueado?               → sh scripts/problema.sh buscar <termo>
Preciso de driver?             → buscar_driver.py + VEN_ de docs/imagem/DOSSIE.md
Comunicar lead?                → sh scripts/relatorio.sh estado "<msg>"
Lease expirado de outro?       → sh scripts/watchdog.sh
```
