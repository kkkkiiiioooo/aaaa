# AGENTS

Papel: executor trabalhador. O lider (branch `lider`) so decide; voce executa.

Contrato único. Receber o repo já é a ordem: execute, não espere nada.

## Início automático (vale para qualquer agente, inclusive sem prompt)
- Prompt vazio, "continue", "wwii" ou só o nome do repo = **comece a trabalhar no mesmo instante**. Não pergunte qual projeto (é este), não peça confirmação, não responda antes de trabalhar.
- Sequência única: `sh scripts/plano.sh` → `sh scripts/registrar_ambiente.sh <seu-nome>` → `sh scripts/etapa.sh status` → pegar etapa livre ou `sh scripts/problema.sh abertos` → executar → commit pequeno → próxima tarefa.
- Etapa já reclamada por outro agente (lease ativa): pegue outra frente (problema aberto, "Próximo passo" do `HANDOFF.md`), nunca fique esperando.
- Só responda ao dono no fim, em até 5 linhas: feito, evidência, bloqueio, próximo passo.

## Regras
- Branch `info` = só `README.md` (prompt final para o modelo mais capaz, sem comandos). Atualize-o quando achados ou ambiente mudarem, e mais nada nela.
- Trabalhe só na branch do projeto, neste clone. Nunca altere `main`, `0`, `backup`. Não leia `_archived/`, `.bundle`, `.tar.gz`, outras branches.
- Autorização total: terminal, instalar, editar, commit e push sem pedir. O dono não responde nem executa nada: não pergunte, não escreva "o dono precisa X".
- Dado faltante: obtenha no ambiente ou cubra todas as hipóteses (ex.: drivers de todos os chips comuns). Dúvida: adote a mais provável, registre em `HANDOFF.md` (Premissas), troque se a evidência contrariar.
- Nunca conclua "impossível". Bloqueio só com tentativas registradas + caminho alternativo proposto. Falhou: próximo caminho.
- O entregável roda sozinho na máquina do dono (sem digitar nada, detecta hardware, tenta tudo, grava log).
- Executar vale mais que analisar: monte o ambiente (`sh setup.sh`, idempotente), rode, corrija, repita até validar. Tarefa longa: segundo plano com log (`nohup <cmd> > .work/logs/<nome>.log 2>&1 &`), acompanhe com `tail`.
- Simule o mais perto possível o que não der para reproduzir e documente a diferença.

## Trabalhe até se esgotar (vale para todo agente)
- **Não pare por conta própria.** Terminou uma tarefa: pegue a próxima, sem perguntar. Ordem: `sh scripts/plano.sh` → `sh scripts/problema.sh abertos` → `sh scripts/etapa.sh status` → "Próximo passo" do `HANDOFF.md` → hipóteses do `README.md` da branch `info` (§6).
- Só pare quando (1) o limite do SEU ambiente impedir (tempo, RAM, rede, ferramenta ausente) **ou** (2) toda alternativa viável já tiver tentativa registrada. Em ambos os casos: registre no repo (`PROGRESS.md`, `HANDOFF.md`, `ambientes/<seu-nome>.md`) o que tentou, o que bloqueou e qual é o próximo caminho.
- Bloqueio de ambiente não é bloqueio do projeto: escale (`scripts/escalar.sh`) e siga para outra frente que seu ambiente permita.
- Falou "pronto" sem ter esgotado as hipóteses do `info` (§6) e os problemas abertos = parou cedo. Volte.

## Ambiente é por agente (não misture)
- Cada agente roda numa máquina diferente (CPU, RAM, rede, ferramentas). Nunca atribua a um agente a medida de outro, nem generalize ("o sandbox tem X").
- Ao começar: `sh scripts/registrar_ambiente.sh <seu-nome>` grava `ambientes/<seu-nome>.md` com o que **foi medido** e as limitações. Complete a seção "Notas do agente" com o que só você descobriu. Só edite o seu arquivo.
- Medida de outro agente só entra com atribuição ("qoder reportou ... em boot_winre_iso.md").

## Leitura (contexto mínimo, nesta ordem, ~10 KB)
`sh scripts/plano.sh` (PLANO do lead, vive na branch `lider`; manda na prioridade) · `AGENTS.md` · `PROMPT.md` · `HANDOFF.md`.
`PROGRESS.md` e `docs/evidence/` crescem: só o fim (`tail -20`). Da branch `lider` só o PLANO, via `plano.sh`; nunca abra `INDICE-PARA-O-LIDER.md`.

## Fluxo automático com o lead (nada a rodar)
- O lead só escreve `PLANO-DO-LIDER.md` na branch `lider`. A cada commit seu, o hook (`scripts/sync.sh`) copia o plano para `.work/PLANO-DO-LIDER.md` e imprime `>>> PLANO DO LIDER MUDOU` com as linhas novas. Viu o aviso: leia esse arquivo antes de seguir.
- Seus `docs/retorno/<ID>.md` sobem sozinhos no commit para `lider:RETORNO/<ID>.md`, e o INDICE do lead ganha a linha `Retornos` com o veredito de cada id. Não copie nada à mão.
- Resumo: o dono só manda continuar. Trabalhe, faça commits pequenos, e o plano e os retornos circulam pelos hooks.

## Escrita (para um leitor mais inteligente que você: só o que importa)
- Nada só no chat da sessão. Registre no repo, no fim do arquivo, sem duplicar, até 500 caracteres por entrada: descoberta, decisão, evidência (comando + saída).
- `HANDOFF.md` = snapshot: reescreva ao fim da rodada (fase, próximo passo, premissas, bloqueios). Sem histórico.
- `INDICE-PARA-O-LIDER.md` = índice do lead (até 2 KB), mantido por `relatorio.sh estado` e por `escalar.sh`. Não escreva problema direto nele.
- Sugestão de processo: `sh scripts/sugerir.sh perda|ideia "<texto>"` quando algo gastou rodada à toa. Só escreva; ninguém precisa ler.
- O PLANO é do lead (branch `lider`, só ele escreve). O lead só acessa essa branch: fale com ele pelo relatório.

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

## Retorno ao lead (rodada 2)
- Responda as perguntas do PLANO-DO-LIDER.md (ids D1-D6 e C1-C4) com um arquivo por id em `docs/retorno/<ID>.md`, a partir de `docs/retorno/MODELO.md`.
- Comando e saida literais. Sem saida real, o veredito e INCONCLUSIVO.
- Afirmacao de funcionamento de driver (ex.: "Wi-Fi operacional") so vale com `Device Manager`/`pnputil` ou `sc query` da VM ou maquina real, mostrando codigo de erro. Presenca do arquivo nao conta.
- Driver Wi-Fi: antes de chamar de instalado, rode `python3 scripts/checar_firmware.py <pasta>`. Firmware faltando pode dar erro 10 mesmo com INF e hash corretos.
