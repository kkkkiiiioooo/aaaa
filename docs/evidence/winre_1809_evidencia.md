# Evidência — WinRE do Windows 10 Home 1809 (build 17763.9376)

**Método:** inspeção estática da imagem real do WinRE, extraída dos pacotes oficiais
Microsoft via uupdump (`scripts/uup_links.sh` + `scripts/baixar_uup.sh`), aberta com
`wimlib-imagex` no Linux. Não é análise de documentação: é o conteúdo do arquivo.

**Fonte da imagem**
- `Feature update to Windows 10, version 1809 (17763.9376)` amd64, edição **core (Home)**.
- Arquivo: `Core_en-us.esd` — **índice 2** = `Microsoft Windows Recovery Environment (x64)`,
  `Edition ID: WindowsPE`, `Build: 17763` (2.169.435.125 bytes descompactados, 21.230 arquivos).

**Como reproduzir**
```sh
sh scripts/uup_links.sh                      # gera .tsv com links diretos oficiais
sh scripts/baixar_uup.sh 'Core_en-us'        # baixa só o ESD que contém o WinRE
wimlib-imagex info .work/uup/files/Core_en-us.esd 2   # confirma: WindowsPE / 17763
wimlib-imagex dir  .work/uup/files/Core_en-us.esd 2 | grep -i wlan
```

## Resultado — o WinRE 1809 tem ou não tem?

| Componente | Estado | Consequência no plano |
|---|---|---|
| `netsh.exe` | **PRESENTE** | base para configurar rede |
| `netshell.dll` + `wlancfg.dll` | **PRESENTE** | helper do contexto → **`netsh wlan` existe** |
| `wlanapi.dll`, `wlanmsm.dll`, `wlansec.dll`, `wlansvc.dll`, `WlanConn.dll` | **PRESENTE** | pilha WLAN completa |
| `nwifi.sys`, `vwififlt.sys`, `WdiWiFi.sys` | **PRESENTE** | NativeWiFi + WDI |
| `dism.exe` | **PRESENTE** | permite montar/injetar offline |
| `wpeutil.exe`, `wpeinit.exe` | **PRESENTE** | reboot/init do WinPE |
| `net.exe`, `net1.exe` | **PRESENTE** | `net use` (SMB) para puxar ISO de outra máquina |
| `ftp.exe` | **PRESENTE** | download por FTP |
| `cscript.exe`, `wscript.exe`, `mshta.exe` | **PRESENTE** | download HTTP por script |
| `msxml3/6.dll`, `winhttp.dll`, `urlmon.dll`, `jscript/vbscript.dll` | **PRESENTE** | `XMLHTTP`/`WinHttpRequest` disponível |
| pilha TCP/IP (`dnsapi`, `dhcpcsvc`, `nsi`, `iphlpapi`) | **PRESENTE** | IP/DNS/DHCP funcionais |
| **`certutil.exe`** | **AUSENTE** | ❌ quebra o passo 3 do runbook antigo |
| **`powershell.exe`** | **AUSENTE** | ❌ sem `Invoke-WebRequest` |
| `bitsadmin.exe` | **AUSENTE** | ❌ sem BITS |
| driver Wi-Fi de fabricante | **`mrvlpcie8897.inf` apenas** (Marvell 88W8897) | genérico; não cobre o adaptador real |

## Conclusões — correção dos pressupostos

1. **Derrubado:** "WinRE 1809 não inclui WLAN; sem `netsh wlan` é preciso o WinPE-WiFi-Package (ADK)".
   O WinRE 17763 já traz `netsh` + `wlancfg.dll` + toda a pilha WLAN. **Não é necessário
   adicionar pacote do ADK** para ter `netsh wlan`.
2. **Mantido:** o driver Wi-Fi **do fabricante** ainda é obrigatório. Só há um driver Wi-Fi
   embutido (`mrvlpcie8897`), então **A1 (injetar driver via DISM) continua sendo o passo 1**
   para o adaptador real — e agora com caminho confirmado, porque `dism.exe` está no WinRE.
3. **Corrigido:** o passo de download da ISO (**R3**) não pode usar `certutil -urlcache`.
   Alternativas confirmadas como presentes, em ordem de preferência:
   - **SMB:** `net use Z: \\<ip>\share` + `copy Z:\win.iso C:\` (mais simples e robusto);
   - **HTTP por script:** `cscript get.vbs` usando `WinHttp.WinHttpRequest.5.1` ou
     `MSXML2.XMLHTTP` (DLLs presentes);
   - **FTP:** `ftp.exe -s:cmd.txt`;
   - **Injetar `certutil.exe`** no `Winre.wim` via `dism /Add-...` a partir do `install.wim`
     (plano C, exige imagem de origem).

## Runbook corrigido (WinRE 1809)

```bat
0) diskpart -> list volume ; select vol <RE> ; assign letter=R   (Winre.wim em R:\Recovery\WindowsRE\)
   select vol C ; assign letter=C
1) dism /Mount-Image /ImageFile:R:\Recovery\WindowsRE\Winre.wim /Index:1 /MountDir:C:\mnt
   dism /Image:C:\mnt /Add-Driver /Driver:<driver-wifi.inf> /Recurse
   dism /Unmount-Image /MountDir:C:\mnt /Commit
   wpeutil reboot
2) netsh wlan show interfaces     :: disponivel (wlancfg.dll confirmado)
   netsh wlan connect name=<SSID> :: ou perfil com chave
   ipconfig /all
3) sem certutil:  net use Z: \\<ip>\share  ->  copy Z:\win.iso C:\win.iso
   (ou cscript download.vbs com WinHttpRequest)
   montar e rodar setup.exe com destino C:, "nada a preservar"
4) antes de reinstalar: dism /Online /Export-Driver /Destination:R:\DriversOEM
   depois do OOBE:      pnputil /add-driver R:\DriversOEM\*.inf /subdirs /install
```

## Validação offline executada (passo 1 do runbook)

A imagem WinRE foi exportada do ESD e um driver `.inf` de teste foi injetado **offline**,
confirmando que o procedimento do passo 1 (montar → adicionar driver → commit) fecha sem erro:

```sh
wimlib-imagex export Core_en-us.esd 2 .work/wim/Winre.wim --compress=none
# imagem: "Microsoft Windows Recovery Environment (x64)", Edition ID WindowsPE, Build 17763
wimlib-imagex update .work/wim/Winre.wim 1 \
  --command="add .work/drvtest/wifiteste.inf /Windows/INF/wifiteste.inf"
wimlib-imagex dir .work/wim/Winre.wim 1 | grep wifiteste
# => /Windows/INF/wifiteste.inf   (SUCESSO)
```

Equivalência: no Windows o mesmo passo é `dism /Mount-Image` + `dism /Add-Driver` +
`dism /Unmount-Image /Commit`. Aqui foi feito com `wimlib` (Linux), que grava os arquivos
na imagem; o DISM faz além disso o registro no DriverStore/hive — parte que só executa
na máquina real.

## Limite desta evidência

Inspeção do **conteúdo da imagem** (arquivos presentes/ausentes), não boot do WinRE.
Não valida o carregamento do driver em runtime nem o erro 10 do adaptador citado no
desafio — isso depende da máquina real. Mas elimina as duas incógnitas que travavam o
plano: `netsh wlan` existe (não precisa de ADK) e `certutil` não existe (precisa de
alternativa de download).
