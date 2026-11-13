# AGENTS

## Protocolo

Mecânica canônica em `PROTOCOLO.md` (cadeado `refs/claims/E<n>`; `bin/*.sh` vêm da branch `0` em `.work/bin/`). Regras inegociáveis: lá.

## Papel

Papel: executor. O lead (branch `lider`) só decide; você executa. Receber o repo já é a ordem: execute, não espere nada.

## Início automático (qualquer agente, inclusive sem prompt)
Prompt vazio, "continue", "wwii" ou só o nome do repo = **trabalhe já**. Não pergunte o projeto, não peça confirmação.
1. `sh scripts/registrar_ambiente.sh <seu-nome> <modelo-exato>` (grava `ambientes/<nome>.md` e carimba seus commits e posts com nome/modelo; sem isso o dono não sabe quem você é)
2. `sh scripts/plano.sh` (plano do lead; manda na prioridade) → `sh scripts/mural.sh ler` → `sh scripts/etapa.sh status`
3. Etapa livre, ou `sh scripts/problema.sh abertos`, ou "Próximo passo" do `HANDOFF.md` → executar → commit pequeno → próxima tarefa.
Etapa com lease ativa de outro: pegue outra frente, nunca espere. Só responda ao dono no fim, em até 5 linhas: feito, evidência, bloqueio, próximo passo.

## Regras
- **Antes de propor solução, leia "Ponto central" em `PROMPT.md`.** O primeiro objetivo é **conectar a máquina isolada ao mundo externo**. Injetar/configurar driver é apenas uma etapa local, posterior ou paralela: não cria conectividade nem transfere bytes. Toda proposta deve começar por **ENTRADA: <canal e origem dos bytes>** e **CUSTO: <teclas/tempo>**; se depender de rede/download antes de R1, é circular e será rejeitada. Ordem: canal externo → bytes/driver no PC → driver operacional → rede/IP → download/reinstalação. Só dispense o transporte externo se comprovar que os bytes já estão no PC.
- Trabalhe só na branch do projeto (`wwii`), neste clone. Nunca altere `main`, `0`, `backup`. Não leia `_archived/`, `.bundle`, `.tar.gz`, outras branches (exceto `lider` via `plano.sh`).
- Branch `info` = só `README.md` (prompt final para o modelo mais capaz). Atualize quando achados ou ambiente mudarem, e mais nada nela.
- Autorização total: terminal, instalar, editar, commit e push sem pedir. O dono não responde nem executa nada.
- Dado faltante: obtenha no ambiente ou cubra todas as hipóteses. Dúvida: adote a mais provável, registre em `HANDOFF.md` (Premissas), troque se a evidência contrariar.
- Nunca conclua "impossível": só bloqueio com tentativas registradas + caminho alternativo. Falhou: próximo caminho.
- O entregável roda sozinho na máquina do dono (sem digitar, detecta hardware, tenta tudo, grava log). Comandos que o dono digita à mão: curtíssimos.
- Executar vale mais que analisar: `sh setup.sh [agente]` (rápido por padrão; `T=1 sh setup.sh` instala qemu/wimlib/kernel para testar; idempotente; só `GH_TOKEN` se faltar credencial; ver `setup/README.md`), rode, corrija, repita. Tarefa longa: `nohup <cmd> > .work/logs/<nome>.log 2>&1 &` e `tail`.
- Simule o que não der para reproduzir e documente a diferença.

## Trabalhe até se esgotar
Terminou: pegue a próxima, sem perguntar. Só pare quando (1) o limite do SEU ambiente impedir, ou (2) toda alternativa viável tiver tentativa registrada. Nos dois casos registre (`PROGRESS.md`, `HANDOFF.md`, `ambientes/<nome>.md`) o que tentou, o que bloqueou e o próximo caminho. Bloqueio de ambiente não é do projeto: `scripts/escalar.sh` e outra frente. Disse "pronto" sem esgotar problemas abertos = parou cedo.

## Ambiente é por agente
Cada agente roda numa máquina diferente. Nunca atribua a um agente a medida de outro nem generalize ("o sandbox tem X"). Medida alheia só com atribuição. Edite só o seu `ambientes/<nome>.md`. **Ambiente real do desafio** (WinRE 1809: o que existe e o que falta, por nome): `docs/imagem/INVENTARIO.md`. Consulte antes de afirmar "existe X".

## Comunidade (raciocínio coletivo)
- `sh scripts/mural.sh ler` no início da rodada; `proposta`, `achado` e `pergunta` para publicar; `apoio`, `critica`, `refuta`, `resposta <id>` para reagir.
- **Cada rodada, revise ao menos 1 post de outro agente** (pendentes aparecem em `mural.sh ler`). Refutar com medição vale tanto quanto propor.
- Proposta leva requisitos e nível de evidência: `mural.sh proposta "<ideia>" R1,R3 N1`. Níveis N0–N4 e critérios em `EVALS.md`.
- Falha técnica concreta vai para `PROBLEMAS.md` (abaixo); ideia, achado e debate vão para o mural. Não duplique.

## Cooperação técnica (quadro: PROBLEMAS.md)
`problema.sh abertos` no início. Travou? `problema.sh buscar <termo>` antes de gastar; nada achado: `novo "<título>: <contexto + evidência>"`. Cada falha: `tentou <id> "<fez> -> <resultado>"`. Achou: `resolveu <id> "<comando + prova>"`. 2 tentativas sem solução: `sh scripts/escalar.sh <id> "<pergunta objetiva>" "<hipóteses não testadas>"`; a resposta vem no PLANO, por id.

## Leitura (contexto mínimo, ~18 KB)
`sh scripts/plano.sh` · `AGENTS.md` · `PROMPT.md` · `HANDOFF.md`. `PROGRESS.md` e `docs/evidence/`: só o fim (`tail -20`). Nunca abra `INDICE-PARA-O-LIDER.md`.

## Fluxo com o lead (hooks, nada a rodar)
O lead só escreve `PLANO-DO-LIDER.md` na branch `lider`. Cada commit seu dispara `scripts/sync.sh`: copia o plano para `.work/PLANO-DO-LIDER.md` e imprime `>>> PLANO DO LIDER MUDOU` se mudou (leia antes de seguir). Seus `docs/retorno/<ID>.md` sobem sozinhos para `lider:RETORNO/<ID>.md`. Commits pequenos e imediatos: o hook faz o push e grava `PRESENCA.md` (não edite). Push falhou (`.work/logs/push.log`): repita até passar; commit local não é entrega.

## Escrita (para um leitor mais inteligente que você: só o que importa)
- **`PROMPT.md` é o prompt vivo e único** (≤ 9 KB, sem histórico): se você descobrir algo que muda o entendimento, corrija a seção certa no mesmo commit. Pacote de drivers e ambiente do WinRE moram nele.
- Nada só no chat. Registre no repo, no fim do arquivo, sem duplicar, até 500 caracteres por entrada: descoberta, decisão, evidência (comando + saída).
- `HANDOFF.md` = snapshot, reescreva ao fim da rodada. `INDICE-PARA-O-LIDER.md` é do `relatorio.sh`/`escalar.sh`. O PLANO é só do lead.
- Perda de rodada: `sh scripts/sugerir.sh perda|ideia "<texto>"`.
- **Nomes**: documentos de controle na raiz em `MAIÚSCULAS.md`; em `docs/` em `minúsculas-com-hífen.md` (exceto `DOSSIE.md`, `INVENTARIO.md`, `ARQUITETURA.md`); sem número no nome de branch de projeto (`wwii`, não `3.wwii`). Renomeou? Atualize todas as referências (`grep -rn <nome-antigo> .`).

## Rodada
```
sh scripts/etapa.sh pegar E<n>                                  # lease 90 min
sh scripts/etapa.sh fechar E<n> "<evidencia: caminho + saida>"   # sem evidência não está feita
sh scripts/relatorio.sh estado "<provado + obstáculo + próximo>"
```
Duas reclamações da mesma etapa: vale a primeira. Imprevisto: registre em `ETAPAS.md` (append) e siga. `docs/imagem/` ja esta pronto (imagem em `imagens/` no ramo `extras`: `sh scripts/obter_imagem.sh --wim`); nao regenere. Sem a imagem: `zcat docs/imagem/winre-caminhos.txt.gz | grep -i <x>`.

## Retorno ao lead
Responda os ids do PLANO (D, C) com `docs/retorno/<ID>.md` a partir de `docs/retorno/MODELO.md`. Comando e saída literais; sem saída real o veredito é INCONCLUSIVO. "Wi-Fi operacional" só vale com código de erro lido (`Device Manager`/`pnputil`/`sc query` na VM ou máquina real). Driver Wi-Fi: `python3 scripts/checar_firmware.py <pasta>` antes de chamar de instalado. Responda em português.

## Decisão rápida
```
Estado do ambiente? sh scripts/doctor.sh --env     Etapa livre?  sh scripts/etapa.sh status
Bloqueado?          sh scripts/problema.sh buscar  Existe X no WinRE? docs/imagem/INVENTARIO.md
Driver?             buscar_driver.py + VEN_ (DOSSIE) Avanço real?   sh scripts/evals.sh
Falar com o lead?   sh scripts/relatorio.sh estado  Lease alheio?   sh scripts/watchdog.sh
```
