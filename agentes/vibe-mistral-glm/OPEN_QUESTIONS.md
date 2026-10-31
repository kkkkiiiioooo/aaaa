# OPEN_QUESTIONS.md — Agente GLM

| ID | Data | Dúvida | Contexto | Impacto | Destinatário |
|----|------|--------|----------|---------|--------------|
| OQ001 | 2026-10-27 | O `WRE.wim` da partição de recuperação é uma **imagem completa de instalação do Windows** (índice de sistema, tipo install.wim) ou apenas uma **imagem WinPE de recuperação OEM** (tipo HP/Dell WRE)? | Define se a Fase 1 (A4) consegue aplicar a imagem direto via `DISM /Apply-Image` ou precisa executar o fluxo de push-button reset (`ResetConfig.xml` / `systemreset`). | Bloqueante para R3 | Dono do desafio |
| OQ002 | 2026-10-27 | A partição de recuperação contém, além do WRE.wim, alguma pasta de **drivers do OEM** (ex.: `$OEM$`, `Drivers`, `RecoveryImage`, `SWSetup`, `eSupport`) ou `ResetConfig.xml`? | Se houver, a Fase 2 (A1) fica viável offline: extrair o driver Wi-Fi do próprio disco sem precisar de rede. | Alto para R1/R2 | Dono do desafio |
| OQ003 | 2026-10-27 | Qual é a **marca/modelo do adaptador Wi-Fi e do Bluetooth** (ex.: Intel AX200, Realtek 8822CE, Qualcomm)? | Permite saber se o `.sys` correto já existe dentro do driver store do WinRE (upgrade do .inf local na Fase 2, item 9c) ou se é necessário obter o INF externamente. | Médio para R1/R2 | Dono do desafio |
| OQ004 | 2026-10-27 | O destino C: formatado permanece uma partição com letra atribuída no diskpart e existe partição **EFI (ESP) intacta**? | Define se `bcdboot` pode reapontar o boot sem recriar o ESP, e se a troca de NM/thread de boot precisa de `fixboot`/`bootrec`. | Médio para R3 | Dono do desafio |
| OQ005 | 2026-10-27 | O `data.txt` está vazio de propósito — deve ser usado como log cru do inventário do WinRE (Fase 0)? | Alinha o formato de registro entre os agentes. | Baixo | Dono do desafio / outros agentes |

## Notas de autossuficiência (2026-10-27)
- OQ001 e OQ003 podem ser respondidas de forma autônoma na Fase 0 (PLAN-002): `dism /Get-WimInfo` revela o tipo do WIM; `pnputil /enum-drivers` e `netcfg -s -n` revelam os adaptadores e drivers presentes no WinRE. O dono só precisa confirmar os casos em que a saída for inconclusiva.
