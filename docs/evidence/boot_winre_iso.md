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
| gate | `winre-wwii.iso` (LZMS, drivers + autorun com persistência) | `-cpu max -smp 4 -m 4096` | em andamento (`.work/logs/e4-gate.log`) |

Conclusão que muda o plano: **a tela azul não é da injeção**. O `pristine.raw.wim` (WIM original,
sem driver nenhum e sem autorun) e o `Winre.nodrv.wim` (drivers, autorun sem `drvload`) deram a
MESMA tela laranja, e o `boot.wim` em LZMS não deu. O que quebra é o `boot.wim` **sem compressão**
(1,03 GB) — maior do que o RAMDisk descrito no `boot.sdi` do WinRE, então o PE sobe e bugcheck.
Efeito colateral útil: com cache de página quente, o boot LZMS ainda é lento (CPU-bound na
descompressão), mas é o caminho correto; `wimlib-imagex optimize --compress=None` está
**proibido** no engolidor de teste.

## Estado do aceite (o que falta)

O gate é "PE inicia o script sozinho e grava log em disco; log lido no host". O run de 20:26–20:51 (1500 s) e o de até 20:56 não podiam produzir log por causa da descoberta 7. Rebuild com persistência incremental no autorun (item 2 abaixo) + disco preso + `--vga cirrus`: run em andamento desde 20:57 (UTC-3), timeout 3600 s, poll 60 s, `.work/logs/e4-boot2.log`.

Foi feito enquanto o run anda, para o gate virar verificável em qualquer cenário:

1. **Persistência incremental no autorun** (`scripts/autorun-wwii.cmd`): cada bloco (`wpeinit`, `drvload` dos 6 drivers, `diag`, `pnputil`, `netsh wlan`, `ipconfig`, fim) chama `:persist`, que copia `X:\wwii.log` para `C:`..`H:`. Um PE que bugue no meio deixa rastro parcial em vez de nada. Teste offline: `python3 scripts/tests/unit/autorun_offline.py` → `PASS ini / PASS cmd / PASS autorun_offline`.
2. **Reinjeção e rebuild**: `sh scripts/injetar_autorun.sh --imagem .work/wim/Winre.lote.wim` (INI reextraído confere `LaunchApps`) + `sh scripts/montar_iso_winre.sh --imagem ... --saida ...` → novo sha256 acima.

Pendências para o próximo turno, na ordem:

1. Ler o resultado de `.work/logs/e4-boot2.log`. Se aparecer `wwii.log LIDO DO DISCO`, anexar o conteúdo em `docs/evidence/` e fechar E4 com a evidência; se aparecer só um log parcial, registrar qual bloco parou (isso já é evidência de qual serviço do PE falha).
2. **Prova visual**: trocar `-display none` por `-display vnc=127.0.0.1:<porta>` no
   `boot-winre.sh` e chamar `python3 scripts/vncshot.py --porta <5900+N> --saida
   .work/vm/tela-$T.png` a cada poll (o `screendump` continua como registro barato,
   mas não é mais a prova). Feito no próximo run, porque mexer no arquivo com o
   `sh` executando ele pode corromper o run em andamento.
3. Se o log parcial parar em `netsh wlan` / `WlanSvc`: o suspeito continua sendo o `wcmsvc.dll` ausente (p0402412842), não o transporte — abrir problema próprio com a linha exata do log.
4. Se não aparecer log nenhum com o disco preso: trocar o `-hdb` por `-hda` (o PE do 1809 às vezes não enumera slave IDE) e usar a tela VNC para ver onde o bootmgr parou.
5. Reduzir o custo do ciclo: o gargalo é LZMS + TCG. Um `boot.wim` menor (extrair só o necessário) ou `--cpus 4` encurtam o teste do gate.
6. Transporte: com iPXE confirmado no firmware deste QEMU (descoberta 10), montar um teste PXE (dnsmasq proxy + TFTP/HTTP) para a alternativa A5 de p0402452582.
