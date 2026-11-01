@echo off
rem diag.cmd - lista IDs de hardware Wi-Fi/Bluetooth no WinRE (VEN_/DEV_/VID_).
rem Uso no WinRE: diag   (resumo na tela p/ foto; completo em X:\diag.txt)
rem Obs: le o hive SYSTEM do proprio WinRE = so dispositivos presentes neste boot.
set O=X:\diag.txt
echo === PCI > %O%
for %%k in (Network Wireless Wi-Fi 802.11) do reg query HKLM\SYSTEM\CurrentControlSet\Enum\PCI /s /d /f %%k >> %O% 2>&1
echo === USB-BT >> %O%
reg query HKLM\SYSTEM\CurrentControlSet\Enum\USB /s /d /f Bluetooth >> %O% 2>&1
echo === WLAN >> %O%
netsh wlan show drivers >> %O% 2>&1
echo === IP >> %O%
ipconfig >> %O% 2>&1
findstr /i "=== VEN_ VID_ DeviceDesc Driver" %O% | more
