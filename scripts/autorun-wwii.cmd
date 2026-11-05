@echo off
rem autorun-wwii.cmd - WinRE 1809, ZERO tecla, ZERO pause.
rem Permitido: cmd reg netsh pnputil drvload ipconfig net diskpart find type.
rem Proibido: certutil findstr powershell bitsadmin pause msiexec sc (sc.exe nao esta no WinRE 1809).
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
call :persist

echo --- netsh wlan --- >> %LOG%
netsh wlan show drivers >> %LOG% 2>&1
netsh wlan show interfaces >> %LOG% 2>&1
call :persist

echo --- ipconfig --- >> %LOG%
ipconfig /all >> %LOG% 2>&1
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
