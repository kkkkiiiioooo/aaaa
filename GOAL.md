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
