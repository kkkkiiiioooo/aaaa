# Solução — Recuperação do Windows sem conexões físicas

Estado: proposta técnica baseada em documentação oficial. **Não executada** neste
ambiente (sandbox Linux, sem Windows/WinRE nem virtualização) — ver "Limite de evidência".

## Caminho escolhido
**A1 (injetar driver Wi-Fi no WinRE via DISM)** + **A3 (reset/reinstalação com download
na nuvem)**, com **R5** garantido por export/import do driver set. É a única combinação
que atende R1–R5 sem mídia física e sem cabo. **R4 (Bluetooth PAN)** só é utilizável
depois do Windows reinstalado (WinRE/WinPE não traz utilitário de Bluetooth) — vira plano B,
não caminho primário.

## Matriz de decisão (A × R)
| Alternativa | R1 | R2 | R3 | R4 | R5 | Risco |
|---|---|---|---|---|---|---|
| A1 injetar driver Wi-Fi | ✅ | ✅ | ➖ | ➖ | ➖ | baixo* |
| A2 Bluetooth PAN celular | ❌ | ➖ | ➖ | ✅ | ➖ | alto (sem utilitário no WinRE) |
| A3 reset com download nuvem | precisa rede | precisa rede | ✅ | ➖ | parcial | médio |
| A4 restaurar pela partição | ❌ | ❌ | ✅ | ❌ | ✅ | baixo (exige imagem de fábrica) |
| A5 PXE/WDS | ❌ | ❌ | ✅ | ❌ | ➖ | descartado (exige cabo/ROM) |

\* baixo **se** o driver Wi-Fi existir localmente. Sem fonte local, A1 fica bloqueado por
ausência de insumo (não por dificuldade).

## Runbook (comandos no cmd do WinRE)
0. **Mapear discos/partições**
   `diskpart` → `list volume` (achar a partição de recuperação com `\Recovery\WindowsRE\Winre.wim`).
   `select volume N` → `assign letter=R` → `exit`.
   Preparar rascunho gravável: `select volume C` → `assign letter=C` (formatar se preciso).
1. **R1+R2 — driver Wi-Fi no WinRE (offline, não no ramdisk X:)**
   `dism /Mount-Image /ImageFile:R:\Recovery\WindowsRE\Winre.wim /Index:1 /MountDir:C:\mnt`
   `dism /Image:C:\mnt /Add-Driver /Driver:<pasta-ou-inf-do-driver> /Recurse`
   `dism /Unmount-Image /MountDir:C:\mnt /Commit`
   `wpeutil reboot`
2. **Validar rede no WinRE**
   `netsh wlan show interfaces` · `ipconfig /all`
   (WinRE 1809 precisa do componente WLAN — ver Pressupostos.)
3. **R3 — reinstalar sem mídia física** (duas opções)
   - Nuvem: no WinRE, fluxo de reset com download.
   - Manual: `certutil -urlcache -split -f <URL_do_ISO/ESD> C:\win.iso`
     depois montar (DISM/PowerShell) e rodar `setup.exe` com destino `C:`,
     opção "nada a preservar" (C: já formatado).
4. **R5 — preservar drivers**
   - Antes: `dism /Online /Export-Driver /Destination:R:\DriversOEM` (guardar na partição
     de recuperação, que sobrevive à formatação de C:).
   - Depois do OOBE: `pnputil /add-driver R:\DriversOEM\*.inf /subdirs /install`.
5. **R4 — Bluetooth PAN com celular** (após OOBE)
   Parear em Configurações → Bluetooth; ativar "Compartilhamento de Internet" no celular.

## Pressupostos / riscos
- **Fonte do driver Wi-Fi é obrigatória** (pasta OEM na partição de recuperação ou backup
  de drivers). `C:` formatado apagou o `DriverStore` original.
- **WinRE 1809** não inclui WLAN por padrão; injetar só o driver pode não bastar — se
  `netsh wlan` não existir, é preciso adicionar o **WinPE-WiFi-Package** (ADK, Windows-only)
  ou usar A4 (restaurar pela partição) como plano B.
- **A4** resolve R3 rápido se houver imagem de fábrica na partição (menor risco, menos requisitos).

## Limite de evidência
Não houve execução real: sandbox Linux, sem `/dev/kvm`, qemu, docker ou WinRE. Verificável
aqui: a **lógica** do fluxo e a coerência com a documentação oficial (DISM mount/add-driver,
certutil no WinPE, export-driver). Verificação definitiva exige a máquina real.
