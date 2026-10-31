# PLAN-MAIN — Plano principal (Agente Vibe | Mistral AI | GLM)

Plano principal consolidado, editado continuamente. Substitui os antigos
PLAN-001.md (analise inicial) e PLAN-002.md (roteiro executavel), que foram
mesclados aqui e em PLAN-EXECUCAO.md.

## Objetivo
Restaurar o Windows 10 1809 em C: formatado, via WinRE com cmd, sem nenhuma
conexao fisica (cabos, pendrives, adaptadores).

## Premissas assumidas
- C: formatada: component store e DriverStore anteriores perdidos.
- Particao de recuperacao intacta, com WRE.wim.
- cmd do WinRE roda como SYSTEM a partir de X:\Windows\System32.
- Driver Wi-Fi do WinRE incompleto (erro 10); Bluetooth carrega mas sem utilitario.

## Priorizacao de alternativas
| Ordem | Alternativa | Justificativa | Status |
|-------|-------------|---------------|--------|
| Plano A | A4 Restauracao pela particao de recuperacao | Ataca R3 sem rede, menor risco | definida |
| Plano B | A1 Injecao de driver Wi-Fi no WinRE via DISM | Depende de .inf local, tenta-se apos A4 falhar | definida |
| Plano C | A2 Bluetooth PAN / A3 reset por nuvem | A2 reclassificada como pos-instalacao (D007); A3 exige rede (D004) | definida |
| Descartada | A5 PXE/WDS | Sem servidor na LAN e sem rede (D003) | descartada |

## Fases
| Fase | Descricao | Status | Plano auxiliar |
|------|-----------|--------|----------------|
| 0 | Inventario WinRE (diskpart, dism /Get-WimInfo, pnputil, netcfg) | pendente (executar na VM/maquina) | PLAN-EXECUCAO.md |
| 1 | Aplicar imagem local e reconstruir boot (A4 -> R3) | pendente | PLAN-EXECUCAO.md |
| 2 | Obter/reparar driver Wi-Fi (A1 -> R1, R2) | pendente | PLAN-EXECUCAO.md |
| 3 | Bluetooth PAN pos-instalacao (A2 -> R4) | pendente | PLAN-EXECUCAO.md |
| Final | Preservar drivers apos reinstalacao (R5) | pendente | PLAN-EXECUCAO.md |

## Requisitos atendidos por fase
R1, R2: Fase 2. R3: Fase 1. R4: Fase 3. R5: Fase final. Ver DECISIONS.md (D001-D007).

## Proximo passo
Montar VM Windows 10 1809 (QEMU/KVM) com particao WinRE, reproduzir o cenario
e executar as fases coletando evidencias (regra de autonomia da raiz).
