# DESAFIO: Recuperação do Windows sem conexões físicas

> Prompt vivo: este arquivo (≤ 9 KB, sem histórico) basta para entender o problema. Descobriu algo que muda o entendimento (dispositivo, ambiente, canal, driver)? Atualize a seção certa no mesmo commit.

## Objetivo
Restaurar o Windows em uma partição C: formatada, sem cabos, pendrives ou adaptadores físicos.

## Contexto
- Windows 10 1809; WinRE funcional, com Winre.wim (enunciado original: "WRE.wim") na partição de recuperação.
- Problema 1: WinRE sem driver Wi-Fi completo (erro 10 no adaptador).
- Problema 2: driver Bluetooth carrega, mas falta utilitário para configurar/usar.
- Acesso: cmd no WinRE, iniciado automaticamente no boot.
- Restrição crítica: nenhuma conexão física.

## Ponto central (leia antes de propor qualquer solução)

**OBJETIVO ZERO: CONECTAR O PC AO MUNDO EXTERNO. INJETAR DRIVER NÃO É O OBJETIVO E NÃO CONECTA NADA.** Driver só usa bytes que já estão no PC; ele não transporta arquivos nem cria rede. Não proponha, feche etapa ou marque requisito como atendido com base apenas em injeção/`drvload`. Preencha: `CANAL EXTERNO=...; ORIGEM DOS BYTES=...; CUSTO (teclas/tempo)=...`. Rede/download como meio de obter o primeiro payload é circular. Ordem obrigatória: **canal externo → bytes no PC → driver → rede/IP → reinstalação**. Exceção: bytes locais comprovados (OEM/recuperação/EFI), com caminho e evidência.
- A máquina real **não tem rede, Wi-Fi, cabo nem mídia**. Injetar driver no Winre.wim (A1) só serve se os bytes do driver **já estiverem na máquina**. Sem um canal de dados, "injetar o driver" não resolve nada.
- Canal garantido: **teclado (entrada) e tela (saída)**. Tudo que entra passa por digitação; tudo que sai, pela leitura da tela. Rede só existe depois de R1, então R1 não pode depender de baixar nada.
- Prova que falta: transferir um **binário intacto** por esse canal. E2–E5 usaram o host (wimlib) e a NIC do QEMU: provam que o driver carrega e que o download funciona **com rede**, não o cenário real. **E5 escrita binária no PE: FECHADA N3 (2026-11-12)** — FSO Unicode empacotado (`lo|hi<<8`, cortar BOM `FF FE`) grava 0x00..0xFF com sha256 ok por 5 caminhos (b64, MSXML `bin.hex`, ResponseText cru); armadilha: `WScript.Arguments.Count` não existe em JScript (use `.length`) e FSO ASCII `Write` lança exceção em 0..255. Detalhes: `docs/evidence/e5-escrita-binaria-n3.md`. A ENTRADA por teclado/tela (E6) continua sem prova.
- Toda proposta diz **por qual canal os bytes chegam** e quantas teclas custa. Sem isso, está errada.
- Cubra também: driver já presente em disco no próprio PC (partições OEM/recuperação/EFI) e Bluetooth como canal (o enunciado diz que o driver carrega; `docs/evidence/wlan-wcm-bth-hive.md` mediu 0 arquivos `bth` no WinRE: confronte).

## Dispositivo (fatos e fonte)
- Aparelho: Xiaomi Mi Pad 2 (versão Windows), 16 ou 64 GB (dono; README de github.com/brianwoo/mipad2-win10-howto). De fábrica: Windows 10 build 10586; hoje 1809. Demais especificações do dono **não estão no repositório**: se aparecerem, registre aqui.
- Wi-Fi: "Broadcom 802.11ac Wireless PCIE Full Dongle Adapter". README (Passo 7): o Windows instala o driver da Microsoft e o Wi-Fi não funciona; escolhendo o driver da Broadcom, funciona. O INF oficial cobre PCI\VEN_14E4&DEV_ 4355 4364 43A3 43BA 43C3 43EC 43EF 440D. Chip provável BCM4356 (DEV_43EC): o pacote traz `4356a2rtecdc.bin` e `bcm94356wlpagbl_P3_150828M.txt`. Não confirmado no aparelho.
- Bluetooth: Broadcom por UART (ACPI\BCM2Exx; firmware `BCM4356A2_*.hcd`).

## Drivers que já temos (extraídos em `drivers/`, detalhes e hashes em `drivers/README.md`)
| Tipo | Pasta | Versão |
|---|---|---|
| A. Microsoft/inbox (o que o Windows instala sozinho; **já está no WinRE**) | `drivers/winre-inbox/wifi-wdi-pcie` | 1.558.53.25 (2017) · DEV 4355, 43EC |
| B. Oficial Wi-Fi (pacote do aparelho) | `drivers/mipad2-oficial/wifi` | 1.558.14.0 (2015) · 8 DEVs · traz nvram |
| B. Oficial Bluetooth (UART) | `drivers/mipad2-oficial/bt-uart` | 12.0.1.731 (2015) |
- **Achado (medido, N2 no binário)**: o driver `bcmpciedhd63.sys` monta `\SystemRoot\system32\drivers\%04Xr%dnvram.txt` → `4356r2nvram.txt` e o WinRE 1809 **não tem nenhum nvram.txt** (0 na imagem); o firmware `4356r2rtecdc.bin` (renomeado do `4356a2rtecdc.bin` pelo próprio INF) existe. Strings no .sys: `dhd_bus_download_firmware() failed`, `dongle nvram file download failed`. Sem nvram o download de firmware falha → **erro 10**. Delta = 1 arquivo de 5361 B: `drivers/nvram-delta/` (pronto; autorun já copia de qualquer volume e faz `pnputil /scan-devices`). Falta provar na máquina real (D5).
- Falta o driver mais novo do Catálogo da Microsoft para DEV_43EC: este ambiente bloqueia catalog.update.microsoft.com. O "lote de 6 fabricantes" (E2) foi chute sem HWID; está superado.

## Ambiente do WinRE (o que existe por padrão; fonte: docs/imagem/INVENTARIO.md)
### Identidade
- Windows 10 build 17763 (1809), edicao Core (Home), en-us; imagem WinRE = indice 2 do ESD (UUP dump).
- Cuidado: o WinRE do dono pode ter sido alterado pelo OEM e ser Pro (componentes mudam). Nao verificado.
- Contagem: 187 executaveis unicos (.exe/.com), 1168 DLLs unicas, 392 drivers .sys, 987 .inf (UTF-16LE: grep ASCII engana).

### Ferramentas de linha de comando: PRESENTE / AUSENTE
- **rede** — PRESENTES: netsh ipconfig ping net net1 ftp tracert route arp nbtstat netstat hostname pathping
  AUSENTES: tftp telnet nslookup getmac curl wget bitsadmin certutil
- **script/exec** — PRESENTES: cmd cscript wscript mshta rundll32 regsvr32 wmic more find xcopy robocopy expand
  AUSENTES: powershell schtasks start sort findstr tar where timeout
- **driver** — PRESENTES: drvload pnputil dism wpeutil wpeinit drvcfg drvinst newdev driverquery InfDefaultInstall
  AUSENTES: devcon
- **disco/boot** — PRESENTES: diskpart bcdedit bcdboot bootsect bootrec chkdsk format fsutil mountvol convert mbr2gpt attrib icacls takeown manage-bde
  AUSENTES: setup
- **sistema** — PRESENTES: reg regedit net sfc notepad
  AUSENTES: sc tasklist taskkill whoami shutdown systeminfo msiexec setx
- Observacao: `format`, `more`, `xcopy`, `sort`, `find` etc. podem ser `.com`/`.exe` ou builtin do cmd; "ausente" aqui = sem arquivo na lista.
- `wpeinit`/`wpeutil`: o PE usa `winpeshl.ini` ([LaunchApps]); sem `wpeinit` a rede do PE nao sobe sozinha (ver docs/evidence/autorun-winpe.md).

### Executáveis (187 únicos, sem extensão)
abortpxe arp atbroker attrib audiodg autochk autoconv bcdboot bcdedit bfsvc bmrui bootcfg bootmgr bootrec bootsect chcp chkdsk chkntfs cloudrecsvc cmd compact comppkgsrv conhost convert convertvhd credentialuibroker cscript csrss devicecensus diagnosticshub.standardcollector.service diskpart diskraid dism dismhost dllhost dllhst3g dnscacheugc doskey dpapimig driverquery drvcfg drvinst drvload dtdump eap3host esentutl etfsboot expand find finger fixmapi fltmc fontdrvhost format fsutil ftp hdlscom1 hdlscom2 hh hostname icacls infdefaultinstall ipconfig iscsicli lodctr lsass manage-bde mbr2gpt mcbuilder mdsched memtest mighost mode mofcomp more mountvol mrinfo mshta muiunattend narrator nbtstat ndadmin net net1 netbtugc netcfg netcfgnotifyobjecthost netiougc netsh netstat newdev notepad ntoskrnl ntprint openwith pacjsworker pathping ping pkgmgr pnpunattend pnputil poqexec powercfg print pxeboot rasautou rdrleakdiag recdisc recenv recover refsutil reg regedit regedt32 register-cimprovider regsvr32 repair-bde replace resetengine resetenginterfaces resetpluginhost robocopy route rstrui rundll32 runexehelper sacsess sapisvr scrcons services setupplatform sfc smss spatialaudiolicensesrv startrep subst svchost sxstrace sysreset tabtip takeown taskmgr tcpsvcs tifilefetcher tiworker tracert tree trustedinstaller ucsvc unlodctr unsecapp userinit vds vdsldr verifier verifiergui vssvc wallpaperhost wbadmin wbemtest wbengine wdscapture wdsclient wdsmcast wdsnbp werfault werfaultsecure wermgr wevtutil wimserv wininit winload winlogon winmgmt winpeshl winresume wlanext wmiadap wmiapsrv wmic wmiprvse wowreg32 wpeinit wpeutil wpr wscript xcopy

## Requisitos
- R1 rede no WinRE (adaptador sem erro 10, IP válido) · R2 driver Wi-Fi instalado e operacional · R3 reinstalar o Windows sem mídia física (boot até a tela inicial) · R4 Bluetooth PAN (celular/PC) · R5 drivers preservados após reinstalação.

## Alternativas
- A1 injetar driver Wi-Fi no WinRE via DISM pelo cmd · A2 Bluetooth PAN com celular · A3 reset do PC com download na nuvem · A4 restaurar pela partição de recuperação · A5 reinstalação por rede (PXE/WDS).

## Como decidir
Atender o máximo de requisitos (R1–R5) com o menor risco.

## Autonomia
Ninguém ajuda: o dono não responde nem executa nada durante o trabalho. O agente resolve sozinho, com o próprio ambiente, e entrega algo que roda sozinho na máquina.

## Regras
Ver `AGENTS.md`.

## Regra de persistência
Não pare por conta própria: ao fim de uma tarefa pegue a próxima (AGENTS.md, "Trabalhe até se esgotar"). Ambiente é por agente: `ambientes/<nome>.md`.
