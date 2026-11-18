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
