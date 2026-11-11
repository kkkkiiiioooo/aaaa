@echo off
rem autorun-wwii.cmd - WinRE 1809, ZERO tecla, ZERO pause.
rem Permitido: cmd reg netsh pnputil drvload ipconfig net diskpart find type.
rem Proibido: certutil findstr powershell bitsadmin curl pause msiexec sc tasklist taskkill (nenhum deles esta no WinRE 1809; conferido por nome exato na lista de caminhos).
rem
rem Persistencia em DOIS canais (PLANO DO LIDER D6, 2026-11-04):
rem   1) COM1 - o host escuta com -serial file:, entao o log chega ao host mesmo sem
rem      disco, sem rede e mesmo se o volume FAT nao for enumerado pelo PE;
rem   2) todo volume que existir (C:..H:) - copia do arquivo, para quando o disco funcionar.
rem Antes o copy so rodava no fim: em PE lento (TCG) ou bugcheck no meio o host nao via
rem rastro nenhum e nao dava para saber em que passo o boot parou.
setlocal
set LOG=X:\wwii.log
echo === autorun-wwii start === > %LOG%
echo %DATE% %TIME% >> %LOG%
call :persist

wpeinit >> %LOG% 2>&1
call :persist

for %%I in (
  netwtw06.inf
  netrtwlane.inf
  netathr10x.inf
  bcmwdi.inf
  mtkwl6ex.inf
  mrvlpcie8897.inf
) do (
  if exist %SystemRoot%\INF\%%I (
    echo drvload %%I >> %LOG%
    drvload %SystemRoot%\INF\%%I >> %LOG% 2>&1
  )
)
call :persist

echo --- diag --- >> %LOG%
if exist %SystemRoot%\System32\diag.cmd call %SystemRoot%\System32\diag.cmd >> %LOG% 2>&1
call :persist

echo --- pnputil --- >> %LOG%
pnputil /enum-drivers >> %LOG% 2>&1
call :persist

rem D1 do lead: aceite de Wi-Fi = wlansvc RODANDO + netsh lista a interface.
rem sc.exe nao existe no WinRE 1809, entao "net start" e o que prova o servico.
echo --- net start --- >> %LOG%
net start >> %LOG% 2>&1
net start wlansvc >> %LOG% 2>&1
net start >> %LOG% 2>&1
call :persist

echo --- netsh wlan --- >> %LOG%
netsh wlan show drivers >> %LOG% 2>&1
netsh wlan show interfaces >> %LOG% 2>&1
rem D1 (a): se existir wifi.xml em algum volume (perfil exportado, connectionMode=auto), carrega e deixa conectar.
for %%D in (C D E F G H) do (
  if exist %%D:\wifi.xml (
    echo add profile %%D:\wifi.xml >> %LOG%
    netsh wlan add profile filename=%%D:\wifi.xml >> %LOG% 2>&1
  )
)
netsh wlan show profiles >> %LOG% 2>&1
netsh wlan show networks >> %LOG% 2>&1
call :persist

echo --- ipconfig --- >> %LOG%
ipconfig /all >> %LOG% 2>&1
call :persist

rem --- D2 do lead: download HTTP (cscript + WinHttpRequest) ---
rem O WinRE 1809 nao tem certutil nem powershell (conferido por nome exato), entao o
rem transporte do ESD e o scripts/download.vbs. A URL vem de um arquivo
rem (wwii-url.txt) em qualquer volume; sem ele, usa a URL do ambiente emulado
rem (10.0.2.2 = o host do QEMU na rede slirp).
echo --- download HTTP (D2) --- >> %LOG%
set URL=
if exist C:\wwii-url.txt set /p URL=<C:\wwii-url.txt
if not defined URL if exist X:\wwii-url.txt set /p URL=<X:\wwii-url.txt
if not defined URL set URL=http://10.0.2.2:8000/wwii-teste.bin
echo url: %URL% >> %LOG%
if exist %SystemRoot%\System32\download.vbs (
  cscript //nologo %SystemRoot%\System32\download.vbs %URL% C:\wwii-download.bin >> %LOG% 2>&1
) else (
  echo download.vbs AUSENTE na imagem >> %LOG%
)
call :persist

rem --- D2 do lead, PLANO B: ftp.exe ---
rem Medido em 2026-11-07: o download.vbs (HTTP) CHEGA no servidor dentro do PE, mas
rem nao consegue gravar o corpo da resposta: o WinRE 1809 nao tem ADODB.Stream
rem (falta WinPE-MDAC). O ftp.exe existe na imagem e grava binario nativamente.
echo --- download FTP (D2 plano B) --- >> %LOG%
if exist %SystemRoot%\System32\ftp.exe (
  echo open 10.0.2.2> %SystemDrive%\ftp.txt
  echo user anonymous anonymous>> %SystemDrive%\ftp.txt
  echo binary>> %SystemDrive%\ftp.txt
  echo get wwii-teste.bin C:\wwii-ftp.bin>> %SystemDrive%\ftp.txt
  echo bye>> %SystemDrive%\ftp.txt
  rem medido em 2026-11-07: o ftp.exe do WinRE 1809 manda PORT (modo ATIVO) e o
  rem NAT/slirp nao honra a conexao de dados ("500 Illegal PORT command / 425 Use
  rem PORT or PASV first"), com login e modo binario OK. O ftp.exe nao tem switch
  de modo passivo nesta versao.
  ftp.exe -n -s:%SystemDrive%\ftp.txt >> %LOG% 2>&1
) else (
  echo ftp.exe AUSENTE na imagem >> %LOG%
)
call :persist

rem --- D2: download em JScript (grava binario sem ADODB, que nao existe no 1809) ---
echo --- fso unicode pack (E5 escrita binaria) --- >> %LOG%
if exist %SystemRoot%\System32\teste-fso-binario.js (
  cscript //nologo %SystemRoot%\System32\teste-fso-binario.js C:\fso-t >> %LOG% 2>&1
) else (
  echo teste-fso-binario.js AUSENTE na imagem >> %LOG%
)
call :persist

echo --- msxml binario (E5 ResponseBody sem ADODB) --- >> %LOG%
if exist %SystemRoot%\System32\teste-msxml-binario.js (
  cscript //nologo %SystemRoot%\System32\teste-msxml-binario.js C:\msxml-t >> %LOG% 2>&1
) else (
  echo teste-msxml-binario.js AUSENTE na imagem >> %LOG%
)
call :persist

echo --- download HTTP JS (D2) --- >> %LOG%
if exist %SystemRoot%\System32\download-js.js (
  cscript //nologo %SystemRoot%\System32\download-js.js %URL% C:\wwii-js.bin >> %LOG% 2>&1
  cscript //nologo %SystemRoot%\System32\download-js.js http://10.0.2.2:8000/wwii-256.bin.b64 C:\wwii-256.bin b64 >> %LOG% 2>&1
  cscript //nologo %SystemRoot%\System32\download-js.js http://10.0.2.2:8000/wwii-256.bin C:\wwii-256.raw unicode >> %LOG% 2>&1
) else (
  echo download-js.js AUSENTE na imagem >> %LOG%
)
call :persist

echo === autorun-wwii end === >> %LOG%
call :persist
endlocal
exit /b 0

:persist
rem Canal 1: serial. Se COM1 nao existir no PE, o erro e engolido e o disco ainda vale.
type %LOG% > COM1 2>nul
rem Canal 2: todo volume. Copia simples, sem falha visivel.
for %%D in (C D E F G H) do (
  if exist %%D:\ (
    echo persist %%D: >> %LOG%
    copy /Y %LOG% %%D:\wwii.log >nul 2>&1
  )
)
goto :eof
