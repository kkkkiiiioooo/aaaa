#!/bin/sh
# ETAPAS — pipeline do projeto. Uma etapa por vez, com gate objetivo.
#
# Como se usa (é isto que o agente chama, nao editar a mao):
#   sh scripts/etapa.sh status          # quem esta em que etapa, agora
#   sh scripts/etapa.sh pegar    E2     # reclama a etapa (com lease)
#   sh scripts/etapa.sh fechar   E2 "<evidencia>"
#   sh scripts/etapa.sh liberar  E2     # desiste / travou
#
# Regra de orquestracao: ninguem executa etapa sem reclama-la, e ninguem pula gate.
# Lease expira (PADRAO 90 min): agente que morreu nao tranca o projeto para sempre.

## Etapas e gates
| Etapa | Nome | Entrada | Gate de saida (objetivo) |
|---|---|---|---|
| E1 | Ambiente capaz de testar | clone + deps | `doctor.sh` diz T0+T1+T2 e a suíte fecha SUITE: PASS com log em `.work/logs/` |
| E2 | Cobertura de drivers sem ID | E1 | >=1 `.cab` oficial por fabricante (Intel/Realtek/Qualcomm/Broadcom/MediaTek/Marvell) baixado, INF conferido, injetado no Winre.wim e verificado por hash |
| E3 | Autorrun no WinRE | E2 | PE inicia o script sozinho (`winpeshl.ini`), sem tecla, e grava log em disco |
| E4 | Boot real do PE (T3) | E3 | ISO convertida; WinRE bootado em QEMU; log do boot lido no host |
| E5 | Reinstalacao R3/R5 | E4 | `setup.exe` por rede reinstala C: e os drivers voltam pos-OOBE |
| E6 | Entrega | E5 | artefato + runbook de 1 linha, sem passo manual |

## Reclamacoes (append-only; NAO reescreva)
Formato: `E<n> | <agente> | <inicioUTC> | <estado> | <evidencia>`
estado: ativa | feita | liberada
E1 | investigador-ti | 2026-11-03T17:43Z | ativa | -
E3 | claude | 2026-11-03T22:00Z | ativa | -
E1 | investigador-ti | 2026-11-03T17:43Z | feita | .work/logs/bootstrap-teste.log SUITE:PASS 28/0 em 259s TCG; doctor: T0 T1 T2
E2 | investigador-ti | 2026-11-03T17:43Z | ativa | -
E4 | piloto-01 | 2026-11-03T17:48Z | ativa | -
