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
- [x] E2 - mecânica de servicing offline (lado do host, em cópias do WIM WinRE 1809 oficial). Resultado:
  `host-only / não é prova` — re-rotulado em 17/11/2026 para seguir a regra de evidência adicionada ao `AGENTS.md`; o
  servicing em si rodou de verdade e é reproduzível, mas nenhum WinRE inicializado e nenhum dispositivo foi exercitado.
  As duas cargas (H1 só nvram, H2 troca de pacote) constroem em segundos, relê-se byte-idêntico por SHA-256 e passam
  `wimlib-imagex verify`. Novos fatos medidos: os binários `.sys` embutem
  \`SystemRoot\system32\drivers\%04Xr%dnvram.txt` (=> `4356r2nvram.txt`) e o template de firmware correspondente; na
  imagem de fábrica nem `bcmpciedhd63.sys` nem o firmware renomeado ficam implantados em `System32\drivers`, então a
  carga mínima de runtime é provavelmente dois arquivos (firmware 0,64 MB + nvram 5,4 KB), não um; `devcon.exe` está
  ausente do WinRE enquanto `pnputil.exe`, `dism.exe`, `drvload.exe` e `cmd.exe` estão presentes. Os hashes de contêiner
  não se reproduzem entre builds (o wimlib carimba Last Modification Time). Owner: qoder.
  (experiments/E2-offline-servicing.md, docs/03)
- [x] E3 - prova do canal de texto digitado: nvram (5361 B, TEXTO) digitada por teclado touch simulado num convidado
  sem rede, reconstruída byte a byte, hash conferido (PASS). O controle de fluxo com ACK corrigiu as
  quedas de teclas. Owner: aaaa2. (experiments/E3-typed-text-channel.md)

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
- E3 concluído; veja Feito.

## Próximo — viável agora, sem KVM

- [ ] E3b — reconstruir a nvram DENTRO do WinRE usando só ferramentas da imagem (`cmd` `copy con` /
  `echo >>` / `notepad`), depois hash. Precisa que o WinRE inicialize (ver diagnóstico de BSOD abaixo). A nvram
  é texto, então nenhum decodificador binário é necessário.
- [ ] Teste de carga mínima (ideia do dono): determinar se só a nvram (H1) basta, evitando qualquer
  transferência binária. O E2 restringiu: a observação decisiva é uma única listagem de diretório no dispositivo
  vivo, `dir C:\Windows\System32\drivers\4356*` — se `4356r2rtecdc.bin` está lá e
  `4356r2nvram.txt` não está, nvram-only é o patch inteiro; se nenhum dos dois está, a carga é também o
  firmware (binário de 0,64 MB, que precisa do sumidouro binário do E7) e possivelmente o `.sys`. Bloqueado em
  conseguir um console (E1b).
- [~] Método de reconstrução binária (PROBLEMA ABERTO) — Owner: stackai (E7, inventário+algoritmo no host; teste no WinRE
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
