# Evidência E4 — boot do WinRE em QEMU (ISO gerada a partir do próprio Winre.wim)

**Agente:** qoder · **quando:** 2026-11-04 21:00 (UTC-3) · **etapa:** E4 (ativa)

## O que está provado nesta rodada

| # | alegação | como foi medido |
|---|---|---|
| 1 | a ISO de boot do WinRE pode ser montada **sem baixar UUP** | `scripts/montar_iso_winre.sh` extrai `\Windows\Boot\DVD\{PCAT,EFI}` do próprio `Winre.lote.wim` e grava `.work/iso/winre-wwii.iso`. Build atual: 297 893 888 bytes, sha256 `11540227a70deb4dae12e47a254b2a7ca52308b916f00d1ccee29e872b66340e` (build anterior, sem a persistência incremental do autorun: 294 670 336 bytes, sha256 `179da78b46ed8be16fe350e96231249aa6d2a5c3ccd0cb71b1b71575fddb3b18`) |
| 2 | os caminhos que a ISO precisa satisfazer não são chute | `montar_iso_winre.sh --bcd` lê os hives BCD dentro do WIM: ramdisk `\boot\boot.sdi`, osdevice `\sources\boot.wim`, loader `\windows\system32\boot\winload.exe` (PCAT) / `winload.efi` (EFI) |
| 3 | `boot.wim` da ISO é o WIM modificado, byte a byte | `cmp` entre `.work/wim/Winre.lote.wim` (drivers E2 + autorun E3) e `stage/sources/boot.wim` — idênticos |
| 4 | SeaBIOS carrega o `etfsboot.com` da ISO | screenshot 20:19: com `-boot-load-size 8` o texto "Booting from DVD/CD..." aparece e o etfsboot executa (com `4` ele morre em `Code: 5`) |
| 5 | o bootmgr de PCAT foi carregado e começou a rodar | screenshot 20:26 (ISO de prova): depois do patch `BOOTMGR;1` a tela sai do texto do etfsboot e passa a mostrar conteúdo de vídeo do bootmgr (dump de `0xb8000` em 20:43 mostra plano gráfico, não mais texto do SeaBIOS); `rchar` do QEMU subiu a 293 937 637 bytes ≈ o `boot.wim` inteiro (288 MB) lido do CD |
| 6 | a raiz da ISO realmente expõe `BOOTMGR;1` | leitura do diretório raiz ISO9660 do build atual (LBA 20): `BOOT`, `BOOT.CAT;1`, `BOOTMGR;1` (ext 2319, 408 074 bytes), `EFI`, `SOURCES` — o patch do identificador está aplicado no arquivo final, não só no estágio |

## Descobertas que destravam a etapa (cada uma custou uma tentativa)

1. **`-boot-load-size 8`, não 4.** O `etfsboot.com` do 1809 tem 4096 bytes. Com 4 (2048 B) o SeaBIOS lê metade e aborta: `CDBOOT: Cannot boot from CD - Code: 5`.
2. **O `bootmgr` de BIOS existe no WinRE** — em `/Windows/Boot/PCAT/bootmgr` (408 074 bytes). Ele precisa ir para a **raiz** da ISO; sem ele o etfsboot diz `CDBOOT: Couldn't find BOOTMGR`.
3. **O nome ISO9660 é o problema, não o arquivo.** O etfsboot procura o identificador exato `BOOTMGR;1`; o xorriso grava `BOOTMGR.;1` (e `BOOTMGR.` com `-N`). `montar_iso_winre.sh` agora corrige o registro do diretório raiz depois de gravar a ISO (campo de identificador é de tamanho variável, sobra padding no mesmo registro — nenhum byte de dado se move).
4. **`bootfix.bin` NÃO vai para a ISO.** É ele que imprime "Press any key to boot from CD" — com ele dentro, o gate de zero-tecla quebra.
5. **UEFI/OVMF não colabora com QEMU 6.2 + firmware Debian.** Medido três vezes: a opção de boot gerada a partir do `fw_cfg` do QEMU traz o caminho `PciRoot(0x0)/Pci(0x1,0x1)/Ata(...,0x0)` **sem** `Partition()`, então:
   - ISO El Torito (`efisys_noprompt.bin`): `BdsDxe: failed to start Boot0001 ... : No mapping`
   - disco MBR com ESP FAT32 (`/EFI/BOOT/BOOTX64.EFI` = `bootmgr.efi` do WIM): `failed to load Boot0002 ... : Not Found`
   - disco "super-floppy" FAT32 sem tabela de partição: `Not Found` também
   `scripts/montar_disco_winre.sh` ficou pronto e documentado; enquanto o `fw_cfg` gerar essa opção, o caminho confiável é **BIOS + etfsboot + `BOOTMGR;1`**.
6. **`efisys.bin` pede tecla; `efisys_noprompt.bin` não.** Os dois estão dentro do WIM, em `/Windows/Boot/DVD/EFI/en-US/`.
7. **A ausência do log era do engolidor de teste, não do PE.** `scripts/boot-winre.sh` só prendia o disco de dados quando `DISK_BOOT` estava definido (`MEDIA="-boot order=d -cdrom $ISO"`, sem `-hdb`). Ou seja: nos dois primeiros runs o convidado nunca viu o disco onde o autorun grava `wwii.log`, e o `mtype t:/wwii.log` do host lia um disco que não estava na VM. Corrigido: o disco de dados vai **sempre** como `-hdb`. Isso invalida a conclusão provisória de que "o PE não chegou a rodar o autorun" — ela nunca foi testável.
8. **`-vga std` + `-display none` não dá prova visual.** O `screendump` do QEMU 6.2 devolve 720x400 ilegível depois que o convidado sai do modo texto, e com `-vga cirrus` devolve faixas. Medido também: `pmemsave 0xb8000 4000` já vem preenchido por framebuffer (o bootmgr saiu do texto), então o dump de vídeo só vale na fase do SeaBIOS.
9. **Prova visual resolvida: cliente RFB próprio (`scripts/vncshot.py`).** Com `-display vnc=127.0.0.1:N` (sem X, sem cliente instalado) o script fala RFB 3.8, segurança None, e grava PNG. Medido neste build: o `ServerInit` tem 24 bytes (w2 h2 pixfmt16 nameLen4 — o nameLen está **dentro** do cabeçalho), bpp=32, e o `FramebufferUpdate` chega com **byte de tipo 0**, não 2 — quem filtrar por 2 descarta o frame inteiro. Validação: VM de teste sem mídia de boot devolveu a tela legível com `Booting from DVD/CD...`, `Boot failed: Could not read from CDROM (code 0003)` e `No bootable device.` (18 526 pixels não-pretos em 720x400).
10. **iPXE existe neste QEMU** (`iPXE 1.21.1+git-20220113.fbbdc3926-0ubuntu1`, `-device e1000` + `-netdev user`): a tela do teste mostra DHCP ok (`10.0.2.15/255.255.255.0 gw 10.0.2.2`). Isso destrava testar a alternativa de transporte **PXE** (A5 / p0402452582) aqui dentro, sem hardware.

## Ambiente

`doctor.sh`: MEM=7940 MB, DISK=20370 MB, KVM=nao → TCG puro, `-smp 3 -m 4096`. QEMU 6.2.0, SeaBIOS 1.15.0-1.
Leitura do log do convidado pelo host sem `mount`: o kernel deste sandbox não tem o módulo `vfat`, então `scripts/boot-winre.sh` usa mtools com `partition=1` no `MTOOLSRC` (`mdir/mtype/mcopy t:/`).

## Matriz de configuração do ambiente (`scripts/chovar-qemu.sh`, 2026-11-04 21:56–22:02 UTC-3)

Cada linha é um boot real medido; veredito em `.work/chovar/resultados.tsv`.

| rótulo | ISO | QEMU | veredito |
|---|---|---|---|
| base | `winre-wwii-raw.iso` (boot.wim **sem compressão**, 1,03 GB) | `-cpu qemu64 -smp 3 -m 4096`, sem NIC | **BSOD em 36 s** (tela laranja, `SYSTEM_THREAD_EXCEPTION_NOT_HANDLED`) |
| lzms | `winre-wwii.iso` (boot.wim **LZMS**, 288 MB) | idem | **sem BSOD** — 232 s em modo texto, ainda carregando |
| gate | `winre-wwii.iso` (LZMS, drivers + autorun com persistência) | `-cpu max -smp 4 -m 4096` | 1800 s sem BSOD e sem log (`.work/logs/e4-gate.log`) |
| lzx2 | `winre-wwii-lzx.iso` (boot.wim **LZX**, 367 MB) | `-smp 4 -m 4096` | 1159 s sem BSOD, ainda em modo texto |
| xp | `winre-wwii-xp.iso` (boot.wim **XPRESS**, 429 MB) | `-smp 4 -m 4096` + NIC + VNC | **BSOD em 425 s**, mesmo stop code (`e4-bsod-xpress-425s.png`) |

O que está medido e o que **não** está: a tela azul aparece com o WIM **sem compressão** (36 s) e
com **XPRESS** (425 s), e não aparece com **LZMS** (232 s / 1800 s) nem com **LZX** (1159 s). A
correlação que eu tinha escrito antes — "o que quebra é o boot.wim sem compressão" — está
**refutada pelo XPRESS**, que é comprimido e quebrou do mesmo jeito. As durações de observação são
diferentes entre as linhas, então "sem BSOD" aqui não significa "bootou": nenhuma dessas duas
chegou ao autorun. O mecanismo do BSOD continua **não medido**.

O que continua de pé: **a tela azul não é da injeção**. `pristine.raw.wim` (WIM original, sem
driver nenhum e sem autorun) e `Winre.nodrv.wim` (drivers, autorun sem `drvload`) deram a MESMA
tela laranja. Hipótese que já caiu: o `boot.sdi` do PCAT tem
3 170 304 bytes e é contêiner **SDI** (registros PART e WIM internos), não VHD — o campo
"Current Size" que cheguei a ler nele (956 MB) é leitura fora de contexto, não medida. Ou seja,
não existe ali um "tamanho de RAMDisk" declarado para estourar.
`wimlib-imagex optimize --compress=None` continua **proibido** no engolidor de teste (produz o
caso que BSOD em 36 s).

## Veredito da E4 (decisão D6 do lead, 2026-11-04 22:56 UTC-3)

D6 mandava repetir **uma** vez o boot com `-hda` (e não `-hdb`) e trazer a prova por
`-serial file:` — canal que não depende do volume FAT ser enumerado pelo PE. Foi feito
exatamente uma vez: `scripts/autorun-wwii.cmd` agora faz `type %LOG% > COM1` em cada bloco,
`scripts/boot-winre.sh` usa `DISKAT=hda` por padrão e grampeia a marca `autorun-wwii` em
`.work/vm/serial.log`, e a ISO reconstruída foi `winre-wwii.iso` sha256 `72081aba…` (LZMS,
299 253 760 bytes).

Resultado medido (`.work/logs/e4-d6.log`, 01:14:44–01:45:04 UTC, 1800 s, `-smp 4 -m 4096`):

- `serial.log` = **0 bytes** no fim dos 1800 s; a marca `autorun-wwii` nunca apareceu.
- Disco de dados lido pelo host no fim do run: só `host_marker.txt` (3 bytes), sem `wwii.log`.
- Ou seja: o PE **não chegou** ao `winpeshl.ini → autorun-wwii.cmd` dentro do tempo, por nenhum
  dos dois canais independentes.

Consequência, conforme o próprio D6: **E4 = INCONCLUSIVA, não CONFIRMADA**. A E3 fica valendo só
como evidência **offline** (injeção verificada no WIM: `winpeshl.ini` com `[LaunchApps]` e o
`.cmd` presente, teste `scripts/tests/unit/autorun_offline.py` → PASS). Nada foi afirmado sobre
"o PE roda o script sozinho em runtime". `p0423333970` foi escalado ao lead com a pergunta
objetiva. E4 foi **liberada** (`etapa.sh liberar`) para outro agente tentar outro transporte.

Medida nova útil que o run D6 deixou: foi a primeira vez que `ide0-hd0` **foi lido** pelo
convidado (35 840 bytes / 70 operações) — antes o disco nem era tocado. Não é prova de autorun
(0 escritas), mas mata a hipótese "o PE não enumera disco IDE como master".

## O que já está pronto para o próximo turno de E4

Ferramental (tudo commitado, nada precisa ser reescrito):

- `scripts/boot-winre.sh` — boot por CD com disco de dados **sempre** preso (`DISKAT=hda` por
  causa do D6), `--timeout/--poll/--mem/--cpus/--vga`, canal de prova duplo: leitura de
  `t:/wwii.log` via mtools **e** grampeio da marca `autorun-wwii` em `serial.log`.
  `DISP=vnc=127.0.0.1:N VNC=<porta>` liga a prova visual real; `--iso` aceita qualquer ISO.
- `scripts/vncshot.py` — cliente RFB 3.8 sem dependências (ver descoberta 9).
- `scripts/chovar-qemu.sh` — matriz de configurações com classificador de tela
  (`bsod|logo|texto|vazio`) e TSV em `.work/chovar/resultados.tsv`.
- `scripts/autorun-wwii.cmd` — log em `X:\wwii.log` + `type %LOG% > COM1` + cópia para
  `C:`..`H:` a cada bloco; teste offline `python3 scripts/tests/unit/autorun_offline.py` → PASS.
- ISOs já montadas e com hash conhecido em `.work/iso/` (LZMS `72081aba…` é a de produção;
  LZX/XPRESS/raw só existem como controles da matriz).

Pendências, na ordem de valor:

1. **E4 não tem runtime gate.** Aceitar só evidência offline para E3 e perguntar ao lead
   (dossiê `casos/p0423333970.md` na branch `relatorio`) se o aceite pode vir de outro
   transporte — USB/PXE (iPXE confirmado, descoberta 10) ou hardware real — em vez de TCG+CD.
2. Se o lead mand insistir em TCG: o ciclo é caro porque o bootmgr descomprime o WIM inteiro em
   CPU. Alavancas não testadas: `-cpu max` (o engolidor ainda fixa `qemu64`, linha 107),
   `boot.wim` menor (extrair só o necessário), e medir se LZMS **progredia** aos 1800 s — o run
   D6 não gravou `info blockstats` nem as telas em disco, então isso está perdido; o próximo run
   precisa gravar os dois (`.work/vm/` é sobrescrito a cada run).
3. Se aparecer log parcial parando em `netsh wlan` / `WlanSvc`: suspeito é `wcmsvc.dll` ausente
   (p0402412842), não o transporte — abrir problema próprio com a linha exata do log.
4. Transporte PXE (alternativa A5 de p0402452582): dnsmasq proxy + TFTP/HTTP dentro do sandbox.
