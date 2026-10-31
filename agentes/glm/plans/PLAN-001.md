# PLAN-001 — Plano de ação do Agente GLM

## Premissas assumidas
- A partição C: está formatada, logo o component store do Windows e o `DriverStore` anteriores foram perdidos.
- A partição de recuperação é **íntegra** e contém `WRE.wim` (conforme AGENTS.md, seção 2).
- O terminal (cmd) é iniciado automaticamente no WinRE e roda com privilégios de SYSTEM em `X:\Windows\System32`.
- O driver Wi-Fi presente no WinRE está incompleto (erro 10 = Code 10, dispositivo não inicia), mas o driver **Bluetooth carrega corretamente**.

## Estimativa de viabilidade das alternativas

| Alt. | Viabilidade | Justificativa técnica |
|------|-------------|----------------------|
| A4 | **Alta (offline, sem dependências)** | Uma partição de recuperação com imagem completa (install/recovery image) permite reaplicar o Windows via `DISM /Apply-Image` direto no cmd, sem rede. Ataca R3 imediatamente. |
| A1 | Média | Depende de localizar o `.inf` + arquivos do driver Wi-Fi *dentro do disco* (partição de recuperação, imagem WIM montável ou pasta de drivers do OEM). Sem fonte local, é um beco sem saída. |
| A2 | Baixa/Média | O stack Bluetooth carrega, mas WinRE não tem perfil PAN nem UI. Em cmd existe `bthprops.cpl`? Não no WinPE. Alternativa: usar o stack via PowerShell/WinRT — improvável no WinRE 1809 (mantém .NET limitado). Serve só como plano C. |
| A3 | Baixa (dependente) | `Cloud recovery` em 1809 não existe nativamente (recurso de 2004+/Win11 via MDM/console). Exige rede (R1) — bloqueada até resolver o driver. |
| A5 | Baixa | Sem servidor PXE/WDS na LAN (premissa do desafio) e sem rede. Descartada nesta fase. |

## Fases executáveis

### Fase 0 — Inventário (cmd no WinRE, ~10 min)
1. `diskpart` → `list disk`, `list vol`, `list part`, `detail vol` de cada volume → identificar letras reais da partição de recuperação e de destino (fonte: `data.txt`).
2. `dir` recursivo na partição de recuperação: localizar `\Recovery\WindowsRE\WRE.wim` e quaisquer pastas `Drivers`, `RecoveryImage`, `PushReset`, `ResetConfig.xml`, `install.wim`/`install.esd`.
3. `dism /Get-WimInfo /WimFile:<letra>:\...\WRE.wim` → descobrir imagem(es) contidas, índice, nome e se é WinPE ou imagem completa de instalação.
4. `pnputil /enum-drivers` no WinRE → ver o que já está no driver store do WinRE.
5. Registrar tudo em `data.txt` e em `STATE.md`. **Commits imediatos a cada fase.**

### Fase 1 — Caminho A4 (R3) — restauração offline
6. Se o WRE.wim contiver imagem completa (índice tipo "Windows 10 ... Home/Pro"):
   - `format` C: já feito; validar ID de partição e etiqueta;
   - `dism /Apply-Image /ImageFile:<img>.wim /Index:N /ApplyDir:C:\`
   - `bcdboot C:\Windows /s <partição EFI> /f UEFI`
   - **R5 (parcial):** antes de aplicar, montar a imagem e usar `dism /Image:<mount> /Get-DriverStore`? Não existe; usar `/Export-Driver` na imagem montada e copiar `C:\Windows\Inf` do apply — instalar drivers pós-boot via `pnputil /add-driver` no Windows reinstalado.
7. Se o WRE.wim for apenas WinPE de OEM: procurar `ResetConfig.xml` + imagem em `RecoveryImage\` e executar o fluxo de push-button reset via `systemreset -factoryreset` (se presente no WinRE) apontando para a partição de recuperação.
8. Se A4 falhar em todos os cenários → marcar nó de decisão e ir à Fase 2.

### Fase 2 — Caminho A1 (R1 + R2) — obter rede para_ENABLE R3 via A3 como último recurso
9. Procurar o driver Wi-Fi em: (a) pastas `Drivers` do OEM na partição de recuperação; (b) dentro de qualquer `.wim`/`.esd` local via `dism /Mount-Image` em `X:\` (WinRE permite montagem em RAM/disco temporário); (c) dentro do próprio driver store do WinRE (extrair .sys/.inf correspondentes e reinstalar com `pnputil /add-driver /install`).
10. Injetar: `dism /Image:X:\ /Add-Driver /Driver:<inf>` **ou** `pnputil` no ambiente live. Validar: `netsh wlan show drivers` + `ipconfig` com IP válido → R1/R2 fechados.
11. Com rede: tentar via cmd baixar mídia oficial (ex.: `setup.exe` da ISO disponível em espelho) para a unidade de trabalho e reinstalar → R3 por A3.

### Fase 3 — Caminho A2 (R4) — só se Fase 2 falhar
12. Verificar presença de `bthport.sys`/`fsquirt` e tentar `netsh bluetooth` (inexistente) — documentar limite real do WinRE 1809 quanto a PAN.
13. Se inviável, registrar contramedida: conectar celular na mesma rede IPv4? Não há rádio. Encerrar A2 com lição documentada.

## Critérios de sucesso
- R3 atendido via A4 (preferencial) ou via A3 com rede da Fase 2.
- R1/R2 demonstrados com saída de `ipconfig`/`netsh wlan`.
- R5: driver Wi-Fi presente após primeiro boot do sistema reinstalado.

## Regras de execução
- Trabalhar apenas em `main`, commits a cada alteração (rule da raiz do repositório).
- Toda evidência crua em `data.txt`; conclusões em `STATE.md`/`DECISIONS.md`; pendências para o humano em `OPEN_QUESTIONS.md`.
