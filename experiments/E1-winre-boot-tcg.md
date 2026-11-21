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
- `experiments/E3-typed-text-channel.md` (a prova de canal de que a E3b depende deste)
