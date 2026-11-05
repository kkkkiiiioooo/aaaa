# PROMPT FINAL — Recuperação do Windows 10 1809 sem conexões físicas

**Para quem lê:** um modelo mais capaz que o executor. **Não execute comandos. Só pense.** Este arquivo tem tudo que o executor (branch `wwii`) mediu até 2026-11-05. Leia, ache o que o executor não viu e entregue a melhor decisão e o melhor runbook. Fatos medidos estão marcados **[MEDIDO]** com a fonte. O que é palpite está marcado **[HIPÓTESE]**.
Base das fontes: https://github.com/kkkkiiiioooo/aaaa (branch `wwii`, caminhos `docs/evidence/*`).

---

## 1. O problema (enunciado original)

Restaurar o Windows numa partição **C: formatada**, **sem cabos, pendrives ou adaptadores físicos**.

- Windows 10 **1809** (build 17763). WinRE funcional, com `Winre.wim` (no enunciado: "WRE.wim") na partição de recuperação.
- Problema 1: WinRE sem driver Wi-Fi completo (**erro 10** no adaptador).
- Problema 2: driver Bluetooth carrega, mas falta utilitário para configurar/usar.
- Acesso: **cmd no WinRE**, iniciado automaticamente no boot.
- Requisitos: **R1** rede no WinRE (sem erro 10, IP válido) · **R2** driver Wi-Fi instalado e operacional · **R3** reinstalar o Windows sem mídia física (boot até a tela inicial) · **R4** Bluetooth PAN (celular/PC) · **R5** drivers preservados após reinstalar.
- Alternativas dadas: **A1** injetar driver Wi-Fi no WinRE via DISM · **A2** Bluetooth PAN com celular · **A3** reset do PC com download na nuvem · **A4** restaurar pela partição de recuperação · **A5** reinstalação por rede (PXE/WDS).
- Critério: atender o máximo de requisitos (R1–R5) com o menor risco.

## 2. Restrições práticas (importam tanto quanto a técnica)

1. O dono **não responde e não executa nada** durante o trabalho. O entregável tem de rodar sozinho.
2. O dono **digita tudo à mão** (sem copiar/colar) na máquina real. Comando curto vale mais que comando certo e longo.
3. **Hardware do dono desconhecido** (chip Wi-Fi não informado). Não há como consultar.
4. Sem rede no WinRE, **o driver e os scripts precisam estar em disco local** (partição de recuperação, restos do OEM) ou chegar por digitação. Este é o ponto mais subestimado do problema.
5. O executor só tem um sandbox **Linux** (sem Windows, sem KVM). Nada de Wi-Fi/WinRE roda lá de verdade.

## 3. O que o WinRE 1809 realmente tem — [MEDIDO]

Fonte: `docs/evidence/winre_1809_evidencia.md`, `docs/evidence/wlan_wcm_bth_hive.md`. Imagem real: `Core_en-us.esd` índice 2 (WindowsPE, 17763), 21 230 arquivos; lista completa em `docs/imagem/winre-caminhos.txt.gz` (branch `wwii`).

| Item | Estado | Consequência |
|---|---|---|
| `dism.exe`, `drvload.exe`, `wpeutil`, `wpeinit`, `diskpart` | presentes | injetar/carregar driver é possível |
| `net.exe`/`net1.exe`, `ftp.exe` | presentes | `net use` (SMB) e FTP possíveis |
| `cscript`, `wscript`, `mshta`, `winhttp.dll`, `msxml3/6`, `urlmon`, `jscript`, `vbscript` | presentes | download HTTP por script (`WinHttpRequest`) possível |
| TCP/IP (`dnsapi`, `dhcpcsvc`, `iphlpapi`) | presente | IP/DNS/DHCP funcionam |
| `certutil.exe`, `powershell.exe`, `bitsadmin.exe` | **ausentes** | runbook antigo com `certutil -urlcache` está errado |
| `netsh.exe`, `netshell.dll`, `wlancfg.dll` | presentes | mas veja a linha seguinte |
| `wlancfg.dll` registrado como helper do netsh (hive `\Microsoft\NetSh`: `wlancfg=wlancfg.dll`), importa `NETSH.EXE`+`wlanapi.dll`, e o `en-US/wlancfg.dll.mui` traz a ajuda de `connect`/`add profile`/`export`/`show` | presente | **`netsh wlan ...` provavelmente EXISTE** `[MEDIDO estático]`; runtime não provado. Fonte: `wwii:docs/evidence/netsh_wlan_existe.md` |
| `wlancmds.dll` | ausente (0 ocorrências) | **não é o helper do `wlan`**; a conclusão anterior do executor "netsh wlan inexistente" partiu dessa premissa errada e foi **corrigida** em 2026-11-05 |
| `wlansvc.dll`, `wlanapi.dll`, `wlanmsm.dll`, `wlansec.dll`, `nwifi.sys`, `vwififlt.sys`, `WdiWiFi.sys`, `ndisuio.sys` | presentes | pilha WLAN existe, falta a interface de linha de comando |
| Serviço `WlanSvc` | `Start=2` (auto), `ServiceDll=wlansvc.dll`, depende de `nativewifip`, `RpcSs`, `Ndisuio` | sem dependência de `wcmsvc` |
| `wcmsvc.dll` | ausente, mas `wlansvc.dll` **não importa** `wcmsvc.dll` e testa `WCMPresent` em runtime | a hipótese "falta wcmsvc quebra o Wi-Fi" **caiu** |
| Binário que exporte `WlanConnect` (via `rundll32`/`cscript`) | nenhum | irrelevante agora: `netsh wlan connect` cobre |
| `wmic.exe`, `reg.exe`, `pnputil.exe` (sem `/enum-devices` no 1809), `regedit.exe`, `drvload.exe`, `bcdedit.exe`, `bcdboot.exe`, `robocopy.exe`, `xcopy.exe`, `diskpart.exe`, `mountvol.exe`, `expand.exe`, `bootsect.exe`, `WcnNetsh.dll`, `wcncsvc.dll`, `WiFiConfigSP.dll`, pasta `\ProgramData` | presentes | `reg query ...\Enum` e `wmic` ajudam a listar hardware (P4/P11) |
| `sc.exe`, `tasklist.exe`, `taskkill.exe`, `curl.exe`, `tar.exe`, `findstr.exe`, `where.exe`, `reagentc.exe`, `setup.exe`, `schtasks.exe`, `msiexec.exe`, `devcon.exe` | **ausentes** (0 na lista de caminhos) | sem `curl`; `reagentc` e `setup.exe` não estão no WinRE (vêm de fora) |
| Pilha Bluetooth (`bth*`, `bthserv`, `bthpan.sys`, `bthprops.cpl`) | **0 arquivos, 0 chaves no hive** | **PAN não existe no WinRE**; só no Windows instalado |
| Driver Wi-Fi embutido | só `mrvlpcie8897.inf` (Marvell 88W8897) | não é genérico |
| `WCM Auto Connect` | está dentro de `wlansvc.dll` | com perfil XML certo o serviço pode conectar sozinho **[HIPÓTESE, nunca medida em runtime]** |

Correções ao que o enunciado e os planos supunham: o WinRE 1809 **traz** a pilha WLAN e, pelas evidências estáticas, **traz também o `netsh wlan`** (via `wlancfg.dll`); não precisa do ADK. O erro "falta `wcmsvc`" não procede. `certutil`, `powershell`, `bitsadmin`, `curl` e `findstr` **não existem**.

## 4. O que já foi construído e provado — [MEDIDO]

- **E2 — drivers (6/6 fabricantes):** um `.cab` oficial por fabricante (Intel AC 8265 `VEN_8086&DEV_24FD`, Realtek RTL8822BE, Qualcomm QCA6174, Broadcom BCM4365, MediaTek MT7921, Marvell 88W8897) baixado do Catálogo Microsoft Update, INF conferido (são **UTF-16LE**), injetado no `Winre.wim` e re-extraído com hash idêntico (17/17). `Winre.wim` 254 MB → 274 MB. Fonte: `docs/evidence/drivers_lote.md`. **Limite:** `wimlib` só grava arquivos; o registro no DriverStore/hive só acontece com `dism /Add-Driver` ou `drvload` na máquina real. O PnP escolhe entre os 6.
- **E3 — autorun offline:** `winpeshl.ini` com `[LaunchApps]` (sobe o script e depois a GUI) + `autorun-wwii.cmd` + `diag.cmd` (somente leitura) dentro do `Winre.lote.wim`. Teste `scripts/tests/unit/autorun_offline.py` PASS. **Só prova que os arquivos estão na imagem; não prova que o PE executa.** Fonte: `docs/evidence/autorun_winpe.md`.
- **Suíte Linux (T1+T2), PASS 21/0:** fdisk real (partição de recuperação **sobrevive** ao formatar C:; md5 idêntico antes/depois) e **PAN simulado** com namespaces + `veth` (PC→celular→rede externa, caso negativo e restauração). Prova só a lógica no kernel Linux, **não** Bluetooth nem Windows. Fonte: `docs/evidence/ambiente-teste-pan-fdisk.md`, `docs/evidence/t1t2_ubuntu_fallback.md`.
- **ISO de boot do WinRE montada do próprio WIM** (sem ADK/UUP): `scripts/montar_iso_winre.sh`. Descobertas que custaram tentativas: `etfsboot.com` exige `-boot-load-size 8` (com 4 dá `Code: 5`); o `bootmgr` PCAT vai na **raiz** e o identificador ISO9660 precisa ser exatamente `BOOTMGR;1` (xorriso grava `BOOTMGR.;1`, foi corrigido por patch); `bootfix.bin` **não** entra na ISO (senão pede tecla); UEFI/OVMF falhou 3 vezes (`No mapping`/`Not Found`) com este QEMU. Fonte: `docs/evidence/boot_winre_iso.md`.

## 5. O que NÃO está resolvido

### 5.1 E4 — o WinRE nunca chegou ao autorun no QEMU — INCONCLUSIVA

Cinco boots reais, TCG puro (sem KVM), todos sem chegar ao `autorun-wwii.cmd`:

| ISO | Resultado |
|---|---|
| WIM **sem compressão** (1,03 GB) | BSOD em **36 s**, `SYSTEM_THREAD_EXCEPTION_NOT_HANDLED` |
| **LZMS** (288 MB) | sem BSOD, 232 s e depois 1800 s ainda em modo texto, sem log |
| **LZX** (367 MB) | 1159 s sem BSOD, ainda em modo texto |
| **XPRESS** (429 MB) | BSOD em **425 s**, mesmo stop code |
| LZMS + `-hda` + `-serial file:` (decisão D6) | 1800 s, serial = **0 bytes**, sem `wwii.log` |

- O BSOD **não é da injeção**: o WIM original sem driver e sem autorun deu a mesma tela. A correlação "WIM sem compressão quebra" foi **refutada** pelo XPRESS. Mecanismo **não medido**.
- O convidado leu o disco IDE (35 840 bytes), então "o PE não enumera o disco" caiu.
- Não medido: `-cpu max` (o script fixa `qemu64`), progresso real do LZMS aos 1800 s (faltou gravar `info blockstats` e telas por run), WIM menor.
- **iPXE existe no QEMU** (`-device e1000` + `-netdev user`, DHCP ok `10.0.2.15`). Abre o teste de transporte PXE (A5) sem hardware.

### 5.2 Conectar no Wi-Fi no WinRE — (CORRIGIDO)

O executor chegou a afirmar que `netsh wlan` não existia (premissa `wlancmds.dll`). **Corrigido:** o helper é `wlancfg.dll` e o texto de `connect`/`add profile` está na imagem (§3). O caminho passa a ser: `drvload <inf>` → `netsh wlan add profile filename=<perfil.xml>` → `netsh wlan connect name=<perfil>`.
**Ainda em aberto (runtime, nunca medido):** (1) o `wlansvc` iniciar e enxergar a interface sem `wcmsvc`; (2) o perfil XML precisa do **SSID e da senha**, que ninguém informou ao executor e que o dono teria de digitar ou deixar num arquivo; (3) `drvload` carregar o driver sem erro 10; (4) a hipótese anterior de depositar o XML no store do `wlansvc` e copiar `wlancmds.dll` do ESD fica como plano B, sem evidência.

### 5.3 Transporte até o WinRE (p0402452582, aberto)

Sem rede, sem mídia e sem copiar/colar, como os scripts e drivers chegam ao WinRE? O dono digita à mão. O entregável precisa de comandos curtíssimos. **Ninguém resolveu.**

### 5.4 Hardware real e erro 10

O erro 10 é firmware ausente **[HIPÓTESE]**. Falta uma ferramenta que leia o código de erro no WinRE 1809 (`pnputil /enum-devices` só existe a partir do 1903). `diag.cmd` (somente leitura) existe para rodar no hardware real.

## 6. Ideias que o executor NÃO explorou — **[HIPÓTESE]**, avalie

1. **Drivers inbox do Windows como fonte local.** O `install.wim`/ESD do Windows 10 Home tem muitos drivers Wi-Fi inbox no DriverStore. Se a partição de recuperação do dono guarda a imagem de fábrica (A4), os drivers podem sair dela sem baixar nada.
2. **A4 como caminho primário.** Se houver imagem de fábrica na partição, resolve R3 com um comando e ignora Wi-Fi. A partição de recuperação **sobrevive** ao formatar C: (provado no Linux).
3. **Como o `Winre.wim` real é editado no WinRE real?** `dism /Mount-Image` do `Winre.wim` exige espaço gravável (C: formatada serve de rascunho). Depois, como o BCD/`reagentc` aponta para o WIM modificado? O executor não modelou o BCD real do dono.
4. **R3 sem rede:** `setup.exe` precisa de fonte. Sem rede e sem ESD local, A3 (reset na nuvem) exige o Wi-Fi funcionando no WinRE. Se o Wi-Fi não conectar, R3 depende de A4.
5. **Bluetooth como transporte de rede** não existe no WinRE (0 arquivos). Injetar a pilha BT vinda do `install.wim` é possível em tese, mas é grande e arriscado.
6. **Digitação:** um `.cmd` que o próprio PE gera a partir de um arquivo mínimo (ex.: um único `for` que baixa o resto) reduz o que o dono digita. Também vale um arquivo de resposta já gravado no WIM.
7. **Testar o fluxo em Windows real** (VM com KVM, outra máquina) é o que falta. O sandbox Linux nunca fecha a prova.

## 7. Ambientes de teste — um por agente, NÃO misturar

Cada agente roda numa máquina diferente (CPU, RAM, rede, ferramentas). **Nenhuma medida de um agente vale para outro.** Cada um mede e anota o seu em `wwii:ambientes/<agente>.md` (gerado por `sh scripts/registrar_ambiente.sh <agente>`, com limitações medidas e notas). Leia o arquivo do agente que vai executar a ideia antes de decidir o que dá para provar nele.

Quem mediu o quê, **com atribuição**:

| Agente | O que foi reportado | Fonte |
|---|---|---|
| **claude** (executor atual) | Ubuntu 24.04.5, 1 CPU, 3 990 MB RAM, ~8 GB de disco, sem KVM, sem módulo `vfat`, QEMU 8.2.2, wimlib 1.14.4. Rede: apt, pypi, npm e github respondem; **Alpine CDN, uupdump.net, learn.microsoft.com e o catálogo do Windows Update não respondem**. Tem busca web e leitura de páginas fora do bash. | `wwii:ambientes/claude.md` (medido em 2026-11-05) |
| **qoder** | 7 940 MB RAM, 3 CPUs, sem KVM, QEMU 6.2.0, SeaBIOS 1.15.0; todos os boots do WinRE (E4) foram feitos nessa máquina | `docs/evidence/boot_winre_iso.md` |
| **stackai** | alcançou o Catálogo Microsoft Update e baixou os 6 `.cab` de driver (E2) | `docs/evidence/drivers_lote.md` |

Consequência: o que o **claude** não consegue baixar (ESD, `wlancmds.dll`, drivers novos) pode ser possível em outro agente. O boot do WinRE em TCG foi medido **só no ambiente do qoder**; no do claude (1 CPU) nem foi tentado.

Inventário do ambiente do **claude** (resumo; detalhe e limites no arquivo dele):
- **Presentes:** `qemu-system-x86_64`, `wimlib-imagex`/`wimextract`, `xorriso`, `mtools`, `7z`, `unsquashfs`, `cpio`, `zstd`, `xz`, `python3` 3.12 (+`regipy`, `pefile`, `requests`), `node`/`npm`, `gcc`, `make`, `git`, `curl`, `wget`, `objdump`, `strings`, `ip`, `busybox`, `depmod`, `xxd`, `file`.
- **Ausentes:** `jq`, `hivexsh`, `reglookup`, `chntpw`, `fdisk`/`sfdisk`/`parted` (o `fdisk` dos testes é o do busybox dentro da VM), `mkfs.vfat`, `ntfs-3g`, `cabextract`, `msitools`, `hexdump`, `bsdtar`, `genisoimage`, `smbclient`, `tftp`.
- **Firmware/ROMs:** OVMF em `/usr/share/OVMF/` e `/usr/share/ovmf/OVMF.fd`; iPXE em `/usr/lib/ipxe/` (`e1000_82540.rom`, `virtio-net.rom`, `rtl8139.rom`, `pcnet32.rom`, `eepro100.rom`, `ns8390.rom`).
- **Kernel de teste:** como o Alpine CDN não responde para o claude, `scripts/fetch-base.sh` cai para o kernel Ubuntu `6.8.0-147-generic` via apt (`sd_mod` e `virtio_net` são built-in; `veth.ko` vem de `linux-modules-*`).

**O que um ambiente Linux assim consegue:** inspecionar/alterar WIMs (`wimlib`), montar ISO, ler hive/PE (`regipy`, `objdump`), rodar VM Linux mínima, simular PAN com `veth`, testar iPXE/DHCP.
**O que nenhum dos ambientes conseguiu:** executar `dism`/`drvload`/`wlansvc` de verdade, provar Wi-Fi, Bluetooth, erro 10 e o BCD do dono.

## 8. Mapa do repositório

| Branch | Função |
|---|---|
| `wwii` | trabalho do executor (scripts, evidências, testes) |
| `lider` | só o líder escreve (`PLANO-DO-LIDER.md`, casos, retornos). Antiga `relatorio` |
| `info` | **este arquivo** |
| `imagem` | partes da imagem do Windows 1809 (para remontar o WIM) |
| `0` | lançador (`h.sh`) |
| `main` | só `README.md` |
| `iaag`, `backup` | outros projetos / cópia, fora do escopo |

Scripts principais em `wwii:scripts/`: `ambiente.sh`, `doctor.sh`, `obter_imagem.sh`, `buscar_driver.py`, `injetar_driver.sh`, `injetar_autorun.sh`, `autorun-wwii.cmd`, `diag.cmd`, `download.vbs`, `montar_iso_winre.sh`, `boot-winre.sh`, `chovar-qemu.sh`, `vncshot.py`, `ler_hive.py`, `checar_firmware.py`, `tests/run-tests.sh`. Setup do executor: `setupenvclaude.sh` (idempotente) e `auto.sh`.

## 9. Plano do líder vigente (resumo das decisões D1–D6)

- **D1** testar Wi-Fi sem `wcmsvc.dll` (injetar driver, `drvload`, `sc query wlansvc`, `netsh wlan show drivers`) — **vale como escrito**: `netsh wlan` provavelmente existe (§5.2, correção de 2026-11-05); falta provar em runtime.
- **D2** baixar o ESD por **HTTP** (`cscript` + `WinHttpRequest`), em partes, retomando por `Range`; plano B FTP.
- **D3** exportar drivers antes do wipe (`dism /Image:C:\ /Export-Driver /Destination:R:\DriversOEM`) só se C: ainda existir.
- **D4** Bluetooth PAN só como plano B, **verificado**: sem BT no WinRE, PAN só no Windows instalado.
- **D5** não ir ao hardware real sem E4 + download HTTP em NIC emulada + `dism apply` em disco virtual; rodar só `diag.cmd` (somente leitura) no hardware.
- **D6** repetir o boot **uma** vez com `-hda`/`-serial`; falhou ⇒ E4 **INCONCLUSIVA**.

## 10. O que se espera de você (modelo mais capaz)

Pense em todas as possibilidades, inclusive as que contradizem o executor e o líder. Entregue:

1. **A rota de menor risco que cubra mais de R1–R5**, justificando por quê (compare A1–A5 e as ideias do §6).
2. **O que decide entre as rotas** e como o dono descobre isso lendo o mínimo da própria máquina (`diag.cmd` somente leitura).
3. **Um runbook digitável**, com o menor número de caracteres possível, para o WinRE 1809, sem `certutil`, `powershell`, `curl` nem `findstr`.
4. **Como conectar o Wi-Fi no WinRE** com `netsh wlan add profile` + `connect` (§5.2): o que pode falhar em runtime (serviço, GUID, driver, SSID/senha desconhecidos) e como obter SSID/senha com a menor digitação.
5. **O que provar antes de tocar a máquina real** e o que só a máquina real prova.
6. **Falhas e plano B/C** para cada passo, e **onde o plano atual do líder está errado**.

> Regras do projeto: **os agentes trabalham até se esgotar** (nunca param por conta própria; só param por limite do ambiente ou com todas as alternativas registradas). Ambiente é por agente.
>
> Pesquisa profunda complementar: branch `pesquisador`, arquivo `PROMPT-PESQUISA.md`. Antes de decidir, confira se já há `RESULTADO-PESQUISA.md` lá.
>
> Outras regras: nunca declarar "impossível" sem tentativas registradas; marcar claramente o que é medido e o que é hipótese; nada destrutivo na máquina do dono antes do D5.
