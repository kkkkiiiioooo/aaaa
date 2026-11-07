# INVENTARIO DO AMBIENTE REAL — WinRE 1809 do desafio

Gerado por `python3 scripts/inventario.py` a partir de `docs/imagem/winre-caminhos.txt.gz` (21230 caminhos, lista COMPLETA do indice 2 de `Core_en-us.esd`). Medicao por nome exato, nao documentacao.
Serve para o lead decidir sem perguntar "existe X?". Fonte unica; se a imagem mudar, rode o script e comite.

## 1. Identidade
- Windows 10 build 17763 (1809), edicao Core (Home), en-us; imagem WinRE = indice 2 do ESD (UUP dump).
- Cuidado: o WinRE do dono pode ter sido alterado pelo OEM e ser Pro (componentes mudam). Nao verificado.
- Contagem: 187 executaveis unicos (.exe/.com), 1168 DLLs unicas, 392 drivers .sys, 987 .inf (UTF-16LE: grep ASCII engana).

## 2. Ferramentas de linha de comando: PRESENTE / AUSENTE
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

## 3. TODOS os executaveis (.exe/.com) do WinRE
abortpxe.com ARP.EXE AtBroker.exe attrib.exe audiodg.exe autochk.exe autoconv.exe bcdboot.exe bcdedit.exe bfsvc.exe bmrui.exe bootcfg.exe bootmgr.exe BootRec.exe bootsect.exe chcp.com chkdsk.exe chkntfs.exe CloudRecSvc.exe cmd.exe compact.exe CompPkgSrv.exe conhost.exe convert.exe convertvhd.exe CredentialUIBroker.exe cscript.exe csrss.exe DeviceCensus.exe DiagnosticsHub.StandardCollector.Service.exe diskpart.exe diskraid.exe Dism.exe DismHost.exe dllhost.exe dllhst3g.exe dnscacheugc.exe doskey.exe dpapimig.exe driverquery.exe drvcfg.exe drvinst.exe drvload.exe dtdump.exe Eap3Host.exe esentutl.exe etfsboot.com expand.exe find.exe finger.exe fixmapi.exe fltMC.exe fontdrvhost.exe format.com fsutil.exe ftp.exe hdlscom1.com hdlscom2.com hh.exe HOSTNAME.EXE icacls.exe InfDefaultInstall.exe ipconfig.exe iscsicli.exe lodctr.exe lsass.exe manage-bde.exe MBR2GPT.EXE mcbuilder.exe MdSched.exe memtest.exe mighost.exe mode.com mofcomp.exe more.com mountvol.exe MRINFO.EXE mshta.exe MuiUnattend.exe Narrator.exe nbtstat.exe ndadmin.exe net.exe net1.exe netbtugc.exe netcfg.exe NetCfgNotifyObjectHost.exe netiougc.exe netsh.exe NETSTAT.EXE newdev.exe notepad.exe ntoskrnl.exe ntprint.exe OpenWith.exe pacjsworker.exe PATHPING.EXE PING.EXE PkgMgr.exe PnPUnattend.exe pnputil.exe poqexec.exe powercfg.exe print.exe pxeboot.com rasautou.exe rdrleakdiag.exe recdisc.exe RecEnv.exe recover.exe refsutil.exe reg.exe regedit.exe regedt32.exe Register-CimProvider.exe regsvr32.exe repair-bde.exe replace.exe ResetEngine.exe ResetEngInterfaces.exe ResetPluginHost.exe Robocopy.exe ROUTE.EXE rstrui.exe rundll32.exe runexehelper.exe sacsess.exe sapisvr.exe scrcons.exe services.exe setupplatform.exe sfc.exe smss.exe SpatialAudioLicenseSrv.exe StartRep.exe subst.exe svchost.exe sxstrace.exe sysreset.exe TabTip.exe takeown.exe taskmgr.exe TCPSVCS.EXE TiFileFetcher.exe TiWorker.exe TRACERT.EXE tree.com TrustedInstaller.exe ucsvc.exe unlodctr.exe unsecapp.exe userinit.exe vds.exe vdsldr.exe verifier.exe verifiergui.exe VSSVC.exe WallpaperHost.exe wbadmin.exe wbemtest.exe wbengine.exe wdscapture.exe wdsclient.exe wdsmcast.exe wdsnbp.com WerFault.exe WerFaultSecure.exe wermgr.exe wevtutil.exe wimserv.exe wininit.exe winload.exe winlogon.exe WinMgmt.exe winpeshl.exe winresume.exe wlanext.exe WMIADAP.exe WmiApSrv.exe WMIC.exe WmiPrvSE.exe wowreg32.exe wpeinit.exe wpeutil.exe wpr.exe wscript.exe xcopy.exe

## 4. Bibliotecas por tema (nome exato)
- **wlan/wifi** (24): eapp3hst.dll eappcfg.dll eappcfgui.dll eappgnui.dll eapphost.dll eappprxy.dll eapprovp.dll onex.dll WcnEapPeerProxy.dll WiFiConfigSP.dll WiFiDisplay.dll winlogonext.dll wlanapi.dll wlancfg.dll WLanConn.dll wlandlg.dll wlanhlp.dll wlanmsm.dll wlanpref.dll wlansec.dll wlansvc.dll wlansvcpal.dll wlanui.dll wlanutil.dll
- **bluetooth** (0): -
- **http/rede alto nivel** (32): crypt32.dll dhcpcmonitor.dll dhcpcore.dll dhcpcore6.dll dhcpcsvc.dll dhcpcsvc6.dll dnsapi.dll FWPUCLNT.DLL IPHLPAPI.DLL mswsock.dll msxml3.dll msxml3r.dll msxml6.dll msxml6r.dll netapi32.dll netman.dll nlaapi.dll nsi.dll rasapi32.dll rasman.dll rasmans.dll schannel.dll sspicli.dll urlmon.dll webio.dll winhttp.dll winhttpcom.dll wininet.dll winnsi.dll ws2_32.dll ws2_helper.dll wsock32.dll
- **script/COM** (5): jscript.dll jscript9.dll jscript9diag.dll scrrun.dll vbscript.dll
- **driver/PnP** (13): cfgmgr32.dll devobj.dll DismApi.dll DismCore.dll DismCorePS.dll DismProv.dll drvsetup.dll drvstore.dll newdev.dll pnpui.dll setupapi.dll umpnpmgr.dll wimgapi.dll
- Ausencias que importam (medidas): `wcmsvc.dll`, `netprofm.dll`, `certutil.exe`, `powershell.exe`, `bitsadmin.exe`, `findstr.exe`, `sc.exe`, `tasklist.exe`, `taskkill.exe`, `curl.exe`, `tar.exe`.
  Verifique cada uma pelo nome na secao 2/3/4 antes de decidir; este arquivo e a fonte.

## 5. Drivers (.sys) relacionados a rede/USB/Bluetooth (nome exato)
afd.sys b57nd60a.sys bcmdhd63.sys bcmfn2.sys bcmpciedhd63.sys Dmpusbstor.sys e1e6032e.sys E1G6032E.sys e1i63x64.sys e1y60x64.sys genericusbfn.sys hidusb.sys http.sys mausbhost.sys mausbip.sys mrvlpcie8897.sys ndis.sys ndistapi.sys ndisuio.sys NdisVirtualBus.sys ndiswan.sys NetAdapterCx.sys netbios.sys netbt.sys netio.sys NETJME.sys netvsc.sys nwifi.sys rdbss.sys rt640x64.sys srvnet.sys tcpip.sys USBAUDIO.sys usbccgp.sys usbd.sys usbehci.sys usbhub.sys USBHUB3.SYS usbnet.sys usbohci.sys usbport.sys usbser.sys USBSTOR.SYS usbuhci.sys USBXHCI.SYS vwifibus.sys vwififlt.sys vwifimp.sys WdiWiFi.sys

## 6. Drivers .inf: contagem por pasta
- `/Windows/INF`: 324
- `/Windows/System32`: 8
- `/Windows/WinSxS/amd64_microsoft-windows-i..dsetup-rejuvenation_31bf3856ad364e35_10.0.17763.1_none_435f098468e509d2`: 7
- `/Windows/WinSxS/amd64_microsoft-windows-p..al-securitytemplate_31bf3856ad364e35_10.0.17763.1_none_deae7cdeaaf4edb8`: 6
- `/Windows/System32/ras`: 2
- `/Windows/WinSxS/amd64_microsoft-windows-rasbase_31bf3856ad364e35_10.0.17763.1_none_fea651c6d298b115`: 2
- Wi-Fi no WinRE sem injecao: apenas `mrvlpcie8897.inf` (Marvell 88W8897, nao generico). Detalhe: docs/imagem/DOSSIE.md §6b e docs/evidence/winre-1809-evidencia.md.

## 7. Extensoes (visao geral)
manifest=4356, dll=2785, mui=2224, cat=1835, inf=987, sys=958, mum=654, inf_loc=590, (sem)=507, cdf-ms=411, exe=381, xml=260
