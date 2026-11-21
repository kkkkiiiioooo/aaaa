# Project documentation bundle

Generated from 31 markdown files (excluding .git, node_modules, symlinks).

---

## FILE: .opencode/agents/advisor.md

---
description: "Consulte PROATIVAMENTE para decisões complexas, de alto risco ou bloqueadas de recuperação MIPAD2/WinRE: canal de texto digitado, reconstrução binária sem certutil/PowerShell/ADODB, estratégia de driver/nvram, trade-offs de boot/servicing, ou quando várias opções consistentes com as restrições precisam ser pesadas. Executa o advisor externo Coarena (caro, precisa de COARENA_API_KEY) via scripts/advisor-request.py; use quando o raciocínio local for insuficiente, não para tarefas rotineiras."
mode: subagent
permission:
  edit: deny
  bash:
    "*": ask
    "scripts/advisor-request.py*": allow
    "./scripts/advisor-request.py*": allow
    "python3 scripts/advisor-request.py*": allow
    "cat prompts/advisor-resposta.md*": allow
    "readlink prompts/advisor-resposta.md*": allow
    "ls prompts/advisor-respostas*": allow
    "ls prompts/advisor-historico*": allow
    "ls prompts/advisor-anexos*": allow
---

Você é a ponte para o advisor externo Coarena (modelo padrão `gpt-6-astra`, esforço `low`). O prompt de briefing é `prompts/advisor.md`; as respostas são salvas como arquivos com timestamp em `prompts/advisor-respostas/` e a mais recente é vinculada em `prompts/advisor-resposta.md`.

Use este advisor para análises genuinamente complexas ou bloqueadas neste repositório; não o invoque para edições rotineiras, consultas simples ou quando a resposta já estiver clara na documentação. Se as credenciais não estiverem disponíveis, informe isso e siga com a melhor análise local.

Quando for invocado:
1. Determine o modelo solicitado (argumento posicional, ex. `gpt-6-sol`) e as opções (`--effort`, `--dry-run`, `--list-models`, `--attach-dir`, `--history-dir`, `--history-limit`, `--no-history`) a partir do pedido do usuário. Se não especificado, use os padrões.
2. O script anexa automaticamente todos os arquivos não ocultos de `prompts/advisor-anexos/` (coloque contexto como `docs/DOCS-BUNDLE.md` ou notas do dono lá) e inclui transcrições anteriores de entrada/saída de `prompts/advisor-historico/` como histórico de conversa. Ele também salva a transcrição de cada execução no diretório de histórico. Garanta que perguntas essenciais bloqueantes sejam respondidas em execuções de acompanhamento (anexos/histórico) em vez de serem repetidas.
3. Execute `./scripts/advisor-request.py [modelo] [opções]` a partir da raiz do repositório. O script carrega credenciais de `prompts/.advisor.env`, se presente. Se falhar por ausência de `COARENA_API_KEY`, informe isso claramente e pare.
4. Após uma execução bem-sucedida, leia `prompts/advisor-resposta.md` (ou o caminho salvo impresso pelo script) e devolva a resposta do advisor a quem chamou. Inclua o modelo, o esforço, o caminho do arquivo salvo e o uso de tokens, se relatado.
5. Para `--list-models` ou `--dry-run`, devolva a saída do comando.

Não invente respostas. Não edite arquivos do repositório além do que o script grava. Se o usuário pedir para mudar o briefing, informe que o arquivo do prompt é `prompts/advisor.md`.

---

## FILE: AGENTS.md

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

## Autorização: depuração do QEMU (dono, 21/11/2026)

O dono autorizou ler o código de parada (STOP code) do WinRE **dentro do QEMU**, só para diagnóstico: `-d` (logs do QEMU), `pmemsave`/`dump-guest-memory` pelo monitor, `-debugcon` e serial do kernel do convidado para um destino que o host lê. Isso não é canal de transferência: nada entra nem sai do dispositivo real. Continua proibido `-serial file:` como transferência (`qemu/audit.sh`). Todo resultado assim é `QEMU / não é prova de hardware`.

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

- **Só vale teste executado DIRETAMENTE no ambiente de recuperação (WinRE inicializado), no QEMU ou no
  dispositivo físico (decisão do dono, 21/11/2026).** Não crie nem mantenha testes simulados: mock, stub,
  algoritmo rodado só no host (python/node), convidado Linux no lugar do WinRE, edição de WIM no host
  apresentada como teste. Rotular como `host-only` não basta: não faça. Ferramentas e scripts que serão
  digitados/executados dentro do WinRE (`cscript`, `.js`, `.cmd`) são permitidos, mas só contam como
  funcionando depois de rodar no WinRE real, com a saída da tela registrada. Fatos lidos nos arquivos das
  imagens (inventário, `strings`) são observação, não teste, e podem ser registrados como tal.
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

---

## FILE: ANOTACOES-IMPORTANTES.md

# Notas canônicas

## Dispositivo e situação

- Xiaomi Mi Pad 2, x64.
- Windows 10 build 17763 estava instalado.
- O `C:` foi formatado rapidamente.
- O único ambiente Windows restante é a partição de recuperação no `D:`.
- Não é permitido USB, SD, Ethernet, teclado físico ou abrir o case.
- Canais disponíveis: tela, `cmd` do WinRE, Wi-Fi, Bluetooth, touch.
- **Realidade dos canais:** o dispositivo não tem rede funcional — o Wi-Fi BCM4356 é o dispositivo com o erro 10. O único canal de entrada válido é texto digitado pelo teclado virtual da tela touch (carga como hex/base64, reconstruída no WinRE). Rede/HTTP não é um canal válido do dispositivo; o HTTP em modo usuário do QEMU é só uma linha de base de mecânica. Edição do WIM no lado do host é prova de mecânica, não o método de transferência do dispositivo.
- O dispositivo não consegue enviar arquivos. Não há clipboard nem pasta compartilhada.

## Imagem fornecida

O repositório contém um WIM: a imagem de firmware de fábrica.

- Caminho: `winre-fabrica-10586-424MB/`.
- Tamanho do WIM: 444.856.529 bytes.
- Build: 10586.
- Arquitetura: x86_64.
- Idiomas: en-US, zh-CN, zh-TW.
- Edição: WindowsPE.
- Arquivos: 21.867.
- Diretórios: 4.593.
- Total de bytes: 2.234.709.726.
- Compressão: LZX.
- Boot index: 1.
- SHA-256 do WIM remontado: `152addc420748815c2cad90d382229e249ec853d3842531ddcc2b9998248067a`.
- Entradas do `FileRepository` no DriverStore: 752.

Pacotes Broadcom no DriverStore:

- `bcmdhd.inf_amd64_73691eb4230e8b44`
- `bcmdhd64.inf_amd64_284d283773fa4a7a`
- `bcmfn2.inf_amd64_a54399b6da2a3cc5`
- `bcmfn.inf_amd64_3bf62da6fe3a6002`

O WIM de firmware **não** contém `bcmwdidhdpcie.inf` e não contém um pacote Wi-Fi PCIe. Ele não consegue reproduzir a falha do driver PCIe de 2017 sem injetar esse pacote.

Nenhum arquivo de nvram foi encontrado no WIM de firmware.

O WIM de firmware tem 444.856.529 bytes, maior que a partição de recuperação de cerca de 398 MB. Ele não pode substituir o `D:` como está.

## Estado alvo do DriverStore

Caminho: `drivers/estado-dispositivo/`.

O estado alvo é mantido como o pacote 2017 quebrado. A imagem original dele não está mais no repositório.

Nomes exatos:

- `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9` — quatro arquivos.
- `bcmdhd64.inf_amd64_e0bae6831f60ea5f` — cinco arquivos.
- `bcmfn2.inf_amd64_5ebadf201c5b5845` — dois arquivos.

Arquivos Wi-Fi alvo:

- `bcmwdidhdpcie.inf`
- `bcmpciedhd63.sys`
- `4356a2rtecdc.bin`
- `43596a0rtecdc.bin`

A pasta Wi-Fi alvo não contém um arquivo de nvram. O firmware 4359 permanece na mesma pasta porque o estado do DriverStore alvo é mantido idêntico.

O manifesto de checksums está em `drivers/estado-dispositivo/SHA256SUMS`; é um artefato do repositório, não parte do DriverStore.

## Versões de driver

- Pacote 2017 quebrado: `bcmwdidhdpcie.inf`, versão `1.558.53.25`, data `21/04/2017`.
- Pacote OEM: `oem25.inf`, versão `1.558.14.0`, data `23/12/2015`.
- Ambos usam `bcmpciedhd63.sys`.
- O pacote 2017 tem duas seções de dispositivo: `PCI\VEN_14E4&DEV_43EC` (BCM4356) e `PCI\VEN_14E4&DEV_4355` (BCM4359).
- O pacote OEM cobre mais dispositivos, incluindo `PCI\VEN_14E4&DEV_43EC`.
- O pacote OEM inclui a linha de nvram: `4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6`.
- O pacote 2017 não inclui essa linha de nvram.

## nvram

- Origem: `drivers/mipad2-oficial/wifi/bcm94356wlpagbl_P3_150828M.txt`.
- SHA-256: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
- Tamanho: 5.361 bytes.
- A cópia hipotética é `drivers/nvram-delta/4356r2nvram.txt`, idêntica byte a byte à origem.
- O driver procura `\SystemRoot\system32\drivers\4356r2nvram.txt`.
- A nvram não está no estado alvo do DriverStore.
- A nvram não está presente no WIM de firmware.

## Problema conhecido

- O Wi-Fi do Mi Pad 2 reporta o erro 10 (`ConfigManagerErrorCode=10`, dispositivo não inicia) depois que o pacote PCIe de 2017 é usado.
- O Microsoft Q&A documenta o mesmo sintoma e a solução de contorno: selecionar manualmente o driver Broadcom 2015 mais velho.
- O Windows classifica o driver 2017 mais novo acima do pacote de 2015. Adicionar o pacote mais velho sem remover ou forçar o mais novo não basta.
- O usuário lembra que a seleção manual do driver restaurou o Wi-Fi depois da atualização.

## Hipóteses

### H2 — regressão de versão de driver (primária)

O pacote PCIe 2017 é a causa. Removê-lo e instalar o pacote OEM 2015, incluindo a sua nvram, é a correção principal.

### H1 — nvram ausente (secundária)

A nvram da placa está ausente do estado do DriverStore alvo. Sem ela, o download do firmware pode falhar mesmo com o driver correto. A nvram pode precisar ser fornecida separadamente se a instalação do pacote OEM não a copiar.

## Fidelidade

- F1 — linha de base do firmware: WIM de firmware de fábrica como está. Ele não tem `bcmwdidhdpcie.inf`; não consegue reproduzir o erro 10.
- F2 — estado sintético funcional: WIM de firmware + pacote alvo PCIe 2017 injetado + pacote OEM 2015 + nvram. É uma aproximação, não a partição de recuperação real, e o build é 10586.
- F3 — WIM real do dispositivo: a imagem real de recuperação de cerca de 398 MB. Indisponível.

A imagem real de 398 MB só foi vista na tela do dispositivo e não pode ser transferida. Não a exija para o F2.

Estas são definições de teste. Elas não afirmam a origem do pacote 2017 nem do WIM de firmware.

## Estado das evidências

Verificado pelo conteúdo:

- O WIM de firmware contém bcmdhd, bcmdhd64, bcmfn2 e bcmfn.
- O WIM de firmware não contém `bcmwdidhdpcie.inf`.
- Os arquivos do estado alvo estão presentes com os hashes em `drivers/estado-dispositivo/SHA256SUMS`.
- Os valores de metadados do WIM de firmware registrados acima.

Não verificado:

- A origem do WIM de firmware. O usuário relata que é a recuperação de fábrica; nenhum hash de referência independente foi comparado.
- A origem do pacote PCIe 2017 mantido no estado alvo.
- Se a partição real de cerca de 398 MB pode ser aproximada pelo F2.
- Se o pacote 2017 é original ou foi montado de outra fonte.

Consequência: F2 é um estado funcional sintético, não uma reprodução da partição de recuperação real. Rotule-o assim em cada experimento.

## Regra de evidência (dono, 17/11/2026)

- Testes simulados, simulados ou só-do-host são **inadmissíveis como evidência**. Eles podem orientar
  a implementação, mas nunca contam como pass. Uma capacidade é provada só executando o
  teste real no alvo: WinRE inicializado para as ferramentas no convidado, dispositivo físico
  para Wi-Fi/hardware. As ferramentas de preparação do host devem ser rotuladas `host-only / não é prova`.

## Limitações do QEMU

- O QEMU não emula o rádio BCM4356.
- O QEMU não consegue reproduzir o erro 10.
- O QEMU pode provar preparo de driver, remoção de driver, posicionamento de arquivo e uma carga entrando no convidado como texto digitado (reconstruída no convidado). O canal HTTP/modo usuário é só linha de base de mecânica, não o canal do dispositivo.
- A validação no hardware exige que o usuário leia a tela e digite comandos; sem transferência de arquivos.
- **Corrigido em 16/11/2026:** o "WinRE alcança o kernel e dá BSOD sob TCG, sem diagnóstico"
  registrado antes foi um erro de leitura. Observado no ISO do WinRE 1809 oficial com `-cpu qemu64` e
  `-cpu max`: uma falha do Windows Boot Manager, `File: \EFI\Microsoft\Boot\BCD`,
  `Status: 0xc000000f` — o kernel nunca é carregado. A causa era o `qemu/build-iso.sh`
  colocando o BCD só no lado ISO9660 em vez de dentro da imagem ESP El Torito;
  corrigido. Consequência: modelo de CPU e velocidade do TCG **não** eram o bloqueador do boot do WinRE, então
  o E3b deve ser repetido contra o ISO corrigido antes de qualquer conclusão sobre o TCG.
  Veja `experiments/E1-winre-boot-tcg.md`.
- **A memória do ambiente é pequena demais para as duas imagens WinRE versionadas.** Um WIM do WinRE é expandido
  num disco em RAM que também hospeda o sistema em execução. `wimlib-imagex info` dá
  Total Bytes 2.169.435.125 (2,02 GiB) para o WinRE 1809 e 2.234.709.726 (2,08 GiB) para a
  imagem de fábrica 10586, enquanto `qemu/run-winre.sh` e `qemu/run-winre-disk.sh` fixam
  `-m 2048`. 2 GiB não seguram um ramdisk de 2,02 GiB mais o SO vivo, então esse boot falha por
  aritmética, independentemente de modelo de CPU, chipset ou controladora de storage. Use `-m 4096` ou mais.
  O `boot.sdi` na imagem é um template em branco (`$SDI0001`, descritor MBR zerado), então ele não é o fator limitante.
- A mídia de volume único FAT32 de `qemu/build-disk.sh` alcança o Windows boot manager
  (`BdsDxe: starting Boot0002 "UEFI QEMU HARDDISK"` e então o loader roda); o ISO El Torito
  de `qemu/build-iso.sh` não alcançava, até o BCD dele ser colocado dentro da imagem ESP, e mesmo
  assim parava em `0xc000000f` "a required device isn't connected". Prefira a mídia em disco.

## Estado do repositório

- Branch: `desafio`.
- Commit inicial: `2b51dd0`.
- O repositório foi montado a partir do conteúdo da branch inicial.
- Nenhuma imagem completa do Windows está presente.
- O único WIM versionado é a imagem de firmware de fábrica.
- Nenhum experimento do QEMU foi executado como parte da base.
- Persistência: o dono deu autorização permanente para commit e push imediatos na `desafio` (veja a regra de persistência do `AGENTS.md`). A antiga regra de "sem commit sem pedido" foi substituída.

## 16/11/2026 — Fatos dos binários + causa-raiz da mídia PCAT (qoder)

- O caminho de busca da nvram agora está provado a partir dos binários, não dos nomes de arquivo: AMBOS os builds de `bcmpciedhd63.sys`
  contêm `\SystemRoot\system32\drivers\%04Xr%dnvram.txt` (+ o template de firmware e a
  string `dongle nvram file download failed`). Para o chip 0x4356 rev 2 → `System32\drivers\4356r2nvram.txt`.
- Na imagem de fábrica o driver Broadcom está **preparado, não implantado**: `System32\drivers` tem 295
  `.sys` e nem `bcmpciedhd63.sys` nem o firmware renomeado está entre eles. A carga mínima de
  runtime é, portanto, provavelmente 2 arquivos (firmware 0,64 MB + nvram de 5.361 B), talvez 3. Uma única
  listagem do dispositivo decide: `dir C:\Windows\System32\drivers\4356*`.
- `devcon.exe` NÃO está no WinRE; `pnputil.exe`, `dism.exe`, `drvload.exe`, `cmd.exe` ESTÃO, e o
  hive SYSTEM está no WIM. Qualquer sugestão de documento de `devcon update` precisa da ferramenta trazida de fora.
- Duas armadilhas para os outros agentes: o INF do inbox é UTF-16LE (grep sem `iconv` dá um zero falso),
  e o `wimlib-imagex update` carimba `Last Modification Time`, então hashes de contêiner não se reproduzem
  entre reconstruções — fixe os digests só no build final.
- **Causa-raiz PCAT do E1b encontrada (bug de mídia, não do QEMU):** células I/J/L param todas no SeaBIOS
  "Booting from DVD/CD..." com uma tela idêntica bit a bit (`compare -metric AE` = 0). Eliminado:
  prompt `bootfix.bin` (J), `-boot-load-size 8` (L). A árvore não tinha `boot\pcatboot.wim` — o
  ambiente de boot BIOS que o `etfsboot` realmente carrega. `/Windows/Boot/PCAT/bootmgr` existe dentro do
  WIM WinRE, então o `build-pcat-iso.sh` agora o captura em `boot/pcatboot.wim` (383.032 B); a célula M
  testa essa mídia.

## 16/11/2026 — E1b estado da matriz (qoder), células I a T

- PCAT/SeaBIOS: 7 variantes de mídia (I/J/L/M/N/O/P) param todas no MESMO frame bit-idêntico
  "Booting from DVD/CD..." (`compare -metric AE` = 0). Eliminado: bootfix.bin, `-boot-load-size 8`,
  ausência de `boot\pcatboot.wim`, nomes minúsculos no descritor primário, LZX vs none, layout
  interno do pcatboot.wim. Suspeita restante: formato/offset da boot info table que o xorriso escreve
  vs. o que `etfsboot.com` espera. Não é caminho promissor sem uma mídia de referência do oscdimg.
- UEFI com a mídia oficial (`build-efi-dvd-iso.sh`, `-e boot/efisys.bin`): é a primeira
  mídia desta matriz que faz o stub da Microsoft rodar e imprimir "Press any key to boot from CD or
  DVD……". Com tecla injetada pelo monitor (`KEY_AT`/`KEY_TIMES` no `e1-run.sh`) o erro muda de
  `Time out` para `BdsDxe: failed to start Boot0001 … No mapping` (células S e T). Injetar o BCD
  dentro da própria ESP do efisys.bin (célula T) não muda nada → a falha é anterior ao BCD.
- Alvo exato da próxima célula (lido do `xorriso -help`, não chutado): `-as mkisofs` não aceita
  `--efi-boot-image`, mas o modo nativo aceita `-boot_image any efi_boot_part=--efi-boot-image`.
  Antes de dar boot, conferir o GPT: a partição 1 tem que ter o GUID do ESP
  `C12A7328-F81F-11D2-BA4B-00A0C93EC93B`; `-isohybrid-gpt-basdat` produz o GUID de Basic Data, que
  não serve.
- Nada aqui é evidência de hardware: nenhum convidado chegou ao kernel.

## Referências

- Microsoft Q&A: https://learn.microsoft.com/en-us/answers/questions/2779164/broadcom-802-11ac-wireless-pcie-cant-be-started-af
- Microsoft Update Catalog: https://www.catalog.update.microsoft.com/Search.aspx?q=Broadcom%20BCM4356
- Origem OEM: https://github.com/brianwoo/mipad2-win10-howto
- Evidência local de drivers: `drivers/README.md`, `drivers/nvram-delta/README.md`, `docs/03-driver-wifi-erro-10.md`.

## Verificações técnicas abertas

- Confirmar o resultado offline exato de injetar o pacote PCIe 2017 no WIM de firmware.
- Confirmar o resultado offline exato de remover `bcmwdidhdpcie.inf` do WIM modificado.
- Confirmar se a instalação PnP copia `4356r2nvram.txt` para `System32\drivers` no WinRE modificado.
- Confirmar se o driver 2015 inicia no WinRE no hardware.
- Confirmar o caminho final de instalação do Windows sem uma imagem completa.

## 16/11/2026 — E7 sumidouro de escrita binária (stackai)

- Sem sumidouro binário clássico em nenhuma imagem do WinRE (`certutil` / PowerShell / .NET / ADODB / CDO / WIA / makecab / tar / zipfldr ausentes).
- Não é prova de hardware. Nvram-primeiro (texto) ainda evita a transferência binária.
## 2026-11-17 — E1b células U e V: hipótese do GPT eliminada e o console que já estava ali (qoder)

- **Célula U (mídia híbrida de verdade).** `HYBRID=1` no `build-efi-dvd-iso.sh` usa o frontend
  nativo do xorriso (`efi_boot_part=--efi-boot-image`, `partition_offset=16`,
  `partition_table=on`). Mídia: `qemu/work/winre-efidvd-u.iso` 273.022.976 B sha256
  `2ca259ce89063afa…`. Como `gdisk`/`parted` não existem no sandbox, a tabela foi conferida
  byte a byte: MBR protetor (tipo 0xEE) + GPT com partição 1 de GUID
  `C12A7328-F81F-11D2-BA4B-00A0C93EC93B` cobrindo exatamente o `efisys.bin` (setores 484–3363).
  Resultado no convidado: **o mesmo `BdsDxe: failed to start Boot0001 … : No mapping`**. A
  hipótese "o `EFI_NO_MAPPING` vem de a ESP não ser uma partição GPT do tipo ESP" está eliminada.
- **Correção ao registro anterior.** Eu havia anotado que as células S/T terminavam em `No
  mapping`. Relendo as sequências de frames (`e1-S/frame-65`, `e1-U/frame-40+`, `e1-V/frame-55+`),
  S, U e V caem todos no **UEFI Interactive Shell v2.2 com `FS0:` = o CD**
  (`PciRoot(0x0)/Pci(0x1,0x1)/Ata(0x0)/CDROM(0x0)`). Ou seja: já existia um console de texto
  interativo nesta matriz e eu o estava tratando como tela morta. As 8 linhas `Shell>` extras são
  os 8 `ret` que o loop `KEY_AT`/`KEY_TIMES` enviou, não saída.
- **Célula V.** `EFI_BOOT_COPY=1` expõe `\EFI\BOOT\BOOTX64.EFI` também na árvore ISO9660/Joliet
  (mídia 274.530.304 B sha256 `16a5e4efbdc00399…`). A tela final é bit-idêntica à da célula U
  (`compare -metric AE -fuzz 5%` = 0), como esperado: a opção Boot0001 aponta para a ESP, então a
  cópia não muda o que o BdsDxe resolve. O que muda é o que o **shell** consegue alcançar, porque
  `FS0:` é o volume ISO9660 e a ESP dentro de `efisys.bin` não é montada por ele.
- **Ferramenta nova para o console.** `keys.py` traduz texto literal em `sendkey`
  (um por caractere) e os knobs `TYPE_AT`/`TYPE_FILE`/`TYPE_GAP` no `e1-run.sh` digitam cada linha
  de um arquivo no prompt. Canal: teclado apenas — `qemu/audit.sh` continua PASS. Detalhe medido:
  dois-pontos é `shift-semicolon`, não `shift-2`; na sonda ao vivo o convidado ecoou `fs0@`, que
  é exatamente o tipo de bug de mapeamento que se leria como "o shell não tem FS0:".
- **Célula W (em execução).** mesma mídia V, sequência `e1-w-shell.txt`:
  `fs0:` → `ls efi\boot` → `ls efi\microsoft\boot` → `\efi\boot\bootx64.efi`. O que se testa é se o
  bootmgr da Microsoft carrega quando o caminho vem do FS0: em vez da opção de boot do firmware.
- Nada aqui é evidência de hardware: nenhum convidado chegou ao kernel do Windows.

## 2026-11-17 — E1b: o console interativo existe e o `FS0:` não é o que se pensava (qoder)

- **Console de texto interativo confirmado sob TCG.** Com `keys.py` (texto literal →
  `sendkey`) e os knobs `TYPE_AT`/`TYPE_FILE`/`TYPE_GAP` do `e1-run.sh`, o UEFI Interactive Shell
  aceita comandos digitados, ecoa e mostra a saída. Células W e X: `fs0:` muda o prompt para
  `FS0:\>`; `ls efi\boot` lista; `\efi\boot\bootx64.efi` executa e volta ao shell (provado pelo
  `echo voltou-do-bootx64`). Canal: teclado apenas; `qemu/audit.sh` continua PASS.
- **Método novo, obrigatório:** o shell do EDK2 limpa a tela quando uma aplicação termina. A
  célula W, que dumpava um frame por rodada, terminou com duas linhas `FS0:\>` e nada mais —
  evidência ambígua. Por isso o runner agora dumpa **um frame por linha digitada** (`cmd-<n>.png`).
- **Descoberta decisiva (célula Y).** `map` mostra só `FS0:` (alias `CD0c0::BLK1:`) e `BLK0:`; e
  `ls` na raiz de `FS0:` tem exatamente uma entrada: `<DIR> EFI`, carimbada 09/14/2018. Ou seja,
  **o único filesystem montado é o ESP de 1.474.560 B que vem do `efisys.bin`** (imagem FAT da
  Microsoft, que só contém `\EFI\BOOT\BOOTX64.EFI`), e o volume ISO9660 de 261 MB — onde moram
  `\sources\boot.wim` e o `\EFI\MICROSOFT\BOOT\BCD` da nossa árvore — nunca é montado.
- **O que isso derruba:** (a) `EFI_BOOT_COPY=1` da célula V nunca teve efeito, pois copia para um
  volume que ninguém lê; (b) o `No mapping` das células S/U/T não era o único obstáculo — mesmo um
  boot option bem-sucedido cairia num filesystem sem `boot.wim`; (c) o E3b continua dependendo
  de resolver isto, porque sem `boot.wim` acessível não há `cmd`.
- **Duas células isolando as variáveis restantes:** AA = mesma árvore com BCD dentro do ESP
  (`ESPBCD=1`) e SEM tabela de partições (conferido: sem `EFI PART` em LBA 1, MBR@0 `0000`), para
  ver se o `partition_offset=16` do híbrido era o que suprimia a montagem do ISO9660; Z = híbrida
  com BCD no ESP, lançando o bootmgr do shell com rajada de teclas (`!burst`), porque o bootmgr
  imprime `Press any key to boot from CD or DVD……` e sai quando nada chega.
- Nada aqui é evidência de hardware: nenhum convidado chegou ao kernel do Windows.

## 2026-11-17 — E1b: a linha do ISO EFI fecha; o azul não é artefato de captura (qoder)

- **Célula AC — a rajada densa não abre a porta do "pressione qualquer tecla".** `keyspam-dump.py`
  injetou **5.117 espaços em 902 s (5,68 teclas/s)** começando ~0,2 s depois do Enter que lançou
  `\efi\boot\bootx64.efi`. O cursor do shell avançou **+17 colunas por frame, sempre, desde o
  primeiro frame** — quem consumiu as teclas foi o shell, então o bootmgr já tinha desistido antes
  dos 31 s do primeiro frame. Os pixels de `Press any key to boot from CD or DVD……` que sobrevivem
  até o frame 003 são resíduo subindo na tela (o prompt passa de y=540 para y=198), não uma janela
  viva. Fica de pé a leitura (b): o bootmgr limpa a fila de entrada ao começar (`ResetEngine`), e
  nada de teclado resolve isso. Como a porta é propriedade de mídia de **CD**, a linha do ISO EFI
  para aqui.
- **Medido de quebra:** o convidado ecoou ~0,55 caractere/s enquanto injetávamos 5,68 teclas/s.
  ~90% dos eventos não chegam ao console sob TCG. Ninguém deve apostar em "segurar uma tecla".
- **Célula AD — o azul chato é real.** `-vga ramfb` não existe neste QEMU 6.2 (visto com `-vga
  help`), então o runner ganhou `VGA_DEV` (`-vga none -device X`). Com `-device bochs-display` e o
  disco `winre.img` das células E–H: t=20 s texto do `BdsDxe` + **logo TianoCore** (66 cores),
  t=40 s e t=60 s **uma única cor** `srgb(32,103,178)` cobrindo os 786.432 px, e o QEMU saiu com
  **código 0** (desligamento pedido pelo convidado) mesmo com `NOREBOOT=0`. O mesmo dispositivo
  mostra texto e modo gráfico: a captura acompanha o convidado. O azul não é quadro velho.
- **Célula AE — o shell do WinPE nunca é alcançado.** `build-cmd-media.sh` troca,
  dentro do `boot.wim`, o `winpeshl.ini` que aponta para `X:\sources\recovery\recenv.exe` por
  `AppPath=X:\Windows\System32\cmd.exe`. Resultado idêntico ao AD. Logo o azul é pintado **antes**
  do `winpeshl.exe` — por `winload` ou pelo kernel, não pela interface de recuperação. (Também
  conferido: o `boot.sdi` dos nossos WIMs é o arquivo Microsoft real de 3.170.304 B com imagem GPT
  dentro, não um template vazio.)
- **Célula AF — a localização decisiva.** Renomeando `sources\boot.wim` na mesma mídia, a mesma
  máquina e o mesmo dispositivo de vídeo mostram uma tela **perfeita de texto**: `Windows Boot
  Manager` … `Status: 0xc000000f` … `Info: A required device isn't connected or can't be accessed`
  com `ENTER=OS Selection  ESC=UEFI Firmware Settings`. Consequências: (1) o bootmgr renderiza texto
  por esse mesmo caminho de captura, então "sem texto porque a fonte/captura falha" está morto;
  (2) a tela de erro do bootmgr é preta com texto, não azul — o azul só aparece quando o
  `boot.wim` **existe**, ou seja, depois da entrega do bootmgr para o `winload`; (3) essa tela fica
  esperando tecla e ainda assim o convidado se desliga em ~45 s, então o desligamento não é evidência
  extra sobre o azul.
- **O que pedir ao dono agora:** para ler o stop code real faltaria um canal de debug (serial do
  kernel, `pmemsave`, ou logs `-d` do QEMU) — nada disso está autorizado ainda. Enquanto isso, o
  eixo hardware continua sendo testado sem isso: célula AG (`q35` + `-cpu max`, controladora
  AHCI em vez de IDE).
- Nada aqui é evidência de hardware: nenhum convidado chegou a um console do Windows.

## 2026-11-17 — E1b: células AH e AJ fecham o que dá para testar sem canal de debug (qoder)

- **AH — tirar o `winload.efi` de dentro do ramdisk não muda nada.** `build-nowl-media.sh`
  apagou os dois caminhos que a imagem traz (`\Windows\System32\Boot\winload.efi` e
  `\Windows\System32\winload.efi`); a mídia `winre-nowl.img` (`d53f813a…`) deu o mesmo azul
  `srgb(32,103,178)` em t=30 s e t=45 s e `exit code 0` aos 60 s. Lido com cuidado, isso não prova
  que a falha é depois do winload: prova que, **nessa fase, o bootmgr desenha os mesmos pixels quer
  exista aplicação de boot quer não**, enquanto na fase de dispositivo (AF) o mesmo programa desenha
  texto legível.
- **AJ — a aritmética do ramdisk também está eliminada.** O cabeçalho de partição do `boot.sdi`
  declara `Sectors=3.161.088` (= 1,51 GiB) contra 2,02 GiB do WinRE 1809. `build-small-media.sh`
  apagou `\Windows\WinSxS` e `\Windows\System32\DriverStore` de uma cópia do WIM e o
  `Total Bytes` caiu para **952.214.657** (0,89 GiB), folgado dentro dos 1,51 GiB. Resultado:
  exatamente o mesmo azul. Correção honesta registrada no doc: eu tinha escrito que o `boot.sdi`
  continha uma imagem GPT — **não contém**; não há assinatura `EFI PART` em lugar nenhum e LBA 1 é
  zero. `PART` é a assinatura do próprio cabeçalho de partição do SDI.
- **Armadilha nova, medida na prática:** a primeira versão do `build-small-media.sh` listou um caminho
  inexistente; o wimlib aborta o update inteiro no primeiro erro e o script seguiu construindo a
  mídia a partir do WIM **sem alteração** — um teste silenciosamente falso. Agora o script recusa
  construir mídia se o `Total Bytes` não cair abaixo de 1,5 GB.
- **Busca inconclusiva, registrada para não repetir:** o BCD de 16 KB do disco contém
  `\sources\boot.wim` e `boot.sdi`, mas o GUID da imagem (`4d9eec8d…`) não aparece nele em nenhuma
  ordem de bytes. Isso **não** é achado: o elemento ramdisk do BCD de DVD guarda um GUID de
  dispositivo, não o GUID do WIM. Nem provado nem refutado.
- **Estado da matriz:** RAM (2 GiB vs 4 GiB), modelo de CPU (`qemu64` vs `max`), controladora
  (`pc`/IDE vs `q35`/AHCI), presença do `winload.efi`, tamanho do WIM e configuração do shell do
  WinPE — todos variados, todos terminando no mesmo quadro de uma cor. O que separa as duas leituras
  restantes é ver por dentro do convidado, e isso pede autorização do dono: debug de kernel por
  serial, `pmemsave` ou logs `-d` do QEMU.
- Nada aqui é evidência de hardware: nenhum convidado produziu um console do Windows.

---

## FILE: GOAL.md

# Objetivo

## Missão

Construir um desafio reproduzível no qual um agente hospedado na nuvem, com apenas a tela do WinRE e o prompt de comando, possa restaurar um canal externo e depois recuperar o Windows 10 build 17763 em um Xiaomi Mi Pad 2 sem nenhuma conexão física.

## Objetivo principal

Provar, em um ambiente QEMU controlado, o caminho software que substitui o pacote inbox 2017 da Broadcom (quebrado) pelo pacote OEM 2015 de funcionamento garantido e disponibiliza a nvram da placa ao driver.

## Restrições rígidas

- Sem USB, SD, Ethernet, teclado físico ou abrir o dispositivo.
- Nenhuma transferência de dados a partir do dispositivo. O dispositivo só fornece tela e entrada digitada.
- Canais disponíveis do dispositivo: tela, `cmd` do WinRE, Wi-Fi, Bluetooth, touch.
- Sem PowerShell no WinRE.
- Agentes da nuvem rodam em contêineres; o QEMU é o ambiente de maior fidelidade disponível.
- O QEMU não deve expor arquivos do host via `-virtfs`, 9p, pastas compartilhadas, transferência serial de arquivos ou portas redirecionadas do host.
- O dispositivo não tem rede funcional (o Wi-Fi é o dispositivo quebrado). O único canal de entrada válido é texto digitado pelo teclado virtual da tela touch. O HTTP em modo usuário do QEMU é apenas uma linha de base de mecânica, não um canal de transferência do dispositivo. Veja **Realidade dos canais**.
- O rádio BCM4356 não é emulado pelo QEMU.

## Realidade dos canais (obrigatória — leia antes de escolher qualquer método de transferência)

O dispositivo **não tem conexão de rede funcional**. Sua única interface de rede,
o Wi-Fi BCM4356 (`PCI\VEN_14E4&DEV_43EC`), é exatamente o dispositivo que falha com
o erro 10. O Bluetooth não está verificado. Portanto **qualquer transferência de rede
(HTTP, FTP, SMB, ...) pressupõe uma conexão funcional que não existe e NÃO é um canal
de transferência válido para o dispositivo.**

O endpoint HTTP do NAT em modo usuário do QEMU (`10.0.2.2`) funciona só porque o QEMU
emula uma NIC e1000 funcional. Ele **não modela o dispositivo** e **não deve** ser
usado como canal de transferência da solução. É, no máximo, uma linha de base de mecânica.

O **único canal de entrada consistente com as restrições é o teclado virtual da tela
touch: texto digitado.** A carga útil (os bytes do driver e/ou a nvram da placa) entra
no dispositivo como texto — hexadecimal ou base64 — digitado pelo teclado, e depois é
reconstruída como binário dentro do WinRE usando apenas as ferramentas presentes lá
(não presuma `certutil`, `curl` ou `bitsadmin`). A tela é o único canal de saída.

Edição do lado do host (servicing offline de uma cópia do WIM com wimlib/DISM) é uma
prova de mecânica em uma cópia. **Não** é assim que o dispositivo isolado recebe a
carga útil e não deve ser apresentado como a solução do dispositivo.

## Não objetivos

- Não reivindicar prova de hardware a partir de resultados do QEMU.
- Não fornecer uma imagem completa de instalação do Windows neste repositório.
- Não contornar as restrições do desafio.
- Não adicionar drivers não relacionados, pacotes de vídeo, áudio, câmera ou sensores.
- Não modificar as partes do WIM versionadas no lugar.
- Não fazer commit de artefatos gerados nem segredos.

## Critérios de sucesso

### Repositório

- `scripts/verify-repo.sh` passa.
- Todos os checksums passam.
- `drivers/estado-dispositivo/` usa os nomes exatos de pastas do DriverStore.
- A pasta Wi-Fi alvo contém quatro arquivos de driver e nenhuma nvram.
- O pacote OEM e a hipótese de nvram estão documentados separadamente.
- Toda a documentação técnica voltada aos agentes está em português; os resumos para o usuário estão em português.

### Caminho software no QEMU

- O WinRE inicializa no QEMU.
- A linha de base mostra o driver inbox de 2017.
- (Linha de base de mecânica no lado do host, em uma cópia, não o método de transferência do dispositivo) O servicing offline remove o pacote inbox e prepara o pacote OEM de 2015.
- A imagem modificada contém o driver de 2015 e a fonte da nvram.
- O caminho alternativo `pnputil`/`devcon` está documentado e é testável.
- A carga útil entra no convidado como texto digitado (hex/base64) pelo teclado touch simulado e é reconstruída e verificada por hash no próprio convidado. O canal HTTP/modo usuário é apenas linha de base de mecânica, não o canal do dispositivo.
- (Proposto, não provado) O sintoma do erro 10 é reproduzido sinteticamente: um dispositivo PCI falso com o ID real (`VEN_14E4&DEV_43EC`) mais o driver real falha ao iniciar (Abordagem A); a correção da seleção de driver é demonstrada em um substituto funcional (Abordagem B). Precisa de um Windows completo inicializável (o repositório tem só o WinRE); KVM recomendado por velocidade (TCG inicializa devagar). Ainda não demonstrado aqui. Veja `docs/04`.

### Validação no hardware

- `ConfigManagerErrorCode` de `PCI\VEN_14E4&DEV_43EC` é `0` após a correção.
- `netsh wlan show drivers` lista o adaptador.
- O dispositivo conecta a uma rede Wi-Fi.
- O usuário grava evidências na tela sem transferir arquivos.

## Marcos

| ID | Marco | Condição de aprovação |
|---|---|---|
| M0 | Inventário | Checksums do repositório passam; estado alvo reconstruído; inventário de ferramentas registrado. |
| M1 | Canal externo | Pelo menos 1 KB entra no convidado como texto digitado pelo teclado touch simulado, reconstruído e verificado por hash no próprio convidado; go/no-go registrado. Rede/HTTP não é o canal do dispositivo. |
| M2 | Carga do driver | Driver OEM 2015 preparado e pacote inbox 2017 removido ou sobreposto. |
| M3 | Wi-Fi | Adaptador inicia sem erro 10 no hardware. |
| M4 | Instalação do Windows | Windows 10 1809 aplicado e inicializável. |
| M5 | Validação no hardware | Wi-Fi, touch e verificações básicas do SO passam no dispositivo. |

## Níveis de fidelidade

| Nível | Conteúdo | Uso |
|---|---|---|
| F1 | WIM do firmware de fábrica 10586 como está | Linha de base. Não tem `bcmwdidhdpcie.inf` e não consegue reproduzir o erro 10. |
| F2 | WIM do firmware + pacote alvo PCIe 2017 injetado + pacote OEM 2015 + nvram | Estado sintético funcional. Aproxima o conflito de drivers; build 10586, não a partição real. |
| F3 | WIM real de cerca de 398 MB do dispositivo | Alvo exato; indisponível a menos que o usuário o forneça. |

F1 é a linha de base do firmware. F2 é o estado sintético funcional porque a imagem de firmware não tem o pacote PCIe. F3 não está disponível neste repositório. Todo resultado F2 deve ser rotulado como sintético.

## Regras antitrapaça

- Nenhum compartilhamento do sistema de arquivos do host.
- Nenhuma porta redirecionada do host.
- Nenhuma transferência de arquivo por serial.
- Nenhuma integração de área de transferência.
- Nenhum proxy de rede oculto.
- Nenhuma reivindicação de sucesso sintético.
- `qemu/audit.sh` deve passar antes de um experimento ser considerado válido.

## Requisitos de evidência

Cada experimento deve registrar:

- Objetivo e nível de fidelidade.
- Pré-condições e versões das ferramentas.
- Comandos exatos.
- Saída observada.
- Artefatos e checksums.
- Decisão passou/falhou.
- Limitações.
- Resultado da reversão.

## Referências

- Microsoft Q&A: Broadcom 802.11ac Wireless PCIe não inicia, erro 10, Mi Pad 2.
- Microsoft Update Catalog: pacotes Broadcom BCM4356.
- Evidências locais: `drivers/nvram-delta/README.md`, `drivers/README.md`, `docs/03-driver-wifi-erro-10.md`.

## Estado atual

A montagem do repositório é a entrega atual. Os experimentos do QEMU estão definidos, mas não executados. A validação no hardware está pendente.

Imagem base: o WIM do firmware de fábrica é a única imagem versionada. Ele não tem `bcmwdidhdpcie.inf`, então o teste funcional exige injetar o pacote alvo de 2017 em uma cópia. Este é um estado sintético, não a partição de recuperação real. A imagem do dispositivo de cerca de 398 MB continua indisponível.

---

## FILE: INDEX.md

# INDEX — mapa do repositório (leia primeiro, depois `STATE.md`)

Projeto: recuperar o Wi-Fi (BCM4356, erro 10) de um Xiaomi Mi Pad 2 só com WinRE + `cmd` + texto digitado. Prova em QEMU antes de hardware.
Branch única: `desafio`. Um agente por vez. Detalhes ficam nos arquivos abaixo: leia só o que a tarefa pedir.

## Ordem de leitura

1. `INDEX.md` (este) e `STATE.md` (estado atual, feito/próximo/bloqueios).
2. Só se for mudar algo: `AGENTS.md` (regras), `GOAL.md` (objetivo e restrições).
3. Só se a tarefa tocar o tema: o arquivo da tabela abaixo.

## Raiz

| Arquivo | O que é |
|---|---|
| `AGENTS.md` | Regras de agente: sincronização, evidência, restrições (193 linhas) |
| `GOAL.md` | Missão e restrições rígidas |
| `README.md` | Visão geral do desafio e organização |
| `TODO.md` | Plano amplo e ideias do dono (139 linhas) |
| `ANOTACOES-IMPORTANTES.md` | Notas canônicas (dispositivo, canais) |
| `hypotheses.md` | Hipóteses (não são fatos) |
| `setup.sh`, `qoder-setup.sh` | Preparação do ambiente efêmero |
| `projeto.gpg` | Arquivo cifrado (não ler) |
| `.opencode/` | Configuração de agente |

## Pastas

| Pasta | Conteúdo | Quando abrir |
|---|---|---|
| `docs/` | `00` visão, `01` restrições, `02` estado do dispositivo, `03` driver Wi-Fi erro 10, `04` fidelidade, `05` offline servicing, `06` auditoria 1809, `07` inventário. `DOCS-BUNDLE.md` junta tudo (grande, evitar) | Para entender um tema |
| `experiments/` | `README.md` = quadro de experimentos (E0.1–E7); `E1-…`, `E3b-…`, `E7-…`; `templates/` | Antes de rodar ou registrar experimento |
| `qemu/` | Scripts de boot do WinRE (`run-winre*.sh`, `build-*.sh`, `mon.py`, `audit.sh`) e `README.md` | Para E1/E1b |
| `scripts/` | `salvar.sh` (commit+push), `verify-*.sh`, `prepare-ascii-transfer.py`, `winre-*.js`, `advisor-request.py` | Para tarefas de automação |
| `drivers/` | `estado-dispositivo/`, `mipad2-oficial/`, `nvram-delta/` (67 arquivos) | Para trabalho de driver/nvram |
| `inventory/` | `names-only/` (nomes por tipo) + `README.md` | Para consultar o que existe nas imagens |
| `prompts/` | `advisor.md` (briefing), `advisor-resposta.md` (orientação recente), histórico e anexos | Só para estratégia de recuperação |
| `winre-1809-oficial-intacta/` | WIM 1809 oficial em partes + SHA256SUMS | Nunca editar; trabalhar em cópias |
| `winre-fabrica-10586-424MB/` | WIM de fábrica 10586 em partes + SHA256SUMS | Nunca editar; trabalhar em cópias |

## Comandos curtos

- Sincronizar: `git fetch origin desafio && git merge --ff-only origin/desafio`
- Salvar: `scripts/salvar.sh "msg" caminho...` (sempre caminhos explícitos)
- Buscar sem ler tudo: `grep -rl termo .` e `sed -n 1,30p arq`
- Histórico recente: `git log -5 --oneline`

## Armadilhas de contexto

- Não use `cat` em `TODO.md`, `AGENTS.md` ou `DOCS-BUNDLE.md` inteiros; a célula E1b em `TODO.md` é muito longa (linhas 19–82).
- Resultado de QEMU/mock nunca é prova (regra de evidência em `AGENTS.md`).
- Não commitar imagens geradas, logs ou segredos.

---

## FILE: README.md

# Desafio de recuperação do Windows no Mi Pad 2

Este repositório é um desafio reproduzível e multiagente para um problema específico de recuperação:

- Xiaomi Mi Pad 2, x64, Windows 10 build 17763.
- O `C:` foi formatado rapidamente.
- O único ambiente Windows restante é a partição de recuperação no `D:`.
- O dispositivo não tem conexão USB, SD, Ethernet ou teclado físico.
- Os canais de entrada/saída disponíveis são a tela, o prompt de comando da recuperação e o touch. O Wi-Fi é o dispositivo quebrado (erro 10), então não há rede funcional; o único canal de entrada válido é texto digitado pelo teclado virtual da tela touch.
- O adaptador Wi-Fi reporta o erro 10 depois que o pacote PCIe de 2017 é usado.

O repositório não contém uma imagem completa de instalação do Windows. Ele versiona dois WIMs: a imagem de recuperação do firmware de fábrica (10586) e o WinRE 1809 oficial extraído do ESD da Microsoft. O repositório reúne as evidências, o estado alvo dos drivers, um ambiente QEMU e protocolos de experimento para que os agentes reproduzam o caminho software antes de alguém reivindicar um resultado de hardware.

## Como este repositório se organiza (leia primeiro)

- **Um repositório git, uma branch de trabalho: `desafio`.** Todo agente trabalha, commita e envia na `desafio`.
- **Agentes trabalham um de cada vez**, sem pasta própria. O trabalho vive nas pastas compartilhadas (docs, drivers, experiments, qemu, scripts). Não crie uma branch por agente nem por tarefa.
- **Sincronize antes de começar e antes de enviar:** `git fetch origin desafio` + `git merge --ff-only origin/desafio`. Nunca force push nem apague branches.
- **Um agente por vez:** não há reivindicação de tarefas; registre o estado em `TODO.md` e `experiments/README.md`.
- **Persista imediatamente:** o sandbox é temporário; faça commit e push de cada artefato concluído via `scripts/salvar.sh "mensagem" caminho...` (autorização permanente). Veja `AGENTS.md`.

## Estado

- A modulação do repositório é a entrega atual; a execução do desafio está adiada.
- Dois WIMs versionados: o firmware de fábrica (10586, sem `bcmwdidhdpcie.inf`) e o WinRE 1809 oficial (contém o pacote PCIe 2017 quebrado; procedência verificada).
- O dispositivo não tem rede funcional (o Wi-Fi é o dispositivo quebrado). O único canal de entrada válido é texto digitado pelo teclado virtual da tela touch; a carga útil entra como hex/base64 e é reconstruída no WinRE. Rede/HTTP não é canal do dispositivo.
- Edição de WIM no lado do host (servicing offline, ou injetar o pacote de 2017 em uma cópia) é linha de base de mecânica em uma cópia, não o método de transferência do dispositivo.
- O ambiente QEMU está montado; não há reivindicação de resultado do erro 10 no dispositivo. Reproduzir o sintoma do erro 10 com um dispositivo PCI falso idêntico mais o driver real é proposto, mas não provado; precisa de um Windows completo inicializável (o repositório tem só o WinRE) e KVM é recomendado por velocidade. Não demonstrado aqui. Veja `docs/04`.
- O rádio BCM4356 não pode ser emulado pelo QEMU. Nenhum resultado do QEMU é prova de hardware.
- O WIM real de recuperação de cerca de 398 MB do dispositivo não está disponível.

## Fatos-chave

- O estado quebrado é o pacote PCIe 2017 `bcmwdidhdpcie.inf`, versão `1.558.53.25`.
- O pacote de funcionamento garantido é o driver OEM 2015 `oem25.inf`, versão `1.558.14.0`.
- O Windows prefere o driver mais novo. Substituir o pacote sozinho não basta; o pacote 2017 deve ser removido ou o driver mais velho deve ser forçado.
- O estado alvo do DriverStore não contém o arquivo de nvram da placa.
- O pacote OEM contém o arquivo de origem da nvram. A nvram é uma carga útil separada, não parte do estado alvo.
- O WIM de firmware tem os pacotes bcmdhd, bcmdhd64, bcmfn2 e bcmfn, mas não tem `bcmwdidhdpcie.inf`.
- O dispositivo não consegue enviar arquivos. O desafio não deve pressupor clipboard, pastas compartilhadas, USB ou qualquer outro canal de transferência de dados.

## Mapa do repositório

| Caminho | Propósito |
|---|---|
| `GOAL.md` | Missão, restrições, marcos e critérios de aceitação. |
| `ANOTACOES-IMPORTANTES.md` | Fatos e evidências canônicos para os agentes. |
| `AGENTS.md` | Regras de operação para os agentes. |
| `drivers/` | Estado alvo do DriverStore, pacotes OEM e hipótese de nvram. |
| `winre-fabrica-10586-424MB/` | WIM do firmware de fábrica dividido em partes versionadas. |
| `winre-1809-oficial-intacta/` | WIM do WinRE 1809 oficial (do ESD da Microsoft), dividido em partes versionadas. |
| `docs/` | Explicações técnicas e runbooks. |
| `qemu/` | Design do ambiente QEMU e scripts. |
| `experiments/` | Protocolos de experimento reproduzíveis. |
| `scripts/` | Validação no host e folhas de comando do WinRE. |

## Ordem de leitura

1. `GOAL.md`
2. `ANOTACOES-IMPORTANTES.md`
3. `AGENTS.md`
4. `docs/00-visao-geral.md`
5. `docs/01-restricoes.md`
6. `docs/02-estado-do-dispositivo.md`
7. `docs/03-driver-wifi-erro-10.md`
8. `docs/04-fidelidade-mimetizacao.md`
9. `docs/05-offline-servicing.md`
10. `experiments/E0.1-firmware-baseline.md`
11. `experiments/README.md`

## Segurança e escopo

- Não conecte o dispositivo a USB, SD, Ethernet ou teclado físico.
- Não pressuponha nenhum caminho de transferência de arquivos a partir do dispositivo.
- Não descreva um resultado do QEMU como prova de hardware.
- Não modifique as partes versionadas dos WIMs. Trabalhe em cópias em `qemu/work/` ou `/tmp`.
- Não faça commit de WIMs gerados, imagens de disco, ISOs, logs ou segredos.
- Faça commit e push imediatamente na `desafio` (autorização permanente, 15/11/2026); o sandbox é temporário. Use `scripts/salvar.sh`. Um commit local não é entrega.

## Próximo passo

Revise `experiments/E0.1-firmware-baseline.md` para o inventário do firmware. Depois que as ferramentas estiverem instaladas, valide o repositório com `scripts/verify-repo.sh`. Os experimentos do QEMU estão definidos em `experiments/` e devem ser executados separadamente.

---

## FILE: STATE.md

# STATE — passagem de bastão entre chats (leia depois de `INDEX.md`)

Atualizado em: 21/11/2026 (criação do arquivo, a partir de `TODO.md` e `experiments/README.md`).
Regra: ao fim de cada chat, reescreva este arquivo (máx. 60 linhas) e salve com `scripts/salvar.sh "state" STATE.md`.
Fonte de verdade dos detalhes: `TODO.md` (plano) e `experiments/README.md` (quadro). Este arquivo só resume.

## Foco atual

E1b — fazer o WinRE inicializar sob QEMU/TCG até um `cmd` interativo, para destravar E3b e E7.

## Feito (resumo)

- Procedência do WinRE 1809 verificada (E0.1) e inventário das duas imagens (`inventory/`, `docs/07`).
- Regras de canais, sincronização e coordenação fixadas em `AGENTS.md` / `GOAL.md`.
- Ambiente UEFI com console de texto interativo (UEFI Shell, `FS0:`) e digitação via `keys.py`.
- Descartados por medição (E1b, células I–AJ): PCAT/SeaBIOS, ISO9660 em EFI (o firmware só monta o ESP `efisys.bin` como `FS0:`), modelo de CPU, controladora de storage, tamanho do ramdisk, `winload.efi`, trocar `recenv.exe` por `cmd.exe` em `winpeshl.ini`.
- Fato: o azul chapado `#2067B2` é real (não é artefato de captura) e vem do estágio depois do bootmgr; falhas do próprio bootmgr aparecem como texto preto (célula AF).

## Próximo passo imediato

1. Ler o STOP code do WinRE com `pmemsave`, `-d` ou `-debugcon` na mídia `qemu/work/winre-cmd.img`.
   Autorizado pelo dono em 21/11/2026 (regra em `AGENTS.md`). Antes de rodar, conferir `qemu/audit.sh`: `-serial file:`, `-virtfs`, 9p e portas redirecionadas continuam proibidos.
2. Com o STOP code, decidir a próxima variação de E1b ou registrar `bloqueado` em `experiments/README.md`.

## Bloqueios

| Tarefa | Depende de |
|---|---|
| E3b (nvram em ASCII + hash dentro do WinRE) | WinRE com `cmd` (E1b). Teste simulado não vale |
| E7 (escrita binária a partir de texto) | WinRE real (E1b). certutil, PowerShell, .NET e ADODB.Stream estão ausentes |
| E5 e E6 (erro 10 reproduzido) | Windows completo inicializável, de preferência com KVM. O sandbox atual só tem TCG |
| E4 (hardware) | O dono, no dispositivo físico |

## Decisões abertas do dono

- Nenhuma imagem-base aprovada (`experiments/README.md`, "Decisão atual de base").
- Teste de carga mínima: se só a nvram basta. Observação decisiva: `dir C:\Windows\System32\drivers\4356*` no aparelho vivo.

## Armadilhas

- A seção E1b de `TODO.md` (linhas 19–82) é muito longa: leia só as últimas linhas (`sed -n 76,82p TODO.md`).
- Nunca apresentar resultado de QEMU/mock como prova de hardware.
- Não editar os WIMs versionados; trabalhar em cópias em `qemu/work/` ou `/tmp`.

---

## FILE: TODO.md

# TODO

Lista de tarefas compartilhada. Um agente trabalha por vez, sem reivindicação de tarefas (veja a regra de coordenação em `AGENTS.md`). O quadro de experimentos é `experiments/README.md`; este
arquivo acompanha o plano mais amplo e as ideias do dono. Status: [ ] a fazer, [~] em andamento, [x] feito.

## Feito

- [x] Refinar a realidade dos canais: o dispositivo não tem rede funcional; apenas texto digitado pelo teclado
  touch é um canal de entrada válido. (GOAL, AGENTS, docs/00, docs/01, ANOTACOES, READMEs)
- [x] Modelo de repositório + regras de Sincronização + Coordenação; pastas != branches git; uma branch `desafio`.
- [x] Corrigir a super-reivindicação do KVM: KVM é velocidade, não requisito rígido; o TCG consegue inicializar o
  Windows devagar; o bloqueio real é WinRE-only (sem Windows completo) + um BSOD não diagnosticado. (docs/03, docs/04)
- [x] Inventariar as duas imagens: executáveis, DLLs, drivers, ferramentas de reconstrução, ferramentas de canal
  e o delta fábrica-vs-1809. (docs/07-inventario-imagens.md, inventory/)
- [x] Adicionar orientação de pensamento de solução para que os agentes proponham abordagens proativamente. (AGENTS.md)

## Em andamento

- [~] E1b — Diagnosticar o BSOD do WinRE sob TCG: variar modelo de CPU, tipo de máquina, controladora de
  storage e qual WinRE (1809 oficial vs 10586 fábrica). Manter as evidências como quadros `screendump` do monitor
  QEMU (`-serial file:` é proibido pelo `qemu/audit.sh`, então logs de serial não são uma opção).
  Meta: alcançar o `cmd` interativo para que o E3b possa rodar. Owner: qoder. O sandbox é só TCG
  (sem `/dev/kvm`, 4 vCPU, 8 GB) e o dono autorizou o TCG. Veja `experiments/E1-winre-boot-tcg.md`.
  Status 17/11/2026 (células I–AE): a rota PCAT/SeaBIOS é beco sem saída com as ferramentas do host — `etfsboot`
  não imprime nada sob 7 variantes de mídia diferentes. Na rota UEFI o ambiente agora tem um **console de texto
  interativo real**: toda célula EFI esgotada (S, U, V, W, X, Y, Z, AB) cai no UEFI Interactive Shell com `FS0:`
  mapeado, e `keys.py` + `TYPE_AT`/`TYPE_FILE`/`TYPE_GAP` digitam comandos nele que executam e
  renderizam saída (`e1-run.sh` captura um quadro por comando digitado, porque o shell EDK2 limpa a
  tela quando uma aplicação sai).
  Duas causas-raiz foram estabelecidas por medição, não por inferência:
  (1) `map` + `ls` (célula Y) provam que o firmware monta **apenas** o ESP `efisys.bin` de 1.474.560 bytes como
  `FS0:` — o volume ISO9660 de 261 MB que contém `\sources\boot.wim` nunca é montado, então nenhuma mídia construída
  por `build-efi-dvd-iso.sh` alcança o WinRE, aconteça o que for com a opção de boot; a GPT híbrida (célula U)
  e a cópia ISO9660 do `BOOTX64.EFI` (célula V) eram ambas irrelevantes para o `EFI_NO_MAPPING`.
  (2) `\efi\boot\bootx64.efi` lançado do shell realmente executa o bootmgr da Microsoft, e ele para na
  janela de DVD "pressione qualquer tecla" (células X, Z, AB). A taxa de injeção é o obstáculo: um `sendkey`
  por processo custa ~4 s aqui, então 150 teclas se espalharam por ~10 min e foram consumidas pelo shell depois
  que o bootmgr já tinha desistido (AB: cursor +150 colunas). `keyspam-dump.py` agora mantém uma
  conexão de monitor e intercala uma tecla a cada 150 ms com um quadro a cada 30 s — a célula AC é esse teste.
  **Resultado AC: a densidade não abriu a cancela.** 5.117 espaços em 902 s (5,68 teclas/s) estavam em voo
  desde t≈0,2 s, e o cursor do shell avançava a um constante +17 colunas por quadro o tempo todo — o shell
  os consumiu, então o bootmgr já tinha retornado antes do primeiro quadro. Os pixels do press-any-key que
  persistem até o quadro de spam 003 são resíduo rolando para fora do topo, não uma janela viva. A leitura (a)
  (janela estreita demais) é eliminada; a leitura (b) (flush de ConIn no início da aplicação) é a mais bem
  sustentada, e a cancela do CD é uma propriedade das mídias CD, então a linha EFI-ISO termina aqui.
  **Resultado AD: o azul chapado é real, não artefato de captura.** Com `-vga none -device
  bochs-display` (não existe `-vga ramfb` neste QEMU 6.2 — medido com `-vga help`) a mesma fonte de
  quadros mostra o texto do `BdsDxe`, o logo gráfico do TianoCore e depois 786.432 px de
  `srgb(32,103,178)` com zero glifos, seguidos de um desligamento pedido pelo convidado (código de saída do QEMU 0 com
  `NOREBOOT=0`). `#2067B2` é o azul da UI de recuperação, e o `\Windows\System32\winpeshl.ini` dentro
  de `winre1809.wim` nomeia `X:\sources\recovery\recenv.exe` como launcher do shell.
  Próxima célula em fila: **AE** — mesmo disco FAT32, boot.wim com `winpeshl.ini` substituído por
  `AppPath=X:\Windows\System32\cmd.exe` (`build-cmd-media.sh`, mídia
  `qemu/work/winre-cmd.img` sha256 `c8dadd60…`): se é a UI de recuperação que pinta o azul e morre, o mesmo
  ramdisk deveria abrir um console de texto. AA (se `partition_offset=16` suprime a montagem ISO9660) agora é
  prioridade baixa, atrás do AE.
  **Resultados AE, AF e AG (17/11/2026):** AE voltou idêntico ao AD — `cmd.exe` no lugar de
  `recenv.exe` não mudou nada, então o shell do WinPE nunca é alcançado; o `boot.sdi` também foi
  conferido como a imagem real da Microsoft (3.170.304 B, GPT interno, `PART` em 0x400), não um template vazio.
  AG (`-machine q35` = AHCI ICH9, `-cpu max`) terminou na mesma cor única em t=15 s, então os eixos
  modelo-de-CPU e controladora-de-storage estão eliminados para essa mídia. **O AF é a descoberta que
  reorganiza a matriz**: com `\sources\boot.wim` renomeado para fora, a mesma mídia e o mesmo dispositivo
  de vídeo renderizam a tela de erro do bootmgr como texto limpo (`Windows Boot Manager` … `Status: 0xc000000f`
  … `Info: A required device isn't connected or can't be accessed`), então as falhas do próprio bootmgr são
  texto em preto e o azul pertence ao estágio *depois* que o bootmgr entrega. Próxima célula em fila:
  **AH** — remover `\Windows\System32\boot\winload.efi` de dentro do ramdisk para separar "o bootmgr
  não consegue lançar a aplicação de boot" de "o winload/kernel pintou o azul". Ler o código de parada real
  ainda precisa de um canal de debug (serial do kernel, `pmemsave` ou logs `-d` do QEMU) que o dono não
  autorizou.
  **Resultados AH e AJ (17/11/2026):** apagar as duas cópias de `winload.efi` de dentro do ramdisk
  (`build-nowl-media.sh`, mídia `winre-nowl.img` `d53f813a…`) produziu o azul idêntico, e
  encolher o WIM para `Total Bytes 952.214.657` apagando WinSxS + DriverStore
  (`build-small-media.sh`, mídia `winre-small.img` `564b7061…`) — bem dentro dos
  1,51 GiB de volume que o cabeçalho da partição SDI declara — também produziu o azul idêntico. Então a
  aritmética de tamanho do ramdisk também está eliminada, e a fase do bootmgr que pinta o azul renderiza
  os mesmos pixels haja ou não uma aplicação de boot. `build-small-media.sh` ganhou uma guarda depois de sua
  primeira execução construir mídia silenciosamente a partir de um WIM **não corrigido** (o wimlib aborta toda
  a atualização num caminho inexistente). Os próximos movimentos precisam da decisão do dono: ou autorizar um
  canal de debug para ler o código de parada real, ou encerrar a matriz TCG e tratar o E1b como
  `bloqueado — nenhum console alcançável sem instrumentação`.
- **E1b — canal de debug AUTORIZADO pelo dono em 21/11/2026** (opção 1; regra em `AGENTS.md`). Próximo: ler o STOP code com `pmemsave`/`-d`/`-debugcon` na mídia `winre-cmd.img`.

## Próximo — viável agora, sem KVM

- [ ] E3b — reconstruir a nvram DENTRO do WinRE usando só ferramentas da imagem (`cmd` `copy con` /
  `echo >>` / `notepad`), depois hash. Precisa que o WinRE inicialize (ver diagnóstico de BSOD abaixo). A nvram
  é texto, então nenhum decodificador binário é necessário.
- [ ] Teste de carga mínima (ideia do dono): determinar se só a nvram (H1) basta, evitando qualquer
  transferência binária. A observação decisiva é uma única listagem de diretório no dispositivo
  vivo, `dir C:\Windows\System32\drivers\4356*` — se `4356r2rtecdc.bin` está lá e
  `4356r2nvram.txt` não está, nvram-only é o patch inteiro; se nenhum dos dois está, a carga é também o
  firmware (binário de 0,64 MB, que precisa do sumidouro binário do E7) e possivelmente o `.sys`. Bloqueado em
  conseguir um console (E1b).
- [~] Método de reconstrução binária (PROBLEMA ABERTO) — Owner: stackai (E7; teste só no WinRE real,
  bloqueado no E1): certutil, PowerShell, .NET e ADODB.Stream
  estão todos AUSENTES. MSXML decodifica base64, mas escrever bytes brutos não tem sumidouro óbvio. Investigar
  um método texto->binário funcional com as ferramentas existentes (docs/07). Não reivindique que funciona até
  testar num WinRE inicializado.
- [ ] Teste do canal com binário exato pequeno: quando existir um método de escrita binária, transferir um
  binário exato pequeno (ex.: algumas centenas de bytes), reconstruir no convidado, verificar por hash — antes
  do driver de ~1 MB.

## Precisa de um Windows completo inicializável (agente com KVM recomendado)

- E1b (diagnóstico do BSOD do WinRE sob TCG) passou para **Em andamento** acima; não precisa de Windows
  completo nem de KVM. As linhas abaixo ainda precisam.
- [ ] E5 — reprodução do sintoma do erro 10: dispositivo PCI falso com o ID real
  (`x-pci-vendor-id=0x14e4,x-pci-device-id=0x43ec`) + driver Broadcom real -> falha ao iniciar.
  Fidelidade máxima de sintoma; um stub sem resposta não conseguiria então ser corrigido. (docs/04)
- [ ] E6 — demo da correção de seleção de driver numa substituta funcional e1000: driver errado -> erro
  10, driver correto -> inicia. Demo de correção ponta a ponta, menor fidelidade. (docs/04)
- [ ] Enviar o arquivo inteiro do driver substituto; se funcionar, achar o MÍNIMO necessário para pelo
  menos associar/conectar algo.

## Investigações abertas

- [ ] Linha de base de boot (ideia do dono): quando houver boot no QEMU (WinRE/Windows), capturar o que é
  carregado/iniciado por padrão (drivers, serviços, DLLs/módulos — ex.: `driverquery /v`,
  `sc query type= driver state= all`, `sc query type= service state= all`, `tasklist /m`,
  enumeração de módulos) para identificar bibliotecas/arquivos ausentes que precisem ser iniciados;
  coletar o máximo de informação sobre o estado em execução.
- [ ] Bluetooth como canal (ideia do dono): o WinRE não tem a pilha BT da Microsoft (só
  `c_bluetooth.inf`); o driver OEM `bt-uart` (com firmware `.hcd` BCM4356) está no repositório.
  A pilha pode ser carregada, e o BT pode carregar uma carga menor que o driver? Não é um canal
  assumido — verifique. (docs/07)
- [ ] Descompasso de firmware / aproximar a imagem atualizada do dispositivo (ideia do dono): o dispositivo é
  fábrica-10586-depois-atualizado (~398 MB, indisponível). Ideia: instalar o firmware de fábrica, atualizá-lo,
  e então listar os programas / construir um ISO a partir desse estado. Como um agente pode fazer isso sem
  o dispositivo? Descobrir um método. O delta fábrica-vs-1809 é um começo (inventory/), mas uma biblioteca extra
  só no dispositivo poderia importar.
- [ ] Avaliar se o delta da imagem (DLLs/programas extras) afeta a correção do driver ou as ferramentas
  de reconstrução.

## Regras

- Envie cada artefato concluído imediatamente (`scripts/salvar.sh`). O sandbox é temporário.
- Trabalhe e envie apenas na `desafio`. Sincronize (fetch + ff-only) antes de começar e antes de enviar.
- Nunca apresente um resultado do QEMU como prova de hardware. Rotule resultados sintéticos e o nível de fidelidade.
- Não modifique as partes versionadas dos WIMs; trabalhe em cópias em `/tmp` ou `qemu/work/`.

---

## FILE: docs/00-visao-geral.md

# Visão geral

## O que este repositório é

Um desafio montado para recuperar um Xiaomi Mi Pad 2 que só tem o WinRE na partição de recuperação. O repositório contém:

- O estado alvo do DriverStore da Broadcom.
- O pacote OEM 2015 e a hipótese de nvram.
- A imagem de recuperação do firmware de fábrica, dividida em partes versionadas.
- Documentação sobre a falha do driver e os caminhos de recuperação.
- Uma especificação do ambiente QEMU e scripts.
- Protocolos de experimento e folhas de comando do WinRE.

## O que este repositório não é

- Não é uma imagem completa de instalação do Windows.
- Não é prova de que o rádio BCM4356 funciona.
- Não é uma licença para contornar as restrições de sem-conexão.
- Não é uma fonte de sucesso fabricado.
- Não é a partição de recuperação real de cerca de 398 MB do dispositivo.

## O problema em um parágrafo

O Mi Pad 2 tem um adaptador Wi-Fi PCIe BCM4356 (`PCI\VEN_14E4&DEV_43EC`). O estado alvo contém o pacote PCIe 2017 `bcmwdidhdpcie.inf` versão `1.558.53.25`, que é mais novo que o driver OEM 2015 `1.558.14.0`. O dispositivo reporta o erro 10. A solução de contorno conhecida é selecionar manualmente o driver OEM mais velho. Como o rank de drivers do Windows prefere o pacote mais novo, a correção precisa remover o pacote 2017 ou forçar o pacote OEM. O estado alvo também não tem a nvram da placa. O pacote OEM contém a origem da nvram e a regra de cópia do INF.

O WIM de firmware de fábrica não contém `bcmwdidhdpcie.inf`. Para testar o conflito de drivers, o pacote 2017 precisa ser injetado numa cópia da imagem de firmware. Isso produz um estado sintético, não a partição de recuperação real.

## Ordem de leitura

1. `GOAL.md`
2. `ANOTACOES-IMPORTANTES.md`
3. `AGENTS.md`
4. `docs/01-restricoes.md`
5. `docs/02-estado-do-dispositivo.md`
6. `docs/03-driver-wifi-erro-10.md`
7. `docs/04-fidelidade-mimetizacao.md`
8. `docs/05-offline-servicing.md`
9. `experiments/E0.1-firmware-baseline.md`
10. `experiments/README.md`

Glossário em português está planejado.

## Estado

- Montagem do repositório: em andamento até a validação passar.
- Execução no QEMU: não faz parte da base.
- Validação no hardware: pendente e guiada pelo usuário.
- Imagem versionada: apenas o firmware de fábrica 10586.
- Teste funcional: F2, uma imagem de firmware sintética com o pacote PCIe 2017 injetado.
- Linha de base padrão: F1, a imagem de firmware não modificada.

## Caminho de sucesso

1. Validar o repositório e os checksums.
2. Construir o ambiente QEMU com o WinRE a partir da imagem de firmware.
3. Reproduzir a linha de base do firmware: sem pacote PCIe, sem nvram.
4. Injetar o pacote alvo PCIe 2017 numa cópia.
5. Remover o pacote 2017 e preparar o pacote OEM 2015.
6. Verificar o driver 2015 e a origem da nvram na imagem modificada.
7. Provar o canal de entrada de texto digitado no QEMU (carga digitada pelo teclado touch simulado, reconstruída e verificada por hash no convidado). HTTP/modo usuário é só linha de base de mecânica, não o canal do dispositivo.
8. Validar o rádio no dispositivo físico com a lista de verificação.

## Limitações importantes

O QEMU não emula o BCM4356. Ele pode provar que o pacote de driver mudou, que os arquivos foram preparados e que uma carga entra no convidado como texto digitado e é reconstruída no convidado. Não pode provar que o rádio inicia, que o erro 10 desaparece ou que o Wi-Fi associa. Esses são testes de hardware.

**Realidade dos canais:** o dispositivo não tem rede funcional (o Wi-Fi BCM4356 é o dispositivo quebrado). O único canal de entrada válido é texto digitado pelo teclado virtual da tela touch; a carga entra como hex/base64 e é reconstruída no WinRE. Transferência por rede/HTTP não é um canal válido do dispositivo; o endpoint HTTP do QEMU em modo usuário é só uma linha de base de mecânica. Edição do WIM no lado do host é prova de mecânica numa cópia, não o método de transferência do dispositivo. Veja a seção Realidade dos canais de `GOAL.md` e `docs/01-restricoes.md`.

O WIM de recuperação real de cerca de 398 MB não está disponível. O WIM de firmware tem 444.856.529 bytes, maior que essa partição. Ele não pode substituir o `D:` como está.

F2 é sintético: usa o firmware build 10586 mais um pacote PCIe 2017 injetado. É útil para a mecânica dos drivers, não como prova do conteúdo real da partição.

---

## FILE: docs/01-restricoes.md

# Restrições

## Restrições do dispositivo

| Item | Regra |
|---|---|
| USB | Não permitido. Não assuma que existe ou funciona. |
| Cartão SD | Não permitido. |
| Ethernet | Não permitido. |
| Teclado físico | Não permitido. |
| Abrir o dispositivo | Não permitido. |
| Clipboard | Não permitido. |
| Pasta compartilhada | Não permitido. |
| Transferência de arquivo por serial | Não permitido. |
| Portas redirecionadas do host | Não permitido no QEMU. |
| `-virtfs` / 9p | Não permitido no QEMU. |

## Canais permitidos do dispositivo

- Saída de tela.
- Entrada de `cmd` no WinRE.
- Wi-Fi.
- Bluetooth.
- Touch.

**Realidade dos canais:** o dispositivo **não tem conexão de rede funcional**. Sua única
NIC, o Wi-Fi BCM4356, é o dispositivo que falha com o erro 10; o Bluetooth está
não verificado. Qualquer transferência de rede (HTTP, FTP, SMB, ...) pressupõe uma conexão que
não existe e é **não** um canal válido de dispositivo. O endpoint HTTP do NAT em modo usuário
do QEMU (`10.0.2.2`) funciona só porque o QEMU emula uma NIC e1000 funcional; ele não
modela o dispositivo e é só uma linha de base de mecânica, nunca o canal da solução.

| Canal | Serve para colocar uma carga DENTRO do dispositivo? | Por quê |
|---|---|---|
| Teclado virtual da tela touch (texto digitado) | **Sim — o único canal de entrada confiável** | Funciona independente do Wi-Fi quebrado. A carga entra como texto hex/base64, reconstruída no WinRE. |
| Tela | Só saída | O agente lê os resultados da tela. |
| Wi-Fi | Não (quebrado) | O BCM4356 é o dispositivo com o erro 10; sem conexão até corrigi-lo. |
| Bluetooth | Incerto | Presença de pilha/driver não verificada; não assumido. |
| HTTP / FTP / SMB / qualquer rede | **Não** | Pressupõe uma rede funcional que o dispositivo não tem. |
| USB / SD / Ethernet / teclado físico | Não | Proibido pelas restrições rígidas. |
| Clipboard / pasta compartilhada / arquivo serial / hostfwd | Não | Construções antitrapaça proibidas. |

A carga (os bytes do driver e/ou a nvram) deve entrar como **texto digitado** (hex ou base64)
e ser reconstruída dentro do WinRE usando apenas as ferramentas presentes lá (não assuma
`certutil`, `curl` ou `bitsadmin`). Edição do WIM no lado do host é prova de mecânica numa
cópia, não o método de transferência do dispositivo.

## Restrições do WinRE

- O WinRE fornece apenas `cmd`.
- Não assuma PowerShell.
- Não assuma uma instalação completa do Windows.
- Não assuma que `devcon` está presente.
- Não assuma que `curl`, `bitsadmin` ou `certutil` estão presentes.
- `pnputil` pode existir, mas o seu conjunto de recursos depende do build do WinRE.
- WMIC pode não existir no WinRE.

## Restrições do QEMU

O ambiente não deve expor arquivos ou serviços do host. Um endpoint HTTP em modo usuário é permitido apenas como linha de base de mecânica; não é o canal de transferência do dispositivo (veja a seção Realidade dos canais acima).

Proibido:

- `-virtfs`
- Montagens 9p
- Pastas compartilhadas
- `-netdev user,hostfwd=...`
- `-serial file:...`
- `-chardev file:...`
- Integração de clipboard
- Proxy oculto ou redirecionamento de porta

Permitido:

- Firmware UEFI OVMF.
- KVM quando disponível.
- Um servidor HTTP local pelo NAT em modo usuário do QEMU em `10.0.2.2` — só linha de base de mecânica, não o canal do dispositivo.
- Um disco qcow2 criado pelo ambiente.
- Um ISO de WinRE ou mídia de boot equivalente criada a partir das partes versionadas do WIM.

## Restrições de evidência

- Não apresente saída do QEMU como prova de hardware.
- Não reivindique que o rádio funciona sem um resultado no dispositivo físico.
- Não reivindique sucesso sem os comandos, saídas, hashes e carimbos de tempo.
- Não esconda tentativas falhas nem reversões.
- Não faça commit de imagens geradas, logs ou segredos.

## Restrições de escopo

Este repositório monta o desafio. Ele não autoriza contornar as restrições, fabricar uma recuperação ou atacar qualquer sistema de terceiros.

---

## FILE: docs/02-estado-do-dispositivo.md

# Estado do dispositivo alvo

## Significado

`drivers/estado-dispositivo/` é o subconjunto quebrado do DriverStore da Broadcom. É a linha de base, não a correção.

## Pastas exatas

| Pasta | Arquivos | Pacote |
|---|---|---|
| `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` | 4 | Wi-Fi PCIe |
| `bcmdhd64.inf_amd64_e0bae6831f60ea5f/` | 5 | Wi-Fi SDIO |
| `bcmfn2.inf_amd64_5ebadf201c5b5845/` | 2 | Função SDIO |

Esses nomes fazem parte do retrato do DriverStore alvo. A imagem de origem não está neste repositório.

## Arquivos Wi-Fi alvo

```text
bcmwdidhdpcie.inf
bcmpciedhd63.sys
4356a2rtecdc.bin
43596a0rtecdc.bin
```

Nenhum arquivo de nvram está presente.

O arquivo `43596a0rtecdc.bin` pertence à seção BCM4359 / `DEV_4355`. Ele fica na pasta porque o DriverStore alvo é mantido idêntico. A seção `DEV_43EC` usa `4356a2rtecdc.bin`.

## Arquivos SDIO alvo

`bcmdhd64.inf_amd64_e0bae6831f60ea5f/`:

```text
bcmdhd64.inf
bcmdhd63.sys
43241b4rtecdc.bin
4324b5rtecdc.bin
43341b0rtecdc.bin
```

`bcmfn2.inf_amd64_5ebadf201c5b5845/`:

```text
bcmfn2.inf
bcmfn2.sys
```

## Checksums

Manifesto: `drivers/estado-dispositivo/SHA256SUMS`.

É um artefato do repositório no nível acima, fora das pastas do DriverStore. Verifique com:

```sh
cd drivers/estado-dispositivo
sha256sum -c SHA256SUMS
```

## O que não está aqui

- A nvram não está aqui.
- A partição de recuperação completa de 398 MB não está aqui.
- O pacote OEM não está aqui.
- O `bcmpciedhd63.sys` de 2015 não está aqui.
- A correção não está aplicada.

## Relação com o pacote OEM

O estado alvo é o pacote inbox 2017. O pacote OEM em `drivers/mipad2-oficial/wifi/` é a substituição. O `oem25.inf` OEM é da versão 1.558.14.0 e contém a regra de cópia da nvram. O `bcmwdidhdpcie.inf` alvo é da versão 1.558.53.25 e não contém a regra de cópia da nvram.

## Regras do estado alvo

- Não adicione a nvram neste diretório.
- Não substitua os arquivos inbox pelos OEM no lugar.
- Não trate os pacotes SDIO ou de função como a correção do Wi-Fi.
- Não reivindique que este subconjunto é a imagem de recuperação completa.
- Se o estado alvo mudar no dispositivo, atualize este diretório e os seus checksums juntos.

---

## FILE: docs/03-driver-wifi-erro-10.md

# Driver Wi-Fi e erro 10

> **Procedência:** verificada. Os dados da 1809 abaixo foram reconferidos contra
> `winre-1809-oficial-intacta/`, extraído do ESD oficial (`Core_en-us.esd`,
> 522.499.063 bytes, SHA-1 `8352af7661fb4808decc0253f6d516b7c2d88605`, SHA-256
> `b4d37e91…`). O WIM resultante (266.283.224 bytes, SHA-256 `232199c5…`) tem a
> mesma listagem de 21.230 caminhos do WIM derivado anterior, e os 11 arquivos
> do estado de driver são idênticos byte a byte. Veja `docs/06-auditoria-imagem-1809.md`.

## Sintoma

O adaptador BCM4356 é `PCI\VEN_14E4&DEV_43EC`. Depois que o driver inbox de 2017 entra em uso, o Windows reporta:

```text
ConfigManagerErrorCode = 10
```

O erro 10 significa que o dispositivo não consegue iniciar. O adaptador não aparece como interface Wi-Fi funcional.

## Versões

| Pacote | Versão | Data | Origem |
|---|---|---|---|
| Inbox `bcmwdidhdpcie.inf` | 1.558.53.25 | 21/04/2017 | WinRE 1809 |
| OEM `oem25.inf` | 1.558.14.0 | 23/12/2015 | Backup de fábrica do Mi Pad 2 |

Os dois pacotes usam um arquivo chamado `bcmpciedhd63.sys`, mas os binários diferem:

- Inbox: 1.037.824 bytes.
- OEM: 1.041.320 bytes.

## Por que copiar o driver mais velho não basta

O ranking de drivers do Windows prefere o driver mais novo para o mesmo dispositivo. O pacote inbox de 2017 fica acima do pacote OEM de 2015. Adicionar o pacote OEM sem remover o pacote inbox sem forçar o pacote OEM deixa o driver mais novo selecionado.

As opções funcionais são:

1. Remover o pacote inbox, depois adicionar o pacote OEM.
2. Forçar o pacote OEM com `devcon update`.
3. Usar o equivalente do Gerenciador de Dispositivos de "Escolher em uma lista" e selecionar o driver Broadcom de 2015.

A seleção manual do usuário funcionou no dispositivo físico. Isso é consistente com uma regressão de versão de driver.

## Evidência externa conhecida

O Microsoft Q&A documenta o mesmo sintoma no Mi Pad 2 e a solução de contorno com o driver mais velho:

https://learn.microsoft.com/en-us/answers/questions/2779164/broadcom-802-11ac-wireless-pcie-cant-be-started-af

O Microsoft Update Catalog lista os pacotes Broadcom BCM4356:

https://www.catalog.update.microsoft.com/Search.aspx?q=Broadcom%20BCM4356

Essas fontes sustentam o H2. Elas não substituem um teste no dispositivo físico.

## O fator nvram

O driver constrói estes caminhos:

```text
\SystemRoot\system32\drivers\4356r2rtecdc.bin
\SystemRoot\system32\drivers\4356r2nvram.txt
```

O DriverStore alvo contém `4356a2rtecdc.bin`, que o INF renomeia para `4356r2rtecdc.bin` durante a instalação. O DriverStore alvo não contém a nvram.

O INF do OEM contém:

```text
4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6
```

O INF do inbox não. Este é o delta de nvram.

O H2 é primário: o driver de 2017 é a regressão. O H1 é secundário: se a instalação do pacote OEM não copiar a nvram, a nvram precisa ser colocada separadamente em `System32\drivers`.

## Confirmado nos arquivos (análise estática)

Três pontos acima foram verificados lendo os arquivos das imagens (análise estática, sem executar nada). Nenhum deles é evidência de hardware.

1. Os caminhos de busca estão embutidos nos binários, não só implícitos pelo INF. `strings` sobre **ambos** os builds de `bcmpciedhd63.sys` (inbox 1.558.53.25 e OEM 1.558.14.0) devolve os mesmos templates e o mesmo caminho de falha:

   ```text
   \SystemRoot\system32\drivers\%dr%drtecdc.bin
   \SystemRoot\system32\drivers\%04Xr%drtecdc.bin
   \SystemRoot\system32\drivers\%dr%dnvram.txt
   \SystemRoot\system32\drivers\%04Xr%dnvram.txt
   nvram path set to %s
   dhdpcie_download_nvram
   %s: dongle nvram file download failed
   ```

   Para o chip 0x4356 rev 2 isso resolve para `4356r2rtecdc.bin` e `4356r2nvram.txt`, que é exatamente a nomenclatura que `drivers/nvram-delta/` usa. Se o driver trata uma nvram ausente como fatal ou recorre à calibração de bordo ainda não está provado.
2. Na imagem WinRE da fábrica o driver está **preparado, não implantado**. `System32\drivers` contém 295 arquivos `.sys` e este não é um deles; `bcmpciedhd63.sys` e `4356a2rtecdc.bin` existem só em `DriverStore\FileRepository` e no componente `WinSxS`. Então as cópias de runtime *tanto do firmware quanto da nvram* dependem do estágio PnP `CopyFiles` ter rodado. A carga mínima é, portanto, dois arquivos (firmware OEM de 641.951 bytes mais nvram de 5.361 bytes) e não um, e possivelmente três — isso só se resolve listando o diretório vivo no dispositivo.
3. `devcon.exe` **não** está presente na imagem do WinRE. A opção 2 acima ("forçar o pacote OEM com `devcon update`") exige trazer a ferramenta. `pnputil.exe`, `dism.exe`, `cmd.exe`, `drvload.exe`, `setupapi.dll` e `newdev.dll` estão presentes, e o hive SYSTEM está dentro do WIM, então `pnputil /add-driver` e o trabalho com o registro offline são alcançáveis do console de recuperação.

Armadilha operacional:

- O INF do inbox é UTF-16LE (BOM `ff fe`); o INF do OEM é ASCII. Buscar `nvram` no INF do inbox com grep sem decodificar devolve 0 ocorrências pelo motivo errado. Use `iconv -f UTF-16LE -t UTF-8` antes.

## Comportamento do servicing offline

`dism /Add-Driver` numa imagem offline prepara o pacote de driver no DriverStore offline. Não executa uma instalação PnP completa para um dispositivo que não está presente. A operação `CopyFiles` do INF normalmente roda quando o dispositivo é instalado.

Consequências:

- O WIM modificado pode ser verificado quanto ao preparo do pacote de driver.
- A origem da nvram pode ser verificada no DriverStore.
- A cópia final `System32\drivers\4356r2nvram.txt` pode exigir a instalação PnP no hardware, ou uma cópia manual como plano B.
- O QEMU sem o BCM4356 não pode verificar o caminho final do rádio.

## Comandos de verificação

No hardware, antes da correção:

```bat
wmic path Win32_PnPEntity where "DeviceID like '%VEN_14E4&DEV_43EC%'" get Name,DeviceID,Status,ConfigManagerErrorCode
pnputil /enum-drivers
netsh wlan show drivers
```

Depois da correção:

```bat
wmic path Win32_PnPEntity where "DeviceID like '%VEN_14E4&DEV_43EC%'" get Name,DeviceID,Status,ConfigManagerErrorCode
pnputil /enum-drivers
netsh wlan show drivers
netsh wlan show interfaces
```

Esperado: código de erro `0`, o pacote de 2015 listado e o adaptador visível. Se o WMIC estiver ausente no WinRE, use `pnputil /enum-devices /problem` ou `devcon status`, se disponível.

## O que o QEMU pode e não pode provar

Pode provar:

- A imagem alvo contém o pacote de 2017.
- A imagem alvo não contém a nvram.
- A imagem offline tem o pacote de 2017 removido.
- A imagem offline tem o pacote de 2015 preparado.
- A origem da nvram está presente no pacote OEM preparado.
- Os arquivos de driver estão nos caminhos esperados do DriverStore.

Não pode provar:

- O BCM4356 inicia.
- O erro 10 vira 0.
- O Wi-Fi associa.
- A nvram é copiada para `System32\drivers` pelo PnP.

## Reproduzir o sintoma do erro 10 no QEMU (proposto, não provado)

O rádio real não pode ser emulado, mas o *sintoma* do erro 10 pode
potencialmente ser reproduzido sinteticamente. Duas abordagens, com fidelidades diferentes (veja `docs/04`):

- **A - dispositivo falso idêntico + driver real:** apresentar um dispositivo PCI do QEMU com o ID real
  (`x-pci-vendor-id=0x14e4,x-pci-device-id=0x43ec`, mais SUBSYS se o INF conferir) para que o
  Windows enumere `PCI\VEN_14E4&DEV_43EC` e o `bcmwdidhdpcie.inf` real vincule. O
  driver falha em iniciar em hardware não-BCM4356 -> erro 10. Fidelidade máxima de sintoma, mas
  um stub sem resposta não pode então ser *corrigido* (nenhum driver o inicia), então não
  demonstra a correção.
- **B - substituta funcional (e1000) + seleção de driver:** forçar um driver errado para obter o
  erro 10, depois o driver correto para iniciar. Demonstra a correção ponta a ponta, mas o
  dispositivo não é o BCM4356. Fidelidade menor; rotule como substituto.

Ambas precisam de um Windows completo inicializável com PnP (o repositório versiona só o WinRE). KVM é recomendado
por velocidade, não estritamente necessário - o TCG consegue inicializar o Windows devagar; este sandbox não tem
`/dev/kvm` e um boot anterior do WinRE deu BSOD sob TCG (não diagnosticado). Um agente com KVM deve executá-los.
São hipóteses, não resultados. Uma reprodução sintética do sintoma nunca é prova de hardware.
A digitação da nvram no WinRE real é o E3b (bloqueado no E1b).

## Referências

- `drivers/README.md`
- `drivers/nvram-delta/README.md`
- `docs/05-offline-servicing.md`
- `docs/08-checklist-hardware.md`
- `experiments/E1-baseline-winre.md`

---

## FILE: docs/04-fidelidade-mimetizacao.md

# Fidelidade e mimetização

> **Procedência:** verificada. A base 1809 foi reconferida contra
> `winre-1809-oficial-intacta/`, extraído do ESD oficial (`Core_en-us.esd`,
> 522.499.063 bytes, SHA-1 `8352af7661fb4808decc0253f6d516b7c2d88605`). O WIM
> (266.283.224 bytes, SHA-256 `232199c5…`) confere com o WIM derivado anterior caminho por
> caminho (21.230 entradas) e os 11 arquivos do estado de driver são idênticos byte a byte. Veja
> `docs/06-auditoria-imagem-1809.md`.

## Por que a fidelidade importa

O dispositivo real tem uma partição de recuperação de 398 MB. O repositório não tem essa imagem. Ela só foi vista na tela do dispositivo e não pode ser transferida. O desafio precisa ser explícito sobre o que é exato e o que é aproximado.

## Níveis

### F1 — padrão

Conteúdo:

- WinRE 1809, re-extraído do ESD oficial (`winre-1809-oficial-intacta/`).
- Estado alvo do DriverStore inbox 2017.
- Pacote Wi-Fi OEM 2015.
- Origem da nvram.

Exato:

- Build do WinRE.
- Versão do driver inbox.
- Versão do driver OEM.
- Nomes dos arquivos de driver.
- Nomes das pastas do DriverStore.
- Conteúdo da nvram.

Não exato:

- Partição de recuperação completa de 398 MB.
- Extras do OEM fora do subconjunto de drivers Broadcom.
- Estado de registro e BCD específico do dispositivo.

F1 é a definição de teste padrão porque o seu conteúdo é exato para o problema do driver, assumindo a procedência do WIM 1809 verificada.

### F2 — partição aproximada

Conteúdo:

- F1.
- Extras do OEM extraídos do WIM de fábrica 10586.

A base continua sendo o WIM do WinRE 1809. O WIM de fábrica 10586 contribui apenas com extras do OEM. Ele **não** contém `bcmwdidhdpcie.inf`, então não pode ser a base de drivers e não consegue reproduzir a falha do driver PCIe 2017 sem injeção.

Exato:

- Estado de drivers Broadcom do WinRE 1809.
- Mais do layout de arquivos do OEM da imagem de fábrica.

Não exato:

- Extras do build 10586 versus a base 1809.
- O layout real da partição de 398 MB.
- A configuração real do dispositivo.

F2 é opcional para a mecânica de drivers e útil para testar espaço e layout de arquivos. É uma aproximação candidata à partição de 398 MB, não uma aprovada; o F1 continua sendo o padrão para provar a correção do driver.

### F3 — imagem real do dispositivo

Conteúdo:

- O WIM real de 398 MB do dispositivo.

Este é o único nível totalmente idêntico. Não está disponível. Não o exija para o teste padrão. Se o usuário um dia o fornecer, use-o sem modificar o original versionado.

## Seleção da imagem base

Apenas o WinRE 1809 contém o pacote PCIe 2017 quebrado:

| Imagem | Build | `bcmwdidhdpcie.inf` | Papel |
|---|---:|---|---|
| ESD oficial 17763.9376 → WinRE (`winre-1809-oficial-intacta/`) | 17763 | 1.558.53.25 | Base de drivers; procedência verificada |
| `winre-fabrica-10586-424MB/` | 10586 | Ausente | Fonte dos extras do OEM |

O WIM de fábrica tem `bcmdhd`, `bcmdhd64`, `bcmfn2` e `bcmfn`, mas não tem o pacote PCIe `bcmwdidhdpcie`. É uma imagem de recuperação de 2015, não uma versão mais nova da imagem 1809. Usá-la como base de drivers exigiria injetar o pacote 2017, o que muda exatamente o estado sob teste.

Escolhas de trabalho:

- F1: só WinRE 1809. Melhor para a mecânica da correção do driver.
- F2: WinRE 1809 mais os extras do OEM do WIM de fábrica 10586. Melhor aproximação disponível à partição de 398 MB.
- F2b: WIM de fábrica 10586 mais um pacote PCIe 2017 injetado. Menos fiel ao build do dispositivo; use apenas como controle.
- F3: imagem real de 398 MB do dispositivo. Indisponível.

O repositório mantém os dois WIMs. Não apaga a imagem de fábrica. Nenhuma base está aprovada ainda. F2 é candidato só depois que o WIM 1809 for verificado contra uma referência oficial; a base de drivers, se aprovada, é a 1809. Se essa verificação de procedência falhar, a seleção da base é reaberta.

## O que "idêntico" significa

"Idêntico" pode significar quatro coisas diferentes:

1. Estado de driver idêntico: F1 basta.
2. Conteúdo da partição de recuperação idêntico: F2 aproxima, F3 é exato.
3. Comportamento de hardware idêntico: só o dispositivo físico pode fornecer isso.
4. *Identidade* de hardware idêntica (PCI ID) com um dispositivo falso: um experimento proposto do QEMU apresenta `PCI\VEN_14E4&DEV_43EC` para que o driver real vincule e reproduza o *sintoma* do erro 10, não a função do rádio. Veja Fidelidade da emulação de dispositivo abaixo.

O repositório não deve misturá-los.

## Fidelidade da emulação de dispositivo (proposto, não provado)

O dono perguntou se o QEMU consegue apresentar um **dispositivo falso idêntico ao hardware real**
para que o **driver real** vincule e reproduza o erro 10 - e não apenas um driver errado numa
NIC sem relação. Esta é uma dimensão de fidelidade distinta dos níveis de imagem acima. Está
**proposto e ainda não provado**; nada aqui foi executado.

### Abordagem A - dispositivo PCI falso idêntico + driver real (fidelidade máxima de sintoma)

Dispositivos PCI do QEMU aceitam sobreposição de IDs, ex.
`-device <dev>,x-pci-vendor-id=0x14e4,x-pci-device-id=0x43ec` (e
`x-pci-sub-vendor-id`/`x-pci-sub-device-id` se o INF conferir o SUBSYS). O Windows então
enumera `PCI\VEN_14E4&DEV_43EC`, o `bcmwdidhdpcie.inf` real da Broadcom vincula, e a
rotina de start do driver falha em hardware que não é de fato um BCM4356 -> o
*sintoma* do erro 10 (`CM_PROB_FAILED_START`). Isso reproduz o sintoma com o ID real de
dispositivo e o driver real.

**Limite crítico:** um stub sem resposta reproduz o erro 10, mas *nenhum* driver vai iniciá-lo,
então você não consegue demonstrar a correção (erro 10 -> 0) nesse mesmo dispositivo falso.
Fazê-lo iniciar exigiria um modelo de dispositivo QEMU personalizado que responda ao driver o
suficiente para inicializar - pesado, e ainda assim não o rádio real. Fidelidade de reprodução
não é demonstrabilidade de correção.

### Abordagem B - NIC substituta funcional + seleção de driver (demo da correção ponta a ponta)

Use uma NIC emulada funcional (e1000) e force um driver inbox/errado para que falhe ao
iniciar (erro 10), depois instale o driver correto para que inicie. Isso demonstra a correção
de seleção de driver ponta a ponta (o caso "NIC com erro 10 resolvida com outro driver"), mas é
de **fidelidade menor**: o dispositivo não é `VEN_14E4&DEV_43EC` e o rádio não é o
BCM4356. Rotule como substituto.

### Pré-requisitos e bloqueios

- Precisa de um Windows completo inicializável com PnP, não apenas o WinRE (o WinRE pode não iniciar a NIC).
  O repositório versiona apenas o WinRE, não um Windows completo instalado - este é o bloqueio principal.
- **KVM é um acelerador de velocidade, não um requisito rígido.** O QEMU TCG consegue inicializar o Windows, devagar.
  Este sandbox não tem `/dev/kvm` (4 vCPU, ~8 GB). Um boot anterior do WinRE de fábrica sob TCG
  deu BSOD antes do `cmd` interativo, mas isso nunca foi diagnosticado (sem logs retidos); pode ser
  um problema de configuração de boot (controladora de storage, modelo de CPU, qual WinRE), não uma impossibilidade do TCG.
- Um agente com KVM deve rodar E5/E6 por velocidade prática. A reprodução do erro-10 com
  Windows completo **ainda não demonstrada aqui**; também não está provado ser impossível sob TCG.
- Resultados possíveis incluem um BSOD em vez de limpamente o erro 10. Trate como hipótese até
  observado.

### Incremental, viável agora (sem KVM): transferir a nvram primeiro

O driver completo tem ~1 MB, mas a nvram da placa tem apenas **5361 bytes**. O plano do dono: enviar
a nvram pequena primeiro como texto digitado (hex/base64), reconstruí-la no convidado e verificar o hash.
Isso prova o canal de entrada com uma carga real e pequena e não precisa **de KVM nem de Windows**
(um convidado Linux mínimo basta para a prova do canal; WinRE, se inicializar). **Não** prova
a correção do rádio - o efeito funcional da nvram sobre o erro 10 é um teste de hardware. Uma tentativa
anterior chegou a 5305/5361 bytes antes de uma correção de ritmo; com decodificação incremental por linha e
digitação mais lenta espera-se completar. Este é o E3.

### Relato

Qualquer resultado de A ou B é um resultado de **reprodução sintética de sintoma**. Não é prova de
hardware e não mostra que o rádio real funciona. Mantenha intactos "o QEMU não emula o rádio
BCM4356" e "nenhum resultado do QEMU é prova de hardware".

## Capacidade do QEMU

O QEMU consegue:

- Inicializar o WinRE.
- Rodar `cmd`.
- Ler e escrever um disco virtual.
- Rodar servicing offline com DISM.
- Preparar e remover pacotes de driver.
- Servir um endpoint HTTP local via rede em modo usuário (só linha de base de mecânica, não o canal do dispositivo).
- Provar que arquivos e versões de driver mudaram.

O QEMU não consegue:

- Emular o rádio BCM4356.
- Reproduzir o erro 10 do BCM4356 real emulando o rádio em si. (Um dispositivo PCI falso com o ID real mais o driver real pode reproduzir o *sintoma*; veja Fidelidade da emulação de dispositivo acima - proposto, não emulação do rádio, não prova de hardware.)
- Provar a associação Wi-Fi.
- Provar que a nvram é consumida pelo firmware.
- Provar que o dispositivo inicializa o Windows 10 depois da recuperação.

## Verificações só de hardware

- `ConfigManagerErrorCode` de `PCI\VEN_14E4&DEV_43EC`.
- `netsh wlan show drivers`.
- `netsh wlan show interfaces`.
- Associação Wi-Fi.
- Instalação e boot do Windows.
- Comportamento de touch e tela.

## Sem transferência de dados

O dispositivo físico não consegue enviar arquivos. O usuário só pode ler a tela e digitar comandos. Portanto:

- Não peça ao usuário para colar saída do WMIC como etapa obrigatória.
- Não exija a imagem de 398 MB para o teste padrão.
- Não assuma clipboard nem pastas compartilhadas.
- Trate qualquer arquivo no dispositivo como já local ou entregue pelo canal sob teste.
- Documente a evidência de hardware como observações de tela e comandos digitados.

## Regra de relato

Todo resultado deve declarar o seu nível de fidelidade. Um resultado do QEMU é um resultado de mecânica software. Não é um resultado de hardware. Um resultado de hardware deve vir do dispositivo físico e deve incluir o código de erro observado e o estado do adaptador.

---

## FILE: docs/06-auditoria-imagem-1809.md

# Auditoria — documentos e evidências construídos sobre a imagem WinRE 1809 derivada

Data: 15/11/2026. Escopo: todo arquivo versionado neste repositório que nomeie
`winre-1809-254MB/`, os hashes das suas partes, ou o SHA-256 remontado
`f9e30ca308aa23e83d852ccefcfe7bca09a23d7c5b759ae655557612487879b8`.

## Objeto da auditoria

A imagem de 254 MB era uma **derivação local**, não um artefato da Microsoft:

- origem: `Core_en-us.esd`, build 17763.9376, amd64, core/Home, en-us;
- digest oficial: SHA-1 `8352af7661fb4808decc0253f6d516b7c2d88605`, 522.499.063 bytes;
- derivação: `wimlib-imagex export Core_en-us.esd 2 winre-1809.wim`, LZMS, `--boot`
  aplicado (Boot Index 1);
- resultado: 266.283.250 bytes em três partes, SHA-256 `f9e30c…`, 17.669 arquivos.

Medido em 15/11/2026 a partir do histórico do git: as três partes batem com o
`SHA256SUMS` publicado, e remontá-las reproduz `f9e30c…` exatamente. Então o arquivo
versionado é o arquivo gerado; nada mudou depois da divisão. Isso não é o mesmo
que provar procedência da Microsoft: o WIM foi recomprimido e o cabeçalho reescrito pelo wimlib,
então nenhum digest oficial pode nunca conferir com ele.

## Achados

Legenda de status:

- **qualificado** — o documento já diz que a procedência não está verificada.
- **condicional** — afirma fatos retirados da imagem (presença de arquivos, versões,
  tamanhos); válido só se o conteúdo conferir com o ESD oficial. **Fechado:** o ESD
  oficial foi baixado e verificado, e a re-extração conferiu (veja *Fechamento* abaixo).
- **só-mecânica** — um teste de runtime ou servicing executado sobre o WIM derivado; a
  conclusão é sobre o procedimento, não sobre mídia oficial.
- **distribuição** — publica ou serve a imagem derivada como se fosse uma base.
- **corrigido aqui** — atualizado nesta branch por este commit.

## Fechamento (15/11/2026, ainda no mesmo dia)

A auditoria está fechada para a árvore `desafio`. A fonte oficial foi reobtida pela API
do UUP dump (URL assinada do CDN da Microsoft) e verificada antes do uso:

| Item | Valor |
|---|---|
| ESD | `Core_en-us.esd`, build 17763.9376, amd64, core/Home, en-us |
| Tamanho do ESD | 522.499.063 bytes |
| ESD SHA-1 | `8352af7661fb4808decc0253f6d516b7c2d88605` |
| ESD SHA-256 | `b4d37e913b7cd5bf6de0b3c61ba05054e45e81e090d1767f649e825078115887` |
| Extração | `wimlib-imagex export Core_en-us.esd 2 … --compress=LZMS --boot` |
| Novo WIM | 266.283.224 bytes |
| Novo WIM SHA-256 | `232199c585111bfae71ff00dbdcabe5c75195fc9b431eb4d1711b8a7e471eb6c` |
| Lista de caminhos | 21.230 entradas, idêntica ao WIM derivado |
| Metadados | 17.669 arquivos, 3.560 diretórios, 2.169.435.125 bytes, build 17763 |
| Estado de drivers | 11 arquivos nas três pastas do DriverStore, idênticos byte a byte (`diff -r`) |
| nvram | 0 ocorrências na imagem |

Consequências:

- toda linha **condicional** abaixo agora está **verificada**: os fatos foram medidos sobre
  conteúdo extraído do ESD oficial verificado;
- o WIM `f9e30c…` anterior era um contêiner diferente (recompressão do wimlib, diferença de
  250 bytes no tamanho) com o mesmo conteúdo lógico; foi superado, não estava errado;
- os resultados só-mecânica continuam só-mecânica, mas agora descrevem conteúdo
  oficial, não um arquivo de origem desconhecida.

### Branch `desafio` (desafio atual)

| Arquivo | Uso da imagem | Status |
|---|---|---|
| `docs/03-driver-wifi-erro-10.md` | versões dos pacotes inbox e tamanhos de arquivos | verificado; banner atualizado |
| `docs/04-fidelidade-mimetizacao.md` | imagem base F1/F2 e tabela de base de drivers | verificado; caminho e nota atualizados |
| `docs/05-offline-servicing.md` | pré-condição "WIM base deve conter 1.558.53.25" | verificado; caminho aponta para a extração oficial |
| `drivers/README.md`, `drivers/README.pt-BR.md` | "Origem do inbox: WIM WinRE 1809" | verificado; banner e caminho atualizados |
| `drivers/estado-dispositivo/README.md` | retrato do DriverStore extraído do WIM | verificado (11 arquivos idênticos byte a byte); banner atualizado |
| `drivers/nvram-delta/README.md` | afirmação de que não existe nvram na imagem | verificado (0 ocorrências); banner atualizado |
| `experiments/README.md` | nota da decisão de base | feito; link da auditoria presente |
| `scripts/verify-repo.sh` | partes 1809, tamanho, hash e metadados esperados | corrigido: verifica as partes de `winre-1809-oficial-intacta/` |
| `.gitattributes` | regra `winre-1809-254MB/**` | corrigido: regra obsoleta removida |
| `winre-1809-254MB/` | as partes derivadas | removida em `a04f538`; substituída por `winre-1809-oficial-intacta/` |

### Branch `wwii` (não editada neste commit)

| Arquivo | Uso da imagem | Status |
|---|---|---|
| `winre-1809-254MB/` (partes + `SHA256SUMS`) | a própria imagem derivada, ainda versionada | **distribuição** |
| `experiments/E0.1-base-provenance.md` | registra os metadados do WIM e diz que não há hash oficial de referência | qualificado |
| `experiments/E0.2-repo-verification.md` | contagem de partes e hashes de remontagem | só-mecânica |
| `docs/03-*`, `docs/04-*`, `docs/05-*` | mesmo texto da `desafio` antes desta auditoria | condicional |
| `drivers/README*`, `drivers/estado-dispositivo/README.md`, `drivers/nvram-delta/README.md` | mesmas afirmações de extração | condicional |
| `scripts/verify-repo.sh` | espera as partes derivadas | só-mecânica |

### Branch `extras` (não editada neste commit)

| Arquivo | Uso da imagem | Status |
|---|---|---|
| `docs/imagem/DOSSIE.md`, `docs/imagem/INVENTARIO.md`, `docs/evidence/winre-1809-evidencia.md` | inspeção estática do **índice 2 do ESD** (fonte oficial), não do WIM derivado | sólido sob o digest do ESD oficial; não herda o defeito |
| `docs/evidence/driver-injecao.md` | injeta um driver de catálogo no WIM e re-extrai | só-mecânica |
| `docs/evidence/drivers-lote.md` | 6 pacotes de fornecedor injetados; 254 MB para 274 MB | só-mecânica |
| `docs/evidence/e4-*.md` | boot do WIM no QEMU, autorun, carregamento de driver | só-mecânica |
| `docs/evidence/e5-*.md` | transporte HTTP/FTP dentro do WIM inicializado | só-mecânica |
| `docs/RELATO-DONO-E-IMAGEM-FABRICA.md` | linha da tabela "WinRE 1809 (`imagem`, 254 MB)" | condicional |
| `scripts/obter_imagem.sh` | distribui o WIM derivado como base 1809 | **distribuição** |
| `MURAL.md`, `PROGRESS.md`, `PROBLEMAS.md`, `PROMPT.md` | hashes, afirmações de inventário, planos | condicional/só-mecânica |
| `imagens/winre-1809/` (quando em checkout) | as partes derivadas | **distribuição** |

### Branch `info`

| Arquivo | Uso da imagem | Status |
|---|---|---|
| `README.md` | inventário do WinRE 1809 e o resultado "6/6 drivers injetados, 254 MB para 274 MB" | só-mecânica/condicional |

### Branch `htmlai`

| Arquivo | Uso da imagem | Status |
|---|---|---|
| `artefatos/manifest.tsv` | publica URLs cruas do GitHub e SHA-256 das três partes derivadas | **distribuição** |

## Veredito

Nenhum documento afirma que `f9e30c…` é um digest da Microsoft, e
`experiments/E0.1-base-provenance.md` já havia registrado que não existe hash
oficial de referência. Logo, não há reivindicação de procedência fabricada.

Para a `desafio`, a questão aberta agora está respondida: o ESD oficial foi reobtido,
verificado por digest e re-extraído; o resultado confere com a imagem derivada anterior caminho
por caminho e byte por byte no estado de drivers. O desafio, portanto, se apoia em
conteúdo oficial verificado, e os resultados só-mecânica agora descrevem esse conteúdo.

Restando fora da `desafio`: as cópias derivadas ainda publicadas na `wwii`
(`winre-1809-254MB/`) e na `htmlai` (`artefatos/manifest.tsv`). Elas continuam com o
rótulo **distribuição** e precisam de decisão nessas branches (remover, ou rotular como
derivadas com o digest oficial ao lado).

## Como a auditoria foi fechada

1. `Core_en-us.esd` baixado pelo link registrado em
   `winre-1809-oficial-intacta/winre10-1809-254mb.url`, conferindo `SHA1SUMS` e a
   contagem de bytes: 522.499.063 bytes, SHA-1 `8352af76…`. Feito.
2. Índice 2 extraído com o wimlib; novo SHA-256 do WIM registrado (`232199c5…`) e a
   lista de 21.230 entradas. Feito; a lista é idêntica à do WIM derivado.
3. `drivers/estado-dispositivo/` comparado byte a byte com a extração nova:
   `diff -r` limpo para os 11 arquivos. Feito.
4. `scripts/verify-repo.sh` re-executado contra as partes novas. Feito.
5. Decisão sobre as cópias derivadas na `wwii` e na `htmlai`: ainda aberta, acompanhada acima.

---

## FILE: docs/07-inventario-imagens.md

# Inventário de imagens (o que os agentes têm disponível)

> **Procedência:** os dois WIMs foram remontados a partir das partes versionadas em `/tmp` (nunca na
> árvore de trabalho) e verificados: fábrica 10586 SHA-256 `152addc4…`, 1809 oficial SHA-256
> `232199c5…` (conferem com `scripts/verify-repo.sh`). Listagens produzidas com `wimlib-imagex dir`.
> O material bruto está em `inventory/names-only/` (só nomes de arquivo, divididos por tipo, + deltas binários). Este documento é o
> resumo curado para que os agentes raciocinem sobre soluções sem repetir a listagem das imagens.

## Por que isto existe

Os agentes precisam saber, desde o começo, quais ferramentas e arquivos existem dentro das duas imagens, para
poderem propor soluções consistentes com as restrições (métodos de reconstrução, canais, carga mínima)
em vez de assumir ferramentas que não estão lá.

## Contagens

| Imagem | Build | Caminhos | .exe | .dll | .sys | Binários ativos (sem WinSxS) |
|---|---:|---:|---:|---:|---:|---:|
| `winre-1809-oficial-intacta/` | 17763 | 21230 | 381 | 2785 | 958 | 2073 |
| `winre-fabrica-10586-424MB/` | 10586 | 26461 | 335 | 2625 | 876 | 1846 |

As contagens incluem duplicatas do componente WinSxS. "Ativo" exclui `/Windows/WinSxS/`.

## Ferramentas de reconstrução — a descoberta decisiva

O canal de entrada é texto digitado (hex/base64). Para usar uma carga **binária**, ela precisa ser
decodificada e escrita em disco dentro do WinRE. Disponibilidade de ferramentas (ambas as imagens, salvo indicação):

| Ferramenta | Presente? | Nota |
|---|---|---|
| `certutil.exe` | **AUSENTE (ambas)** | O óbvio `certutil -decodehex` NÃO está disponível. Não assuma. |
| `powershell.exe` | **AUSENTE** | Sem `[Convert]::FromBase64String`. |
| `msado15.dll` (ADODB.Stream) | **AUSENTE** | O clássico sumidouro de escrita binária por script NÃO está disponível. |
| `mscoree.dll` / `clr.dll` | **AUSENTE** | Sem .NET. |
| `cmd.exe` | SIM | `copy /b`, `copy con`, `echo >>`, redirecionamento. Somente texto. |
| `cscript.exe` / `wscript.exe` | SIM | Windows Script Host (JScript/VBScript). |
| `mshta.exe` | SIM | Aplicação HTML, host de script COM completo. |
| `regsvr32.exe` + `scrobj.dll` | SIM | Execução de scriptlets. |
| `jscript.dll` / `vbscript.dll` / `scrrun.dll` | SIM | Motores de script + FileSystemObject (texto). |
| `msxml3.dll` / `msxml6.dll` | SIM | MSXML consegue **decodificar** base64 (`dataType="bin.base64"` → array de bytes). |
| `crypt32.dll` | SIM | A API `CryptStringToBinary` existe, mas não é diretamente chamável por rundll32. |
| `fsutil.exe` | SIM | `file createnew nome 1` tem a hipótese de produzir um `0x00` de 1 byte (E7, não provado no WinRE). |
| `wshom.ocx` | SIM | `WScript.Shell` (rodar `copy /b`, `fsutil`). |
| `cdosys.dll` / `wiaaut.dll` / `makecab.exe` / `extrac32.exe` / `tar.exe` / `zipfldr.dll` | **AUSENTE** | Sem sumidouro binário CDO/WIA/cab/tar/zip. `cdosys.dll.mui` existe sem a DLL. |
| WMI (`WMIC.exe`, `wbemdisp.dll`, `stdprov.dll`) | SIM | Nenhuma classe identificada de escrita de bytes brutos em arquivo. |
| `esentutl.exe` / `print.exe` / `expand.exe` | SIM | Não são decodificadores hex/base64. |
| `notepad.exe` | SIM | Editor de texto. |
| `findstr.exe` / `debug.exe` / `edlin.exe` | AUSENTE | |

**Consequência:** a *decodificação* base64 é possível (MSXML), mas **escrever bytes brutos em disco ainda
está não provado no WinRE** — não há certutil, nem PowerShell, nem .NET, nem ADODB.Stream.
O E7 (owner: stackai) propõe um alfabeto de arquivos de 1 byte (`fsutil` para `0x00`, `Write` do FSO
para `1..255`, depois `copy /b`) e um algoritmo PASS no lado do host; o comportamento de
FSO/fsutil precisa ser sondado num WinRE inicializado (`scripts/winre-fso-probe.js`). Não reivindique
que funciona antes dessa sondagem. Evitar transferência binária (nvram primeiro) continua o caminho de menor risco.

## A nvram é TEXTO — a primeira carga viável

`drivers/nvram-delta/4356r2nvram.txt` (5361 bytes) é **ASCII 100% imprimível** (0 bytes não imprimíveis): uma configuração chave=valor de nvram da Broadcom. Ela precisa **de nenhum decodificador binário** — reconstrua com
`cmd` (`copy con` / `echo linha>>arquivo`) ou `notepad`. É por isso que "enviar a nvram primeiro" é a
primeira transferência mais viável (E3). O `.sys` do driver (~1 MB) é binário e esbarra no
problema aberto de escrita binária acima.

**Hipótese de carga mínima (ideia do dono):** o dispositivo já tem os arquivos do driver no seu
DriverStore; o que falta é a nvram (texto). Se o H1 (delta de nvram) for a correção, **só a
nvram em texto precisa cruzar o canal — nenhuma transferência binária.** Verifique no hardware se
só a nvram basta antes de assumir que o binário do driver de ~1 MB precisa ser digitado.

## Ferramentas de canal

| Ferramenta | Presente? | Nota |
|---|---|---|
| `TabTip.exe` | SIM (ambas) | O teclado virtual da tela touch — o canal de entrada. |
| `osk.exe` | AUSENTE | Teclado virtual na tela (legado) não está no WinRE. |
| `fsquirt.exe` | **AUSENTE** | O assistente de transferência de arquivos Bluetooth não está no WinRE. |
| Pilha Bluetooth (`bthport.sys`, `rfcomm.sys`, `bluetoothapis.dll`, …) | **AUSENTE (ambas)** | Só a INF de classe `c_bluetooth.inf` está presente. O WinRE não consegue usar Bluetooth como está. |
| `netsh.exe`, `ping.exe`, `ftp.exe`, `tracert.exe` | SIM | Ferramentas de rede existem, mas o dispositivo não tem rede funcional (Wi-Fi = erro 10). |

**Nuance do Bluetooth:** o pacote de driver Bluetooth OEM ESTÁ no repositório
(`drivers/mipad2-oficial/bt-uart/`: `oem24.inf`, `BtwSerialBus.sys`, `btwdi.dll`,
`BtwRSupportService.exe` e o firmware `.hcd` BCM4356). Mas o WinRE não tem a pilha
Bluetooth da Microsoft, então um canal Bluetooth exigiria carregar essa pilha primeiro. Se o BT
consegue carregar uma carga menor que o driver é investigação aberta (TODO), não um canal assumido.

## Gestão de drivers

| Ferramenta | 1809 | fábrica | Nota |
|---|---|---|---|
| `pnputil.exe` | SIM | **AUSENTE** | Gestão da loja de drivers; só na 1809. |
| `drvload.exe` | SIM | SIM | Carrega um driver no WinRE em execução. |
| `dism.exe` | SIM | SIM | Servicing offline (mecânica no lado do host). |
| `devcon.exe` | AUSENTE | AUSENTE | Não está em nenhuma das imagens. |
| `bcdedit.exe`, `bootrec.exe`, `diskpart.exe` | SIM | SIM | Recuperação de boot/disco. |

## Descompasso de firmware e o delta (por que nenhuma imagem é o dispositivo)

O dispositivo foi **atualizado depois da fábrica**. A sua partição de recuperação real tem ~398 MB e NÃO
está disponível. As duas imagens versionadas a delimitam, mas nenhuma é idêntica:

- **Fábrica 10586 (~424 MB):** tem os extras **SDIO** da Broadcom OEM — `bcmdhd63.sys`,
  `bcmdhd64.sys`, `bcmfn.sys`, `bcmfn2.sys` (DriverStore) — mais `intelppm.sys`, `intelide.sys`.
  **Não** contém a `bcmwdidhdpcie.inf` PCIe (o driver 2017 quebrado).
- **1809 oficial (~254 MB):** imagem limpa da Microsoft; contém o pacote PCIe 2017 quebrado
  `bcmwdidhdpcie`; não tem os extras SDIO do OEM.
- **Dispositivo (~398 MB, indisponível):** base 1809 atualizada **mais** extras do OEM. A diferença
  de tamanho sugere extras (bibliotecas/drivers/programas) que nenhuma das imagens versionadas reproduz por completo.

Delta de binários ativos (sem WinSxS): só-fábrica = 265, só-1809 = 492. Veja
`inventory/names-only/delta-fabrica-only-active.names.txt` e `inventory/names-only/delta-1809-only-active.names.txt`. Saber
o delta é necessário, mas pode não ser suficiente: uma biblioteca extra presente só no dispositivo
poderia importar. Aproximar a imagem atualizada do dispositivo (instalar fábrica, atualizar, depois listar
programas / construir um ISO) é um TODO aberto — veja `TODO.md`.

## Arquivos brutos de inventário

- `inventory/names-only/winre-1809/<tipo>.txt` e `inventory/names-only/winre-fabrica-10586/<tipo>.txt` — só nomes, únicos, por tipo (executaveis, bibliotecas, drivers, inf, catalogos, manifestos, idiomas, scripts, config, fontes, outros).
- `inventory/names-only/delta-*.names.txt` — delta de binários (ativos e completo com WinSxS), só nomes.

## Regra de relato

Este inventário é fato observado (presença de arquivos nas imagens verificadas). Reivindicações de
*capacidade* de ferramenta (ex. "MSXML consegue escrever binário aqui") são hipóteses até testadas num WinRE inicializado.
Nenhum resultado do QEMU é prova de hardware.

---

## FILE: drivers/README.md

# Drivers Broadcom do Mi Pad 2

Arquivos binários não devem ser colados no chat. Verifique-os com `sha256sum -c` e inspecione metadados com `wimlib-imagex` ou `objdump`.

> **Procedência:** verificada. Os arquivos "inbox do WinRE 1809" abaixo foram reconferidos contra
> `winre-1809-oficial-intacta/`, extraído do ESD oficial (`Core_en-us.esd`,
> 522.499.063 bytes, SHA-1 `8352af76…`). Os 11 arquivos das três pastas do DriverStore
> são idênticos byte a byte à extração derivada anterior; o WIM tem a mesma
> listagem de 21.230 caminhos. Veja `docs/06-auditoria-imagem-1809.md`.

## Layout

| Caminho | Origem | Versão | Conteúdo |
|---|---|---|---|
| `mipad2-oficial/wifi/` | Pacote OEM oficial do backup do Windows 10 do Mi Pad 2 | 1.558.14.0 (23/12/2015) | 16 arquivos, 13,97 MB. DEV 4355, 4364, 43A3, 43BA, 43C3, 43EC, 43EF, 440D |
| `mipad2-oficial/bt-uart/` | Mesmo backup OEM | 12.0.1.731 (10/09/2015) | 31 arquivos, 4,0 MB. Enumerador Bluetooth UART e firmware |
| `estado-dispositivo/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` | Inbox do WinRE 1809 | 1.558.53.25 (21/04/2017) | 4 arquivos, 2,2 MB. DEV 4355 e 43EC |
| `estado-dispositivo/bcmdhd64.inf_amd64_e0bae6831f60ea5f/` | Inbox do WinRE 1809 | 5.93.102.22 (06/08/2015) | 5 arquivos, 1,7 MB |
| `estado-dispositivo/bcmfn2.inf_amd64_5ebadf201c5b5845/` | Inbox do WinRE 1809 | 5.93.102.22 | 2 arquivos, 14 KB |
| `nvram-delta/` | Nvram OEM, renomeada para o caminho de busca do driver | n/d | 1 arquivo, 5.361 bytes |

O estado alvo é `estado-dispositivo/`. O pacote OEM não é o estado alvo; é a carga de substituição. A nvram não está no estado alvo.

## Estado Wi-Fi alvo

`estado-dispositivo/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` contém exatamente:

- `bcmwdidhdpcie.inf`
- `bcmpciedhd63.sys`
- `4356a2rtecdc.bin`
- `43596a0rtecdc.bin`

A pasta não tem nvram. O arquivo `43596a0rtecdc.bin` pertence à seção BCM4359 / `DEV_4355`. Ele fica na pasta porque o DriverStore alvo é mantido idêntico. A seção ativa `DEV_43EC` usa o firmware `4356a2rtecdc.bin`.

`SHA256SUMS` está em `estado-dispositivo/SHA256SUMS` e cobre os arquivos das três pastas do DriverStore. É um artefato do repositório, não um arquivo do DriverStore.

## Carga Wi-Fi OEM

`mipad2-oficial/wifi/oem25.inf` é a versão 1.558.14.0. A seção `DEV_43EC` é `BCM43XAC_NT62_4356`. A lista de cópia inclui:

- `bcmpciedhd63.sys`
- `4356r2rtecdc.bin` a partir de `4356a2rtecdc.bin`
- `4356r2nvram.txt` a partir de `bcm94356wlpagbl_P3_150828M.txt`

O pacote OEM inclui o catálogo `bcmpciedhd63.cat` e as DLLs IHV. O INF do inbox não inclui a linha de cópia da nvram e não inclui arquivo de catálogo.

## Conflito de versões

- Inbox: 21/04/2017, 1.558.53.25.
- OEM: 23/12/2015, 1.558.14.0.
- O Windows classifica o driver mais novo acima.
- Instalar o pacote OEM sem remover o pacote inbox não basta.
- A correção precisa remover o pacote inbox ou forçar o driver OEM.

## Detalhes medidos

- `bcmpciedhd63.sys` difere entre os pacotes: inbox 1.037.824 bytes; OEM 1.041.320 bytes.
- Carga Wi-Fi alvo para o `DEV_43EC`: `bcmpciedhd63.sys`, `4356a2rtecdc.bin`, nvram OEM, `oem25.inf`, `bcmpciedhd63.cat`, `bcmihvsrv64.dll`, `bcmihvui64.dll`.
- O INF do inbox não menciona nvram, `bcmihv*.dll` nem `CatalogFile`.
- A imagem do WinRE já contém o `.sys` inbox e o firmware `4356a2rtecdc.bin` no DriverStore, mas não a nvram.

## Origem e hashes

- Origem OEM: https://github.com/brianwoo/mipad2-win10-howto, commit `8526424ca49d9077c16329f150fa176b88bd642e`, arquivos `win10_drivers.7z.001..004`.
- A origem OEM é um backup DoubleDriver de um Windows 10 de fábrica build 10586. Isto é uma inferência, não confirmada independentemente.
- SHA-256 dos arquivos:
  - 001: `10c5b7dfa4c229f6e46a0473e131dd37832973a0b2945e85365998049906b7c3`
  - 002: `8445601afb505de97d23d4f2da25ccab3bb9ff091b73a227ac2b06f182b9198a`
  - 003: `884b82c033fb87cde6a3df9d190eb6197e49f1ebf12cf0bb129803578bd0ada6`
  - 004: `190004e186e0b6aefa4f29778f9affeebe85f3605e6433c799d2daf8456e4c22`
- Origem inbox: WinRE 1809 extraído do ESD oficial em `winre-1809-oficial-intacta/` (verificado); a cópia derivada anterior `winre-1809-254MB/` foi superada.
- SHA-256 da nvram OEM: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.

---

## FILE: drivers/estado-dispositivo/README.md

# Estado do dispositivo alvo

Este diretório é um retrato do estado do DriverStore da Broadcom na imagem WinRE 1809. Não é o pacote OEM e não é uma hipótese.

> **Procedência:** verificada. O retrato foi reconferido contra
> `winre-1809-oficial-intacta/`, extraído do ESD oficial (`Core_en-us.esd`,
> 522.499.063 bytes, SHA-1 `8352af76…`). Os 11 arquivos são idênticos byte a byte à
> extração derivada anterior. Veja `docs/06-auditoria-imagem-1809.md`.

## Nomes exatos de pastas do DriverStore

| Pasta | Arquivos |
|---|---|
| `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` | 4 |
| `bcmdhd64.inf_amd64_e0bae6831f60ea5f/` | 5 |
| `bcmfn2.inf_amd64_5ebadf201c5b5845/` | 2 |

## Pacote Wi-Fi

`bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/`:

- `bcmwdidhdpcie.inf`
- `bcmpciedhd63.sys`
- `4356a2rtecdc.bin`
- `43596a0rtecdc.bin`

A pasta não tem arquivo de nvram.

O arquivo `43596a0rtecdc.bin` pertence à seção BCM4359 / `DEV_4355`. Ele permanece na pasta porque o DriverStore alvo é mantido idêntico. A seção `DEV_43EC` usa `4356a2rtecdc.bin`.

## Pacotes SDIO

`bcmdhd64.inf_amd64_e0bae6831f60ea5f/`:

- `bcmdhd64.inf`
- `bcmdhd63.sys`
- `43241b4rtecdc.bin`
- `4324b5rtecdc.bin`
- `43341b0rtecdc.bin`

`bcmfn2.inf_amd64_5ebadf201c5b5845/`:

- `bcmfn2.inf`
- `bcmfn2.sys`

## Checksums

`SHA256SUMS` é um artefato do repositório neste nível. Ele cobre os arquivos de driver com caminhos relativos. Não é copiado para dentro de uma pasta do DriverStore.

## Origem

Extraído de `winre-1809-oficial-intacta/` (ESD oficial), índice de imagem 2, caminho `Windows/System32/DriverStore/FileRepository/`. Procedência verificada: os 11 arquivos são idênticos byte a byte à extração derivada anterior em `winre-1809-254MB/`.

Os nomes exatos das pastas foram lidos com `wimlib-imagex dir`.

## O que este estado significa

- O pacote Wi-Fi é o pacote inbox de 2017, versão 1.558.53.25.
- O estado alvo não contém a nvram da placa.
- O estado alvo é a linha de base quebrada. O pacote OEM é a carga de correção.
- Não adicione a nvram aqui. Use `drivers/nvram-delta/` ou o pacote OEM.
- Não trate este retrato como a partição de recuperação completa de 398 MB. É apenas o subconjunto de drivers Broadcom.

---

## FILE: drivers/nvram-delta/README.md

# Delta de nvram

> **Procedência:** verificada. As afirmações de "ausente da imagem" abaixo foram
> reconferidas em `winre-1809-oficial-intacta/`, extraído do ESD oficial
> (`Core_en-us.esd`, 522.499.063 bytes, SHA-1 `8352af76…`). O nome da nvram ocorre zero
> vezes na imagem. Veja `docs/06-auditoria-imagem-1809.md`.

## Propósito

Este diretório contém a menor carga de nvram de que o driver Broadcom pode precisar quando o pacote OEM de 2015 é usado.

`4356r2nvram.txt` é o arquivo de nvram OEM `bcm94356wlpagbl_P3_150828M.txt`, renomeado para o nome fixo que o driver procura.

- Tamanho: 5.361 bytes.
- SHA-256: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
- O arquivo é idêntico byte a byte à origem OEM.
- O arquivo não está presente no estado do DriverStore alvo.
- O arquivo não está presente em nenhum lugar da imagem WinRE 1809 (verificado na extração oficial: zero ocorrências).

## Evidência da busca do driver

Strings lidas do `bcmpciedhd63.sys` inbox mostram estes caminhos:

```text
\SystemRoot\system32\drivers\%04Xr%drtecdc.bin
\SystemRoot\system32\drivers\%04Xr%dnvram.txt
```

Para o dispositivo BCM4356 / `DEV_43EC`, os nomes resolvem para:

```text
\SystemRoot\system32\drivers\4356r2rtecdc.bin
\SystemRoot\system32\drivers\4356r2nvram.txt
```

A origem do firmware existe no DriverStore do WinRE como `4356a2rtecdc.bin`. A origem da nvram não existe na imagem.

Os INFs OEM e inbox concordam na renomeação do firmware:

```text
4356r2rtecdc.bin,4356a2rtecdc.bin,,6
```

Apenas o INF do OEM contém a renomeação da nvram:

```text
4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6
```

Essa linha ausente é o delta de nvram.

## Relação com a correção

O H2 é a hipótese primária: o driver inbox de 2017 é a regressão, e o pacote OEM de 2015 é a correção. O pacote OEM já contém a origem da nvram e a regra de cópia.

O H1 é secundário: se a nvram não for copiada pela instalação do driver, a nvram deve ser fornecida separadamente. O driver procura em `System32\drivers`.

A adição de driver por DISM offline prepara o pacote OEM no DriverStore offline. Não garante que a lista de cópia do INF rodou para o dispositivo. O `CopyFiles` real acontece durante a instalação PnP do dispositivo. No QEMU sem o BCM4356, só o preparo pode ser verificado.

## Aplicando só a nvram

Isto é um plano B, não a correção primária:

```bat
for %%D in (C D E F G H) do if exist %%D:\4356r2nvram.txt copy /Y %%D:\4356r2nvram.txt %SystemRoot%\System32\drivers\
pnputil /scan-devices
netsh wlan show drivers
```

Não assuma unidade USB, pasta compartilhada ou clipboard. A carga já precisa estar num volume local ou chegar pelo canal externo sob teste.

## O que confirmaria o H1

- `netsh wlan show drivers` lista o adaptador no dispositivo físico.
- `ConfigManagerErrorCode` vira `0`.
- O log do driver deixa de reportar `dongle nvram file download failed`.

O QEMU não pode confirmar o resultado do rádio. Pode confirmar que o arquivo está presente no caminho esperado e que o pacote de driver está preparado.

## O que confirmaria o H2

- O estado alvo mostra o driver inbox de 2017.
- A imagem offline mostra o driver OEM de 2015 depois da remoção do pacote inbox.
- O dispositivo físico inicia o adaptador com o driver de 2015.
- O mesmo dispositivo falha com o driver de 2017.

## Referências

- `drivers/README.md`
- `docs/03-driver-wifi-erro-10.md`
- `docs/05-offline-servicing.md`

---

## FILE: experiments/E1-winre-boot-tcg.md

# Experimento E1/E1b — boot do WinRE no QEMU sob TCG, e a matriz de causa raiz do BSOD

## Objetivo

Pergunta única: **este sandbox consegue inicializar um WinRE rastreado até um `cmd` interativo
sob TCG, e se não consegue, qual é a causa real do bugcheck?**

E3b (reconstruir a nvram dentro do WinRE com as ferramentas da própria imagem) está bloqueada
até que o WinRE alcance o `cmd`. O repositório registra hoje apenas "o WinRE chega ao kernel e
BSODa antes do `cmd` interativo; o BSOD não foi diagnosticado" (`qemu/README.md`). Este
experimento substitui essa reivindicação não medida por um código de parada retido e por uma
matriz com variáveis variadas.

## Nível de fidelidade

`F1` conforme `docs/04-fidelidade-mimetizacao.md`: o WinRE 1809 oficial
(`winre-1809-oficial-intacta/`, build 17763, a imagem que contém o pacote PCIe de 2017
quebrado) é a base de drivers. A imagem de fábrica 10586 roda apenas como controle.

> **Inconsistência do repositório notada ao preparar esta rodada:** `qemu/build-media.sh` nomeia
> o WIM reassemblado **de fábrica 10586** como `qemu/work/f1.wim`, e `qemu/build-iso.sh` usa
> esse arquivo como padrão. De acordo com a definição atual do `docs/04`, F1 é o WinRE **1809**,
> não a imagem de fábrica. Seguir o padrão do script testaria silenciosamente outro nível de
> fidelidade além do que os docs declaram. Este experimento constrói a imagem 1809
> explicitamente e deixa o script intocado para que o dono decida.

## Pré-condições

- Ferramentas: `qemu-system-x86` 6.2.0, `ovmf` 2022.02-3ubuntu0.22.04.7, `wimtools`
  (wimlib-imagex 1.13.5), `mtools` 4.0.32, `xorriso` 1.5.4, `python3` 3.12.
- Espaço livre: cerca de 19 G antes da reassemblagem; cada WIM unido tem cerca de 266 MB / 445 MB.
- As imagens precisam ser provadas primeiro: `scripts/verify-images.sh` (partes + digests unidos).
- As partes de WIM rastreadas **não** são modificadas; todo o trabalho fica sob `qemu/work/` (ignorado pelo git).
- `qemu/audit.sh` precisa passar com o argv exato antes de cada boot.

## Ambiente

- Data: 16/11/2026 (UTC)
- Host: sandbox Ubuntu 22.04.5 LTS, kernel `Linux 5.10.134-013.10.1.kangaroo.al8.x86_64`, usuário `root`
- Virtualização: **somente TCG** — `/dev/kvm` ausente, flags `vmx`/`svm` em `0`, 4 vCPU, 8 GB de RAM.
  O dono autorizou explicitamente o TCG para esta sessão.
- Versões das ferramentas: conforme registrado acima (`qemu-system-x86_64 --version`, `wimlib-imagex --version`,
  `xorriso --version`, `mformat --version`, `dpkg -l ovmf`)
- Hashes das imagens: ver Artefatos (de `scripts/verify-images.sh`)

## Matriz

Cada célula varia exatamente uma variável em relação à célula A, de modo que qualquer diferença seja atribuível.

| ID | Imagem | Máquina | `-cpu` | Memória | Pergunta respondida |
|---|---|---|---|---|---|
| A | WinRE 1809 (F1) | `pc` | `qemu64` | 2048 | Reproduzir a linha de base de BSOD registrada |
| B | WinRE 1809 (F1) | `pc` | `max` | 2048 | É falta de algum conjunto de instruções do CPU (SSE4/AVX/popcnt)? |
| C | WinRE 1809 (F1) | `q35` | `max` | 2048 | É o chipset/PIIX versus ICH9 + complexo raiz PCIe? |
| D | WinRE 10586 (controle) | `pc` | `max` | 2048 | É específico do build 1809? |

O dispositivo de boot é a ISO UEFI em todas as células (`-boot d`), de modo que o controlador
de armazenamento não está no caminho de carga do kernel; uma variante de controlador de disco
só tem sentido quando uma célula alcança o ponto em que o Windows carrega de um disco, o que
nenhuma célula aqui alcança ainda.

Evidência por célula: frames de `screendump` do monitor do QEMU a cada 30 s (PPM → PNG),
retidos em `e1-<celula>/`. `-serial file:` é proibido pelo `qemu/audit.sh`
(anti-trapaça), então a tela é o único canal — que é também exatamente o canal do dispositivo real.

## Comandos

```sh
# 1. provar as imagens rastreadas
sh scripts/verify-images.sh

# 2. reassemblar o WinRE 1809 oficial na área de trabalho ignorada pelo git
mkdir -p qemu/work
cat winre-1809-oficial-intacta/winre-1809-oficial.wim.part-* > qemu/work/winre1809.wim
sha256sum qemu/work/winre1809.wim

# 3. construir a ISO UEFI a partir dessa cópia
sh qemu/build-iso.sh qemu/work/winre1809.wim

# 4. auditar o argv exato (portão) e então inicializar, célula A como modelo
bash qemu/run-winre.sh          # BUDGET=<segundos> para o caminho lento do TCG
```

## Saída observada

### Portão de pré-condições — imagens rastreadas (`scripts/verify-images.sh`, 16/11/2026)

```text
OK    1809  266283224 bytes  232199c585111bfae71ff00dbdcabe5c75195fc9b4…  build 17763, 17669 files, 3560 dirs
OK    10586  444858791 bytes  152addc420748815c2cad90d382229e249ec853d38…  build 10586, 21867 files, 4593 dirs
== 2 image(s) verified, 0 failure(s)
```

A reassemblagem na área de trabalho reproduziu o digest registrado exatamente:

```text
232199c585111bfae71ff00dbdcabe5c75195fc9b431eb4d1711b8a7e471eb6c  qemu/work/winre1809.wim
```

### Células A e B — o "BSOD" registrado não é um BSOD

ISO construída pelo `qemu/build-iso.sh` **sem modificações** a partir do WIM 1809:
275.548.160 bytes, SHA-256 `5034d7d8d8e6b944990cd47347772f5edfb3e2038cb95b0664384a40800a8550`.
`qemu/audit.sh` devolveu PASS com o argv exato em ambas as células.

| Célula | máquina | cpu | tela em t=30 s | QEMU |
|---|---|---|---|---|
| A | `pc` | `qemu64` | erro do Windows Boot Manager (transcrito abaixo) | encerrou em t=60 s |
| B | `pc` | `max` | frame idêntico, saída idêntica | encerrou em t=60 s |

Transcrição do `frame-30.png` (ambas as células, texto byte-idêntico):

```text
Windows Boot Manager

Windows failed to start. A recent hardware or software change might be the
cause. To fix the problem:

  1. Insert your Windows installation disc and restart your computer.
  2. Choose your language settings, and then click "Next."
  3. Click "Repair your computer."

If you do not have this disc, contact your system administrator or computer
manufacturer for assistance.

     File: \EFI\Microsoft\Boot\BCD

    Status: 0xc000000f

     Info: The Boot Configuration Data for your PC is missing or contains
           errors.
```

Não há bugcheck, não há código de parada, não há barra de progresso: o `winload` nunca recebeu
um BCD, então o kernel nunca foi carregado. `-no-reboot` é o motivo de o QEMU encerrar — o boot
manager reinicia depois de mostrar o erro.

### Causa raiz encontrada no harness, não no TCG

`qemu/build-iso.sh` colocou o BCD apenas na árvore ISO9660 (`EFI/Microsoft/Boot/BCD` dentro
do sistema de arquivos RockRidge/Joliet). A imagem ESP de El Torito sem emulação (`efi.img`)
continha apenas `EFI/Boot/bootx64.efi`. O OVMF carrega o `bootx64.efi` **a partir dessa imagem
ESP**, e o `bootmgfw.efi` então lê o seu BCD do mesmo volume — onde ele não existe.
O próprio BCD é o template correto de DVD: as suas strings referenciam `\boot\boot.sdi`,
`\sources\boot.wim`, `\windows\system32\boot\winload.efi`, ou seja, caminhos no volume de
boot, que o lado ISO9660 de fato fornece.

Correção aplicada ao `qemu/build-iso.sh`: criar `EFI/Microsoft/Boot` dentro do `efi.img` e
copiar o BCD para lá com `mcopy`, mantendo também a cópia ISO9660.

Uma tentativa intermediária falhou e é registrada honestamente: `mmd -p` (criar diretórios-pai)
não é suportado pelo mtools 4.0.32 e, como o script roda sob `set -e`, ele abortou antes do
`xorriso`, deixando silenciosamente a ISO anterior no lugar. Substituído por duas chamadas
explícitas de `mmd`.

ISO reconstruída: 275.548.160 bytes, SHA-256 `1abcc006609884645b89919ab36e5df651a55df01b6137a4c70d2db366a976ba`,
a listagem do ESP confirma `EFI/MICROS~1/BOOT/BCD 16384` (nome longo `Microsoft` presente como LFN).

### Célula A2 — boot com a ISO corrigida: uma camada adiante, ainda não o kernel

| Célula | máquina | cpu | mídia | tela em t=60 s | QEMU |
|---|---|---|---|---|---|
| A2 | `pc` | `qemu64` | ISO v2 | Boot Manager, **sem linha `File:`**, `Status: 0xc000000f`, `Info: A required device isn't connected or can't be accessed`, rodapé `ENTER=OS Selection` | encerrou em t=60 s |

O BCD agora é encontrado e processado — o rodapé que oferece "OS Selection" prova que existe
uma entrada de loader — mas o `bootmgfw.efi` não consegue alcançar o volume que guarda
`\boot\boot.sdi` e `\sources\boot.wim`. Fato observado: com a imagem ESP de El Torito, o
boot para aqui. Hipótese (não provada por esta rodada): a imagem ESP de 4 MB é o único volume
FAT que o loader EFI do Windows enumera, e o lado ISO9660 não é exposto como volume inicializável
porque a imagem não tem uma entrada de partição híbrida MBR/GPT — o `oscdimg` da Microsoft marca
o ESP como partição GPT (`-partition_type 0x1C -partition_head`), o que o `xorriso -as mkisofs`
invocado aqui não faz. De qualquer forma, isto é uma limitação de layout de mídia do harness,
não uma limitação do TCG e nem o problema do driver. A célula E testa em vez disso o layout de
volume único.

### Célula E — volume único FAT32 (`qemu/build-disk.sh`)

O repositório já documenta a alternativa robusta no `qemu/build-disk.sh`: um único ESP FAT32
que contém `\EFI\Boot\bootx64.efi`, `\EFI\Microsoft\Boot\BCD`, `\Boot\boot.sdi` e
`\sources\boot.wim` no *mesmo* volume, de modo que os caminhos de volume de boot do BCD se
resolvem.

```text
UEFI disk built from qemu/work/winre1809.wim:
-rw-r--r-- 1 root root 629145600 qemu/work/winre.img
2819a56f36ebd04cda7e38269e3731d98963c473b442116b28792e27f04c1105  qemu/work/winre.img
```

`qemu/audit.sh` PASS no argv exato (`-drive file=…format=raw -boot c`, ainda NAT de modo de
usuário apenas).

| Célula | máquina | cpu | mem | rastro de tela | QEMU |
|---|---|---|---|---|---|
| E | `pc` | `qemu64` | 2048 | t=60 s: azul uniforme `#2067B2`, sem texto | encerrou até t=120 s |
| F | `pc` | `max` | 2048 | t=10 s: `BdsDxe: starting Boot0002 "UEFI QEMU HARDDISK"` do TianoCore (o disco é encontrado e o `bootx64.efi` roda); t=20/30/40 s: azul uniforme `#2067B2` idêntico, zero texto, carga de CPU do guest ~0,25 em 4 hosts (guest ocioso, não computando) | encerrou em t=50 s |

A célula F prova duas coisas: o layout de volume único FAT32 **faz** o boot manager do Windows
rodar (o caminho ISO nem sequer alcançou isso), e a falha é uma parada silenciosa sem texto de
bugcheck renderizado.

### Segunda causa raiz encontrada por aritmética: a RAM do harness está abaixo do tamanho da imagem

`wimlib-imagex info` sobre as duas imagens unidas:

```text
qemu/work/winre1809.wim   Total Bytes: 2,169,435,125   (2.02 GiB)  build 17763
qemu/work/firmware.wim    Total Bytes: 2,234,709,726   (2.08 GiB)  build 10586
```

O WinRE inicializa expandindo o WIM para um **disco de RAM**, e esse disco de RAM é onde o
sistema em execução vive. `qemu/run-winre.sh` e `qemu/run-winre-disk.sh` fixam
`-m 2048`. O próprio WinRE 1809 descomprimido tem 2,02 GiB, então um guest de 2 GiB não pode
conter o ramdisk mais o sistema em execução — o boot está condenado antes de qualquer pergunta
sobre modelo de CPU, chipset ou controlador de armazenamento. A mesma aritmética mata a imagem
de fábrica 10586 (2,08 GiB), o que é consistente com a observação antiga de "WinRE de fábrica
BSODa sob TCG".

O `boot.sdi` extraído de `/Windows/Boot/DVD/EFI/boot.sdi` é um template vazio
(cabeçalho `$SDI0001`, descritor MBR todo em zeros), então ele não impõe um limite menor de
ramdisk; a RAM do guest é a restrição vinculante.

A célula G testa a memória corrigida (`MEM=4096`, `-cpu max`, `-machine pc`, o mesmo disco FAT32).

### Células G e H — 4 GiB não mudam nada: azul silencioso, e então o guest se desliga

| Célula | mem | `-no-reboot` | intervalo | resultado |
|---|---|---|---|---|
| G | 4096 | sim | 20 s | t=20 s `BdsDxe: starting Boot0002 "UEFI QEMU HARDDISK"` do TianoCore; t=40 s e t=60 s azul uniforme; QEMU encerrou em t=60 s |
| H | 4096 | **não** | 5 s | t=5/10 s tela de texto; t=15/20/25 s azul uniforme; QEMU encerrou em t=30 s **mesmo sem `-no-reboot`** |

Análise de pixels de cada frame de E, F, G, H:

```text
frame com conteúdo:  66 cores distintas, dominante (0,0,0)      -> texto sobre preto
frame "azul":         1 cor, (32,103,178) = #2067B2, 786432 px  -> nenhum texto, nenhum logo
```

Dois fatos se seguem, e eles estreitam muito o problema:

1. Subir o guest para 4 GiB não mudou o resultado, então o achado de memória é aritmética real
   sobre o padrão *antigo* do harness, mas **não** é o que para este boot. A matriz não deve
   parar aqui: `-m 2048` continuava sendo um defeito genuíno que valia a correção.
2. A célula H rodou sem `-no-reboot` e o QEMU ainda encerrou em t=30 s. O QEMU só encerra por
   conta própria em um erro do modelo de dispositivo ou quando o guest pede power-off /
   `ResetSystem()`. O `qemu.log` está vazio em todas as células, então nenhum erro de modelo
   de dispositivo foi reportado. Hipótese de trabalho: o próprio guest pediu o
   reset/power-off cerca de 15 s depois do aparecimento da tela azul — ou seja, o `bootmgr`
   desenhou algo e então chamou o reset EFI. O runner agora registra o código de saída do QEMU,
   de modo que isso é medido, não argumentado.

O azul não é um bugcheck renderizado: um BSOD do Win10 sempre desenha o texto de rosto triste e
uma porcentagem, e aqui o frame é uma cor única com o guest ocioso (carga ~0,25 em 4 vCPUs de
host enquanto a VM estava de pé). `#2067B2` é o azul da interface de recuperação do Windows,
de modo que a leitura mais provável é uma tela de recuperação/erro desenhada por um caminho que
a captura do framebuffer não mostra, ou uma mudança de modo que a captura não acompanha.

### Célula I — mídia BIOS/PCAT (SeaBIOS + etfsboot.com), mesmo WinRE 1809

Como o caminho UEFI para antes de qualquer texto, a mesma imagem é testada pela rota clássica
de CD do WinPE, que é o que o template BCD dentro do WIM realmente espera
(`[boot]\sources\boot.wim`, `[boot]\boot\boot.sdi`). O `build-pcat-iso.sh`
extrai o template PCAT do próprio WIM (`/Windows/Boot/DVD/PCAT/BCD`, `boot.sdi`,
`etfsboot.com`, `en-US/bootfix.bin`) e constrói uma ISO inicializável por BIOS via El Torito
com `-boot-info-table`:

```text
-rw-r--r-- 1 root root 269864960 qemu/work/winre-pcat.iso
7468444e9c280ecfaeb7b7ba3205127ff4c70d924ec36fee476d4e4c81fc797c
```

`qemu/audit.sh` PASS no argv de BIOS (sem drives pflash, ainda NAT de modo de usuário apenas).

**Resultado da célula I (medido dos frames retidos, `qemu/work/e1-I/`):** a tela alcança o modo
texto VGA (720x400, exatamente 2 cores: fundo `gray(0)` e glifos `gray(168)`) e permanece em:

```text
SeaBIOS (version 1.15.0.1)
iPXE (https://ipxe.org) 00:03.0 CA00 PCI2.10 PnP <...> CA00
Booting from DVD/CD...
```

`compare -metric AE` entre `frame-30.png` e `frame-150.png` devolve **0** — o frame é
byte-idêntico por 350 s. Então isto não é um boot lento, é uma entrega morta: o SeaBIOS carrega
a imagem de El Torito, imprime a sua mensagem, e o `etfsboot` nunca chega a imprimir nada.
O runner foi morto em t=360 s (saída por sinal, não power-off do guest, ao contrário das células E-H).

As estruturas de El Torito explicam a falha e foram lidas diretamente da mídia. O dump abaixo é
do build sem bootfix (`qemu/work/winre-pcat.iso` como reconstruído pelo script atual,
269.862.912 bytes, sha256 `736b5e27…`), que é o mesmo layout de loader que a célula J usou; a
mídia da célula I era 2.048 bytes maior (`269,864,960`, sha256 `7468444e…`) só porque ela
também carregava o `bootfix.bin`. Esse arquivo foi sobrescrito no sandbox desde então, então o
artefato da célula I é descrito a partir do digest registrado, não re-dumpado.

| Campo | Valor | Leitura |
|---|---|---|
| LBA do catálogo de boot | 38 (`0x26` no boot record do setor 17) | presente, checksum `aa55 55aa` |
| entrada do catálogo | `bootable=0x88`, `load_size=0x0004`, `load_rba=0x0027` | 4 setores = **2048 bytes** carregados do LBA 39 |
| `etfsboot.com` no WIM | 4096 bytes | o catálogo carrega só **metade** do arquivo |
| imagem de boot no LBA 39, offset 0x08 | `10 00 00 00 27 00 00 00 00 10 00 00 1c a8 ed 46` | o xorriso *escreveu* de fato a boot info table (LBA 39, tamanho 0x1000) |
| imagem de boot no LBA 39, offset 0x40 | `3d c0 07 75 1d 8c c8 8e …` | byte-idêntica ao arquivo sem patch: código, não tabela |

Uma captura anterior de registradores na mesma mídia (QEMU manual com um socket de monitor
separado) mostrou `EIP=0x1bf` em modo real depois de "Booting from DVD/CD...", ou seja, a
execução parou dentro do segmento carregado em vez de num ponto de entrada de loader. Isso é
consistente com a questão de load-size/segundo estágio acima, e é a razão de a célula L existir.

**Célula J (resultado):** a mesma mídia reconstruída **sem** `bootfix.bin` (o script agora a
omite deliberadamente) comporta-se de forma idêntica — os frames de `qemu/work/e1-J/` mostram a
mesma tela de duas cores "Booting from DVD/CD...", `compare -metric AE` de novo 0 entre os
frames, morta em t=120 s. Então o aviso "press any key" **não** é o que bloqueia o caminho PCAT:
a mídia já está depois dessa etapa e ainda não vai a lugar nenhum. Hipótese eliminada.

**Célula L (variável: `-boot-load-size 8`, ou seja, o `etfsboot.com` completo de 4096 bytes
carregado):**
`OUT=qemu/work/winre-pcat-l8.iso LOADSIZE=8 sh build-pcat-iso.sh` →
269.862.912 bytes, sha256 `932b900392346b8601a783dae78987de70e6408bba6d465dfc4317fed3969989`.
Rodada como `BIOS=1 MEM=4096 e1-run.sh L qemu/work/winre-pcat-l8.iso pc qemu64 420 30`.
**Resultado da célula L — `-boot-load-size 8` não muda nada.** Os frames são a mesma tela de
duas cores "Booting from DVD/CD..."; `compare -metric AE` contra `frame-30.png` dá 18
em t=60 s e 0 em t=90 s, ou seja, só o cursor de texto pisca. Então carregar o `etfsboot.com`
completo de 4096 bytes também não é a correção. Hipótese eliminada.

O que as três células PCAT têm em comum é um layout de mídia que não pode funcionar: o
`etfsboot` não lê `sources\boot.wim` por si mesmo. Ele procura `\boot\pcatboot.wim` —
um pequeno WIM cujo payload é `\Windows\Boot\PCAT\bootmgr` — carrega esse arquivo como
ambiente de boot, e só então o `bootmgr` lê o `\boot\BCD` e puxa o `\sources\boot.wim`
para o disco de RAM. A árvore construída pelo script tinha `boot/BCD`, `boot/boot.sdi`,
`boot/etfsboot.com` e `sources/boot.wim`, e **nenhum `pcatboot.wim` de todo**. Essa é uma
explicação completa da parada silenciosa logo depois da mensagem do SeaBIOS: o loader não tinha
nada para carregar.

**Célula M (variável: layout de mídia corrigido).** O `/Windows/Boot/PCAT/bootmgr` existe dentro
do WIM do WinRE, então o `build-pcat-iso.sh` agora o extrai, o re-enraíza como
`Windows/Boot/PCAT/bootmgr` e o captura com `wimlib-imagex capture --compress=LZX` em
`boot/pcatboot.wim` (383.032 bytes):

```text
qemu/work/winre-pcat-m.iso  270,247,936 bytes
a478af26639ba6abb19f8b4698abe4730416f25f54497ea5f355dea7fbe10eb2
```

Rodada como `BIOS=1 MEM=4096 e1-run.sh M qemu/work/winre-pcat-m.iso pc qemu64 900 30`.
**Resultados das células M/N/O/P — a rota PCAT está bloqueada abaixo da camada de mídia.** Todas
as quatro param na mesma tela bit-idêntica do SeaBIOS ("Booting from DVD/CD...", 2 cores,
`compare -metric AE` = 0 entre frames, só o cursor pisca):

| Célula | Variável variada | Mídia | Resultado |
|---|---|---|---|
| M | adicionado `boot/pcatboot.wim` (LZX, bootmgr em `\Windows\Boot\PCAT`) | `winre-pcat-m.iso` 270.247.936 B `a478af26…` | tela estática, AE=0 (t=30 vs t=90/150) |
| N | nomes ISO9660 primários forçados para CAIXA ALTA 8.3 (`-iso-level 1`, árvore em maiúsculas; os registros em minúsculas foram confirmados byte a byte: `\x0e pcatboot.wim;1` versus `\x0e PCATBOOT.WIM;1`) | `winre-pcat-n.iso` 270.237.696 B `ac9a2cbf…` | tela estática, AE=0 |
| O | `pcatboot.wim` capturado com `--compress=none` (caso o etfsboot não consiga ler LZX) | `winre-pcat-o.iso` 270.264.320 B `2fcee098…` | tela estática, AE=0 |
| P | `bootmgr` na raiz do WIM em vez de `\Windows\Boot\PCAT\` | `winre-pcat-p.iso` 270.262.272 B `99e2723f…` | tela estática, AE=0 |

Então a mídia PCAT não é mais a explicação: com o arquivo correto, a caixa do nome correta, a
compressão correta e ambas as disposições internas plausíveis, o `etfsboot` ainda não imprime
um único caractere depois que o SeaBIOS entrega o controle. Combinada com a captura de
`EIP=0x1bf` em modo real, o suspeito restante é a boot info table que o xorriso escreve
(offset 0x08, estilo Linux/isolinux) versus o que o `etfsboot.com` espera. Resolver isso exige
uma imagem PCAT de referência do Windows byte-exata (saída do oscdimg) ou um layout de tabela
documentado — não mais suposições.

### Células Q/R/S — a mídia EFI oficial é reconhecida; ela falha uma etapa depois

O `build-efi-dvd-iso.sh` constrói o layout que um DVD real do Windows usa, com as
próprias peças da Microsoft tiradas do WIM em vez de um ESP feito à mão:

```text
\boot\efisys.bin        = /Windows/Boot/DVD/EFI/en-US/efisys.bin (1,474,560 B FAT ESP,
                          volume "EFISECTOR", contém SOMENTE \EFI\BOOT\BOOTX64.EFI 1,121,792 B)
\EFI\Microsoft\Boot\BCD          = /Windows/Boot/DVD/EFI/BCD
\EFI\Microsoft\Boot\bootmgfw.efi = /Windows/Boot/EFI/bootmgfw.efi
\boot\boot.sdi           = /Windows/Boot/DVD/EFI/boot.sdi
\sources\boot.wim        = o próprio WIM do WinRE
xorriso -as mkisofs -iso-level 4 -J -joliet-long -R -V WINRE -e boot/efisys.bin -no-emul-boot
→ qemu/work/winre-efidvd.iso 272,828,416 bytes sha256 30c48b24c3ec9e3aa0f0005d490bb91ef2d3c40606cc9a599dda246715d1bf40
catálogo: -e '/boot/efisys.bin' -no-emul-boot -boot-load-size 2880  (= o ESP inteiro, 1,47 MB)
```

**Célula Q (sem tecla pressionada)** — primeiro frame em t=60 s, 1024x768, 2 cores, texto real:

```text
Press any key to boot from CD or DVD……
BdsDxe: failed to start Boot0001 "UEFI QEMU DVD-ROM QM00003 " from PciRoot(0x0)/
Pci(0x1,0x1)/Ata(Secondary,Master,0x0) : Time out
>>Start PXE over IPv4.  PXE-E16: No valid offer received.  …
```

É a primeira vez que alguma mídia nesta matriz produz um stub de boot da Microsoft *e* o seu
próprio aviso: o OVMF carregou o `efisys.bin`, o stub rodou, e apenas a tecla ausente o parou.
O fallback PXE também confirma que a regra de auditoria se sustenta na prática — o guest tenta a
rede e não recebe nada (NAT de modo de usuário, sem DHCP offer), nenhum canal proibido envolvido.

**Célula R (uma tecla em t=30 s)** — tarde demais; a janela de tempo limite do stub já tinha
expirado. O mesmo `Time out`, e então a ordem de boot percorre PXE IPv4/IPv6 e HTTP Boot
(`PXE-E16: No valid offer received`, `Error: Could not retrieve NBP file size from HTTP server`).

**Célula S (teclas em t=5,10,15,20,25,30 s — `KEY_AT=5 KEY_TIMES=6`, intervalo 5 s)** — a tecla
é aceita e a falha muda:

```text
BdsDxe: failed to start Boot0001 "UEFI QEMU DVD-ROM QM00003 " from PciRoot(0x0)/
Pci(0x1,0x1)/Ata(Secondary,Master,0x0) : No mapping
```

`EFI_NO_MAPPING` em vez de `TIME_OUT` é um avanço real: a opção de boot agora é alcançada e
rejeitada na etapa de mapeamento, não pulada. Leitura de trabalho: o `bootmgfw.efi` é carregado
fora do disco de RAM do ESP, e então não consegue resolver o seu volume de boot, porque a nossa
ISO não é híbrida — em mídia real de DVD do Windows o ESP *também* é uma partição GPT com o GUID
de EFI System Partition, e essa partição é para a qual o device path do BCD mapeia.

Correção tentada (célula T, não rodada): o xorriso 1.5.4 não aceita a opção que faria isso em
modo `-as mkisofs` —

```text
xorriso -as mkisofs … -e boot/efisys.bin -no-emul-boot --efi-boot-image -partition_offset 16
xorriso : FAILURE : -as mkisofs: Unrecognized option '--efi-boot-image'
```

e a forma aceita mais próxima produz o tipo de partição errado: `-part_like_isohybrid
-partition_offset 16 -isohybrid-gpt-basdat` produz um tipo de MBR `0x01` cobrindo a ISO inteira
e uma partição GPT com o GUID de Microsoft Basic Data `EBD0A0A1-B9E5-4433-87C0-68B6B72699C7`,
não o GUID de ESP `C12A7328-F81F-11D2-BA4B-00A0C93EC93B`. O `-isohybrid-mbr` precisa de um
template (`isohdpfx.bin` / `grub boot_hybrid.img`) que não está instalado neste sandbox. Então
a célula T está bloqueada ou em instalar `syslinux-common`/`grub-pc-bin` (apt, decisão do dono)
ou em escrever à mão um MBR protetor + GPT com o GUID de ESP, o que é exatamente o tipo de
suposição a nível de byte que este arquivo deveria manter fora.

**Célula T (BCD injetado no próprio ESP do `efisys.bin` — variante T2, resultado: sem mudança).**
O `ESPBCD=1` adiciona `\EFI\MICROSOFT\BOOT\BCD` (16.384 B, presença verificada com `mdir`,
317.440 B livres depois) dentro da imagem ESP da Microsoft com o mtools; o `bootmgfw.efi` *não*
é copiado junto — o ESP só tem cerca de 334 KB livres e o `BOOTX64.EFI` dentro dele já **é** o
`bootmgfw.efi` (mesmos 1.121.792 bytes). Mídia: `qemu/work/winre-efidvd-t.iso` 272.828.416 B
sha256 `7ac913e014fac76b08cbbbcd07d34d87153b091699708b1c70c5aba2de14e2af`. Rodada com teclas em
t=5,10,15,20,25,30,35,40 s (`KEY_AT=5 KEY_TIMES=8`, intervalo 5 s). A tela mostra o aviso e
depois exatamente o mesmo `BdsDxe: failed to start Boot0001 … : No mapping` da célula S. Então
a localização do BCD não é o que falha: o erro de mapeamento acontece antes de qualquer leitura
de BCD, na própria entrega do stub. Hipótese "o BCD precisa estar no ESP" eliminada para esta mídia.

**A alavanca precisa para a próxima célula (encontrada lendo a própria lista de opções do xorriso,
não suposta):** o `-as mkisofs` não aceita `--efi-boot-image`, mas o frontend nativo aceita —

```text
xorriso -help:
  … |"efi_boot_part="|"efi_boot_part=--efi-boot-image"
     efi_boot_part= é para bootar sistemas EFI a partir de pendrive.
```

de modo que a célula U deveria construir a mesma árvore com o comando nativo
(`-boot_image any efi_path=/boot/efisys.bin`, `-boot_image any efi_boot_part=--efi-boot-image`,
`-boot_image any partition_offset=16`, `-boot_image any partition_table=on`) e então verificar o
GPT antes de iniciar: a partição 1 precisa carregar o GUID de ESP
`C12A7328-F81F-11D2-BA4B-00A0C93EC93B`, não o GUID de Basic Data que
`-isohybrid-gpt-basdat` produziu na tentativa rejeitada. O trecho de inspeção de GPT/MBR usado
aqui está nos comandos da célula T deste arquivo; um build que não mostre o GUID de ESP não vale
a pena inicializar.

### Célula U — GPT híbrido com o GUID de ESP real: `No mapping` inalterado

```sh
OUT=qemu/work/winre-efidvd-u.iso HYBRID=1 sh build-efi-dvd-iso.sh
→ 273,022,976 bytes  sha256 2ca259ce89063afa31f78feb2a161b1b1089615c8710337d89ac453ec7026fcc
```

O build foi verificado antes de inicializar, como a nota da célula T exige. `gdisk`/`parted`
não estão instalados neste sandbox e `xorriso -report_system_area` só diz
`Boot record : El Torito , MBR protective-msdos-label cyl-align-off GPT`, o que não basta para
distinguir um GUID de ESP de um GUID de Basic Data, então os cabeçalhos foram analisados
diretamente dos bytes:

```text
winre-efidvd.iso  (células Q/R/S, não híbrida): assinatura MBR@0 0000, nenhuma ocorrência de "EFI PART"
winre-efidvd-u.iso:
  MBR @LBA0   assinatura 55aa, partição 0 tipo 0xEE, LBA inicial 1, 532619 setores
  Cabeçalho GPT @LBA1, entradas @LBA2 (248 × 128 B)
    part 0  EBD0A0A2-B9E5-4433-87C0-68B6B72699C7  (Basic Data)        64 … 483
    part 1  C12A7328-F81F-11D2-BA4B-00A0C93EC93B  (EFI System)       484 … 3363
    part 2  EBD0A0A2-B9E5-4433-87C0-68B6B72699C7  (Basic Data)      3364 … 532555
```

(O parser imprime os dois campos do meio em endianidade mista invertidos — `...-4BBA-...` onde o
texto canônico é `BA4B`. Os bytes brutos são os GUIDs canônicos; o artefato está na impressão,
não na mídia.) A partição 1 cobre exatamente o ESP `efisys.bin` de 1.474.560 bytes, de modo que
a camada que a hipótese pedia está realmente presente, e a mídia não híbrida das células Q/R/S
não tem tabela de partição nenhuma.

Rodada: `MEM=4096 SMP=2 KEY_AT=5 KEY_TIMES=8 bash e1-run.sh U
qemu/work/winre-efidvd-u.iso pc qemu64 500 5`.

Resultado (frame-25, 1024x768, 2 cores, texto real): o aviso é aceito e depois
`BdsDxe: failed to start Boot0001 "UEFI QEMU DVD-ROM QM00003 " from PciRoot(0x0)/
Pci(0x1,0x1)/Ata(Secondary,Master,0x0) : No mapping` — a mesma parada da célula S, seguida de
`>>Start PXE over IPv4.` / `PXE-E16: No valid offer received.`, o mesmo sobre IPv6, e
`>>Start HTTP Boot over IPv4……`.

Hipótese eliminada: *"o EFI_NO_MAPPING acontece porque o ESP não é também uma partição GPT com o
GUID de EFI System Partition."* Ele é, e o erro está inalterado.

### Correção ao registro das células S, U e V: toda célula EFI exaurida cai num console

A entrada da célula S acima termina em `No mapping`, e essa leitura veio de um frame inicial
apenas. Re-lendo as sequências de frames (`e1-S/frame-65.png`, `e1-U/frame-40.png` em diante,
`e1-V/frame-55.png` em diante) mostra a mesma tela nas três, uma vez que a ordem de boot é
exaurida:

```text
UEFI Interactive Shell v2.2
EDK II
UEFI v2.70 (EDK II, 0x00010000)
Mapping table
     FS0: Alias(s):CD0c0::BLK1:
          PciRoot(0x0)/Pci(0x1,0x1)/Ata(0x0)/CDROM(0x0)
    BLK0: Alias(s):
          PciRoot(0x0)/Pci(0x1,0x1)/Ata(0x0)
Press ESC in 5 seconds to skip startup.nsh or any other key to continue.
Shell>
```

Então isto não é uma novidade de U/V e não é um beco sem saída: o Shell embutido do OVMF é
alcançado em toda célula EFI que falha, e ele mapeia o CD como `FS0:`. É o primeiro console de
texto interativo que esta matriz produziu, o que importa porque o objetivo da E1b é um console
interativo de qualquer tipo. As 8 linhas de `Shell>` nos frames são as 8 teclas `ret` que o
laço `KEY_AT`/`KEY_TIMES` enviou, não saída.

### Célula V — `\EFI\BOOT\BOOTX64.EFI` também exposto na árvore ISO9660/Joliet

```sh
OUT=qemu/work/winre-efidvd-v.iso HYBRID=1 EFI_BOOT_COPY=1 sh build-efi-dvd-iso.sh
→ 274,530,304 bytes  sha256 16a5e4efbdc00399d7b581e0c7ec9eddb9560b726f6afc0e51befb1418ba7f54
```

Mesma forma de GPT da U (partição ESP 1 agora 500 … 3379, ou seja, o mesmo `efisys.bin`,
deslocado porque a árvore cresceu). Rodada: `MEM=4096 SMP=2 KEY_AT=5 KEY_TIMES=8 bash e1-run.sh V
qemu/work/winre-efidvd-v.iso pc qemu64 400 5`.

Medido: o resultado do BdsDxe está inalterado, e as telas finais são a mesma tela —
`compare -metric AE -fuzz 5% e1-U/frame-400.png e1-V/frame-115.png` = **0** (byte-idêntico).
Isso é esperado: a opção Boot0001 aponta para dentro do ESP, então uma segunda cópia do arquivo
na árvore ISO9660 não pode mudar o que o BdsDxe resolve.

O que a V muda é o *shell*: o `FS0:` é o volume ISO9660/Joliet, e o ESP existe só como imagem
bruta dentro do `efisys.bin`, que o shell não monta. Sem `EFI_BOOT_COPY=1` não há nenhum
`\EFI\BOOT\BOOTX64.EFI` alcançável pelo `FS0:` de todo. A V é, portanto, a mídia que torna
a próxima alavanca testável, em vez de um teste da opção de boot em si.

### Próxima alavanca (célula W): digitar no prompt `Shell>`

Duas peças foram adicionadas para isso, ambas só de teclado, de modo que o `qemu/audit.sh`
continua passando inalterado:

- `keys.py` — traduz uma string literal em nomes de `sendkey` do QEMU (uma
  chamada por caractere) e opcionalmente aperta Enter. Descoberto ao construí-la: dois-pontos é
  `shift-semicolon`, não `shift-2`; uma sonda ao vivo digitou `fs0:` e o console do guest
  ecoou `fs0@`, que é o tipo de bug de mapeamento que de outro modo teria sido lido como
  "o shell não tem FS0:".
- Alavancas `TYPE_AT` / `TYPE_FILE` / `TYPE_GAP` no `e1-run.sh` — em
  `TYPE_AT` segundos, digita cada linha do `TYPE_FILE` e aperta Enter, `TYPE_GAP` segundos
  de distância (o TCG é lento e a linha precisa ser registrada antes da próxima).

O `e1-w-shell.txt` é a sequência: `fs0:`, `ls efi\boot`, `ls efi\microsoft\boot`,
e então `\efi\boot\bootx64.efi`. A última linha é o experimento de fato: se o boot manager EFI
da Microsoft carrega a partir da visão ISO9660, então o `No mapping` é uma propriedade do device
path da opção Boot0001 e não do arquivo, e a matriz ganha uma forma controlada de alcançar o
`bootmgr` — a etapa que toda célula PCAT tentava alcançar pelo outro lado.

### Célula W — primeira sequência digitada: funciona, mas a evidência é ambígua

A primeira tentativa foi abortada por um defeito do harness que vale registrar: o laço
`TYPE_FILE` digitou o próprio cabeçalho de comentário `#` do arquivo no console do guest, de
modo que o shell recebeu prosa como comandos. Corrigido no `e1-run.sh` (linhas
vazias e linhas `#` são puladas); a rodada abortada não é evidência.

A segunda tentativa (`MEM=4096 SMP=2 KEY_AT=5 KEY_TIMES=8 TYPE_AT=70 TYPE_GAP=8`, orçamento
700 s, intervalo 10 s, mídia = ISO da célula V) digitou `fs0:`, `ls efi\boot`,
`ls efi\microsoft\boot`, `\efi\boot\bootx64.efi`. O prompt mudou de `Shell>` para
`FS0:\>` — de modo que o texto digitado é aceito e executado — mas a rodada terminou numa tela
mostrando **duas linhas de `FS0:\>` e nada mais**, idêntica do frame 90 ao frame 140
(`compare -metric AE -fuzz 5%` = 0). Causa: o shell do EDK2 limpa o console quando uma aplicação
sai, de modo que toda listagem digitada antes do último comando foi apagada do único frame que
sobreviveu. Ler essa tela sozinha teria sido suposição, então a célula W é registrada como
*inconclusiva por construção* e o harness foi alterado para despejar **um frame por linha
digitada** (`cmd-<n>.png`) antes de tirar qualquer conclusão.

### Célula X — o console é real: frames por comando a partir da mesma mídia

```sh
MEM=4096 SMP=2 KEY_AT=5 KEY_TIMES=8 TYPE_AT=75 TYPE_FILE=e1-w-shell.txt TYPE_GAP=15 \
  bash e1-run.sh X qemu/work/winre-efidvd-v.iso pc qemu64 700 15
```

Observado, um frame por comando (`qemu/work/e1-X/cmd-<n>.png`, não commitado):

| comando digitado | o que a tela mostrou |
|---|---|
| `fs0:` | o prompt passa de `Shell>` para `FS0:\>` |
| `ls efi\boot` | `Directory of: FS0:\efi\boot\` — `.` 512, `..` 512, `BOOTX64.EFI` **1,121,792 B** datado **09/14/2018 18:28**; `1 File(s) 1,121,792 bytes`, `2 Dir(s)` |
| `ls efi\microsoft\boot` | `ls: File Not Found - 'FS0:\efi\microsoft\'` |
| `\efi\boot\bootx64.efi` | tela limpa, e a linha `Press any key to boot from CD or DVD……` reaparece no topo; nada mais |
| `echo voltou-do-bootx64` | imprime `voltou-do-bootx64` e o prompt volta |

Fatos que isto estabelece, nenhum dos quais era conhecido antes:

1. **Há um console de texto interativo funcionando nesta matriz.** Texto digitado por
   `sendkey` é ecoado, executado, e a sua saída é renderizada. Esse é o canal de que a E3b
   precisa, alcançado sob TCG.
2. **Uma aplicação EFI da Microsoft roda e retorna.** O `BOOTX64.EFI` (= `bootmgfw.efi`,
   mesmos 1.121.792 bytes) executado a partir do shell imprimiu a linha de press-any-key do DVD
   e saiu de volta para o shell quando nenhuma tecla chegou — o `echo` de marcação prova que o
   shell ainda estava vivo.
3. **O `FS0:` não é o volume ISO9660.** O seu conteúdo é exatamente o ESP do `efisys.bin`: um
   arquivo, `EFI\BOOT\BOOTX64.EFI`, com os timestamps de 2018 da própria Microsoft, e nenhum
   `EFI\MICROSOFT` de todo — enquanto a árvore ISO9660 da mesma mídia demonstravelmente *tem*
   `/EFI/Microsoft/Boot` (verificação no host: `xorriso -dev qemu/work/winre-efidvd-v.iso -ls /EFI`
   → `BOOT`, `Microsoft`). Se essa leitura estiver certa, então `EFI_BOOT_COPY=1` (célula V)
   nunca importou, e o BCD nunca foi alcançável pelo bootmgr inicializado em qualquer mídia
   desta matriz.

Hipótese para a família de resultados `No mapping`, afiada por (3): a imagem de boot de
El Torito é montada como o único sistema de arquivos (`FS0:`), ela não contém nenhum
`\EFI\MICROSOFT\BOOT\BCD`, e o volume ISO9660 que o contém nunca é montado — então todo
consumidor que procura o BCD por aquele caminho falha independentemente do GPT híbrido.

A célula Y é o teste direto da leitura (3): `map` e depois `ls` na raiz do `FS0:`. Uma
listagem da raiz com apenas `EFI` significa que o `FS0:` é o ESP; uma listagem da raiz com
`BOOT`, `SOURCES`, `EFI` significa que ele é o volume ISO9660 e a leitura (3) está errada.

### Célula Y — decisiva: o `FS0:` é o ESP de El Torito, e o volume ISO9660 nunca é montado

```sh
MEM=4096 SMP=2 KEY_AT=5 KEY_TIMES=8 TYPE_AT=75 TYPE_FILE=e1-y-diag.txt TYPE_GAP=10 \
  bash e1-run.sh Y qemu/work/winre-efidvd-v.iso pc qemu64 500 20
```

Dois comandos resolvem (`qemu/work/e1-Y/cmd-1.png`, `cmd-3.png`):

```text
Shell> map
Mapping table
     FS0: Alias(s):CD0c0::BLK1:
          PciRoot(0x0)/Pci(0x1,0x1)/Ata(0x0)/CDROM(0x0)
    BLK0: Alias(s):
          PciRoot(0x0)/Pci(0x1,0x1)/Ata(0x0)

FS0:\> ls
Directory of: FS0:\
09/14/2018  11:35 <DIR>          512  EFI
        0 File(s)              0 bytes
        1 Dir(s)
```

Então o *único* sistema de arquivos que o firmware monta é a imagem de boot de El Torito — o
alias `CD0c0` diz isso diretamente: CD 0, entrada de catálogo 0 — e a sua raiz guarda exatamente
um diretório, `EFI`, com data de 09/14/2018, ou seja, a própria imagem FAT `efisys.bin` da
Microsoft de 1.474.560 bytes. O volume ISO9660 de 261 MB, que é onde o `\sources\boot.wim` e
o `\EFI\MICROSOFT\BOOT\BCD` realmente vivem, não tem mapeamento nenhum.

Consequências, enunciadas como fatos sobre este firmware e esta mídia, não como suposições:

1. A leitura (3) da célula X está confirmada e o `EFI_BOOT_COPY=1` (célula V) está confirmado
   como irrelevante — o arquivo que ele copia vai para um volume que nada lê.
2. Nenhuma mídia construída pelo `build-efi-dvd-iso.sh` consegue bootar o WinRE por este
   caminho, porque a imagem do sistema `\sources\boot.wim` é inalcançável por construção.
   Injetar o BCD no ESP (`ESPBCD=1` da célula T) é necessário mas nem de longe suficiente.
3. A família `Time out` / `No mapping` nunca foi a história completa: mesmo uma opção de boot
   bem-sucedida cairia num sistema de arquivos sem nenhum `boot.wim`.

Evidência secundária da mesma rodada: o log de boot desta vez termina em `BdsDxe: failed to start
Boot0001 … : Time out` (primeira tecla injetada em t=20 s, depois da janela do stub — consistente
com as células Q/R), e o fallback de rede é totalmente visível: `PXE-E16: No valid offer
received.` para IPv4 e IPv6, `Error: Could not retrieve NBP file size from HTTP server.`,
`Error: Server response timeout.`, `BdsDxe: failed to load Boot0004 "UEFI HTTPv4
(MAC:525400123456)" … : Not Found`. A regra de auditoria se sustenta também no lado do
dispositivo: o guest tenta a rede e não recebe nada de volta.

Duas correções candidatas se seguem de (2), e elas são experimentos diferentes:

- **AA (isola a questão de montagem):** a mesma árvore com `ESPBCD=1` mas `HYBRID=0`, ou seja,
  sem `-partition_offset 16`. As células Q/R/S eram não híbridas e nunca chegaram a um `map`,
  então ainda não se sabe se o offset é o que suprime a montagem do ISO9660. Se um volume não
  híbrido mostrar um segundo mapeamento de FS, o build híbrido é o culpado e a correção é manter
  a imagem de boot só de ESP.
- **Z (isola a questão do bootmgr):** `HYBRID=1 ESPBCD=1`, de modo que o ESP que *é* montado
  também contenha `\EFI\MICROSOFT\BOOT\BCD`, então disparar o `\efi\boot\bootx64.efi`
  a partir do shell e imediatamente segui-lo com uma rajada de teclas (`!burst` no
  `e1-run.sh`), porque a célula X mostrou que o stub imprime `Press any key to boot from CD or
  DVD……` e retorna para o shell quando nada chega.

### Célula Z — o BCD agora é visível para o shell, mas a rajada de teclas chegou tarde demais

```sh
OUT=qemu/work/winre-efidvd-z.iso HYBRID=1 ESPBCD=1 EFI_BOOT_COPY=1 sh build-efi-dvd-iso.sh
→ 274,530,304 bytes  sha256 cd59d84bfdc679f391596510d237c529c0c667ffd6606a77b4477c8da1cf3359
```

Verificado no host antes de inicializar, puxando a imagem de boot de volta da ISO
(`xorriso -osirrox on -dev … -extract /boot/efisys.bin`, depois `mdir`): o ESP de
1.474.560 bytes agora guarda `\EFI\BOOT\BOOTX64.EFI` *e* `\EFI\MICROSOFT\BOOT\BCD`
(16.384 B), com 317.440 B ainda livres. Rodada: `MEM=4096 SMP=2 KEY_AT=5 KEY_TIMES=40
TYPE_AT=90 TYPE_FILE=e1-z-boot.txt TYPE_GAP=6`, orçamento 900 s, intervalo 20 s.

Frames por comando:

| comando | tela |
|---|---|
| `fs0:` | o prompt vira `FS0:\>` |
| `ls efi\microsoft\boot` | `Directory of: FS0:\efi\microsoft\boot\` → `BCD 16,384` datado de 17/11/2026 00:42, `1 File(s) 16,384 bytes` |
| `\efi\boot\bootx64.efi` | tela limpa + `Press any key to boot from CD or DVD……` e o prompt de volta |

Então a mudança de mídia funcionou exatamente como pretendido — **o BCD está agora no único
volume que o firmware monta** — e a tentativa de boot ainda parou na tecla. O motivo é um
defeito no meu próprio runner, não na mídia: o `screendump` por comando custa cerca de 40 s sob
TCG e ficava *entre* o comando de disparo e a linha `!burst`, de modo que a rajada foi injetada
depois que o bootmgr já tinha dado timeout e retornado. O `cmd-3` mostra exatamente esse estado
finalizado.

Correção do harness (necessária antes que a pergunta sequer possa ser respondida): o laço de
digitação agora lê a sequência inteira num array de antemão e, quando a próxima linha é um
`!burst`, dispara imediatamente depois do Enter do comando atual e *antes* de qualquer sleep
ou screendump. A célula AB re-roda a mesma mídia com a mesma sequência sob a ordem corrigida.

### Célula AB — a ordem corrigida ainda perde a corrida, e o motivo é mensurável

```sh
MEM=4096 SMP=2 KEY_AT=5 KEY_TIMES=4 TYPE_AT=100 TYPE_FILE=e1-ab-boot.txt TYPE_GAP=6 \
  bash e1-run.sh AB qemu/work/winre-efidvd-z.iso pc qemu64 900 20
```

Com a rajada agora disparada logo depois do Enter de `\efi\boot\bootx64.efi`, o `cmd-3`
mostra o mesmo estado finalizado da célula Z (`Press any key to boot from CD or DVD……` mais o
prompt do shell), mas com um detalhe extra que o explica: o cursor do shell está a cerca de 150
colunas à direita do prompt — os 150 espaços da rajada foram digitados na linha de comando **do
shell**, ou seja, eles chegaram depois que o bootmgr já tinha desistido. `compare -metric AE
-fuzz 5% cmd-2 cmd-3` = 14,818 pixels
(3 cores), de modo que a diferença é a tela da aplicação, não um piscar.

Por que uma rajada de 150 teclas pode ainda perder uma janela medida em segundos: um `sendkey`
aqui custa cerca de 4 s de relógio, porque cada chamada é um processo novo de `python3
qemu/mon.py` abrindo um socket novo enquanto o laço principal do QEMU está ocupado emulando.
150 teclas, portanto, se espalham por cerca de 10 minutos, e o monitor aceita apenas um cliente
de cada vez, de modo que o spam não pode simplesmente ser colocado em segundo plano enquanto o
runner continua despejando frames.

Correção (de ferramenta, não de mídia): o `keyspam-dump.py` mantém **uma**
conexão de monitor e intercala teclas densas com `screendump` nessa mesma conexão —
`!spam <tecla> <s> <ms> <dump_s>` no runner. A célula AC roda `!spam spc 900 150 30`: uma
tecla a cada 150 ms por 900 s com um frame a cada 30 s, o que cobre o tempo de carga e a janela
do aviso juntos.

Duas leituras permanecem abertas depois da AC, e elas são problemas diferentes: (a) a janela era
simplesmente estreita demais para a taxa de injeção antiga — resolvido com densidade; (b) o
bootmgr esvazia o ConIn quando começa (`ResetEngine`), de modo que só uma tecla apertada
*depois* do aviso conta, caso em que a resposta não é tempo de teclado de todo, e sim remover a
política de press-any-key do próprio BCD.

### Célula AC — spam denso: a leitura (a) é falsificada, e o portão não é um problema de tempo

```sh
MEM=4096 SMP=2 KEY_AT=5 KEY_TIMES=4 TYPE_AT=100 TYPE_FILE=e1-ac-spam.txt TYPE_GAP=6 \
  bash e1-run.sh AC qemu/work/winre-efidvd-z.iso pc qemu64 1500 30
```

O `keyspam-dump.py` consumiu o próprio orçamento primeiro: `total: 902s teclas=5117 frames=29`,
ou seja, **5,68 teclas/s sustentadas** — 14x a taxa medida na célula AB (um `sendkey` por
processo ≈ 4 s). O spam começou antes do screendump de `cmd-3`, de modo que a primeira tecla
injetada está a menos de um segundo do Enter que lançou `\efi\boot\bootx64.efi`.

Censo de pixels por frame dos `spam-*.png` (área superior = a linha `Press any key to boot
from CD or DVD……` em y<160; "prompt" = último pixel amarelo do `FS0:\>`; cursor = o bloco
cinza):

| frame | spam t | px acima | y do prompt | cursor (x,y) |
|---|---|---|---|---|
| 001 | 31 s | 883 | 540 | (391, 582) |
| 002 | 62 s | 883 | 540 | (527, 620) |
| 003 | 93 s | 0 | 502 | (663, 620) |
| 004 | 125 s | 0 | 464 | (799, 620) |
| 005 | 156 s | 0 | 407 | (295, 620) |
| 006 | 187 s | 0 | 369 | (431, 620) |
| 007 | 218 s | 0 | 331 | (567, 620) |
| 008 | 249 s | 0 | 293 | (703, 620) |
| 009 | 280 s | 0 | 236 | (199, 620) |
| 010 | 311 s | 0 | 198 | (335, 620) |

Três coisas nessa tabela decidem:

1. **O cursor avança a uma taxa constante desde o primeiro frame** — +136 px = 17 colunas por
   frame de 30 s, fazendo a volta da margem direita e então mantendo-se na linha 38. Isso é o
   EditLine do shell ecoando os nossos espaços na sua linha de comando. O shell teve o ConIn
   durante o spam todo, de modo que o bootmgr já tinha ido embora antes do primeiro frame em
   t=31 s.
2. A linha `Press any key` não desaparece porque o bootmgr terminou em t≈90 s: ela desaparece
   porque **ela rola para fora do topo** quando o eco invisível de espaços do shell empurra a
   tela para cima (y do prompt 540 → 198 ao longo de dez frames). Os seus pixels são resíduo,
   não uma janela viva.
3. O frame final (depois do spam, `final.png`) ainda mostra o aviso nas linhas 10–11 e o cursor
   na linha 38, coluna ~79 — a linha de comando está cheia de espaços invisíveis e nada nunca rodou.

Então a densidade não abriu o portão, e o motivo não é que a janela era estreita demais: 5.117
teclas estavam em voo desde t≈0,2 s e o shell as consumiu. A leitura (a) está eliminada. A
leitura (b) — o bootmgr reseta/esvazia o ConIn na entrada, de modo que só uma tecla apertada
*depois* desse ponto conta — é a melhor sustentada, com uma ressalva honesta: o primeiro frame de
spam custa 30 s de relógio, de modo que nunca temos um frame dentro da própria janela, e não
podemos observar o laço de polling do bootmgr diretamente.

Uma segunda ressalva medida que restringe qualquer estratégia futura de teclado: o guest ecoou
cerca de 0,55 caractere/s enquanto injetávamos 5,68 teclas/s. Aproximadamente 90% dos eventos
nunca alcançaram o console — o QEMU descarta scancodes de PS/2 quando o guest não está drenando
a fila de entrada rápido o suficiente sob TCG. "Segurar uma tecla" ou "apertá-la 10.000 vezes"
não podem ser assumidos como funcionários nas taxas que o monitor reporta.

Decisão para a linha EFI-ISO: parar aqui. O portão de press-any-key é uma propriedade da mídia
de *CD*, e as células E e F já provaram que a mídia de **disco** FAT32 de volume único roda o
`bootmgfw.efi` sem portão nenhum (`BdsDxe: starting Boot0002 "UEFI QEMU HARDDISK"`, e então
a tela azul). A pergunta aberta nesta matriz portanto não é o teclado; é o que aquela tela azul
de fato é. É a célula AD.

### Célula AD — o azul liso é real: um segundo dispositivo de vídeo renderiza o mesmo único pixel

```sh
MEM=4096 SMP=2 VGA_DEV=bochs-display NOREBOOT=0 \
  bash e1-run.sh AD qemu/work/winre.img pc qemu64 600 20
```

`-vga ramfb` não existe neste QEMU (medido com `-vga help`: `none std cirrus vmware xenfb qxl
virtio`), de modo que o runner ganhou `VGA_DEV`, que troca `-vga $VGA` por
`-vga none -device $VGA_DEV`. O argv auditado e inicializado foi
`… -vga none -device bochs-display -display none -serial null …` → `audit: PASS`.

| t | frame | cores | conteúdo |
|---|---|---|---|
| 20 s | `frame-20.png` | 66 | texto: `BdsDxe: failed to load Boot0001 "UEFI QEMU DVD-ROM QM00003 " from PciRoot(0x0)/Pci(0x1,0x1)/Ata(Secondary,Master,0x0): Not Found`; `BdsDxe: loading Boot0002 "UEFI QEMU HARDDISK QM00001 " from …/Ata(Primary,Master,0x0)`; `BdsDxe: starting Boot0002 …` **e o logo do TianoCore** |
| 40 s | `frame-40.png` | 1 | `srgb(32,103,178)` = `#2067B2`, todos os 786.432 px |
| 60 s | `frame-60.png` | 1 | idêntico |

O QEMU então encerrou por conta própria com **código de saída 0** — um shutdown pedido pelo
guest — mesmo que esta célula tenha rodado com `NOREBOOT=0`, o que reproduz a observação da
célula H num dispositivo diferente.

Duas conclusões, ambas medidas em vez de argumentadas:

1. A hipótese de artefato de captura está morta para este caminho. O mesmo `-device
   bochs-display` mostra modo texto (as linhas de `BdsDxe`), um logo em modo gráfico
   (TianoCore, 66 cores) e então o azul liso, de modo que o screendump está acompanhando as
   mudanças de modo do guest. O azul não é um frame obsoleto ou não suportado: o guest de fato
   pinta uma cor sobre a tela inteira.
2. Também não é um bugcheck renderizado — um BSOD do Win10 é `#0078D7` com um rosto triste, um
   código de parada e uma porcentagem, e este frame tem zero glifos. `#2067B2` é o azul da
   interface de recuperação, e o guest está ocioso enquanto o mantém, e então pede power-off
   cerca de 20 s depois.

Essa leitura é testável, porque a mídia diz exatamente o que deveria estar na tela: dentro do
`winre1809.wim`, o `\Windows\System32\winpeshl.ini` é

```ini
[LaunchApp]
AppPath=X:\sources\recovery\recenv.exe
```

(`RecEnv.exe` e `StartRep.exe` estão presentes sob `\sources\recovery\`.) Se a interface de
recuperação é o que pinta o azul e então morre, substituir esse launcher por `cmd.exe` deveria
dar um console de texto no mesmo ramdisk. A célula AE constrói exatamente essa mídia.

### Célula AE — o shell do WinPE nunca é alcançado, de modo que o azul está a montante dele

```sh
bash build-cmd-media.sh   # mídia: qemu/work/winre-cmd.img
MEM=4096 SMP=2 VGA_DEV=bochs-display NOREBOOT=0 \
  bash e1-run.sh AE qemu/work/winre-cmd.img pc qemu64 900 20
```

O `build-cmd-media.sh` copia `winre1809.wim` → `winre-cmd.wim`, substitui
`/Windows/System32/winpeshl.ini` dentro dele por

```ini
[LaunchApp]
AppPath=X:\Windows\System32\cmd.exe
```

verifica o novo arquivo extraindo-o de volta do WIM corrigido, constrói o disco com o
`qemu/build-disk.sh` compartilhado, move o resultado para `winre-cmd.img` (`c8dadd6013582dd5…`)
e restaura o `winre.img` byte a byte (`2819a56f36ebd04c…`, ainda a mídia das células E–H).

Resultado: **idêntico à AD** — `frame-20` 66 cores (texto de BdsDxe + logo), `frame-40` e
`frame-60` uma cor `srgb(32,103,178)`, código de saída do QEMU 0 em t=60 s. Trocar a interface
de recuperação por `cmd.exe` não mudou nada, de modo que o boot para **antes** de o
`winpeshl.exe` rodar. O azul é pintado pela entrega do `bootmgr` para o `winload`, pelo
`winload` em si, ou pelo kernel — não pela interface do WinRE.

A hipótese do SDI foi verificada antes de aceitar isso. O `boot.sdi` que ambos os WIMs trazem
(`/Windows/Boot/DVD/EFI/boot.sdi`, 3.170.304 bytes, `cd2c00ce…`, mesmo arquivo de
`efidvd-root/boot/boot.sdi`) não é um arquivo vazio: ele contém 2.187.608 bytes não nulos. O
seu cabeçalho de disco `$SDI0001` (offset 0) está todo em zeros exceto a assinatura, e o
cabeçalho de *partição* SDI em 0x400 lê
`CheckSum=0 BlockSize=0 PartitionOffset=8192 DiskSize=0 Sectors=3,161,088 Heads=0
SectorsPerTrack=7` — ou seja, um volume declarado de 3.161.088 × 512 B = **1,51 GiB**, contra
`Total Bytes: 2,169,435,125` (2,02 GiB) para a imagem do WinRE 1809. Um rascunho anterior desta
seção chamava essa estrutura de "imagem de disco GPT": **isso estava errado** — não há assinatura
`EFI PART` em nenhum lugar do arquivo (procurado) e o LBA 1 em 0x200 está todo em zeros.
`PART` é a própria assinatura do cabeçalho de partição SDI. O descasamento de aritmética em si
é real e é o que a célula AJ foi construída para testar.

### Célula AF — localização decisiva: a própria interface de erro do bootmgr renderiza texto perfeitamente

```sh
cp qemu/work/winre-cmd.img qemu/work/winre-nobwim.img
mmove -i "qemu/work/winre-nobwim.img@@1048576" ::/sources/boot.wim ::/sources/bootx.wim
mdir -i "qemu/work/winre-nobwim.img@@1048576" ::/sources   # confirma que só bootx.wim resta
MEM=4096 SMP=2 VGA_DEV=bochs-display NOREBOOT=0 \
  bash e1-run.sh AF qemu/work/winre-nobwim.img pc qemu64 400 15
```

Com a imagem de ramdisk renomeada de modo que `\sources\boot.wim` não exista mais, a mesma
mídia, o mesmo dispositivo e o mesmo harness produzem uma **tela legível** em t=15 s e t=30 s
(3 cores, fundo preto):

```text
                        Windows Boot Manager
Windows failed to start. A recent hardware or software change might be the
cause. To fix the problem:
  1. Insert your Windows installation disc and restart your computer.
  2. Choose your language settings, and then click "Next."
  3. Click "Repair your computer."
If you do not have this disc, contact your system administrator or computer
manufacturer for assistance.
        Status: 0xc000000f
        Info: A required device isn't connected or can't be accessed.
     ENTER=OS Selection                ESC=UEFI Firmware Settings
```

Esse único frame reorganiza a matriz inteira:

1. O `bootmgr` roda, lê o BCD no volume FAT32 e renderiza **texto perfeito glifo a glifo pela
   mesma fonte de frames `bochs-display`** que depois mostra o azul. Então "o azul não tem
   texto porque a captura não consegue ver texto" está morto, e também está "o caminho da fonte
   está quebrado".
2. A tela de falha do `bootmgr` é texto preto sobre branco, não azul. Portanto o azul da
   AD/AE não é uma tela de erro do bootmgr: ele aparece só quando a imagem de ramdisk *está*
   presente, ou seja, **depois** de o bootmgr entregar o controle ao `winload`.
3. A tela também prova que o guest vai ficar e esperar uma tecla aqui (`ENTER=OS Selection`,
   `ESC=UEFI Firmware Settings`), e ainda assim pediu power-off em t=45 s (código de saída 0).
   Então a vida de ~20–40 s de uma tela de boot do Windows seguida de um shutdown iniciado pelo
   guest é normal para esta mídia e **não** é evidência extra sobre o azul.

Escopo restante para o azul, em ordem: o `winload.efi` falhando depois de o ramdisk abrir, ou o
kernel bugcheckando tão cedo que só o preenchimento de fundo é pintado. As células AG
(q35/AHCI + `-cpu max`) e o eixo de controlador de armazenamento são os próximos discriminadores
baratos; ler o código de parada real exige um canal de depuração que o dono ainda não autorizou
(depuração de serial/kernel, `pmemsave`, ou logs de `-d`).

Nada em AD, AE ou AF é evidência de hardware: nenhum guest nesta matriz alcançou o kernel do
Windows num estado que tenha produzido um console utilizável.

### Célula AG — q35/AHCI e `-cpu max` não mudam nada: o eixo de controlador está fechado

```sh
MEM=4096 SMP=2 VGA_DEV=bochs-display NOREBOOT=0 \
  bash e1-run.sh AG qemu/work/winre-cmd.img q35 max 600 15
```

| t | frame | cores | conteúdo |
|---|---|---|---|
| 15 s | `frame-15.png` | 1 | `srgb(32,103,178)` |
| 30 s | `frame-30.png` | 1 | `srgb(32,103,178)` |

O QEMU encerrou por conta própria em t=45 s (código de saída 0). Em `-machine q35` a porta IDE
do `pc` é substituída pelo controlador AHCI do ICH9, de modo que o kernel precisaria de
`storahci` em vez de `pciide`; o resultado é a mesma cor única. Combinadas com a célula G
(`-cpu max`, `pc`) e a célula F, os eixos de modelo de CPU e controlador de armazenamento
estão eliminados para esta mídia: o azul não é um artefato de driver faltante do chipset emulado.

Uma observação de tempo que vale guardar: no q35 o azul já era a tela inteira em t=15 s, enquanto
no `pc` o texto de `BdsDxe` ainda era legível em t=20 s e o azul veio em t=40 s. Então o azul
chega a poucos segundos de o `bootmgr` começar, o que é por que o próximo discriminador (célula
AH) remove o `winload.efi` de dentro do ramdisk: se o bootmgr não consegue de todo encontrar a
aplicação de boot, a própria interface de erro dele é texto sobre preto (a AF provou que esse
caminho renderiza), e se ele *consegue* encontrá-la, o azul nos diz que o preenchimento pertence
à entrega em vez de a uma fase posterior do kernel.

### Célula AH — apagar o `winload.efi` de dentro do ramdisk não muda nada

```sh
bash build-nowl-media.sh    # mídia: qemu/work/winre-nowl.img d53f813a…
MEM=4096 SMP=2 VGA_DEV=bochs-display NOREBOOT=0 \
  bash e1-run.sh AH qemu/work/winre-nowl.img pc qemu64 400 15
```

O `wimlib-imagex update` apagou as duas cópias que a imagem traz
(`/Windows/System32/Boot/winload.efi` e `/Windows/System32/winload.efi`); o disco
reconstruído ainda tem o `winload.exe` e os arquivos `.mui`, que é o resto esperado. Frames:
t=15 s 66 cores (texto de `BdsDxe` + logo do TianoCore), t=30 s e t=45 s **uma cor
`srgb(32,103,178)`**, código de saída do QEMU 0 em t=60 s.

Então uma mídia cujo ramdisk não pode de forma alguma lançar uma aplicação de boot chega à mesma
tela exata de uma mídia completa. Lido com cuidado, isso **não** prova que a falha é posterior ao
winload: prova que nesta fase o bootmgr produz os mesmos pixels haja ou não `winload.efi`,
enquanto que na fase *dispositivo* (AF) o mesmo programa produz texto legível. O azul é,
portanto, o que essa etapa do bootmgr renderiza de todo — a etapa entre "o BCD e o dispositivo
de boot estão bons" e "há algo para entregar".

### Célula AJ — a aritmética do tamanho do ramdisk também está eliminada

```sh
bash build-small-media.sh   # mídia: qemu/work/winre-small.img 564b7061…
MEM=4096 SMP=2 VGA_DEV=bochs-display NOREBOOT=0 \
  bash e1-run.sh AJ qemu/work/winre-small.img pc qemu64 900 20
```

O `build-small-media.sh` apaga `/Windows/WinSxS` e `/Windows/System32/DriverStore` de uma
cópia do WIM, o que leva o `Total Bytes` de 2.169.435.125 (2,02 GiB) para **952.214.657**
(0,89 GiB) — folgadamente dentro do volume de 1,51 GiB que o cabeçalho de partição SDI declara.
O script agora se recusa a construir a mídia se esse número não estiver abaixo de 1,5 GB, porque
a primeira versão dele listava um caminho que não existe na imagem, o wimlib abortou o update
inteiro com esse erro, e o disco foi construído a partir de um WIM **sem patch**: um teste
silenciosamente falso. Guarda adicionada, re-rodada, números acima.

Resultado: t=20 s 66 cores, t=40 s e t=60 s `srgb(32,103,178)`, código de saída 0 em t=60 s.
Idêntico.

Isso fecha a hipótese de aritmética: a imagem agora cabe no ramdisk declarado com 0,6 GiB de
folga e o boot para no mesmo lugar. Combinadas com as células E–H (tamanho de RAM), F/G (modelo
de CPU), AG (IDE versus AHCI) e AH (winload presente ou não), toda variável do lado da mídia e
do lado da máquina que este harness pode alcançar sem um canal de depuração foi agora variada
com o mesmo resultado.

O que resta, enunciado honestamente: o azul é produzido dentro da fase de ramdisk do bootmgr, e
as duas leituras que sobrevivem são (i) o bootmgr troca o console para gráficos e morre antes de
desenhar qualquer glifo, ou (ii) ele pinta esse fundo de propósito e o erro que quer reportar
nunca alcança a tela. Distingui-las exige ver dentro do guest, o que é exatamente a autorização
que este agente não tem: depuração de kernel por um dispositivo serial, `pmemsave`, ou logs
do QEMU `-d`.

Uma sonda inconclusiva registrada para não ser repetida: o BCD de 16 KB no disco contém
`\sources\boot.wim` (UTF-16 em 10.482 e 11.650) e `boot.sdi` (10.184), mas o GUID de imagem
do nosso WIM `4d9eec8d…ad6cbad109b70ce7559f85e8` não aparece em lugar nenhum dele em nenhuma
ordem de bytes. Isso **não é** um achado — o elemento ramdisk do BCD do DVD carrega um GUID de
dispositivo não relacionado, não o do WIM — de modo que um descasamento de GUID não foi nem
mostrado nem excluído por esta busca.

Nada em AH ou AJ é evidência de hardware: nenhum guest nesta matriz produziu um console do Windows.

## Artefatos e hashes

Todos sob `qemu/work/` (ignorado pelo git) — mídia gerada não é commitada.

| Caminho | SHA-256 | Tamanho |
|---|---|---|
| `qemu/work/winre1809.wim` (F1 unido, bate com `SHA256SUMS.reassembled`) | `232199c585111bfae71ff00dbdcabe5c75195fc9b431eb4d1711b8a7e471eb6c` | 266.283.224 |
| `qemu/work/winre.iso` v1 (ESP quebrado, células A/B) | `5034d7d8d8e6b944990cd47347772f5edfb3e2038cb95b0664384a40800a8550` | 275.548.160 |
| `qemu/work/winre.iso` v2 (BCD no ESP, célula A2) | `1abcc006609884645b89919ab36e5df651a55df01b6137a4c70d2db366a976ba` | 275.548.160 |
| `qemu/work/winre.img` (volume único FAT32, células E–H, AD) | `2819a56f36ebd04cda7e38269e3731d98963c473b442116b28792e27f04c1105` | 629.145.600 |
| `qemu/work/winre-efidvd-z.iso` (híbrida + BCD no ESP, células Z/AB/AC) | `cd59d84bfdc679f391596510d237c529c0c667ffd6606a77b4477c8da1cf3359` | 274.530.304 |
| `qemu/work/winre-cmd.wim` (boot.wim com `winpeshl.ini` → `cmd.exe`) | `a802569fde3417d55d936fb0661d4471fcc936ed9c37cf147464ff857fa3c0b1` | 267.637.786 |
| `qemu/work/winre-cmd.img` (mesmo layout de `winre.img`, WIM corrigido; células AE/AG) | `c8dadd6013582dd55ddb7e102c831f1b55847b8fa2f595d7554ea8c2a4482b6f` | 629.145.600 |
| `qemu/work/winre-nobwim.img` (`winre-cmd.img` com `\sources\boot.wim` renomeado; célula AF) | `e64620e27b97b29242b396ee6cf6760695e5a44aa59ef36f1650f0259ca6aa24` | 629.145.600 |
| `qemu/work/winre-nowl.wim` / `winre-nowl.img` (ambas as cópias de `winload.efi` apagadas; célula AH) | `d53f813ae7f67bb9ccef421f58cc76557a319ebab29538fa981adc9af8e41ca9` (img) | 629.145.600 |
| `qemu/work/winre-small.wim` / `winre-small.img` (WinSxS + DriverStore apagados, `Total Bytes` 952.214.657; célula AJ) | `564b7061b5ebf08d7c46b97541b19e1c6a9b91c9b73499d7d45f601affa8f579` (img) | 629.145.600 |
| `qemu/work/e1-A/frame-30.png`, `qemu/work/e1-B/frame-30.png` | (screendumps — retidos localmente, não commitados conforme `AGENTS.md`) | — |

## Interpretação

### Fatos observados

_(pendente)_

### Hipóteses

_(pendente)_

## Decisão

- Resultado: pendente
- Motivo: pendente
- Próximo experimento: E3b se qualquer célula alcançar o `cmd`; caso contrário, a variável
  vencedora da matriz se torna um padrão documentado do harness QEMU e a E3b segue bloqueada.

## Limitações

- TCG sem KVM: o boot é ordens de magnitude mais lento que o dispositivo; uma célula que só dá
  timeout não é um resultado negativo, é inconclusiva.
- Nenhum resultado do QEMU é prova de hardware. O rádio BCM4356 não é emulado; nada aqui pode
  dizer qualquer coisa sobre o erro 10.
- A imagem de dispositivo de 398 MB (F3) está indisponível; F1 é exato apenas para o estado de
  drivers.

## Reversão

- Todos os arquivos gerados vivem em `qemu/work/` (ignorado pelo git) e em `/tmp`. Apagá-los
  restaura a árvore; as partes de WIM rastreadas são só de leitura em cada etapa. Resultado:
  pendente.

## Referências

- `qemu/README.md` (estado do boot do WinRE, BSOD antes não diagnosticado)
- `docs/04-fidelidade-mimetizacao.md` (definição de F1), `docs/01-restricoes.md`

---

## FILE: experiments/E3b-ascii-hash-prep.md

# Experimento E3b — reconstrução da NVRAM em ASCII digitado e SHA-256 no WinRE

## Objetivo

Reconstruir a NVRAM de 5.361 bytes dentro de um **WinRE inicializado** a partir de texto ASCII digitado e
verificar o SHA-256 usando apenas as ferramentas da imagem. Este experimento **não está completo** até
os comandos rodarem num console WinRE real e o resultado na tela ser registrado.

## Nível de fidelidade

F1 (WinRE 1809 inicializado) é exigido para um pass. Este documento registra atualmente apenas o
**procedimento**; nenhum resultado no convidado foi observado. Segundo as regras de evidência do
`AGENTS.md`, verificações simuladas/simuladas/só-do-host são **inadmissíveis como prova** e não são usadas
aqui. Nenhum mock de host acompanha este experimento.

## Pré-condições

- O E1/E1b precisa primeiro alcançar o `cmd` interativo no WinRE. Isso segue bloqueado; qoder é o owner do E1/E1b.
- `cscript` + motor JScript + FileSystemObject precisam estar confirmados funcionando **dentro do WinRE**.
- Toda a entrada deve ser digitada pelo teclado virtual da tela touch; sem clipboard,
  pasta compartilhada, ACK serial, transferência de rede ou arquivo pré-colocado no convidado.
- O dispositivo físico não é modificado. Nada é instalado num diretório de drivers.

## Ambiente

- Data: 16/11/2026
- Host: sandbox Ubuntu 22.04, Node v22.13.1, Python 3.11.1
- Virtualização: nenhuma usada para este experimento
- Hashes da imagem: SHA-256 da NVRAM `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`

## Comandos

Gerar a folha de comandos digitados no host (só preparação):

```sh
python3 scripts/prepare-ascii-transfer.py --chunk-size 128 > /tmp/e3b-sheet.md
```

Depois, num **cmd de WinRE real inicializado**, digite `ascii.js` pelo Notepad e rode os comandos do shell
e dos pedaços da folha, um pedaço por vez, registrando cada ACK na tela.
Nenhum resultado no convidado existe ainda; não marque este experimento como pass por causa da geração no host.

## Saída observada

Nenhuma no WinRE ainda (bloqueado no E1/E1b). Nenhum "teste" simulado ou só-do-host é reivindicado como prova.

O gerador produz 42 pedaços de 128 bytes cada, exceto o último. O comando final
de verificação na tela deve ser:

```bat
cscript //nologo ascii.js verify 4356r2nvram.txt 5361 a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667
```

## Artefatos e hashes

| Caminho | SHA-256 | Tamanho |
|---|---|---|
| `drivers/nvram-delta/4356r2nvram.txt` | `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667` | 5361 |
| `scripts/winre-ascii.js` | veja `git hash-object` no registro do commit | — |
| `scripts/prepare-ascii-transfer.py` | veja `git hash-object` no registro do commit | — |

Nenhum artefato de teste simulado está incluído; veja as regras de evidência em `AGENTS.md`.

## Interpretação

### Fatos observados (apenas preparação no host — não é prova)

- `scripts/prepare-ascii-transfer.py` divide a NVRAM exata de 5.361 bytes do repositório em
  42 pedaços de 128 bytes e emite um comando digitado por pedaço com o seu SHA-256.
- O gerador usa `copy /b` em ordem explícita de nomes de arquivos, não coringas.
- A origem do verificador escreve com `CreateTextFile(path, true, false)` (ANSI, sem BOM)
  e relê com `OpenTextFile(path, 1, false, 0)` (ASCII), rejeitando bytes não suportados. Esses são fatos
  de código-fonte, não comportamento executado.

### Ainda não observado (exige WinRE real)

- Se `cscript`/JScript/`CreateTextFile`/`OpenTextFile` existem e rodam neste WinRE.
- Se a escrita/leitura ANSI preserva CRLF, espaços à direita e o último byte exatamente.
- Se o SHA-256 implementado em JScript produz o digest correto no motor do WinRE.

### Hipóteses

- JScript + FSO executam no WinRE 17763. A presença no inventário é observada;
  a execução ainda não é observada.
- `CreateTextFile(..., false)` e `OpenTextFile(..., 0)` preservam CRLF e
  espaços à direita neste WinRE. Isso deve ser provado com uma pequena sondagem digitada antes.

## Decisão

- Resultado: **bloqueado** — nenhuma execução real no convidado ainda; a preparação no host não é um pass.
- Motivo: o boot do WinRE (`cmd`) não está disponível neste sandbox; o E1/E1b é o dono dessa dependência.
- Próximo experimento: depois que o E1/E1b for bem-sucedido, digite `ascii.js`, rode `selftest`, depois digite um
  pequeno cenário de CRLF/metacaracteres antes da NVRAM completa de 42 pedaços. Só um pass na tela, num WinRE real,
  fecha o E3b.

## Limitações

- Nenhuma execução no QEMU; nenhum hardware. Não é correção de Wi-Fi, não é teste de erro-10 e não é prova do
  comportamento de JScript/FSO no dispositivo.
- Verificações simuladas/só-do-host são inadmissíveis como prova e foram deliberadamente não incluídas
  para este experimento.
- Os comportamentos de `WScript.Arguments`, `CreateTextFile` e `OpenTextFile` precisam ser confirmados
  no WinRE real antes de qualquer transferência completa.
- A evidência na tela é o único canal de saída válido no dispositivo; não há ACK por serial no dispositivo.

## Reversão

- Nada necessário: nenhum convidado, dispositivo, WIM, BCD ou arquivo de driver foi alterado.
- Para descartar, apague os scripts recém-adicionados e este documento.

## Referências

- `GOAL.md` — Realidade dos canais
- `AGENTS.md` — Regra de canais, regras de evidência
- `docs/07-inventario-imagens.md` — inventário de ferramentas disponíveis
- `prompts/advisor-respostas/advisor-resposta-20261115-124958.md` — recomendação ASCII-primeiro

---

## FILE: experiments/E7-binary-write-sink.md

# Experimento E7 — Sumidouro de escrita binária (hex digitado → bytes brutos)

## Objetivo

Existe um jeito consistente com as restrições de transformar hex/base64 digitado num
arquivo binário bruto dentro do WinRE **sem** certutil, PowerShell, .NET ou ADODB.Stream?

## Nível de fidelidade

`somente metadados` para os fatos sobre as ferramentas da imagem (presença de arquivos nas listagens verificadas).
Algoritmo no lado do host = mecânica de concatenação, **não** uma prova do WinRE e
**não** prova de hardware. O comportamento de FSO/`copy /b` no convidado está **não provado** até
que o E1 entregue um `cmd` interativo.

## Pré-condições

- Inventário em `docs/07-inventario-imagens.md` + `inventory/names-only/`.
- Python 3 no host para o selftest do alfabeto.
- Boot do WinRE (E1) antes de reivindicar que o sumidouro funciona.

## Ambiente

- Data: 16/11/2026
- Host: sandbox Linux, sem `/dev/kvm`, sem QEMU (nesta sessão)
- Hashes da imagem: não remontados aqui; listagens já verificadas em docs/07

## Fatos do inventário (observados)

Presentes (ambas as imagens, salvo indicação): `cmd.exe`, `cscript.exe`/`wscript.exe`,
`mshta.exe`, `jscript.dll`/`vbscript.dll`/`scrrun.dll`/`wshom.ocx`/`scrobj.dll`,
`msxml3.dll`/`msxml6.dll`, `crypt32.dll`, `fsutil.exe`, `expand.exe`,
`print.exe`, `esentutl.exe`, `pnputil.exe` (só 1809), WMI (`WMIC.exe`,
`wbemdisp.dll`, `stdprov.dll`).

Ausentes (ambas): `certutil.exe`, `powershell.exe`, `msado15.dll`, `mscoree.dll`,
`clr.dll`, `debug.exe`, `edlin.exe`, `findstr.exe`, `makecab.exe`,
`extrac32.exe`, `tar.exe`, `zipfldr.dll`, `wiaaut.dll`, `cdosys.dll`
(só `cdosys.dll.mui` — CDO.Message inutilizável), `bitsadmin.exe`.

MSXML decodifica base64 num array de bytes (`dataType="bin.base64"`). Nenhum sumidouro
COM de *arquivo* binário está na listagem. O WMI não tem classe identificada de arquivo de bytes brutos.
`crypt32!CryptStringToBinary` não é chamável por rundll32.

`fsutil file createnew <nome> 1` (comportamento documentado do fsutil) cria um
arquivo de 1 byte `0x00`. Essa é a única forma identificada dentro da imagem de obter um
byte NUL como texto digitado. **Não provado neste WinRE até o E1.**

## Método proposto (não provado no WinRE)

Alfabeto + `copy /b`:

1. Digitar a carga como hex pelo teclado touch (não provado no WinRE).
2. Digitar um pequeno JScript (`scripts/winre-alphabet-decode.js`).
3. Construir 256 arquivos de um byte: `fsutil` para `0x00`; `Write(String.fromCharCode(i))` do FSO
   para `1..255`.
4. `copy /b` concatena-os em ordem hex (lotes de 16 para ficar sob os limites do cmd).

Sondagem de liberação: `scripts/winre-fso-probe.js` — cada byte deve resultar `size=1`.
Se `0x0A` virar tamanho 2 (CRLF) ou `0x00` tamanho 0, esses bytes precisam ser
obtidos de outro jeito; `0x00` está coberto pelo fsutil *se* o comando funcionar.

Plano B se o FSO corromper muitos bytes: ainda viável só para o alfabeto sobrevivente;
caso contrário só-a-nvram (texto) continua a única classe de carga viável.

## Artefatos e hashes

- `scripts/winre-fso-probe.js` — sondagem de liberação no convidado (não executada)
- `scripts/winre-alphabet-decode.js` — decodificador no convidado (não executado)

## Resultado

- **Fato:** nenhum sumidouro binário clássico em nenhuma das imagens.
- **Hipótese:** o WinRE consegue construir esse alfabeto com fsutil + FSO + `copy /b`.
- **Bloqueado:** a sondagem no convidado precisa do `cmd` interativo do E1.
- Não digite o driver de ~1 MB até a sondagem dar PASS.

## Limites da conclusão

QEMU/host não é prova de hardware. Nada aqui foi executado no WinRE; não há sumidouro binário provado. O caminho de carga mínima (só o texto da nvram) ainda
evita este problema por completo (hardware, E4).

---

## FILE: experiments/README.md

# Experimentos

Cada experimento registra uma pergunta, os comandos exatos, a saída observada, os artefatos e os limites da conclusão.

## Índice (quadro de tarefas compartilhado)

Este é o único quadro compartilhado. Um agente trabalha por vez, então não há reivindicação de linhas: atualize o Status ao trabalhar e envie. Veja a regra de coordenação em `AGENTS.md`.

| ID | Título | Owner | Status |
|---|---|---|---|
| E0.1 | Procedência da imagem base | — | Feito — ESD oficial verificado, WinRE re-extraído (`winre-1809-oficial-intacta/`) |
| E1 | Linha de base WinRE no QEMU | qoder | Em andamento — só TCG (sem `/dev/kvm`); veja `E1-winre-boot-tcg.md` |
| E1b | Matriz de causa-raiz do boot do WinRE sob TCG (CPU, máquina, memória, layout da mídia) | qoder | Em andamento — a linha EFI-ISO está fechada como beco sem saída: o firmware monta apenas o ESP `efisys.bin` de 1.474.560 bytes como `FS0:` e nunca monta o volume ISO9660 que contém `\sources\boot.wim` (célula Y), e o bootmgr da Microsoft lançado do UEFI Interactive Shell para na cancela press-any-key do DVD, que 5.117 teclas injetadas não conseguiram abrir porque o shell — e não o bootmgr — as consumiu (células X, Z, AB, AC). A matriz agora se volta para a mídia em disco FAT32: a célula AD provou com `-device bochs-display` que o quadro chapado `#2067B2` é real (modo texto, o logo gráfico do TianoCore e o preenchimento de cor única vêm da mesma fonte de quadros) e que o convidado então pede desligamento por conta própria. Célula AE em andamento (reivindicada agora): mesmo disco com `winpeshl.ini` apontando `cmd.exe` em vez de `X:\sources\recovery\recenv.exe` — resultado: idêntico ao AD, então o shell do WinPE nunca é alcançado. AG (`q35`/AHCI + `-cpu max`) também terminou na mesma cor única, fechando o eixo da controladora. **O AF é o pivô**: com `\sources\boot.wim` renomeado para fora, a mesma mídia renderiza a tela de erro em texto do bootmgr (`Status: 0xc000000f`, `A required device isn't connected or can't be accessed`), então o azul é pintado só depois que o bootmgr entrega ao winload. Próxima célula em fila: AH (apagar `winload.efi` dentro do ramdisk). AH e AJ voltaram: apagar `winload.efi` do ramdisk dá o azul idêntico, e encolher o WIM para 0,89 GiB — dentro do volume de 1,51 GiB que o SDI declara — também dá o azul idêntico, então a aritmética do ramdisk também está eliminada. Toda variável do lado da mídia e da máquina alcançável sem um canal de debug termina na mesma cor única. Veja `E1-winre-boot-tcg.md` |
| E3b | Reconstrução da nvram em ASCII e SHA-256 dentro do WinRE | gpt | Ferramentas preparadas; NÃO é um pass — bloqueado no E1/E1b. Exige execução real no WinRE; testes simulados são inadmissíveis. Veja `E3b-ascii-hash-prep.md`. |
| E4 | Validação no hardware | user | Planejada; guiada pelo usuário |
| E5 | Reprodução do sintoma do erro 10: dispositivo PCI falso (`VEN_14E4&DEV_43EC`) + driver real | agente com KVM | Proposto; precisa de Windows completo inicializável; KVM recomendado. Veja `docs/04` |
| E7 | Sumidouro de escrita binária: hex/base64 digitado -> bytes brutos com ferramentas da imagem apenas | stackai | Planejado — só vale no WinRE real; bloqueado no E1 |
| E6 | Demo da correção de seleção de driver numa substituta e1000 funcional (driver errado -> erro 10, driver correto -> inicia) | agente com KVM | Proposto; fidelidade menor; precisa de Windows completo inicializável. Veja `docs/04` |

Atribua por capacidade: E5/E6 (erro-10 de Windows) precisam de um Windows completo inicializável e são melhor executados por
um agente com KVM. O efeito funcional da nvram sobre o rádio é o E4 (hardware).

## Regras

- Use `experiments/templates/experimento.md`.
- Declare o nível de fidelidade: F1, F2, F2b, F3 ou `somente metadados`.
- Separe fatos observados de hipóteses.
- Registre os comandos exatos e a saída observada.
- Registre os valores de SHA-256 de cada artefato.
- Declare as limitações do QEMU explicitamente.
- Nunca apresente um resultado do QEMU como prova de hardware.
- Não modifique as partes versionadas dos WIMs. Trabalhe em cópias em `qemu/work/` ou `/tmp`.
- Não faça commit de imagens geradas, logs ou segredos.

## Decisão atual de base

Nenhuma base está aprovada. O WinRE 1809 é a única imagem fornecida observada com `bcmwdidhdpcie.inf`, mas era um WIM derivado (reempacotamento wimlib do ESD oficial) e a sua origem não está verificada independentemente. A imagem de fábrica 10586 fornece apenas extras do OEM. F2 é candidato só depois que a procedência da 1809 for verificada; F1 é o teste de replano só-do-driver. Veja `winre-1809-oficial-intacta/` e `docs/06-auditoria-imagem-1809.md`.

---

## FILE: experiments/templates/experimento.md

# Experimento <ID> — <Título>

## Objetivo

Enuncie a pergunta única que este experimento responde.

## Nível de fidelidade

F1, F2, F2b, F3 ou `somente metadados`. Explique o que é exato e o que é aproximado.

## Pré-condições

- Imagens, pacotes e ferramentas necessários.
- Espaço livre necessário.
- Estado exigido no dispositivo ou no QEMU.
- O que precisar ser backup antes.

## Ambiente

- Data:
- Host:
- Kernel:
- Virtualização:
- Versões das ferramentas:
- Hashes das imagens:

## Comandos

```sh
# Comandos exatos, em ordem.
```

## Saída observada

```text
# Cole ou resuma a saída exata. Não invente saída ausente.
```

## Artefatos e hashes

| Caminho | SHA-256 | Tamanho |
|---|---|---|
| | | |

## Interpretação

### Fatos observados

- Fatos diretamente comprovados pela saída.

### Hipóteses

- Inferências ainda não provadas.

## Decisão

- Resultado: passou / falhou / bloqueado
- Motivo:
- Próximo experimento:

## Limitações

- Limitações do QEMU.
- Hardware ausente ou imagem ausente.
- Qualquer coisa que impeça uma conclusão mais forte.

## Reversão

- Como o ambiente foi restaurado.
- Resultado da verificação da reversão.

## Referências

- Documentos, experimentos e fontes externas relacionados.

---

## FILE: hypotheses.md

# Hipóteses

Lista de todas as hipóteses possíveis para o desafio (Wi-Fi BCM4356 com erro 10 no Xiaomi Mi Pad 2, só WinRE + `cmd` + texto digitado).

Regras de uso:

- Isto é **hipótese, não fato**. Fato só entra com experimento (`experiments/`), seguindo a regra de evidência de `AGENTS.md`. QEMU/mock nunca é prova de hardware.
- Cada hipótese tem ID `H-<grupo><n>`, um teste que a confirma ou refuta, e o que a refuta.
- Status: `[ ]` não testada, `[~]` em teste, `[+]` confirmada, `[-]` refutada, `[?]` bloqueada.
- Sem renomear arquivos existentes; sem outras branches (só `desafio`).

## Grupo A — Causa do erro 10 (rádio não inicia)

| ID | Hipótese | Como testar | O que refuta |
|---|---|---|---|
| H-A1 | Regressão do driver inbox de 2017 (`bcmpciedhd63.sys`) em relação ao OEM de 2015 | Comparar INF/binários; trocar o pacote no aparelho (E4) | OEM 2015 também dá erro 10 |
| H-A2 | Falta o arquivo nvram (`4356r2nvram.txt`) em `System32\drivers` | Colocar só a nvram (5.361 B) e reiniciar o dispositivo | Erro 10 persiste com nvram no lugar |
| H-A3 | Falta o firmware com nome renomeado (~0,64 MB) no caminho que o driver busca | Colocar nvram + firmware nos nomes que o `.sys` embute | Erro 10 persiste com os dois |
| H-A4 | A nvram existe mas tem conteúdo errado para a placa (boardtype, MAC, calibração) | Comparar com nvram da placa do Mi Pad 2 e com as de outros dispositivos | Conteúdo idêntico e ainda falha |
| H-A5 | O driver correto está em staging, mas o Windows seleciona outro por ranking (inbox ganha do OEM) | Conferir driver ativo; forçar a seleção por INF/hardware ID | Driver ativo já é o OEM e falha |
| H-A6 | Assinatura/política de driver bloqueia o pacote OEM (Secure Boot, catálogo, código 52) | Verificar código do problema; testar com assinatura de teste | Pacote carrega sem erro de assinatura |
| H-A7 | O problema é de energia/PCIe (ASPM, D3, reset de link) e não de driver | Ajustar parâmetros de energia/INF; comparar logs | Mudar energia não muda o código |
| H-A8 | Hardware ou firmware de plataforma (ACPI/_DSM, regulador) com defeito, fora do alcance do software | Não há teste só por software; E4 no aparelho | Qualquer variante de software inicia o rádio |
| H-A9 | Mais de uma causa ao mesmo tempo (ex.: nvram faltando E driver errado) | Matriz fatorial: {driver 2017, 2015} x {com, sem nvram} x {com, sem firmware} | Uma única variável resolve |
| H-A10 | O código "10" é sintoma de outro código real (ex.: 31, 39, 43) lido de forma errada | Ler código e detalhes pelo Gerenciador/`pnputil`/registro | Código confirmado como 10 |

## Grupo B — Canal de entrada (texto digitado vira binário)

| ID | Hipótese | Como testar | O que refuta |
|---|---|---|---|
| H-B1 | O teclado touch (TabTip) consegue digitar no `cmd` do WinRE de forma confiável | Digitar linha de teste e conferir na tela | TabTip não abre/não envia teclas no WinRE |
| H-B2 | O limite de linha do `cmd` (cerca de 8.191 caracteres) basta para o bootstrap | Colar/digitar linhas longas no WinRE real | Linha é truncada |
| H-B3 | `cscript`/`wscript` (JScript + `FileSystemObject`) existe e roda no WinRE real | `where cscript`, executar um `.js` mínimo | Ausente ou bloqueado |
| H-B4 | `mshta`/HTA existe como alternativa de execução de script | `where mshta` e teste | Ausente |
| H-B5 | Reconstrução em `cmd` puro (`for`, `set /a`, `echo`) é viável sem script | Reconstruir 1 KB só com `cmd` | Lento demais ou perde bytes (CR/LF, `%`, `^`, `!`) |
| H-B6 | Hex vs base64: documentar o método exato e medir | — | [ ] (só vale medir no WinRE real) |
| H-B7 | Alfabeto reduzido (só letras minúsculas/dígitos) evita autocorreção e maiúsculas do teclado | Digitar alfabeto completo e comparar | Teclado altera algo mesmo assim |
| H-B8 | Dá para verificar integridade sem `certutil` (hash em JScript ou `fc /b`/`comp`) | Rodar hash JS no WinRE e comparar com host | Sem mecanismo de checagem possível |
| H-B9 | `copy con arquivo` ou `echo ... > arquivo` grava bytes ASCII fielmente (inclui CR/LF final) | Gravar e comparar bytes | Acrescenta ou altera bytes |
| H-B10 | O Wi-Fi/Bluetooth/OBEX podem ser outro canal de entrada (fora do texto) | Verificar no aparelho; revisar restrições | Restrições proíbem ou não há pilha |
| H-B11 | A taxa de digitação manual (tempo humano) é viável: nvram 5,4 KB entra em tempo razoável | Cronometrar a digitação no touch real e estimar | Tempo inviável (horas) |
| H-B12 | Compressão antes de digitar | — | [ ] (testar `where expand` no WinRE real) |
| H-B13 | O firmware (0,64 MB) não precisa ser digitado: já existe em alguma pasta do aparelho e basta copiar/renomear | Procurar no `C:` e na imagem do WinRE | Não existe localmente |
| H-B14 | A tela como canal de saída basta para conferir (hash curto/QR textual) | Mostrar hash e conferir à mão | Tela corta/rola a saída |

## Grupo C — Ambiente QEMU (E1/E1b)

| ID | Hipótese | Como testar | O que refuta |
|---|---|---|---|
| H-C1 | O azul chapado `#2067B2` é a UI de recuperação rodando e desligando por conta própria | Já medido (AD): quadro real; falta a causa do desligamento | Outro estágio produz o azul |
| H-C2 | O azul vem depois do bootmgr entregar ao `winload` (AF) | Tela de erro do bootmgr em texto prova a ordem | Texto de erro também pinta azul |
| H-C3 | O WinRE sai por falta de driver de storage/vídeo da máquina emulada | Mudar controladora/vídeo (AG feito: não mudou) | Qualquer controladora resolve |
| H-C4 | Falta de canal de debug (serial do kernel, `pmemsave`, `-d`) impede ler o código de parada | Se o dono autorizar, ler o STOP code | Não há STOP code |
| H-C5 | O TCG é lento demais e há timeout de inicialização do WinRE | Aumentar timeouts e rodar com paciência | Mesmo resultado com tempo longo |
| H-C6 | O WinRE 10586 (fábrica) inicia onde o 1809 oficial não | Repetir a matriz com o 10586 | Também falha |
| H-C7 | Mídia em disco FAT32/VHD com layout diferente (BCD, ramdisk) muda o resultado | Variar BCD, `boot.sdi`, partições | Todas as variantes iguais |
| H-C8 | O firmware UEFI (OVMF) é o problema (versão, tamanho de RAM, GOP) | Testar outro OVMF, outro tamanho de RAM | Outro firmware igual |
| H-C9 | Falta uma característica de CPU/ACPI (Atom Z8500 tem features que `-cpu max` não tem) | Modelos de CPU Atom, flags `-cpu` | CPU não importa (AG: indício) |
| H-C10 | Outro emulador/hipervisor (KVM, Hyper-V, VirtualBox, bochs) inicia o WinRE | Rodar fora do QEMU TCG | Mesmo resultado em todos |
| H-C11 | A rota PCAT/SeaBIOS (`etfsboot`) funciona com outra mídia/ferramenta no host | Montar mídia com outra ferramenta | Sempre sem saída |
| H-C12 | Uma imagem de Windows completo (não só WinRE) inicia no QEMU e permite E5/E6 | Agente com KVM e imagem completa | Imagem completa também falha |
| H-C13 | O sandbox sem `/dev/kvm` é limitação definitiva; precisa outro host | Verificar host com KVM (remoto) | TCG resolve com ajustes |

## Grupo D — Instalação/troca do driver

| ID | Hipótese | Como testar | O que refuta |
|---|---|---|---|
| H-D1 | `pnputil /add-driver` coloca o pacote em staging, mas não troca o driver ativo | Instalar e conferir driver ativo | Troca o ativo |
| H-D2 | `drvload` carrega o OEM 2015 no WinRE em runtime | `drvload arquivo.inf` e checar o dispositivo | Falha ou não persiste |
| H-D3 | `dism /image:C:\ /add-driver` (offline) instala o OEM no Windows do `C:` | Rodar DISM offline numa cópia | Não aplica ou falha na assinatura |
| H-D4 | Copiar `.sys`/INF direto para `System32\drivers` e `inf\` basta | Cópia manual e reiniciar | Não é carregado |
| H-D5 | Alterar o registro offline (`reg load` do SYSTEM) força o serviço a usar o driver certo | Editar `Services\bcmpciedhd63` e checar | Serviço volta ao driver antigo |
| H-D6 | O pacote inbox de 2017 não tem `oemXX.inf` removível, então remoção por DISM não funciona | `dism /get-drivers /all` (Inbox: Yes) | Removível |
| H-D7 | `InstallHinfSection` via `rundll32 setupapi` instala sem `devcon` | Testar no WinRE | Comando ausente/falha |
| H-D8 | Renomear/mover o INF inbox de 2017 deixa o OEM vencer a seleção | Testar em cópia offline | Seleção continua errada |
| H-D9 | O pacote OEM completo é grande demais; versão reduzida (só 4 arquivos) é suficiente | Montar pacote mínimo e testar | Assinatura/catálogo exige o completo |
| H-D10 | Basta trocar só o `.sys` (sem INF) | Teste em cópia | Exige INF/catálogo |
| H-D11 | Editar o WIM do WinRE (servicing offline) embute os arquivos e persiste após reiniciar | Falta testar no aparelho | WinRE no aparelho é recriado/restaurado |
| H-D12 | Os arquivos devem ir para a partição de recuperação do aparelho e não para `X:` (RAM) | Verificar persistência após reboot | `X:` persiste |

## Grupo E — Pilha WLAN utilizável no WinRE

| ID | Hipótese | Como testar | O que refuta |
|---|---|---|---|
| H-E1 | O WinRE tem o serviço WLAN (`wlansvc`) e dependências necessárias | `sc query wlansvc`, listar DLLs | Ausente |
| H-E2 | `netsh wlan` existe e funciona sem WLAN AutoConfig completo | `netsh wlan show drivers` | Falha ou sem o contexto |
| H-E3 | Dá para conectar a uma rede WPA2 digitando SSID/senha por `netsh wlan add profile` | Teste com rede de laboratório | Associação falha |
| H-E4 | Mesmo com o rádio funcionando, faltam componentes (NativeWifiP, vwifibus, DHCP) e é preciso adicioná-los | Comparar com WinPE-WiFi | Tudo já presente |
| H-E5 | O Wi-Fi deixa de ser necessário: reinstalar o Windows a partir de fonte local basta | Procurar fonte local | Não há fonte local |
| H-E6 | Bluetooth (PAN) ou outro caminho dá rede sem Wi-Fi | Verificar suporte no WinRE | Sem pilha |
| H-E7 | Mesmo com rede, o WinRE não consegue baixar/aplicar uma imagem completa | Teste de download e aplicação | Consegue |

## Grupo F — Recuperar o Windows 10 17763

| ID | Hipótese | Como testar | O que refuta |
|---|---|---|---|
| H-F1 | `C:` não tem Windows utilizável; um `winre.wim` não é imagem de instalação | Inspecionar `C:`; já indicado pelo advisor | Existe `install.wim` |
| H-F2 | Nenhuma fonte local de 17763 existe (partições, recovery, OEM) | Listar partições do aparelho (E4) | Há fonte |
| H-F3 | "Reset this PC"/recuperação do fabricante restaura o Windows sem rede | Verificar no aparelho | Não existe imagem de recovery |
| H-F4 | `setup.exe`/`dism /apply-image` aplica uma imagem baixada pela rede | Teste com imagem e rede | Falha de driver/espaço |
| H-F5 | O erro 10 aparece só depois de reinstalar (regressão volta) e o driver precisa ser injetado na instalação | Injetar o OEM na imagem aplicada | Não volta |
| H-F6 | Alternativa: instalar outro SO (Linux) só para obter o rádio e baixar o Windows | Avaliar restrições | Fora do escopo |

## Grupo G — Metodologia e processo

| ID | Hipótese | Como testar | O que refuta |
|---|---|---|---|
| H-G1 | Começar pela nvram sem remover drivers é o caminho de menor custo (advisor) | E3b/E7 no WinRE real | Não resolve; outro caminho melhor |
| H-G2 | O E4 (hardware) é o único teste definitivo; o QEMU só valida mecânica | Plano E4 guiado pelo usuário | QEMU reproduz o erro (E5) |
| H-G3 | Um dispositivo PCI falso (E5) reproduz o erro 10 num Windows completo | Montar `VEN_14E4&DEV_43EC` falso + driver real | Não reproduz |
| H-G4 | Substituta e1000 (E6) mostra "driver errado dá 10, correto inicia" | Rodar E6 | Sem diferença |
| H-G6 | Dividir por capacidade (KVM vs TCG) acelera: E5/E6 para agente com KVM, E3b/E7 para os demais | Atribuir e medir | Gargalo é outro |
| H-G7 | Documentar cada experimento com o modelo de `experiments/templates/experimento.md` evita refazer testes | Auditoria dos logs | Refaz mesmo assim |

## Tabela de tarefas

Atualize o Status ao trabalhar (um agente por vez, sem claims). Prioridade sugerida: H-B3, H-B1, H-B2 e H-B8 desbloqueiam o canal; H-A2/H-A3/H-A9 testam a causa; H-C* só desbloqueiam o E1b.

| ID | Tarefa | Owner | Status |
|---|---|---|---|
| H-B1 | Digitar no `cmd` do WinRE pelo TabTip | — | [ ] |
| H-B2 | Limite de linha do `cmd` no WinRE | — | [ ] |
| H-B3 | `cscript`/JScript/FSO no WinRE | — | [?] bloqueada no E1b |
| H-B8 | Hash sem `certutil` | — | [ ] |
| H-B6 | Hex vs base64: documentar o método exato e medir | — | [ ] (só vale medir no WinRE real) |
| H-B11 | Tempo de digitação da nvram | — | [ ] |
| H-B12 | Compressão antes de digitar | — | [ ] (testar `where expand` no WinRE real) |
| H-B13 | Firmware já local (sem digitar) | — | [ ] |
| H-A2 | Só nvram resolve? | — | [ ] |
| H-A3 | nvram + firmware resolve? | — | [ ] |
| H-A4 | Conteúdo da nvram correto para a placa | — | [ ] |
| H-A5 | Seleção do driver por ranking | — | [ ] |
| H-A9 | Matriz fatorial driver x nvram x firmware | — | [ ] |
| H-C4 | Ler o STOP code (canal de debug) | — | [?] precisa autorização do dono |
| H-C6 | WinRE 10586 inicia? | qoder | [~] E1b |
| H-C10 | Outro hipervisor / KVM | — | [ ] |
| H-D2 | `drvload` do OEM 2015 | — | [ ] |
| H-D3 | `dism /add-driver` offline no `C:` | — | [ ] |
| H-D8 | Renomear INF inbox para o OEM vencer | — | [ ] |
| H-D12 | Persistência: `X:` x partição de recuperação | — | [ ] |
| H-E1 | `wlansvc` e dependências no WinRE | — | [ ] |
| H-E4 | Componentes WLAN faltando | — | [ ] |
| H-F1 | `C:` sem Windows utilizável | — | [ ] |
| H-F2 | Fonte local de 17763 | — | [ ] |
| H-G3 | Dispositivo PCI falso (E5) | — | [ ] |
| H-G4 | Substituta e1000 (E6) | — | [ ] |

---

## FILE: inventory/README.md

# Inventário

Nomes de arquivo (sem caminho) das duas imagens WIM verificadas: WinRE 1809 oficial e firmware de fábrica 10586.
Resumo curado e descobertas decisivas: `docs/07-inventario-imagens.md`.

As listagens com caminho completo foram removidas (eram grandes, ~7 MB); continuam no histórico do git
(commit anterior a este) se for preciso consultar um caminho.

## Estrutura

```
names-only/
  winre-1809/<tipo>.txt            nomes únicos, ordenados, um por linha
  winre-fabrica-10586/<tipo>.txt
  delta-*.names.txt                binários só numa das imagens (ativos = sem WinSxS; binaries = com WinSxS)
```

Tipos: `executaveis` (.exe .com .scr .efi), `bibliotecas` (.dll .ocx .cpl .drv .ax .tlb), `drivers` (.sys),
`inf` (.inf .inf_loc .pnf), `catalogos` (.cat), `manifestos` (.manifest .mum), `idiomas` (.mui .nls),
`scripts` (.js .vbs .cmd .bat .ps1 ...), `config` (.ini .xml .xsd .reg .mof .mfl .cdxml .dat .cdf-ms),
`fontes` (.fon .ttf .otf), `outros` (resto, inclui arquivos sem extensão).

Exemplo de busca: `grep -ri cscript inventory/names-only/winre-1809/executaveis.txt`
Busca em tudo: `grep -rix 'expand.exe' inventory/names-only`

## Para regerar (scripts)

```sh
wimlib-imagex dir <wim> 1 > /tmp/lista.txt                       # caminhos completos (só em /tmp)
scripts/extract-basenames.py /tmp/lista.txt -o /tmp/nomes         # tira o caminho
scripts/dividir-inventario.py /tmp/nomes/lista.names.txt -o inventory/names-only/<imagem>
```

Limite: sem caminho, não dá para saber se um `.exe`/`.dll` está em `System32` (utilizável pelo `cmd`) ou só em
`WinSxS`. Existir como nome não prova que roda no WinRE.

---

## FILE: prompts/advisor-anexos/README.md

# Anexos do advisor

Coloque aqui arquivos de contexto para enviar junto ao prompt do advisor (ex.: `docs/DOCS-BUNDLE.md`,
saídas de comandos observadas na tela, notas do dono). `scripts/advisor-request.py` anexa automaticamente
todos os arquivos (não ocultos) desta pasta à mensagem enviada, em ordem alfabética.

- `--attach-dir` altera a pasta (padrão: `prompts/advisor-anexos`).
- Arquivos muito grandes são truncados no envio (limite por arquivo no script) para evitar estouro de contexto/custo.
- Mantenha apenas o que for relevante para a rodada; remova ou mova anexos antigos para não inflar o prompt.

---

## FILE: prompts/advisor-historico/README.md

# Histórico do advisor (entrada/saída)

`scripts/advisor-request.py` salva aqui, a cada execução, uma transcrição `advisor-transcript-<timestamp>.md`
contendo o INPUT (prompt + anexos) e o OUTPUT (resposta). Nas execuções seguintes, os últimos pares são
incluídos como histórico na conversa enviada ao modelo (padrão: 4 pares; `--history-limit N`, `--no-history`).

Isso preserva contexto entre rodadas (perguntas essenciais feitas pelo advisor, respostas do dono, decisões).

---

## FILE: prompts/advisor-respostas/advisor-resposta-20261115-124958.md

# Resposta do advisor

- Modelo: `gpt-6-astra`
- Esforço de raciocínio: `low`
- Prompt: `prompts/advisor.md`
- Gerado em: 2026-11-15 12:48:13 UTC
- Concluído em: 2026-11-15 12:49:58 UTC
- Tokens: prompt=6362 completion=4548 total=10910

---
## 1. TL;DR

**Eu começaria pelo nvram, sem remover drivers nem alterar o WIM original.** Primeiro provaria a escrita fiel de texto ASCII no WinRE real; depois testaria nvram e firmware nos caminhos esperados pelo driver de 2017.
Esse teste pode demonstrar uma recuperação barata, mas **não substitui nem refuta a hipótese de regressão do driver**.
Antes de investir na digitação do OEM, verificaria dois bloqueios independentes: existência de uma pilha WLAN utilizável no WinRE e de uma fonte local para reinstalar o Windows 17763.
O fallback é o pacote OEM completo, instalado por mecanismo suportado e com seleção efetivamente confirmada — condicionado a resolver o transporte binário.
**Não há, nos dados fornecidos, uma recuperação completa já demonstrada.**

## 2. Diagnóstico

Há quatro problemas separados:

| Camada | Situação |
|---|---|
| **Entrada de dados** | Texto entra pelo TabTip. E3 demonstrou reconstrução em Linux, não em WinRE. |
| **Inicialização do rádio** | Driver de 2017 falha; OEM de 2015 com nvram é a hipótese principal de correção. |
| **Canal Wi-Fi utilizável** | Além do rádio iniciado, exige serviço/pilha WLAN e ferramentas de associação presentes e funcionais. `netsh.exe` sozinho não demonstra isso. |
| **Reinstalação do Windows** | `C:` não contém Windows utilizável. Um `winre.wim` não é uma imagem de instalação do Windows completo. Nenhuma fonte completa de 17763 foi identificada. |

Minha recomendação ataca primeiro **entrada de texto e inicialização do rádio**, verificando em paralelo os outros dois bloqueios.

### Fatos, hipóteses e incógnitas importantes

- **Fato:** o nvram tem 5.361 bytes, é ASCII e não está na imagem.
- **Hipótese:** colocar nvram e firmware nos nomes procurados permite ao driver de 2017 iniciar.
- **Hipótese principal:** mesmo com esses arquivos, será necessário selecionar o OEM de 2015.
- **Desconhecido:** componentes WLAN efetivamente funcionais no WinRE real. WinRE/WinPE não deve ser tratado como Windows completo com Wi-Fi garantido.
- **Desconhecido:** método disponível para ler o código de problema do dispositivo no aparelho.
- **Desconhecido:** assinatura e completude do pacote OEM após qualquer redução de payload.
- **Desconhecido:** existência de imagem completa de Windows em alguma partição.

Há ainda três correções necessárias no procedimento conhecido:

1. **`pnputil /scan-devices` e `/enum-devices` não devem ser usados como fallback garantido no build 17763.** São opções introduzidas posteriormente; consultar `pnputil /?`.
2. **DISM não remove drivers inbox pelo procedimento normal de remoção de terceiros.** É preciso distinguir “veio na imagem” de `Inbox : Yes`. O pacote pode não possuir um `oemXX.inf` removível.
3. **`pnputil /add-driver ... /install` não força um driver de ranking inferior.** Sucesso no staging não significa troca do driver ativo.

F1 é a base padrão adequada para mecânica. A alegação antiga de “nenhuma base aprovada” está superada pelo briefing; F3 não é requisito.

## 3. Opções

| Abordagem | O que prova / não prova | Pré-requisitos | Payload e reconstrução | Risco / esforço |
|---|---|---|---|---|
| **1. Nvram-only, mais firmware local no destino correto** | No aparelho, pode provar suficiência desses arquivos. Não prova necessidade do OEM nem recupera o Windows sozinho. | Conteúdo exato do nvram; escrita ASCII validada; forma de reinicializar o dispositivo ou bootar cópia persistente. | 5.361 bytes ASCII; firmware copiado localmente, sem transmissão. | Baixo em RAM; baixo a médio esforço. |
| **2. Bootstrap textual com JScript + FSO** | Prova reconstrução de **ASCII**, inclusive CR/LF exatos. Não prova escrita binária arbitrária. | `cscript`, engine e FSO funcionando, não apenas presentes. | Script digitado; hexadecimal limitado a bytes ASCII. | Baixo; primeiro teste recomendado. |
| **3. Decoder binário por COM ou conversão de página de códigos** | Se validado, abre transporte do OEM. Não prova funcionamento do rádio. | Um sink realmente disponível; teste exaustivo de bytes e hash. | MSXML decodifica; falta provar gravação. Alternativa não óbvia: FSO com mapeamento de página de códigos, **somente se comprovadamente reversível**. | Médio/alto esforço; alto risco de falsa fidelidade. |
| **4. Pacote OEM de 2015 por servicing/PnP** | Prova staging e, separadamente, seleção do OEM. Só o aparelho prova correção do erro 10. | Pacote completo local, assinatura válida, seleção suportada, espaço e backup. | Binários + INF + catálogo + nvram; reconstrução binária ainda bloqueada. | Médio/alto risco; alto esforço manual. |
| **5. Bluetooth** | Poderia criar outro canal; nada disso está demonstrado. | Pilha Microsoft ausente, firmware, drivers, pareamento e ferramentas. | Exigiria entregar mais binários antes de obter o canal. | Descartado nesta etapa: dependência circular e esforço alto. |
| **6. QEMU F1 + cópia de WIM** | Prova boot, scripts e servicing na base sintética. Não prova BCM4356, WLAN real ou boot no tablet. | F1 inicializável; entrada pelo teclado virtual; sem canais proibidos. | Mesmo texto que seria digitado no aparelho. | Baixo risco ao aparelho; esforço médio. E5/E6 não são prioridade. |

### Comandos, verificação e limites dessas opções

**Opções 1 e 2:** comandos do primeiro teste abaixo. Para a opção 1, os destinos são:

```bat
%SystemRoot%\System32\drivers\4356r2nvram.txt
%SystemRoot%\System32\drivers\4356r2rtecdc.bin
```

A origem do firmware deve ser localizada na imagem real antes de copiar:

```bat
dir /s /b "%SystemRoot%\System32\DriverStore\FileRepository\4356a2rtecdc.bin"
```

Não reutilizar um arquivo só pelo nome: comparar seu hash com a origem esperada quando o verificador estiver disponível.

**Opção 3:** não há comando de produção honesto a oferecer com os fatos atuais. O ensaio obrigatório é gravar uma sequência contendo todos os valores `00`–`FF`, reler, verificar tamanho e SHA-256. A ausência de um sink comprovado encerra essa opção antes de digitar megabytes. Entregar “um pequeno decoder como texto” só resolve se ele for interpretado por uma ferramenta existente; enviar um executável em hexadecimal mantém o mesmo problema de bootstrap.

**Opção 4:** apenas quando houver uma cópia montada e o pacote local:

```bat
dism /Image:C:\Mnt /Get-Drivers /All /Format:Table
```

Aqui, `C:\Mnt` é um **diretório de montagem a criar**, não um caminho observado. Consultar o pacote identificado:

```bat
dism /Image:C:\Mnt /Get-DriverInfo /Driver:NOME_PUBLICADO
```

`NOME_PUBLICADO` deve ser substituído pelo nome realmente exibido. Se for terceiro e removível, a sequência conhecida de remoção/adição pode ser ensaiada numa cópia. Se for inbox protegido, **parar**, sem apagar manualmente o DriverStore. Não há `devcon` nem interface de seleção manual garantida neste ambiente.

**Opção 5:** não executar instalação exploratória de Bluetooth no aparelho.

**Opção 6:** dentro do WinRE F1, começar com:

```bat
ver
pnputil /?
dism /?
```

Depois executar o mesmo teste textual abaixo. Se houver BSOD, registrar código e etapa do boot; não concluir que TCG é inviável. Não é necessário resolver E5/E6 para testar nvram no tablet.

## 4. Recomendação

### Principal: teste textual → nvram em RAM → teste real do rádio

A navalha do menor teste produz dois degraus:

1. **Poucos bytes:** descobrir se o WinRE consegue reconstruir ASCII fielmente com o que já tem.
2. **5.361 bytes:** descobrir se nvram, com firmware no destino correto, basta para o driver instalado.

O segundo teste avalia a **suficiência do nvram com o driver atual**. Se falhar de maneira controlada, fortalece a prioridade de H2; **não falsifica H2**.

Não usaria edição de WIM como primeiro experimento. Alterações em RAM preservam o único ambiente de recuperação. Entretanto, copiar arquivos depois que o driver já falhou **pode não provocar nova inicialização**: sem reinicialização efetiva do dispositivo, um erro 10 persistente é resultado inconclusivo.

### Fallback: OEM completo, primeiro numa cópia

Só avançar quando estiverem resolvidos:

- transporte e hash dos binários;
- capacidade real de servicing;
- método de seleção do OEM apesar do ranking;
- boot reversível de uma cópia, preservando toque e TabTip.

O `.sys` OEM sozinho representa aproximadamente **2,08 milhões de caracteres hexadecimais**, antes de comandos e verificações. Portanto, não é racional iniciar essa digitação sem antes esgotar o teste textual e procurar um pacote OEM já armazenado localmente.

Mesmo com rádio corrigido, a recuperação completa exige uma fonte de Windows e WLAN operacional. **Corrigir código 10 não cria automaticamente um canal de rede no WinRE.**

## 5. Passo a passo do primeiro teste

Este teste é não destrutivo: **não troca driver, não altera BCD e não modifica o WIM**.

### A. Identificar ambiente e capacidade WLAN

Digitar e registrar visualmente os resultados:

```bat
ver
echo %SystemRoot%
echo %date% %time%
pnputil /?
netsh wlan show drivers
netsh wlan show interfaces
```

Se `sc.exe` existir, consultar o serviço:

```bat
if exist "%SystemRoot%\System32\sc.exe" sc query WlanSvc
```

Interpretação:

- “Não há interface sem fio” não demonstra ausência da pilha; pode decorrer do driver.
- Contexto `wlan` desconhecido ou serviço inexistente revela **outro bloqueio além do erro 10**.
- Serviço parado é diferente de serviço inexistente.
- Nenhuma dessas saídas, isoladamente, prova `ConfigManagerErrorCode = 0`.

### B. Criar área temporária

```bat
md "%TEMP%\mipad-probe"
notepad "%TEMP%\mipad-probe\ascii.js"
```

No Notepad, digitar o script abaixo. Salvar como texto **ANSI**, mantendo o nome `ascii.js`. O conteúdo do script é todo ASCII.

```js
var f = new ActiveXObject("Scripting.FileSystemObject");
if (WScript.Arguments.length != 2) WScript.Quit(2);
var h = WScript.Arguments(0);
var p = WScript.Arguments(1);
if (!/^[0-9a-fA-F]+$/.test(h) || h.length % 2) WScript.Quit(3);
var s = "";
for (var i = 0; i < h.length; i += 2) {
  var n = parseInt(h.substr(i, 2), 16);
  if (n < 32 && n != 9 && n != 10 && n != 13) WScript.Quit(4);
  if (n > 126) WScript.Quit(4);
  s += String.fromCharCode(n);
}
var w = f.CreateTextFile(p, true, false);
w.Write(s);
w.Close();
var r = f.OpenTextFile(p, 1, false, 0);
var t = r.ReadAll();
r.Close();
var z = "";
for (var j = 0; j < t.length; j++) {
  var q = t.charCodeAt(j).toString(16);
  z += q.length == 1 ? "0" + q : q;
}
WScript.Echo("bytes=" + f.GetFile(p).Size);
WScript.Echo("hex=" + z);
WScript.Echo("time=" + new Date().toUTCString());
if (z != h.toLowerCase()) WScript.Quit(5);
```

Esse script é um **reconstrutor restrito a texto ASCII**, não um decoder binário. A restrição é deliberada.

### C. Executar uma amostra com CR/LF e metacaracteres

```bat
cscript //nologo "%TEMP%\mipad-probe\ascii.js" 410d0a42253e267c5e0d0a "%TEMP%\mipad-probe\probe.txt"
echo %errorlevel%
```

**Resultados esperados — não observados por mim:**

```text
bytes=11
hex=410d0a42253e267c5e0d0a
```

Além disso, deve aparecer um timestamp, e o segundo comando deve mostrar `0`.

Essa amostra inclui `%`, `>`, `&`, `|` e `^`. Como entram codificados, não são interpretados pelo `cmd`. Isso evita um defeito importante de usar `echo` diretamente para qualquer conteúdo do nvram.

### D. Decisão do primeiro teste

- **PASS da mecânica ASCII:** 11 bytes, hexadecimal idêntico e código `0`.
- **FAIL:** erro de engine/COM, tamanho diferente, conteúdo diferente ou código não zero.
- **Não é ainda PASS de E3b:** faltam o nvram completo e SHA-256.

A releitura hexadecimal demonstra igualdade da amostra, mas **não substitui o requisito de hash**. Não há ferramenta de hash nativa comprovada no inventário. O próximo artefato necessário é um verificador SHA-256 em script, previamente validado em F1 com vetores conhecidos, também entregue como texto. Não apresento aqui um comando de hash inexistente.

### E. Próximo teste, condicionado ao conteúdo do nvram

Com o conteúdo original disponível:

1. Preparar blocos curtos numerados e seus hashes fora do aparelho.
2. Digitar cada bloco pelo TabTip; reconstruir em arquivos separados.
3. Só prosseguir após conferir o ACK da execução e o bloco esperado na tela.
4. Concatenar os blocos em ordem explícita com `copy /b`, sem curingas.
5. Exigir tamanho **5.361 bytes** e SHA-256:

```text
a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667
```

6. Copiar para o destino do nvram e colocar o firmware local no nome esperado.
7. Testar nova inicialização do dispositivo por um método efetivamente disponível.

O script acima sobrescreve o arquivo de saída: **não reutilizar o mesmo nome para blocos sucessivos**.

Não forneço os comandos finais de cópia e reinicialização sem conhecer os arquivos existentes e as capacidades do aparelho. Sobrescrever arquivos ou reiniciar agora poderia apagar a única cópia recém-digitada ou tornar o teste inconclusivo.

Registrar comandos, saídas, hashes e horários localmente e na tela; o relógio do WinRE pode estar incorreto. Transcrição manual é suficiente para comunicar observações, sem exportar arquivos.

## 6. Riscos e critérios de abandono

| Observação | Decisão |
|---|---|
| FSO ou engine não funcionam | Abandonar esse bootstrap. Avaliar texto direto no Notepad, mas somente com verificação de bytes e terminações de linha. |
| Nvram não corresponde ao hash | Não instalar. Corrigir a reconstrução. |
| Nvram/firmware corretos, mas driver não foi reinicializado | Resultado inconclusivo; não declarar falha da hipótese. |
| Após inicialização comprovadamente nova, erro 10 continua | Encerrar nvram-only e priorizar OEM de 2015. |
| OEM apenas staged; driver de 2017 continua ativo | Correção não foi testada. Resolver seleção, não repetir instalação. |
| Pacote de 2017 é inbox não removível | Abandonar a receita simples de remoção. Não apagar DriverStore manualmente. |
| Rádio inicia, mas WLAN não existe no WinRE | Sucesso parcial de hardware; canal externo continua bloqueado. |
| Não existe fonte local de Windows completo | Reinstalação continua bloqueada até haver um canal funcional e uma fonte legítima acessível. |
| Montagem/commit não suportados ou espaço insuficiente | Não modificar `D:`. Preservar o original e parar essa etapa. |
| Boot da cópia perde toque/TabTip | Rejeitar a cópia: sem entrada, a recuperação piora. |

USB, SD, Ethernet, rede prévia, clipboard, compartilhamento QEMU, serial e `hostfwd` estão descartados. Editar a imagem no host não entrega arquivos ao tablet.

## 7. Perguntas ao dono

1. **Você tem acesso ao conteúdo original completo do nvram fora do tablet e pode fornecê-lo como texto?**  
   O tamanho e o hash não permitem reconstruí-lo. Isso bloqueia o teste de 5.361 bytes.

2. **O que aparece em `netsh wlan show drivers` e, se disponível, `sc query WlanSvc`?**  
   Basta ler e transcrever o resultado essencial. Isso decide se corrigir o rádio pode realmente criar um canal nesse WinRE.

3. **Onde e por qual ferramenta foi observado o erro 10 no aparelho? Essa ferramenta ainda está acessível?**  
   Precisamos distinguir erro atual de histórico e estabelecer como verificar o critério de código zero.

4. **Há alguma imagem completa de instalação/recuperação do Windows ou pacote OEM já armazenado em alguma partição?**  
   Se houver, informar apenas caminho e tamanho vistos na tela. Isso pode eliminar o transporte binário e desbloquear a reinstalação.

5. **O TabTip permite salvar no Notepad e digitar aspas, barras e sinais do script?**  
   Isso decide se o primeiro teste é executável pelo canal real, sem pressupor atalhos de teclado físico.

## 8. Confiança

- **Alta** na decisão de preservar o WinRE original, começar com ASCII e separar rádio, WLAN e reinstalação.
- **Média** na viabilidade do bootstrap JScript/FSO: os componentes existem, mas falta execução observada no WinRE real.
- **Baixa a média** em nvram-only resolver o erro 10.
- **Média** no OEM de 2015 como correção do rádio; **baixa** numa recuperação completa imediata, porque transporte binário, seleção do driver, pilha WLAN e fonte do Windows ainda não estão resolvidos.

---

## FILE: prompts/advisor.md

# PROMPT — CONSELHEIRO TÉCNICO SÊNIOR (RECUPERAÇÃO MIPAD 2 / WINRE)

Você é um conselheiro técnico sênior contratado para resolver um problema de recuperação
de sistema operacional sob restrições extremas. Sua função não é concordar com o dono nem
repetir o que já foi tentado: é pensar a fundo, encontrar o caminho de menor risco e
entregar uma decisão acionável.

Leia o briefing inteiro antes de responder. Você não tem acesso ao repositório, aos
arquivos, à imagem do dispositivo nem ao hardware. Tudo o que você precisa saber está
neste prompt. Se faltar um dado que bloqueie a decisão, peça explicitamente e diga por quê;
não invente fatos, hashes, saídas de comando ou ferramentas que não existem.

Você pode raciocinar longamente antes de responder. A resposta final deve ser densa,
concreta e verificável, em português.

---

## 1. MISSÃO

Recuperar um Xiaomi Mi Pad 2 (x64) que tem apenas o WinRE na partição de recuperação,
sem nenhum canal físico de entrada ou saída, e cujo único adaptador de rede — o Wi-Fi
Broadcom BCM4356 — é justamente o dispositivo que falha com erro 10.

O caminho pretendido tem três camadas que não podem ser confundidas:

1. **Canal:** fazer um payload entrar no dispositivo apenas como texto digitado no
   teclado virtual da tela e ser reconstruído dentro do WinRE.
2. **Correção do driver:** substituir o driver Broadcom de 2017 (quebrado) pelo driver
   OEM de 2015, incluindo o nvram da placa, vencendo a preferência do Windows pelo
   driver mais novo.
3. **Hardware:** validar no aparelho físico que o adaptador inicia sem erro 10 e que o
   Windows 10 build 17763 volta a bootar.

## 2. CRITÉRIOS DE SUCESSO

- No hardware: `ConfigManagerErrorCode` do `PCI\VEN_14E4&DEV_43EC` igual a `0`.
- `netsh wlan show drivers` lista o adaptador.
- O dispositivo conecta a uma rede Wi-Fi.
- O Windows 10 build 17763 aplicado inicia.
- Toda evidência é registrada como comandos digitados + saída observada na tela +
  hashes + timestamps. Sem transferência de arquivos para fora do aparelho.
- Resultados de QEMU são mecânica de software, nunca prova de hardware.

## 3. RESTRIÇÕES DURAS (NÃO NEGOCIÁVEIS)

| Item | Regra |
|---|---|
| USB | Proibido. Não assuma que existe ou funciona. |
| Cartão SD | Proibido. |
| Ethernet | Proibido. |
| Teclado físico | Proibido. |
| Abrir o aparelho | Proibido. |
| Clipboard / copiar e colar | Proibido no dispositivo. |
| Pasta compartilhada / 9p / `-virtfs` | Proibido no QEMU. |
| Transferência serial de arquivo | Proibida. |
| Portas encaminhadas do host (`hostfwd`) | Proibidas no QEMU. |
| Saída de arquivos do dispositivo | Impossível. O dispositivo não envia arquivos. |
| Rede de entrada | Inviável: o Wi-Fi é o dispositivo quebrado; Bluetooth não verificado. |
| WinRE | Fornece apenas `cmd`. Não assuma PowerShell. |
| Edição de WIM no host | É prova de mecânica numa cópia; não é o método de transferência do dispositivo. |
| QEMU | Não emula o rádio BCM4356; resultado de QEMU não é prova de hardware. |

**Canal de entrada válido:** somente texto digitado pelo teclado virtual da tela
(`TabTip.exe`). O payload entra como hexadecimal, base64 ou texto puro e é reconstruído
dentro do WinRE usando apenas ferramentas que existem na imagem. A tela é o único canal
de saída.

**Consequência:** qualquer solução que presuma HTTP, FTP, SMB, pacote de rede, USB,
cartão SD, teclado físico, clipboard ou pasta compartilhada está errada para este
dispositivo, mesmo que funcione no QEMU.

## 4. ESTADO DO DISPOSITIVO

- Xiaomi Mi Pad 2, arquitetura x64.
- Windows 10 build 17763 estava instalado.
- `C:` foi formatado rapidamente; não há Windows utilizável em `C:`.
- O único ambiente Windows restante é a partição de recuperação em `D:` (WinRE).
- O WinRE roda em RAM; alterações feitas nele durante a sessão desaparecem ao reiniciar,
  a menos que o WIM em `D:` seja modificado e substituído.
- A partição de recuperação real tem aproximadamente 398 MB.
- A imagem real de ~398 MB não está disponível e não pode ser transferida para fora.
- Canais disponíveis: tela, `cmd` do WinRE, toque. Wi-Fi quebrado. Bluetooth não
  verificado e sem pilha no WinRE.
- O dono só pode ler a tela e digitar comandos. Não peça que ele copie arquivos,
  instale programas ou abra o aparelho.

## 5. FATOS DO DRIVER

Dispositivo Wi-Fi: `PCI\VEN_14E4&DEV_43EC` (Broadcom BCM4356).

| Pacote | INF | Versão | Data | Origem |
|---|---|---:|---|---|
| Inbox quebrado | `bcmwdidhdpcie.inf` | 1.558.53.25 | 2017-04-21 | WinRE 1809 |
| OEM bom | `oem25.inf` | 1.558.14.0 | 2015-12-23 | backup OEM do Mi Pad 2 |

- Os dois pacotes usam um arquivo chamado `bcmpciedhd63.sys`, mas os binários diferem:
  inbox tem 1.037.824 bytes; OEM tem 1.041.320 bytes.
- O Windows prefere o driver mais novo. Adicionar o pacote OEM sem remover o inbox, ou
  sem forçar o OEM, não resolve: o inbox de 2017 continua selecionado.
- O pacote inbox de 2017 cobre `DEV_43EC` (BCM4356) e `DEV_4355` (BCM4359).
- O pacote OEM de 2015 cobre mais dispositivos, incluindo `DEV_43EC`.
- O INF OEM inclui a linha de cópia do nvram:
  `4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6`.
- O INF inbox de 2017 NÃO inclui essa linha de nvram, nem catálogo, nem as DLLs IHV.

### Estado alvo do DriverStore (estado quebrado, não é a correção)

Pastas exatas:

- `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9` — 4 arquivos:
  `bcmwdidhdpcie.inf`, `bcmpciedhd63.sys`, `4356a2rtecdc.bin`, `43596a0rtecdc.bin`.
- `bcmdhd64.inf_amd64_e0bae6831f60ea5f` — 5 arquivos.
- `bcmfn2.inf_amd64_5ebadf201c5b5845` — 2 arquivos.

A pasta do Wi-Fi não contém nvram. O `43596a0rtecdc.bin` pertence ao `DEV_4355` e fica
na pasta porque o estado alvo é mantido idêntico.

### Pacote OEM de 2015 (payload de substituição)

- `oem25.inf`, versão 1.558.14.0, 16 arquivos, 13,97 MB.
- Cobre `DEV_4355`, `4364`, `43A3`, `43BA`, `43C3`, `43EC`, `43EF`, `440D`.
- Lista de cópia do `DEV_43EC`: `bcmpciedhd63.sys`, `4356r2rtecdc.bin` (renomeado de
  `4356a2rtecdc.bin`) e `4356r2nvram.txt` (renomeado de
  `bcm94356wlpagbl_P3_150828M.txt`).
- Inclui `bcmpciedhd63.cat`, `bcmihvsrv64.dll`, `bcmihvui64.dll`.
- O WinRE já contém o `.sys` inbox e o firmware `4356a2rtecdc.bin` no DriverStore, mas
  não contém o nvram.

## 6. NVRAM

- Arquivo de origem: `bcm94356wlpagbl_P3_150828M.txt`.
- Cópia hipotética renomeada: `4356r2nvram.txt`.
- Tamanho: 5.361 bytes.
- SHA-256: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
- Conteúdo: 100% ASCII imprimível, formato `chave=valor` de configuração Broadcom.
- O driver procura em: `\SystemRoot\system32\drivers\4356r2nvram.txt`.
- O nvram NÃO está no estado alvo, NÃO está no WinRE 1809 e NÃO está no WIM de fábrica.
- O driver também procura o firmware `\SystemRoot\system32\drivers\4356r2rtecdc.bin`;
  a origem `4356a2rtecdc.bin` já existe na imagem.

### Hipóteses

- **H2 (primária):** o driver PCIe de 2017 é a regressão. Remover o pacote inbox e
  instalar o OEM de 2015, com seu nvram, é a correção principal.
- **H1 (secundária):** se a instalação do pacote OEM não copiar o nvram para
  `System32\drivers`, o nvram precisa ser fornecido separadamente.

### Alavanca de menor payload

O aparelho já tem os arquivos do driver no DriverStore. O que falta é o nvram, que é
texto. Se H1 for suficiente, **somente 5.361 bytes de texto precisam cruzar o canal**, sem
nenhuma transferência binária. Trate isso como a hipótese de menor custo a testar antes de
assumir que o `.sys` de ~1 MB precisa ser digitado.

## 7. IMAGENS DISPONÍVEIS E FIDELIDADE

| Imagem | Build | Tamanho | Conteúdo decisivo |
|---|---:|---:|---|
| WinRE 1809 oficial (`winre-1809-oficial-intacta/`) | 17763 | WIM 266.283.224 bytes; 21.230 paths; 17.669 arquivos; 3.560 diretórios | Contém o driver PCIe quebrado de 2017; contém `pnputil` e `dism`; NÃO contém nvram; NÃO contém extras OEM SDIO. |
| Fábrica 10586 (`winre-fabrica-10586-424MB/`) | 10586 | WIM 444.856.529 bytes; 26.461 paths; 21.867 arquivos; 4.593 diretórios | Contém extras OEM Broadcom SDIO (`bcmdhd63.sys`, `bcmdhd64.sys`, `bcmfn.sys`, `bcmfn2.sys`) e `intelppm.sys`/`intelide.sys`; NÃO contém `bcmwdidhdpcie.inf`; NÃO contém `pnputil`; NÃO contém nvram. |
| Dispositivo real | 17763 atualizado | ~398 MB | Não disponível. Só foi vista na tela do aparelho. Não pode ser transferida. |

Proveniência do WinRE 1809: ESD oficial `Core_en-us.esd`, 522.499.063 bytes, SHA-1
`8352af7661fb4808decc0253f6d516b7c2d88605`; WIM reextraído com SHA-256
`232199c585111bfae71ff00dbdcabe5c75195fc9b431eb4d1711b8a7e471eb6c`. O estado de
drivers foi comparado byte a byte e confere.

Fidelidade do WIM de fábrica: SHA-256
`152addc420748815c2cad90d382229e249ec853d3842531ddcc2b9998248067a`.

### Níveis de fidelidade

- **F1:** WinRE 1809 oficial + estado alvo de 2017 + pacote OEM 2015 + nvram. Base
  considerada para a mecânica do driver. A partição real de ~398 MB não é reproduzida.
- **F2:** F1 + extras OEM extraídos do WIM de fábrica 10586. Aproximação da partição
  atualizada; não é a partição real.
- **F2b:** WIM de fábrica 10586 + injeção do pacote PCIe de 2017. Menos fiel ao build
  do dispositivo; usar só como controle.
- **F3:** imagem real de ~398 MB. Indisponível. Não exigir F3 para o teste padrão.

Atenção: alguns documentos antigos ainda dizem "nenhuma base aprovada". A auditoria de
2026-11-15 verificou a proveniência oficial; trate F1 como base padrão e sinalize a
inconsistência se ela importar para a decisão.

## 8. INVENTÁRIO DE FERRAMENTAS DENTRO DO WINRE

Isto é observado por listagem dos dois WIMs. Presença de arquivo não prova capacidade;
capacidade não testada é hipótese.

### Ausentes (não assuma)

- `certutil.exe` — o óbvio `certutil -decodehex` NÃO existe.
- `powershell.exe` — sem `[Convert]::FromBase64String`.
- `msado15.dll` / ADODB.Stream — o sink clássico de escrita binária NÃO existe.
- `mscoree.dll` / `clr.dll` — sem .NET.
- `devcon.exe` — ausente nas duas imagens.
- `debug.exe`, `edlin.exe`, `findstr.exe` — ausentes.
- `osk.exe` — teclado virtual legado ausente; o canal é o `TabTip.exe`.
- `fsquirt.exe` e pilha Bluetooth (`bthport.sys`, `rfcomm.sys`, `bluetoothapis.dll`) —
  ausentes. Só existe o INF de classe `c_bluetooth.inf`.

### Presentes

- `cmd.exe` — `copy /b`, `copy con`, `echo >>`, redirecionamento. Só texto.
- `cscript.exe` / `wscript.exe` — Windows Script Host (JScript/VBScript).
- `mshta.exe` — host de script COM completo.
- `regsvr32.exe` + `scrobj.dll` — execução de scriptlet.
- `jscript.dll`, `vbscript.dll`, `scrrun.dll` — engines + FileSystemObject (texto).
- `msxml3.dll` / `msxml6.dll` — MSXML consegue **decodificar** base64
  (`dataType="bin.base64"` gera array de bytes).
- `crypt32.dll` — `CryptStringToBinary` existe, mas não é chamável diretamente por
  `rundll32`.
- `esentutl.exe`, `print.exe`, `expand.exe` — não são decodificadores hex/base64.
- `notepad.exe` — editor de texto.
- `TabTip.exe` — teclado virtual da tela; é o canal de entrada.
- `pnputil.exe` — presente só no 1809; ausente no 10586.
- `drvload.exe` — presente nas duas imagens; carrega driver no WinRE em execução.
- `dism.exe` — presente nas duas; servicing offline (mecânica no host).
- `bcdedit.exe`, `bootrec.exe`, `diskpart.exe` — presentes nas duas.
- `netsh.exe`, `ping.exe`, `ftp.exe`, `tracert.exe` — presentes, mas não há rede
  funcional no dispositivo.

### Bluetooth

O pacote OEM de Bluetooth existe no repositório (`oem24.inf`, `BtwSerialBus.sys`,
`btwdi.dll`, `BtwRSupportService.exe`, firmware `.hcd` do BCM4356), mas o WinRE não tem a
pilha Microsoft de Bluetooth. Usar Bluetooth exigiria carregar essa pilha antes. É uma
investigação aberta, não um canal assumido.

## 9. O PROBLEMA CENTRAL EM ABERTO

O canal de texto funciona. O problema é **reconstruir binário no WinRE**.

- Não há `certutil`, PowerShell, .NET nem ADODB.Stream.
- MSXML decodifica base64 para um array de bytes, mas **não há sink óbvio para gravar
  bytes crus em disco** com as ferramentas presentes.
- Métodos candidatos, todos NÃO provados: MSXML + algum sink binário que exista na
  imagem; entregar um pequeno decoder como texto; ou evitar completamente a transferência
  binária.
- O nvram é texto puro, então não precisa de decoder binário. Reconstruir com `cmd`
  (`copy con`, `echo linha>>arquivo`) ou `notepad`.
- O `.sys` de ~1 MB é binário e esbarra nesse problema.

Não declare que um método de escrita binária funciona antes de testá-lo num WinRE
inicializado. Separe claramente "existe o arquivo" de "a capacidade foi testada".

## 10. PROVADO × HIPÓTESE × PENDENTE

### Provado (mecânica)

- E3 PASS: 5.361 bytes do nvram foram digitados como texto hexadecimal via teclado
  virtual simulado, sem rede, e reconstruídos byte a byte num guest, com SHA-256 igual
  ao da origem. O controle de fluxo por ACK por linha foi necessário: sem ele, teclas
  são perdidas sob TCG.
- O guest do E3 era um Linux mínimo, não WinRE. Portanto está provado o canal e a
  reconstrução no guest; **não** está provada a reconstrução com ferramentas do WinRE.
- O alvo de DriverStore, os hashes dos arquivos e os fatos de versão foram verificados
  por conteúdo.

### Hipótese

- H2: remover o inbox 2017 e instalar o OEM 2015 corrige o erro 10.
- H1: o nvram precisa estar em `System32\drivers\4356r2nvram.txt`; o PnP pode não
  copiá-lo.
- A reprodução sintética do erro 10 no QEMU (dispositivo PCI falso com o ID real +
  driver real) reproduz o sintoma, mas um stub que não responde não pode ser corrigido.
- O stand-in funcional (e1000) com driver errado -> erro 10 -> driver certo -> inicia
  demonstra a correção, mas não é o BCM4356.

### Pendente / bloqueado

- E1: baseline do WinRE no QEMU.
- E2: servicing offline no host (mecânica numa cópia).
- E3b: reconstruir o nvram DENTRO do WinRE com ferramentas da imagem e conferir hash.
  Depende de o WinRE iniciar.
- E4: validação no hardware, conduzida pelo dono.
- E5: reprodução do sintoma com PCI falso + driver real. Precisa de Windows completo
  inicializável; o repositório só tem WinRE.
- E6: demonstração da correção num e1000 stand-in. Mesmo bloqueio.
- Um boot anterior do WinRE de fábrica sob TCG deu BSOD antes do `cmd`, sem diagnóstico
  e sem logs preservados. Pode ser controlador de armazenamento, modelo de CPU ou a
  escolha do WinRE; não está provado que TCG seja impossível.
- Não há Windows completo no repositório. KVM acelera, mas não é requisito absoluto;
  TCG pode inicializar Windows lentamente.
- O espaço é apertado: o WIM modificado pode não caber na partição de ~398 MB. A ordem
  preferida é manter o original em `C:`, modificar uma cópia em `C:`, bootar a cópia por
  uma entrada BCD e só substituir `D:` se couber e se o original estiver salvo.

## 11. CAMINHOS JÁ CONHECIDOS (para não redescobrir errado)

### Correção principal (offline, numa cópia)

1. Copiar o WIM para `C:` e fazer backup.
2. `dism /Mount-Wim` na cópia.
3. `dism /Get-Drivers` para achar o nome publicado (`oemXX.inf`) do pacote de 2017.
4. `dism /Remove-Driver /Driver:oemXX.inf`.
5. `dism /Add-Driver /Driver:...\oem25.inf`.
6. Verificar que `Get-Drivers` mostra 1.558.14.0 e que o nvram/firmware estão no pacote
   staged.
7. `dism /Unmount-Wim /Commit`.

Limite: `dism /Add-Driver` faz staging; não executa necessariamente a lista de cópia do
INF para o dispositivo. A cópia para `System32\drivers` normalmente ocorre na instalação
PnP. Se o nvram não for copiado, o fallback é copiá-lo manualmente da pasta staged para
`System32\drivers\4356r2nvram.txt`.

### Fallback no WinRE em execução

```bat
pnputil /enum-drivers
pnputil /delete-driver oemXX.inf /uninstall /force
pnputil /add-driver C:\OEM\wifi\oem25.inf /install
pnputil /scan-devices
netsh wlan show drivers
```

`pnputil` só existe no 1809. Se não for possível deletar o pacote inbox, usar
`devcon update` (se disponível localmente) ou o equivalente à seleção manual "Let me pick
from a list" e escolher o driver Broadcom de 2015.

### Verificação no hardware

```bat
wmic path Win32_PnPEntity where "DeviceID like '%VEN_14E4&DEV_43EC%'" get Name,DeviceID,Status,ConfigManagerErrorCode
pnputil /enum-drivers
netsh wlan show drivers
netsh wlan show interfaces
```

WMIC pode não existir no WinRE; nesse caso usar `pnputil /enum-devices /problem` ou
`devcon status` se disponível.

### Último recurso

Substituir `System32\drivers\bcmpciedhd63.sys` à mão contorna o tratamento normal de
pacote de driver e pode quebrar registro de serviço ou verificação de assinatura. Não
começar por aí; usar só se DISM e `pnputil` falharem, registrando cada passo.

## 12. RISCOS E LIMITES

- O rádio BCM4356 não é emulado pelo QEMU. QEMU não prova erro 10, associação Wi-Fi nem
  boot do Windows no aparelho.
- O dispositivo não envia arquivos. Não peça ao dono para colar saída como requisito
  obrigatório; no máximo, ele pode ler a tela e digitar.
- A partição real de ~398 MB pode não caber o WIM modificado.
- A cópia do nvram via PnP não é garantida.
- A pilha Bluetooth não existe no WinRE.
- A imagem real do dispositivo não está disponível; F2/F2b são aproximações sintéticas.
- Qualquer sucesso sintético precisa ser rotulado como sintético.
- Não fabrique sucesso, não esconda falhas, não apresente hipótese como resultado.

## 13. PROTOCOLO DE RACIOCÍNIO (OBRIGATÓRIO)

Antes de recomendar qualquer coisa:

1. **Reformule o problema real.** Separe canal × correção do driver × validação de
   hardware × reinstalação do Windows. Diga qual dessas camadas sua resposta ataca.
2. **Liste as incógnitas.** Marque o que é fato observado, o que é hipótese e o que é
   desconhecido. Não trate hipótese como fato.
3. **Gere de 4 a 6 abordagens**, incluindo pelo menos uma não óbvia. Considere, entre
   outras: nvram-only; payload de texto; decoder pequeno entregue como texto; uso de
   MSXML + sink; Bluetooth; imagem sintética; reprodução do sintoma no QEMU; correção
   via `pnputil`/DISM; seleção manual do driver.
4. **Para cada abordagem**, diga: o que ela prova, o que ela NÃO prova, pré-requisitos,
   comandos exatos, formato do payload, método de reconstrução, verificação, riscos,
   esforço e critério de abandono.
5. **Aplique a navalha do menor teste.** Qual é o menor experimento que falsifica a
   hipótese central com o menor payload e o menor risco? Prefira texto a binário.
6. **Escolha uma recomendação.** Se a incerteza for alta, recomende o teste que mais
   reduz incerteza primeiro, não o mais impressionante.
7. **Diga o que faria você mudar de ideia.** Inclua critérios de kill/go.
8. **Respeite todas as restrições.** Se uma opção violar uma restrição, descarte-a
   explicitamente em vez de apresentá-la como solução.
9. **Perguntas essenciais são obrigatórias.** Se faltar informação que bloqueie ou mude
   materialmente a decisão, você **deve** listar as perguntas na seção "Perguntas ao
   dono" (máximo 5, objetivas), explicar como cada resposta muda a decisão e não
   prosseguir como se o dado fosse conhecido. Se não houver bloqueios, escreva
   explicitamente "nenhuma".
10. **Contexto fornecido.** O prompt pode incluir anexos de uma pasta e um histórico de
    rodadas anteriores (entrada/saída). Use-os; não repita perguntas já respondidas no
    histórico, mas reavalie se as respostas resolvem os bloqueios. Se um anexo
    contradisser este briefing, aponte a contradição e baseie-se no fato verificável.

## 14. FORMATO DA RESPOSTA

Responda em português, com estas seções:

1. **TL;DR** — 3 a 6 linhas com a recomendação.
2. **Diagnóstico** — o problema real e a camada atacada.
3. **Opções** — tabela com: abordagem, o que prova, o que não prova, pré-requisitos,
   payload/reconstrução, risco, esforço.
4. **Recomendação** — uma opção principal e uma de fallback, com justificativa.
5. **Passo a passo do primeiro teste** — comandos exatos digitáveis no WinRE, o que
   observar na tela e como decidir PASS/FAIL.
6. **Riscos e critérios de abandono** — o que invalida a abordagem.
7. **Perguntas ao dono** — só se forem bloqueantes; caso contrário, diga "nenhuma".
8. **Confiança** — alta/média/baixa e o motivo.

Seja específico. Não entregue conselho genérico. Não diga "é impossível" sem enumerar
opções e explicar exatamente onde cada uma quebra. Não invente comandos, caminhos,
hashes ou ferramentas.

## 15. ANTI-PADRÕES (NÃO FAÇA)

- Sugerir rede, HTTP, FTP, SMB, USB, SD, Ethernet, teclado físico, clipboard, pasta
  compartilhada ou `hostfwd` como solução para o dispositivo.
- Assumir `certutil`, PowerShell, .NET, ADODB.Stream ou `devcon` no WinRE.
- Tratar resultado de QEMU como prova de hardware.
- Confundir edição offline do WIM com o método de transferência do dispositivo.
- Recomendar substituir o `.sys` à mão como primeira opção.
- Ignorar o erro 10 ou a preferência do Windows pelo driver mais novo.
- Apresentar o nvram como correção garantida sem validar no hardware.
- Pedir ao dono para transferir arquivos ou abrir o aparelho.
- Responder com generalidades, listas de "boas práticas" ou texto motivacional.
- Fabricar sucesso, output, hash ou número de versão.

## 16. SUA TAREFA

Com base em tudo acima, encontre a solução e entregue a decisão no formato da seção 14.

Prioridade explícita do dono: **fazer o dispositivo voltar a ter um canal externo e
recuperar o Windows 17763 sem violar nenhuma restrição**. O caminho deve ser o mais
provável de funcionar no hardware real, não o mais fácil de demonstrar no QEMU.

Se você precisar de dados que só o dono pode fornecer (por exemplo, o conteúdo do nvram,
a saída de um comando na tela, o que já foi tentado, ou o comportamento exato do BSOD),
peça de forma objetiva e continue com o que já é possível decidir.

## 17. ANEXOS (OPCIONAL — O DONO PODE COLAR AQUI)

- Conteúdo do nvram (`4356r2nvram.txt`), se for necessário:
  [colar aqui]
- Saída observada na tela do dispositivo (erro, versão, listagem):
  [colar aqui]
- O que já foi tentado e o resultado:
  [colar aqui]
- Restrições adicionais do dono:
  [colar aqui]

---

## FILE: qemu/README.md

# Ambiente QEMU

## Realidade dos canais (leia primeiro)

O dispositivo **não tem conexão de rede funcional**: a sua única NIC, o Wi-Fi
BCM4356, é o dispositivo que falha com o erro 10. **Transferência por rede/HTTP NÃO é um
canal de dispositivo válido.** O endpoint HTTP do NAT em modo usuário do QEMU (`10.0.2.2`)
funciona só porque o QEMU emula uma NIC e1000 funcional; ele não modela o dispositivo e é uma
linha de base de mecânica apenas.

O **único canal de entrada válido é texto digitado pelo teclado virtual da tela
touch.** A carga entra como texto hex/base64, digitado pelo teclado
(`sendkey` do QEMU), e é reconstruída como binário dentro do convidado. A tela é
o único canal de saída. Edição do WIM no lado do host é prova de mecânica em uma cópia, não
o método de transferência do dispositivo. Veja a seção Realidade dos canais de `GOAL.md` e `docs/01-restricoes.md`.

## Estado

Scripts montados. Não há reivindicação de resultado do erro 10 no dispositivo aqui. O QEMU não emula
o rádio BCM4356; nenhum resultado do QEMU é prova de hardware.

- **Boot do WinRE (`run-winre*.sh`):** o "BSOD antes do `cmd` interativo,
  sem diagnóstico" registrado **não era um BSOD**. `experiments/E1-winre-boot-tcg.md` reproduziu a parada
  em dois modelos de CPU (`qemu64` e `max`) como um erro do **Windows Boot Manager** —
  `File: \EFI\Microsoft\Boot\BCD`, `Status: 0xc000000f`, "The Boot Configuration Data for
  your PC is missing or contains errors" — então o kernel nunca foi alcançado. A causa estava
  no ambiente: `build-iso.sh` colocava o BCD só no lado ISO9660, enquanto o OVMF carrega
  `bootx64.efi` da imagem ESP El Torito e o `bootmgfw.efi` lê o seu BCD desse mesmo
  volume. Corrigido copiando `EFI/Microsoft/Boot/BCD` também para o `efi.img`. Mesmo depois
  dessa correção o ISO para em `0xc000000f` "a required device isn't connected or can't be
  accessed"; `build-disk.sh` (volume único FAT32) é a mídia que realmente alcança o
  Windows boot manager, e é essa que deve ser usada. **Segundo bloqueio independente: tanto
  `run-winre.sh` quanto `run-winre-disk.sh` fixam `-m 2048`, mas o WIM do WinRE expande para
  um disco em RAM de 2,02 GiB (1809) / 2,08 GiB (10586), então 2 GiB não inicializa nenhuma das imagens — use
  `-m 4096` ou mais.** KVM continua sendo um acelerador de velocidade, não um requisito. Uma reprodução
  fiel do erro-10 de Windows ainda precisa de um Windows completo inicializável (o repositório tem só o WinRE).
  Evidências e a matriz completa de células: `experiments/E1-winre-boot-tcg.md`.
- **Reprodução do erro 10 (proposto, não provado):** veja a seção Fidelidade da emulação de dispositivo em `docs/04`.
  Abordagem A: um dispositivo PCI falso com o ID real
  (`x-pci-vendor-id=0x14e4,x-pci-device-id=0x43ec`) mais o driver real reproduz o
  sintoma do erro 10, mas um stub sem resposta não pode depois ser corrigido. Abordagem B: uma
  substituta e1000 funcional mais a seleção de driver demonstra a correção ponta a ponta (fidelidade menor).
  Ambas precisam de um Windows completo inicializável (o repositório tem só o WinRE); KVM recomendado (TCG possível, mas
  lento). Não demonstrado aqui. Nenhum script para isso existe ainda. 

## Scripts

| Caminho | Papel |
|---|---|
| `audit.sh` | Porta antitrapaça no argv do QEMU. Deve passar antes de uma execução. |
| `mon.py` | Envia um comando HMP ao soquete de monitor do QEMU (screendump/status). |
| `build-media.sh` | Remonta as partes versionadas do WIM numa cópia sob `qemu/work/`. |
| `build-iso.sh` | Constrói um ISO UEFI WinRE (El Torito) a partir de uma cópia do WIM. |
| `build-disk.sh` | Constrói um disco de boot UEFI FAT32 a partir de uma cópia do WIM. |
| `run-winre.sh` | Inicializa o ISO WinRE sob OVMF; screendumps periódicos. |
| `run-winre-disk.sh` | Inicializa o disco UEFI WinRE sob OVMF; screendumps periódicos. |
| `wwii/` | O ambiente mínimo de 3 arquivos da branch `wwii` (`audit.sh`, `build-iso.sh`, `run.sh`), preservado por referência. |

`run-winre-disk.sh` é bash
(arrays); o resto é POSIX sh.

## Restrições antitrapaça (de `docs/01-restricoes.md`)

Proibido (imposto pelo `audit.sh`): `-virtfs`; 9p; `-fsdev local`; pastas compartilhadas;
`hostfwd=`; `guestfwd=`; `-serial file:`; `-chardev file`; clipboard/vdagent;
tap/bridge/hubport; SMB embutido. O canal de texto digitado não usa rede nenhuma.

## Regras

- Nunca modifique as partes versionadas dos WIMs. Trabalhe em cópias em `qemu/work/` ou `/tmp`.
- Nunca apresente um resultado do QEMU como prova de hardware. Rotule os resultados sintéticos.
- Não faça commit de WIMs gerados, imagens de disco, ISOs, logs, screendumps ou segredos.
- `audit.sh` deve passar antes de qualquer experimento ser considerado válido.
- Trabalhe e envie apenas na `desafio` (veja a regra de branch de `AGENTS.md`).

## Referências

- `GOAL.md` (Realidade dos canais), `docs/01-restricoes.md`, `AGENTS.md`.

---

## FILE: winre-1809-oficial-intacta/README.md

# WinRE 1809 — fonte oficial intacta

Esta pasta substitui `winre-1809-254MB/`, que foi removida porque o WIM de 254 MB
ali era um arquivo **derivado** sem cadeia de procedência. Esta pasta foi reconstruída
a partir do ESD oficial verificado em 15/11/2026. Ela carrega o ponteiro oficial, os
dados de verificação e o WinRE extraído da mídia oficial.

"Intacta" significa que o **conteúdo** veio da Microsoft sem modificação e foi verificado
contra os digests oficiais antes da extração. O contêiner WIM é produzido
localmente pelo wimlib, então os seus bytes não são um fluxo da Microsoft: não existe
arquivo oficial de 254 MB.

## Procedência verificada (15/11/2026)

| Passo | Comando | Resultado |
|---|---|---|
| Fonte oficial | URL assinada devolvida por `api.uupdump.net get.php` | `Core_en-us.esd`, 522.499.063 bytes |
| SHA-1 | `sha1sum Core_en-us.esd` | `8352af7661fb4808decc0253f6d516b7c2d88605` — confere |
| SHA-256 | `sha256sum Core_en-us.esd` | `b4d37e913b7cd5bf6de0b3c61ba05054e45e81e090d1767f649e825078115887` — confere |
| Extração | `wimlib-imagex export Core_en-us.esd 2 winre-1809-oficial.wim --compress=LZMS --boot` | 266.283.224 bytes |
| WIM SHA-256 | `sha256sum winre-1809-oficial.wim` | `232199c585111bfae71ff00dbdcabe5c75195fc9b431eb4d1711b8a7e471eb6c` |
| Metadados | `wimlib-imagex info ... 1` | build 17763, 17.669 arquivos, 3.560 diretórios, 2.169.435.125 bytes |
| Lista de arquivos | diff de `wimlib-imagex dir` contra o antigo WIM derivado | 21.230 caminhos idênticos |
| Estado de drivers | `diff -r` contra `drivers/estado-dispositivo/` | 11 arquivos idênticos byte a byte |
| nvram | `wimlib-imagex dir ... | grep nvram` | ausente |

Consequência: o antigo WIM derivado era equivalente em conteúdo a esta extração oficial.
A diferença era só o contêiner: o antigo não tinha digest que o vinculasse à Microsoft.

## Artefato oficial

| campo | valor |
|---|---|
| Build | Feature update to Windows 10, version 1809 (17763.9376), amd64 |
| Edição / idioma | `core` (Home) / `en-us` |
| Arquivo de origem | `Core_en-us.esd` |
| Tamanho | 522.499.063 bytes |
| SHA-1 | `8352af7661fb4808decc0253f6d516b7c2d88605` |
| SHA-256 | `b4d37e913b7cd5bf6de0b3c61ba05054e45e81e090d1767f649e825078115887` |
| WinRE | índice 2 do ESD — `Microsoft Windows Recovery Environment (x64)`, Edition ID `WindowsPE`, build 17763 |

## Link direto

`winre10-1809-254mb.url` aponta para a página do build:

```
https://uupdump.net/selectlang.php?id=814acacb-6203-4083-b0f0-21746910e3a9
```

Endpoint resolvedor que devolve as URLs do CDN da Microsoft exatamente para este build:

```
https://api.uupdump.net/get.php?id=814acacb-6203-4083-b0f0-21746910e3a9&lang=en-us&edition=core&ring=retail
```

As URLs por arquivo dentro da resposta da API são **links assinados da Microsoft que expiram**.
Resolva-os de novo a cada download. Ferramentas históricas:

```sh
git show f76aab8:scripts/uup_links.sh    # resolver -> .tsv (url, name, size, sha1)
git show f76aab8:scripts/baixar_uup.sh   # download com aria2c do arquivo selecionado
```

A branch `backup` guarda um único arquivo, `wwii-2026-11-09_2325.zip`. Ele foi extraído
e os seus membros `.gz` (`winre-caminhos.txt.gz`, `setupmedia-caminhos.txt.gz`)
descomprimidos: são só listas de caminhos e não contêm URL de download. O link acima vem
do resolvedor, não do backup.

## Arquivos aqui

| Arquivo | Bytes | SHA-256 |
|---|---:|---|
| `winre-1809-oficial.wim.part-00` | 99.614.720 | `bb45f28686202ff5cebbc361b9e9afacde2d890cf88758929a5b59a172b7b46b` |
| `winre-1809-oficial.wim.part-01` | 99.614.720 | `d230b55c81b41f176c330418fa9c9a601ba5de327f94833def3d94dec0b4b1a9` |
| `winre-1809-oficial.wim.part-02` | 67.053.784 | `b8b6aacfc5b6582ab76f20faaf5a290fb89850b7f52a0dd1944215ef1347bad0` |

`SHA256SUMS` cobre as partes. `SHA256SUMS.reassembled` cobre o
`winre-1809-oficial.wim` unido, para que quem juntar as partes possa provar o resultado com
`sha256sum -c SHA256SUMS.reassembled`. `SHA1SUMS` cobre o ESD oficial. Dividido
porque o GitHub rejeita arquivos acima de 100 MiB; cada parte fica abaixo de 95 MiB.

## Remontar e verificar

```sh
cat winre-1809-oficial.wim.part-* > winre-1809-oficial.wim
sha256sum -c SHA256SUMS
sha256sum -c SHA256SUMS.reassembled   # o arquivo unido
wimlib-imagex info winre-1809-oficial.wim 1
```

Um comando faz tudo e imprime uma única linha — use isto em vez de ler
hashes na conversa:

```sh
scripts/verify-images.sh                 # as duas imagens versionadas
scripts/verify-images.sh winre-1809-oficial-intacta
KEEP=1 scripts/verify-images.sh          # mantém o WIM unido e imprime o caminho dele
```

Ele confere cada parte, junta-as, compara o resultado com `SHA256SUMS.reassembled` e
com o digest registrado, e (quando o wimlib está instalado) o build e as contagens de
arquivos e diretórios. Saída 0 significa verificado. `scripts/verify-repo.sh` faz o mesmo dentro da
verificação mais ampla do repositório, e também confere as pastas do DriverStore, a ausência da nvram e o
alvo do `.url`.

Para baixar a origem de novo e repetir a cadeia: obtenha a URL assinada do
endpoint resolvedor, confira os dois digests acima, e então execute o comando de extração.

`official-manifest.txt` é a listagem oficial completa dos 33 arquivos deste build
(nome, tamanho, SHA-1), transcrita de `docs/imagem/manifest.txt` (histórico do git, removido
em `92bf46d`).

A revisão de cada documento e item de evidência que usou a antiga imagem derivada está em
`docs/06-auditoria-imagem-1809.md`.

## Não commitado de propósito

O ESD (522 MB) não é commitado: o `.gitignore` exclui `*.esd` e o `AGENTS.md`
proíbe commitar imagens. A extração do WinRE é commitada por pedido explícito do usuário,
dividida em partes, com os digests da fonte oficial registrados acima.

---

