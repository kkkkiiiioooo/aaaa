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
| H-B6 | Hex é mais seguro que base64 (alfabeto sem caracteres especiais do `cmd`) | Comparar taxa de erro/tempo de digitação | Base64 não tem erro e é mais curto |
| H-B7 | Alfabeto reduzido (só letras minúsculas/dígitos) evita autocorreção e maiúsculas do teclado | Digitar alfabeto completo e comparar | Teclado altera algo mesmo assim |
| H-B8 | Dá para verificar integridade sem `certutil` (hash em JScript ou `fc /b`/`comp`) | Rodar hash JS no WinRE e comparar com host | Sem mecanismo de checagem possível |
| H-B9 | `copy con arquivo` ou `echo ... > arquivo` grava bytes ASCII fielmente (inclui CR/LF final) | Gravar e comparar bytes | Acrescenta ou altera bytes |
| H-B10 | O Wi-Fi/Bluetooth/OBEX podem ser outro canal de entrada (fora do texto) | Verificar no aparelho; revisar restrições | Restrições proíbem ou não há pilha |
| H-B11 | A taxa de digitação manual (tempo humano) é viável: nvram 5,4 KB entra em tempo razoável | Cronometrar E3 simulado e estimar | Tempo inviável (horas) |
| H-B12 | Compressão antes de digitar (RLE/dicionário) reduz a digitação de forma útil | Medir tamanho comprimido da nvram/firmware | Ganho desprezível |
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
| H-D11 | Editar o WIM do WinRE (servicing offline) embute os arquivos e persiste após reiniciar | E2 já provou a mecânica no host; falta o aparelho | WinRE no aparelho é recriado/restaurado |
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
| H-G6 | Dividir por capacidade (KVM vs TCG) acelera: E5/E6 para agente com KVM, E3/E7 para os demais | Atribuir e medir | Gargalo é outro |
| H-G7 | Documentar cada experimento com o modelo de `experiments/templates/experimento.md` evita refazer testes | Auditoria dos logs | Refaz mesmo assim |

## Tabela de tarefas

Atualize o Status ao trabalhar (um agente por vez, sem claims). Prioridade sugerida: H-B3, H-B1, H-B2 e H-B8 desbloqueiam o canal; H-A2/H-A3/H-A9 testam a causa; H-C* só desbloqueiam o E1b.

| ID | Tarefa | Owner | Status |
|---|---|---|---|
| H-B1 | Digitar no `cmd` do WinRE pelo TabTip | — | [ ] |
| H-B2 | Limite de linha do `cmd` no WinRE | — | [ ] |
| H-B3 | `cscript`/JScript/FSO no WinRE | — | [?] bloqueada no E1b |
| H-B8 | Hash sem `certutil` | — | [ ] |
| H-B6 | Hex vs base64: documentar o método exato e medir (docs/08-data-transfer.md) | claude | [~] doc + teste de host feitos; falta WinRE (bloqueado no E1b) |
| H-B11 | Tempo de digitação da nvram | — | [ ] |
| H-B12 | Compressão antes de digitar | claude | [~] medido no host (docs/09-compressao-antes-de-digitar.md); falta `where expand` no WinRE |
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
