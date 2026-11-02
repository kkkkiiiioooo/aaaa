@echo off
rem diag.cmd - IDs de hardware Wi-Fi/Bluetooth no WinRE 1809 (VEN_/DEV_/VID_/PID_).
rem Uso no WinRE: diag   (resumo na tela p/ foto; completo em X:\diag.txt)
rem
rem POR QUE ESTE SCRIPT EXISTE
rem   O ID de hardware (PCI\VEN_14E4&DEV_4365) fica no NOME DA CHAVE em
rem   HKLM\SYSTEM\CurrentControlSet\Enum\PCI - e nao no valor de um registro.
rem   Por isso "reg query ... /f Wireless /d" (que busca so em DADOS) pode
rem   NAO achar o adaptador defeituoso: e justamente o que ainda nao tem
rem   driver (erro 10), logo sem "Wireless" em nenhum valor.
rem   Aqui a busca e feita nos NOMES das chaves (/k), que e onde o ID vive.
rem
rem   INVENTARIO REAL DO WINRE 1809 (verificado na imagem, build 17763):
rem     reg.exe, netsh.exe, pnputil.exe, find.exe, more.com, tree.com  OK
rem     findstr.exe  AUSENTE  -> nao da para filtrar texto com findstr
rem     sort.exe     AUSENTE
rem     wmic, msinfo32, powershell, certutil   AUSENTES
rem     pnputil /enum-devices  AUSENTE (so existe a partir do Windows 10 1903)
rem   Por isso o filtro NAO depende de findstr: o proprio reg query faz a
rem   selecao (/f ... /k) e, se nao supporter, cai no find.exe (que existe).
rem
rem   IMPORTANTE: roda NO WinRE da maquina do dono, onde o PnP ja enumerou
rem   o hardware real no boot. Le o registro em memoria (o do boot atual),
rem   nao uma imagem de fabrica.
rem
rem SAIDA
rem   X:\diag.txt = log completo
rem   tela        = resumo (para fotografar)

setlocal
set O=X:\diag.txt
set P=X:\pnputil.txt
set W=X:\wlan.txt
set N=X:\net.txt
set I=X:\ip.txt
set D=X:\disk.txt
set T=X:\tmp-id.txt
set A=X:\ids-pci.txt
set B=X:\ids-usb.txt
set CLS={4d36e972-e325-11ce-bfc1-08002be10318}

rem ---------- arvore completa (sempre, sem filtro: e o backup de verdade) ----------
reg query HKLM\SYSTEM\CurrentControlSet\Enum\PCI /s > X:\enum-pci.txt 2>&1
reg query HKLM\SYSTEM\CurrentControlSet\Enum\USB /s > X:\enum-usb.txt 2>&1

rem ---------- IDs: /f + /k = busca nos NOMES das chaves ----------
rem (ordem documentada pela MS: reg query <key> /s /f <dado> /k)
rem Se o reg nao aceitar /f (ou nao achar nada), cai no find.exe, que existe
rem no WinRE 1809. find e case-sensitive, mas os IDs sao sempre em MAIUSCULAS.
reg query HKLM\SYSTEM\CurrentControlSet\Enum\PCI /s /f "VEN_" /k > %T% 2>&1
if errorlevel 1 goto fallback_pci
type %T% > %A%
goto done_pci
:fallback_pci
type X:\enum-pci.txt | find "VEN_" > %A%
:done_pci
reg query HKLM\SYSTEM\CurrentControlSet\Enum\USB /s /f "VID_" /k > %T% 2>&1
if errorlevel 1 goto fallback_usb
type %T% > %B%
goto done_usb
:fallback_usb
type X:\enum-usb.txt | find "VID_" > %B%
:done_usb

rem ---------- demais evidencias, uma por arquivo ----------
reg query HKLM\SYSTEM\CurrentControlSet\Control\Class\%CLS% /s > %N% 2>&1
pnputil /enum-drivers > %P% 2>&1
netsh wlan show drivers > %W% 2>&1
netsh wlan show interfaces >> %W% 2>&1
ipconfig /all > %I% 2>&1
echo list volume > %D%
echo list disk >> %D%
echo exit >> %D%
diskpart /s %D% >> %D% 2>&1

rem ---------- log completo ----------
echo === diag.cmd - diagnostico WinRE 1809 === > %O%
echo. >> %O%
echo --- IDs PCI --- >> %O%
type %A% >> %O% 2>&1
echo. >> %O%
echo --- IDs USB --- >> %O%
type %B% >> %O% 2>&1
echo. >> %O%
echo --- arvore Enum\PCI completa --- >> %O%
type X:\enum-pci.txt >> %O% 2>&1
echo. >> %O%
echo --- arvore Enum\USB completa --- >> %O%
type X:\enum-usb.txt >> %O% 2>&1
echo. >> %O%
echo --- Drivers de rede (classe Net) --- >> %O%
type %N% >> %O% 2>&1
echo. >> %O%
echo --- pnputil /enum-drivers --- >> %O%
type %P% >> %O% 2>&1
echo. >> %O%
echo --- netsh wlan --- >> %O%
type %W% >> %O% 2>&1
echo. >> %O%
echo --- ipconfig /all --- >> %O%
type %I% >> %O% 2>&1
echo. >> %O%
echo --- diskpart (volumes) --- >> %O%
type %D% >> %O% 2>&1

rem ---------- resumo na tela ----------
echo ===================== RESUMO (foto) =====================
echo.
echo --- IDs PCI (VEN_/DEV_) ---
type %A%
echo.
echo --- IDs USB (VID_/PID_) ---
type %B%
echo.
echo --- Drivers de rede presentes ---
type %N%
echo.
echo --- Drivers de terceiros no DriverStore (pnputil /enum-drivers) ---
type %P%
echo.
echo --- netsh wlan (adaptadores WLAN) ---
type %W%
echo.
echo --- volumes (diskpart) ---
type %D%
echo.
echo ==========================================================
echo Log completo em %O%
endlocal
