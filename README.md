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

Ponto de entrada em português: `README.pt-BR.md`.

## Segurança e escopo

- Não conecte o dispositivo a USB, SD, Ethernet ou teclado físico.
- Não pressuponha nenhum caminho de transferência de arquivos a partir do dispositivo.
- Não descreva um resultado do QEMU como prova de hardware.
- Não modifique as partes versionadas dos WIMs. Trabalhe em cópias em `qemu/work/` ou `/tmp`.
- Não faça commit de WIMs gerados, imagens de disco, ISOs, logs ou segredos.
- Faça commit e push imediatamente na `desafio` (autorização permanente, 15/11/2026); o sandbox é temporário. Use `scripts/salvar.sh`. Um commit local não é entrega.

## Próximo passo

Revise `experiments/E0.1-firmware-baseline.md` para o inventário do firmware. Depois que as ferramentas estiverem instaladas, valide o repositório com `scripts/verify-repo.sh`. Os experimentos do QEMU estão definidos em `experiments/` e devem ser executados separadamente.
