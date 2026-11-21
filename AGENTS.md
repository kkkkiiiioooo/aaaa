# Regras de agente

Leia estes arquivos antes de mudar qualquer coisa:

1. `GOAL.md`
2. `ANOTACOES-IMPORTANTES.md`
3. `docs/00-visao-geral.md`
4. `docs/01-restricoes.md`
5. `prompts/advisor-resposta.md` (orientação mais recente do advisor externo) e `prompts/advisor.md` (briefing) antes de propor ou executar mudanças de estratégia de recuperação.

## Restrições rígidas

- Não use nem assuma USB, SD, Ethernet, teclado físico ou abrir o dispositivo.
- Não assuma nenhum caminho de transferência de arquivos a partir do dispositivo. O dispositivo só consegue mostrar uma tela e aceitar entrada digitada.
- Não use integração de clipboard, pastas compartilhadas, `-virtfs`, 9p, transferência serial de arquivos ou portas redirecionadas do host no QEMU.
- O dispositivo não tem rede funcional (o Wi-Fi é o dispositivo quebrado). O único canal de entrada válido é texto digitado pelo teclado virtual da tela touch. O HTTP em modo usuário do QEMU é apenas uma linha de base de mecânica, não um canal de transferência do dispositivo. Veja a regra de canais abaixo e a seção Realidade dos canais em `GOAL.md`.
- O WinRE fornece apenas `cmd`. Não assuma PowerShell.
- Não apresente um resultado do QEMU como prova de hardware.
- Não reivindique que o rádio BCM4356 funciona, a menos que tenha sido verificado no dispositivo físico.

## Modelo de repositório e regra de branch (obrigatória)

Este é **um repositório git** com **uma branch de trabalho: `desafio`**. Todo agente
trabalha, commita e envia na `desafio`.

- **Agentes trabalham um de cada vez** (decisão do dono, 21/11/2026), todos na `desafio`, sem pasta própria. O trabalho vive nas pastas compartilhadas (docs, drivers, experiments, qemu, scripts). Não crie uma branch por agente nem por tarefa.

## Regra de sincronização (obrigatória)

Vários agentes compartilham a `desafio`. Mantenha-se atualizado e nunca sobrescreva o trabalho de outro agente.

- Antes de começar a trabalhar e antes de enviar: `git fetch origin desafio` e depois
  `git merge --ff-only origin/desafio`.
- Se a árvore divergir (commits locais mais novos commits remotos), integre com um merge
  (ou faça rebase dos seus commits locais). Resolva os conflitos; não descarte as mudanças
  de outro agente.
- Rejeição de push (non-fast-forward): fetch, merge e tente de novo.
- **Nunca** force-push, `git reset --hard` ou apague branches para "consertar" um problema de sincronização.
- `scripts/salvar.sh` usa `git add -A` por padrão; sempre passe caminhos explícitos para
  não preparar arquivos de outro agente nem artefatos gerados.

## Regra de coordenação (obrigatória)

Só um agente trabalha por vez: não há reivindicação de tarefas nem pasta por agente. Registre o estado em `TODO.md` e `experiments/README.md` e deixe tudo enviado antes de parar; o próximo agente começa pelo repositório.

## Regra de canais (obrigatória)

O dispositivo **não tem conexão de rede funcional**: sua única NIC, o Wi-Fi BCM4356,
é o dispositivo que falha com o erro 10. **Qualquer transferência de rede (HTTP, FTP,
SMB, ...) NÃO é um canal de dispositivo válido**, porque pressupõe uma conexão que
não existe. O endpoint HTTP do NAT em modo usuário do QEMU (`10.0.2.2`) funciona só
porque o QEMU emula uma NIC e1000 funcional; ele não modela o dispositivo e é apenas uma
linha de base de mecânica, nunca o canal de transferência da solução.

O **único canal de entrada válido é texto digitado pelo teclado virtual da tela
touch.** A carga útil entra como texto hexadecimal ou base64, digitada pelo teclado,
e é reconstruída como binário dentro do WinRE usando apenas as ferramentas presentes
lá (não assuma `certutil`, `curl` ou `bitsadmin`). A tela é o único canal de
saída. Edição do WIM no lado do host (servicing offline) é prova de mecânica em uma
cópia, não o método de transferência do dispositivo. Veja a seção Realidade dos canais de `GOAL.md`.

## Pensamento de solução (obrigatório)

O dono não é especialista técnico e não deve ter de inventar a abordagem. Os agentes devem
**propor soluções consistentes com as restrições de forma proativa**, não esperar que lhes digam
e não parar em "não dá para fazer". Antes de declarar um bloqueio, enumere opções e a
viabilidade de cada uma. Um dono leigo pensando numa abordagem que um agente esqueceu é um sinal
de pensar mais, não de delegar.

- **Advisor externo (caro, opcional):** para decisões complexas ou bloqueantes em que várias
  opções consistentes com as restrições precisam ser pesadas e a análise local não basta, consulte
  o subagente `advisor` do projeto (`.opencode/agents/advisor.md`, executa `scripts/advisor-request.py`
  contra o briefing em `prompts/advisor.md`; requer `COARENA_API_KEY`, custa tokens). Use-o
  com parcimônia para raciocínios de alto risco (ex.: reconstrução texto/binário, estratégia
  driver-nvram, trade-offs boot/servicing), não para tarefas rotineiras. Se indisponível, declare
  isso e siga com a melhor análise local.

- **Leia o inventário primeiro** (`docs/07-inventario-imagens.md`, `inventory/`). Saiba quais
  ferramentas realmente existem nas imagens antes de assumir um método (ex.: certutil / PowerShell /
  .NET / ADODB.Stream estão ausentes; a nvram é texto). As soluções devem usar apenas o que existe.
- **Enumere várias abordagens, inclusive as não óbvias:**
  - Emular um *dispositivo falso idêntico ao hardware real* (sobreposição do PCI ID) para que o driver
    real vincule e reproduza o sintoma do erro 10; vs. uma NIC substituta funcional para a demo da correção.
  - *Menor carga primeiro:* prove o canal com o menor arquivo significativo (a nvram em texto, 5361 B)
    antes do driver binário de ~1 MB.
  - *Carga mínima:* o dispositivo já tem os arquivos do driver; talvez só a nvram em texto precise
    cruzar. Encontre o mínimo que precise ser transferido.
  - *Canais alternativos:* investigue o Bluetooth (existe driver OEM; pilha ausente no WinRE) ou
    outros caminhos — verifique, não presuma.
  - *Reconstrução binária sem certutil:* encontre um método texto->binário com as ferramentas
    existentes (ex.: decodificação MSXML mais um sumidouro de escrita), ou evite a transferência binária por completo.
- **Separe as perguntas:** transferência/reconstrução do canal (hash) vs correção funcional (hardware)
  vs reprodução do sintoma (sintético). Não misture.
- **Seja honesto quanto à viabilidade:** KVM é velocidade, não um requisito rígido; o TCG consegue
  inicializar o Windows devagar. Diga o que está provado, o que é proposto e o que está bloqueado, com o motivo.
- Se travar, apresente 2-3 opções concretas com trade-offs e um próximo passo recomendado, em vez de
  um simples "impossível".

## Regras de driver

- O estado alvo do DriverStore está em `drivers/estado-dispositivo/`.
- A pasta Wi-Fi alvo é `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9`.
- O estado alvo tem quatro arquivos de driver e nenhuma nvram.
- O pacote OEM está em `drivers/mipad2-oficial/wifi/`.
- A hipótese de nvram está em `drivers/nvram-delta/`.
- Não adicione a nvram em `drivers/estado-dispositivo/`.
- O driver inbox 2017 é `1.558.53.25`. O driver OEM 2015 é `1.558.14.0`.
- O Windows prefere o driver mais novo. Remova o pacote inbox ou force o driver mais velho; adicionar só o pacote mais velho é insuficiente.

## Regra de persistência (obrigatória; substitui a antiga regra de "não commitar")

Todo agente roda em um **sandbox temporário**. Arquivos que só existem lá se perdem quando
a sessão termina, quando o crédito do LLM acaba, quando o sandbox é retomado ou quando o
contexto é compactado. Trabalho que não foi publicado é trabalho que nunca aconteceu.

O dono do repositório deu **autorização permanente (15/11/2026)**: commit e push
imediatos, em toda sessão, sem perguntar antes.

- Envie cada artefato concluído assim que ele existir — não no fim da sessão.
- Nunca deixe um script, documento, arquivo de evidência ou configuração apenas no sandbox.
- Se a sessão for interrompida no meio do trabalho, o que foi enviado sobrevive; o que não
  foi, se perde.
- Use `scripts/salvar.sh "mensagem" caminho...` (ou commit e push manualmente). O script
  comita, envia a branch atual e prova que o ref remoto aponta para `HEAD`.
- Anuncie o resultado: branch, hash do commit, confirmação do remoto. Um commit local não é entrega.
- Se um push falhar (crendenciais, limite de tamanho, rede), diga isso explicitamente e tente de novo; não
  relate o trabalho como concluído.
- Arquivos acima de 100 MiB são rejeitados pelo GitHub: divida em partes ou não versioná-los.
- Nunca escreva fora das pastas compartilhadas e de `/tmp`.

Regra prática: **se o trabalho valeria ser feito duas vezes, envie-o agora.**

## Regras de modificação

- Não modifique as partes versionadas dos WIMs. Remonte e modifique cópias em `qemu/work/` ou `/tmp`.
- Faça backup de qualquer WIM antes do servicing offline.
- O servicing offline é prova de mecânica no lado do host, em uma cópia, não o método de transferência do dispositivo. No dispositivo, a correção é comandos WinRE digitados (`pnputil`/`devcon`) mais uma carga que chega como texto digitado (veja a regra de canais).
- Não execute comandos destrutivos no hardware real sem autorização explícita do usuário.
- Não faça commit de WIMs gerados, imagens de disco, ISOs, logs ou segredos — a menos que a
  tarefa exija explicitamente o artefato no repositório (veja a regra de persistência e
  `winre-1809-oficial-intacta/README.md` para o caso de partes divididas).

## Regras de evidência

- **Testes simulados/simulados são INADMISSÍVEIS como prova.** Um teste que substitui o ambiente
  real por um mock, stub, fake ou algoritmo só-do-host NÃO é evidência de que a capacidade funciona.
  Pode ser usado apenas para desenvolver uma implementação, nunca para reivindicar um pass. O teste
  REAL deve ser executado no ambiente alvo (WinRE inicializado para as ferramentas no convidado;
  dispositivo físico para reivindicações de Wi-Fi/hardware). Rotule as verificações só-do-host
  explicitamente como `host-only / não é prova` e não marque um experimento como `passou` por causa delas.
- Registre comandos, saídas, hashes e carimbos de tempo.
- Use `experiments/templates/experimento.md`.
- Separe fatos observados de hipóteses.
- Marque as limitações do QEMU explicitamente.
- Atualize `ANOTACOES-IMPORTANTES.md` quando um fato mudar.
- Prove uma imagem dividida com `scripts/verify-images.sh` (uma linha por imagem, código de saída
  0/1). Não cole `SHA256SUMS` nem `SHA256SUMS.reassembled` na conversa para "conferir a olho":
  o script os lê, junta as partes e devolve o veredito. Toda pasta de imagem dividida deve carregar
  os dois `SHA256SUMS` (partes) e `SHA256SUMS.reassembled` (arquivo unido).

## Idioma

- O português é canônico para os arquivos técnicos voltados aos agentes.
- O português também é usado nos resumos para o usuário e no glossário.
- Mantenha nomes de arquivos e de scripts sem alterá-los (não renomeie arquivos).

## Escopo

Este repositório serve para montar o desafio e suas evidências. Não é uma licença para contornar as restrições declaradas nem para fabricar uma recuperação bem-sucedida.

## Resumo em português

Todo agente trabalha num ambiente temporário. O que não for enviado ao repositório
desaparece quando a sessão termina, quando os créditos do LLM acabam ou quando o sandbox
é reciclado. Por isso a regra de persistência acima é obrigatória e tem autorização
permanente do dono do repositório (2026-11-15): **faça commit e push imediatamente**, não
no fim. Use `scripts/salvar.sh "mensagem" caminho...`; ele faz commit, push do ramo atual
e confirma que o remoto aponta para o mesmo commit. Um commit local não é entrega. Se o
push falhar, diga isso claramente e tente de novo — não declare a tarefa concluída.
Para provar imagens divididas, rode `scripts/verify-images.sh`: ele junta as partes,
confere `SHA256SUMS` e `SHA256SUMS.reassembled` e imprime uma linha por imagem — não é
preciso colar hash nenhum no chat.
Estrutura: um único repositório, um único ramo de trabalho (`desafio`). Agentes
trabalham um de cada vez, sem pasta própria; o trabalho fica nas pastas comuns. Sincronize antes de começar e antes de enviar (`git fetch origin`
desafio` + `git merge --ff-only origin/desafio`); nunca force-push nem apague ramos. Como
só um agente trabalha por vez, não há reivindicação de tarefas: registre o estado em `TODO.md` e
`experiments/README.md`.
Regra prática: se o trabalho vale ser feito duas vezes, envie agora.
