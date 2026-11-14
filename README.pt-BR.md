# Desafio de recuperação do Mi Pad 2

Este repositório monta um desafio reproduzível para um problema específico:

- Xiaomi Mi Pad 2, x64, Windows 10 build 17763.
- O `C:` foi formatado rapidamente.
- O único ambiente Windows restante é a partição de recuperação no `D:`.
- Não há USB, SD, Ethernet nem teclado físico.
- Os canais disponíveis são tela, prompt do WinRE, Wi-Fi, Bluetooth e toque.
- O Wi-Fi apresenta erro 10 com o pacote PCIe de 2017.

O repositório não contém uma imagem completa do Windows. O único WIM versionado é a imagem de recovery do firmware de fábrica. O objetivo é montar evidências, o estado do driver do alvo, o harness QEMU e os protocolos de experimento para que os agentes provem a parte de software antes de qualquer conclusão sobre o hardware.

## Estado atual

- A entrega atual é a estrutura do repositório.
- O WIM de fábrica é a única imagem versionada. Ele não tem `bcmwdidhdpcie.inf` e não reproduz o erro 10 sozinho.
- O teste de trabalho injeta o pacote PCIe de 2017 em uma cópia do WIM de fábrica. Esse é um estado sintético, rotulado F2.
- O harness QEMU está especificado, mas não foi executado nesta montagem.
- O QEMU não emula o rádio BCM4356. Ele prova a mecânica de driver e arquivos, não o erro 10 real.
- A imagem real de aproximadamente 398 MB do `D:` não está disponível.

## Fatos principais

- O estado quebrado é o pacote PCIe de 2017 `bcmwdidhdpcie.inf`, versão `1.558.53.25`.
- O pacote bom é o driver OEM de 2015 `oem25.inf`, versão `1.558.14.0`.
- O Windows prefere o driver mais novo. Só adicionar o pacote antigo não resolve; é preciso remover o pacote de 2017 ou forçar o antigo.
- O estado do alvo não tem o nvram da placa.
- O pacote OEM contém o nvram. O nvram é um payload separado, não faz parte do estado do alvo.
- O WIM de fábrica tem bcmdhd, bcmdhd64, bcmfn2 e bcmfn, mas não tem `bcmwdidhdpcie.inf`.
- O aparelho não consegue enviar arquivos. O desafio não pode assumir clipboard, pasta compartilhada, USB ou qualquer outro canal de transferência.

## Mapa do repositório

| Caminho | Função |
|---|---|
| `GOAL.md` | Missão, restrições, marcos e critérios de aceite. |
| `ANOTACOES-IMPORTANTES.md` | Fatos canônicos e evidências para agentes. |
| `AGENTS.md` | Regras de operação dos agentes. |
| `drivers/` | Estado do DriverStore do alvo, pacotes OEM e hipótese do nvram. |
| `winre-fabrica-10586-424MB/` | WIM do firmware de fábrica em partes versionadas. |
| `docs/` | Explicações técnicas e runbooks. |
| `qemu/` | Harness QEMU e scripts. |
| `experiments/` | Protocolos reproduzíveis. |
| `scripts/` | Validação no host e fichas de comando do WinRE. |

## Ordem de leitura

1. `GOAL.md`
2. `ANOTACOES-IMPORTANTES.pt-BR.md`
3. `AGENTS.md`
4. `docs/00-visao-geral.md`
5. `docs/01-restricoes.md`
6. `docs/02-estado-do-dispositivo.md`
7. `docs/03-driver-wifi-erro-10.md`
8. `docs/04-fidelidade-mimetizacao.md`
9. `docs/05-offline-servicing.md`
10. `experiments/E0.1-firmware-baseline.md`
11. `experiments/README.md`

## Escopo e segurança

- Não conectar USB, SD, Ethernet nem teclado físico.
- Não assumir nenhum caminho de transferência de arquivos do aparelho.
- Não tratar resultado do QEMU como prova de hardware.
- Não alterar as partes WIM versionadas. Trabalhar em cópias em `qemu/work/` ou `/tmp`.
- Não commitar WIM gerado, disco, ISO, log ou segredo.
- Não commitar sem pedido explícito.

## Próximo passo

Revisar `experiments/E0.1-firmware-baseline.md` para o inventário do firmware. Depois de instalar as ferramentas, validar com `scripts/verify-repo.sh`. Os experimentos QEMU estão em `experiments/` e devem ser executados separadamente.