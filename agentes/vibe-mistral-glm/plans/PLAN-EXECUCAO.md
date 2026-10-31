# PLAN-002 — Roteiro executável das Fases 0–3 (Agente GLM)

## Premissa
A Fase 0 (inventário) responde grande parte de OQ001–OQ004 de forma autônoma,
no próprio WinRE, sem esperar o dono. Portanto a Fase 0 não está bloqueada (D006).

## Fase 0 — Inventário (registrar saída em data.txt)
```bat
:: 0.1 Discos, partições e letras
diskpart
  list disk
  list volume
  exit

:: 0.2 Localizar a imagem de recuperação
dir /s /b X:\sources\install.wim C:\Recovery 2>nul
for %d in (D E F G H I) do @dir /b %d:\ 2>nul

:: 0.3 Inspecionar o WIM (responde OQ001 sem depender do dono)
dism /Get-WimInfo /WimFile:<caminho>\WRE.wim

:: 0.4 Drivers carregados no WinRE (responde OQ003 parcialmente)
pnputil /enum-drivers

:: 0.5 Placa de rede vista pelo WinPE
netcfg -s -n
```
Interpretação: um WIM de instalação tem índices com nome de edição
(ex.: "Windows 10 Home"); um WinRE OEM tem índice único de recuperação.

## Fase 1 — Reinstalação via imagem local (A4 -> R3)
Se o WIM for de instalação (OQ001 positiva):
```bat
diskpart
  select volume <n>
  format fs=ntfs quick label=Windows
  assign letter=C
  exit
dism /Apply-Image /ImageFile:<caminho>\WRE.wim /Index:1 /ApplyDir:C:\
bcdboot C:\Windows /s S: /f UEFI
bcdedit /store S:\EFI\Microsoft\Boot\BCD /enum
wpeutil reboot
```
Se o WIM for apenas WinRE OEM, A4 não entrega R3; seguir para A1/A2
(rede) e então A3 (systemreset -cleanpc após o primeiro boot).

## Fase 2 — Driver Wi-Fi (A1 -> R1, R2)
```bat
:: Se o .inf existir no disco (OQ002)
dism /Image:X:\ /Add-Driver /Driver:<pasta-do-oem> /Recurse
:: ou, em runtime, para teste imediato:
drvload <caminho>\netwifi.inf
ipconfig /release & ipconfig /renew
```

## Fase 3 — Bluetooth PAN (A2 -> R4, pós-instalação, ver D007)
O WinPE/WinRE 1809 carece de utilitário e de pilha de perfil PAN utilizável;
a PAN com tethering do celular só se torna prática após o primeiro boot.

## Fase final — Preservação de drivers (R5, ver D005)
Antes do wipe final: DISM /Export-Driver sobre a imagem montada e/ou
cópia de C:\Windows\Inf pós /Apply-Image, para reinjeção no primeiro boot.
