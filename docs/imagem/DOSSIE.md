# DOSSIÊ — conteúdo real da imagem do Windows 1809

**Quem escreveu:** `investigador-ti` · **quando:** 2026-11-03T17:58Z · **etapa:** E2
**Por que este arquivo existe:** para quem **ainda não passou da E1** (sem imagem, sem
ambiente) poder pensar na solução agora, em vez de esperar. Nada aqui exige que você
tenha a imagem em disco para ser lido.

Gerado de `.work/uup/files` (33 arquivos, 3,7 GB) com `sh scripts/dossie.sh`.
Os números deste arquivo são **medição**, não documentação da Microsoft.
Detalhe verificável em `manifest.txt` (sha1), `indices.txt`, `winre-caminhos.txt.gz`
(21 230 caminhos do WinRE, completo).

---

## 1. O que é esta imagem — FATO

| item | valor |
|---|---|
| origem | UUP dump, edição `Core`, en-us |
| arquivos baixados | 33 · 3,61 GiB declarados · **sha1 33/33 conferem** |
| `Core_en-us.esd` | 499 MB, LZMS, boot index 2, **3 índices** |
| índice 1 | *Windows Setup Media* — 941 arquivos, 272 MB |
| índice 2 | **WinRE** (é o que nos interessa) — 17 669 arquivos, 2,17 GB |
| índice 3 | *Windows 10 Home* — 86 160 arquivos, 14,27 GB |
| build | 17763 (1809). Carimbo interno dos componentes: `10.0.17763.1`, criado 2018-09-15 |

## 2. O que o WinRE 1809 TEM — FATO (procura em `winre-caminhos.txt.gz`)

`cmd` `reg` `dism` `pnputil` `bcdedit` `bcdboot` `bootsect` `diskpart` `chkdsk`
`sfc` `netsh` `wpeutil` `wpeinit` `winpeshl` `startnet.cmd` `net` `ipconfig` `ping`
`route` `netstat` `tracert` `robocopy` `xcopy` `rundll32` `mshta` `powercfg`
`cscript.exe` `wscript.exe` `notepad.exe` `taskmgr.exe`
**`drvload.exe`** — existe, e é a melhor notícia deste dossiê: é o carregador de driver
nativo do PE, fala com o kernel **sem** precisar de DISM nem de TrustedInstaller.
`TrustedInstaller.exe` também existe (logo `DISM /Add-Driver` tem com que falar).
`wlanapi.dll` `wlanutil.dll` `wlanmsm.dll` `wfdprov.dll` (a API de Wi-Fi existe)

## 3. O que o WinRE 1809 NÃO tem — FATO (zero ocorrências nos 21 230 caminhos)

| ausente | consequência prática |
|---|---|
| `certutil.exe` | não há como checar hash/assinatura de arquivo por dentro do PE |
| `powershell.exe` | nada de script moderno; só `cmd` + `reg` + `cscript` |
| `findstr.exe` | pipes de filtragem de texto precisam de `grep`-equivalente inexistente |
| `bitsadmin.exe` | sem BITS (e a chave do serviço **BITS** também não existe no hive) |
| `msiexec.exe` | nada de `.msi` dentro do PE — driver tem de entrar por INF (`drvload`/`DISM`) |
| `regedit.exe` | sem GUI de registro: só `reg.exe` em linha de comando |
| `wcmsvc.dll` | **ver §4 — é o achado** |

## 4. ACHADO CENTRAL: o Wi-Fi do WinRE está ligado a uma DLL que não existe — FATO

Extraí o hive `\Windows\System32\config\SYSTEM` do **índice 2** e li
`ControlSet001\Services` (330 serviços) com parser de hive, não com `strings`:

```
WlanSvc              AUTO      svchost.exe -k WlansvcGroup
NlaSvc               AUTO      svchost.exe -k NetworkService -p
Dhcp                 AUTO      ...LocalServiceNetworkRestricted -p
LanmanWorkstation    AUTO      svchost.exe -k NetworkService -p     <- \\host\share funciona
LanmanServer         AUTO      svchost.exe -k netsvcs -p
CryptSvc             AUTO      (driver assinado tem como ser validado)
TrustedInstaller     AUTO      (DISM /Add-Driver tem com que falar)
BFE / mpssvc / Winmgmt  AUTO
dot3svc              CHAVE AUSENTE
netprofm             CHAVE AUSENTE   <- gerenciador de perfis de rede
BITS, Schedule, TermService, profsvc, AppIDSvc  CHAVE AUSENTE
```

O serviço de autoconfiguração sem fio **existe, está em AUTO e aponta para
`svchost -k WlansvcGroup`, cuja ServiceDll é `wcmsvc.dll` — e `wcmsvc.dll` não está
na imagem.**

**HIPÓTESE (confiança alta, ~80%):** injetar driver Wi-Fi no WinRE 1809 **não basta**.
O `WlanSvc` vai tentar subir e falhar por DLL ausente; sem ele, `netsh wlan` não
conecta perfil, por mais que o driver esteja presente. `netprofm` ausente reforça
(perfis de rede não são registrados).

**O teste que fecha isto** (é a E4, não a E2): dar boot no PE e rodar
`sc query wlansvc` + `netsh wlan show interfaces`. Se vier *O serviço não pode ser
iniciado* / *API não disponível*, a hipótese vira fato e o plano muda de
"achar o driver certo" para "repor as peças de software que faltam".

## 5. Se confirmar: as peças NÃO precisam de download novo — FATO

Estão no **`Microsoft-Windows-Client-Desktop-Required-Package.ESD`** (786 MB), que já
está em `.work/uup/files`, como componente WinSxS:

```
amd64_microsoft-windows-wcmsvc/            wcmsvc.dll, wcmcsp.dll,
                                           cellulardatacapabilityhandler.dll
amd64_microsoft-windows-onecoreuap-wlansvc/ wlanapi.dll wlanhlp.dll wlanmsm.dll
                                           wlansec.dll wfdprov.dll WiFiConfigSP.dll
amd64_microsoft-windows-wlan-netsh-helper/  wlancfg.dll   <- dá o `netsh wlan`
amd64_microsoft-windows-wlan-extension/     wlanext.exe
amd64_microsoft-windows-networkprofile/     netprofm.dll, netprofmsvc.dll
```

Caminho de correção, em ordem de reversibilidade:
1. `wimlib-imagex extract` do componente → `wimlib-imagex update --add` no `boot.wim`
   (não toca no `Winre.wim` original; reversível por ser cópia).
2. repor as **chaves de serviço** correspondentes no hive do PE (reg load/unload).
3. só então `dism /Add-Driver` com o `.cab` da E2.
`NÃO VERIFICADO`: se 1+2 bastam, ou se faltam dependências de import table. Isso se
mede na E4, não aqui.

## 6. Consequência por etapa — o que muda no que cada agente pretendia fazer

| etapa | antes | agora |
|---|---|---|
| E2 (driver oficial) | achar o `.cab` certo resolve | o `.cab` é **necessário, não suficiente**; valide INF contra 17763. Bom caminho: extrair `.inf`+`.sys`+`.cat` e testar com **`drvload`** direto, que existe; `DISM /Add-Driver` é para persistir |
| E3 (autorrun) | criar `winpeshl.ini` | **ele já existe** em `/Windows/System32/winpeshl.ini` (+`startnet.cmd`): é para **editar**, e o conteúdo atual importa |
| E4 (boot real) | prova de conceito de boot | passa a ser **o teste decisivo do §4** — prioridade subiu |
| E5 (setup via rede) | depende de Wi-Fi | **cabo/smb first**: `LanmanWorkstation`+`Dhcp`+`NlaSvc` estão AUTO e as DLLs existem; Wi-Fi é o caminho arriscado |

Isso é a parte que vale para quem está preso na E1: **o plano mais provável de
funcionar não é o que o HANDOFF propunha.**

## 7. Reproduzir do zero (3 comandos, ~4 min a 15 MB/s)

```sh
sh scripts/uup_links.sh        # so resolve links (padrao: Home 1809 en-us, UUID no cabecalho)
sh scripts/baixar_uup.sh       # aria2c -x4 -s4 -> .work/uup/files  (~244 s a 15 MB/s)
sh scripts/dossie.sh           # regenera docs/imagem/ e confere o sha1 dos 33 arquivos
```

Outras edições/idioma: `UUP_EDITION=professional sh scripts/uup_links.sh`.
`--search <termo>` acha builds pelo nome. O UUID desta imagem e
`814acacb-6203-4083-b0f0-21746910e3a9` (esta no nome do .tsv).

Sem a imagem em disco, leia `manifest.txt` + `winre-caminhos.txt.gz`:
`zcat docs/imagem/winre-caminhos.txt.gz | grep -i <algo>`.

## 8. Limites deste dossiê — leia antes de confiar

- Descreve o **índice 2 de `Core_en-us.esd`**, ou seja, WinRE *de fábrica*. O PE que o
  dono realmente bootou pode ter sido modificado por OEM — não verifiquei OEM.
- É estático (arquivos + hive). **Não medi nada em runtime.** Toda afirmação de
  comportamento aqui é inferência a partir de presença/ausência.
- A imagem é `Core` (Home). Se a máquina do dono for Pro, componentes diferem.
- `docs/imagem/*` é gerado: se você re-baixar a imagem, rode `dossie.sh` e comite a
  diferença em vez de editar texto à mão.
