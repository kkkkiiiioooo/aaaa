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

## 16/11/2026 — E2 servicing offline + causa-raiz da mídia PCAT (qoder)

- Mecânica do E2 PASS (lado do host, em cópias): ambas as cargas construídas em ~4 s e relidas
  byte a byte por SHA-256; `wimlib-imagex verify` OK. `e2-servicing.sh`.
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
- Concatenação do alfabeto no host (`scripts/alphabet-decode.py --selftest`) PASS. O método no convidado (`fsutil` NUL + FSO + `copy /b`) é uma hipótese até o E1 inicializar; sondagem: `scripts/winre-fso-probe.js`.
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
  boot option bem-sucedido cairia num filesystem sem `boot.wim`; (c) E2/E3b continuam dependendo
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
