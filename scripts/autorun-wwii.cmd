@echo off
rem autorun-wwii.cmd - WinRE 1809, ZERO tecla, ZERO pause.
rem Permitido: cmd reg netsh pnputil drvload ipconfig net diskpart find type.
rem Proibido: certutil findstr powershell bitsadmin pause msiexec.
setlocal
set LOG=X:\wwii.log
echo === autorun-wwii start === > %LOG%
echo %DATE% %TIME% >> %LOG%

wpeinit >> %LOG% 2>&1

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

if exist %SystemRoot%\System32\diag.cmd call %SystemRoot%\System32\diag.cmd >> %LOG% 2>&1

echo --- pnputil --- >> %LOG%
pnputil /enum-drivers >> %LOG% 2>&1
echo --- netsh wlan --- >> %LOG%
netsh wlan show drivers >> %LOG% 2>&1
netsh wlan show interfaces >> %LOG% 2>&1
echo --- ipconfig --- >> %LOG%
ipconfig /all >> %LOG% 2>&1

for %%D in (C D E F G H) do (
  if exist %%D:\ (
    echo persist %%D: >> %LOG%
    copy /Y %LOG% %%D:\wwii.log >> %LOG% 2>&1
  )
)
echo === autorun-wwii end === >> %LOG%
endlocal
