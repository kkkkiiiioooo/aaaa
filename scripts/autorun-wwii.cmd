@echo off
rem autorun-wwii.cmd - WinRE 1809, ZERO tecla, ZERO pause.
rem Permitido: cmd reg netsh pnputil drvload ipconfig net diskpart find type.
rem Proibido: certutil findstr powershell bitsadmin pause msiexec.
rem Persistencia incremental (E4, 2026-11-04): cada bloco copia o log para todo volume que
rem existir. Antes o copy so rodava no fim; em PE lento (TCG) ou bugcheck no meio o host nao
rem via rastro nenhum e nao dava para saber em que passo o boot parou.
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
rem Nao pode usar findstr/certutil. Copia simples, sem falha visivel, para todo volume.
for %%D in (C D E F G H) do (
  if exist %%D:\ (
    echo persist %%D: >> %LOG%
    copy /Y %LOG% %%D:\wwii.log >nul 2>&1
  )
)
goto :eof
