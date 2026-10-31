# PLANO DE AÇÃO - Recuperação do Windows sem conexões físicas

## Estratégia Geral
**Abordagem:** inventariar os recursos locais **antes** de tentar qualquer alternativa. Com C: formatada e sem rede/mídia física, a solução depende inteiramente do que sobreviveu no disco (imagem de instalação, driver OEM) ou de uma fonte de rede que ainda não existe. O plano segue uma árvore de decisão, e não uma lista cega de tentativas.

**Princípio técnico:** primeiro descobrir os bits disponíveis; depois escolher o caminho que consome esses bits. Sem esse inventário, qualquer tentativa de DISM/driver é especulação.

---

## Fase 0: Diagnóstico e inventário local (BLOQUEANTE)

Executar no `cmd` do WinRE. Registrar todas as saídas em `data.txt`/`STATE.md` antes de avançar.

### 0.1 Confirmar plataforma e firmware
```bat
echo %PROCESSOR_ARCHITECTURE%
wmic os get osarchitecture /value
bcdedit /enum {fwbootmgr}
```
- `{fwbootmgr}` existir indica UEFI; erro indica Legacy/BIOS.

### 0.2 Mapear discos, partições e volumes
```bat
diskpart
  list disk
  select disk 0
  list partition
  list volume
  exit
```
Anotar: tabela (GPT/MBR), tamanho de cada partição, tipo, rótulo e letra atual.

### 0.3 Atribuir letras às partições candidatas
No `diskpart`, para cada volume sem letra que possa conter imagem ou driver:
```bat
select volume N
assign letter=W
```
Sugestão de letras: `W:` recuperação, `D:` dados, `E:` OEM. **Não** usar `C:` para montagem de imagem.

### 0.4 Procurar imagem completa do Windows (install.wim / install.esd / install.swm)
```bat
for %d in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do @if exist %d:\ dir /s /b %d:\install.wim %d:\install.esd %d:\install.swm 2>nul
for %d in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do @if exist %d:\Recovery dir /s /b %d:\Recovery\*.wim %d:\Recovery\*.esd 2>nul
dir /s /b W:\Recovery\WindowsRE\Winre.wim
```
Inventariar também `resetconfig.xml`, `ReAgent.xml` e pastas `Sources`, `Recovery\Customizations`, `OEM`.

### 0.5 Procurar drivers OEM sobreviventes
```bat
for %d in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do @if exist %d:\Windows\System32\DriverStore dir /s /b %d:\Windows\System32\DriverStore\FileRepository\*.inf 2>nul | findstr /i "netwlan wlan iwlwifi iwlw rtwlane rtl8 bcmwl bcmonly athw qcamain"
for %d in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do @if exist %d:\Recovery dir /s /b %d:\Recovery\*.inf 2>nul
for %d in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do @if exist %d:\OEM dir /s /b %d:\OEM\*.inf 2>nul
for %d in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do @if exist %d:\Drivers dir /s /b %d:\Drivers\*.inf 2>nul
```
Se nada for encontrado, **A1 está bloqueado por falta de insumo**.

### 0.6 Inspecionar o conteúdo da partição de recuperação
```bat
dir /a W:\
dir /a W:\Recovery
dir /a W:\Recovery\WindowsRE
dism /Get-WimInfo /WimFile:W:\Recovery\WindowsRE\Winre.wim
```
- Se houver `install.wim`/`install.esd` → **A4 viável**.
- Se houver apenas `Winre.wim` → A4 permite no máximo reabilitar o WinRE, **não** reinstalar o Windows.

### 0.7 Verificar drivers inbox e dispositivos com problema no WinRE
```bat
pnputil /enum-drivers
wmic path Win32_PnPEntity where "ConfigManagerErrorCode=10" get Name,DeviceID,ConfigManagerErrorCode
netsh wlan show interfaces
net start
```
Registrar o **Hardware ID** do adaptador Wi-Fi (ex.: `PCI\VEN_...` ou `SDIO\...`). Sem esse ID não é possível escolher um driver compatível.

**Critério de saída da Fase 0:** existe imagem completa? existe driver OEM? qual o Hardware ID? qual o firmware? Sem respostas, não avançar.

---

## Priorização de Alternativas

### A4 — Restauração a partir da partição de recuperação (Prioridade 1)
**Motivo:** é a única alternativa que produz um Windows completo **sem rede e sem mídia física**, desde que exista uma imagem de instalação local. Também preserva os drivers OEM originais, atendendo R5.
**Pré-requisito:** `install.wim`/`install.esd`/`install.swm` presente na partição de recuperação ou em outro volume sobrevivente.

**Passos:**
1. Identificar a imagem e listar edições/índices:
   ```bat
   dism /Get-WimInfo /WimFile:W:\Sources\install.wim
   ```
2. Validar a imagem montando-a somente para leitura:
   ```bat
   mkdir X:\mountcheck
   dism /Mount-Image /ImageFile:W:\Sources\install.wim /Index:1 /MountDir:X:\mountcheck /ReadOnly
   dism /Image:X:\mountcheck /Cleanup-Image /CheckHealth
   dism /Unmount-Image /MountDir:X:\mountcheck /Discard
   ```
3. Formatar/limpar C: (somente se necessário e após confirmar que C: é a partição correta):
   ```bat
   diskpart
     select volume C
     format quick fs=ntfs label="Windows"
     exit
   ```
4. Aplicar a imagem (escolher o índice correto):
   ```bat
   dism /Apply-Image /ImageFile:W:\Sources\install.wim /Index:1 /ApplyDir:C:\
   ```
   Para `.esd`, o mesmo comando é aceito no Windows 10 1809 (mais lento).
5. Se houver pasta de drivers OEM, injetá-los offline:
   ```bat
   dism /Image:C:\ /Add-Driver /Driver:W:\Drivers /Recurse /Install
   ```
6. Recriar os arquivos de boot. Identificar a ESP (FAT32, ~100 MB) e atribuir letra `S:`:
   ```bat
   bcdboot C:\Windows /s S: /f UEFI /l pt-BR
   ```
   Em Legacy/BIOS: `bcdboot C:\Windows /s S: /f BIOS`.
7. Ajustar a ordem de boot, se necessário (substituir o GUID abaixo pelo identificador do Windows Boot Manager exibido em `bcdedit /enum firmware`):
   ```bat
   bcdedit /enum firmware
   bcdedit /set {fwbootmgr} displayorder {GUID-DO-WINDOWS-BOOT-MANAGER} /addfirst
   ```
8. `wpeutil reboot` e acompanhar o OOBE.

**Status:** [ ] Não testado | [ ] Em teste | [ ] Funcionando | [ ] Falhou

---

### A1 — Injeção de driver Wi-Fi via DISM/drvload (Prioridade 2, condicional)
**Motivo:** resolveria R1/R2 e destravaria A3. Porém **depende de um `.inf` compatível já presente no disco**. Com C: formatada, o DriverStore da instalação antiga não existe; a fonte precisa ser a partição de recuperação, uma pasta OEM sobrevivente ou outro volume.
**Pré-requisito:** arquivo `.inf` + `.sys` + `.cat` compatível com o Hardware ID, acessível localmente.

**Passos:**
1. Carregar o driver no WinRE em execução:
   ```bat
   drvload W:\Drivers\Wlan\nome_do_driver.inf
   pnputil /add-driver W:\Drivers\Wlan\nome_do_driver.inf /install
   ```
2. Reinicializar a rede:
   ```bat
   wpeutil InitializeNetwork
   ipconfig /all
   ```
3. Se o erro 10 persistir, verificar dependências e log:
   ```bat
   type X:\Windows\INF\setupapi.dev.log | findstr /i "wlan wifi error"
   net start
   ```
4. Para persistir no WinRE, montar o `WRE.wim`, injetar e registrar:
   ```bat
   mkdir X:\mount
   dism /Mount-Image /ImageFile:W:\Recovery\WindowsRE\Winre.wim /Index:1 /MountDir:X:\mount
   dism /Image:X:\mount /Add-Driver /Driver:W:\Drivers\Wlan /Recurse /Install
   dism /Unmount-Image /MountDir:X:\mount /Commit
   reagentc /setreimage /path W:\Recovery\WindowsRE
   ```
   **Atenção:** `reagentc` pode não estar disponível/operacional dentro do WinRE; validar antes.
5. Para R5, após aplicar a imagem (A4), injetar o driver em C: com `/Add-Driver`.

**Status:** [ ] Não testado | [ ] Em teste | [ ] Funcionando | [ ] Falhou

---

### A3 — Redefinição do PC com download na nuvem (Prioridade 3, dependente)
**Motivo:** caminho mais simples **se** houver rede.
**Pré-requisito:** A1 ou A2 funcionando + WinRE com `systemreset`/recurso de nuvem. Com C: formatada, o "Reset" local não funciona; somente o download na nuvem.
**Passos:**
1. Confirmar rede (`ping`, `curl`).
2. Executar `systemreset -cleanpc` ou a opção de nuvem no menu de recuperação.
3. Acompanhar download e instalação.

**Status:** [ ] Não testado | [ ] Em teste | [ ] Funcionando | [ ] Falhou

---

### A2 — Bluetooth PAN com celular (DESCARTADA)
**Motivo do descarte:** WinRE 1809 não inclui o stack PAN/NAP nem utilitário de pareamento. Sem interface para parear, não há como iniciar o tethering. Registrado em DECISIONS.md (D002).

**Status:** ❌ Falhou / inviável no ambiente

---

### A5 — Reinstalação por rede (PXE/WDS/HTTP Boot) (Prioridade 4, condicional)
**Motivo:** só é viável se o **firmware** tiver stack de rede e a interface usada for suportada no pré-boot. PXE clássico exige Ethernet; Wi-Fi em UEFI é raro. Sem cabo, a probabilidade é baixa.
**Pré-requisito:** servidor PXE/WDS ou HTTP Boot na LAN + firmware com driver de rede.
**Passos:**
1. `bcdedit /enum {fwbootmgr}` e menu de boot do firmware para verificar "Network Boot"/"HTTP Boot".
2. Testar boot de rede; se não houver interface, descartar.

**Status:** [ ] Não testado | [ ] Em teste | [ ] Funcionando | [ ] Falhou

---

## Árvore de decisão

```
Fase 0
├─ Existe install.wim/esd local?
│  ├─ SIM → A4 (aplicar imagem + bcdboot). Se faltar driver, injetar OEM. FIM.
│  └─ NÃO
│     ├─ Existe driver Wi-Fi OEM local compatível?
│     │  ├─ SIM → A1 (drvload/pnputil) → rede → A3 (nuvem)
│     │  └─ NÃO
│     │     ├─ Firmware tem HTTP Boot/Wi-Fi? → A5 (baixa probabilidade)
│     │     └─ NÃO → IMPOSSÍVEL sem mídia física ou rede; registrar bloqueio.
```

## Critérios de impossibilidade (a declarar formalmente)
O desafio é **tecnicamente impossível** se, simultaneamente:
1. Não existir imagem completa do Windows em nenhum volume local;
2. Não existir driver Wi-Fi compatível em nenhum volume local;
3. Não houver rede funcional (Wi-Fi/Bluetooth) nem boot de rede pelo firmware.

Nesse cenário, nenhuma sequência de comandos cria bits inexistentes. A única saída é alterar uma premissa: permitir uma conexão física, um adaptador USB-Ethernet, um pendrive ou acesso à rede.

---

## Estratégia para R5 (preservação de drivers)
- **Se A4 for usado:** a imagem aplicada é a fonte de drivers. Após o primeiro boot, validar `devmgmt.msc`/`pnputil /enum-devices` e, se o Wi-Fi não subir, injetar o driver OEM com `pnputil /add-driver ... /install` em modo offline antes do boot ou no primeiro logon.
- **Se A1 for usado:** montar a imagem aplicada em C: e injetar o driver Wi-Fi com `dism /Image:C:\ /Add-Driver /Driver:... /Recurse /Install` antes do reboot, garantindo que o driver esteja no DriverStore do sistema reinstalado.
- **Evidência de sucesso:** `netsh wlan show drivers` retorna o driver no Windows reinstalado e o adaptador inicia sem erro 10 após o OOBE.

---

## Instruções para Agentes

1. **Sempre comece pelo AGENTS.md** — entenda o desafio.
2. **Execute a Fase 0 antes de qualquer tentativa** — sem inventário, não há decisão técnica.
3. **Consulte STATE.md** — evite repetir trabalho.
4. **Dúvidas?** Adicione em OPEN_QUESTIONS.md.
5. **Decisões?** Adicione em DECISIONS.md.
6. **Atualize STATE.md** após cada ação.

**NUNCA:**
- Responda no bate-papo.
- Modifique AGENTS.md (apenas o criador pode modificar).
- Apague o trabalho de outros agentes.
- Afirme sucesso sem evidência de execução (saída de comando registrada).
