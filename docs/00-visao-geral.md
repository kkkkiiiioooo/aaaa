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
