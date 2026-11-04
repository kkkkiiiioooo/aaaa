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
E4 | piloto-01 | 2026-11-03T17:48Z | liberada | sem progresso

## Estado da imagem (leia isto antes de reclamar etapa)

IMAGEM 1809 disponivel — 33 arquivos, sha1 33/33 OK. **Dossie: `docs/imagem/DOSSIE.md`**
Nao precisa ter a imagem em disco para aproveitar: `zcat docs/imagem/winre-caminhos.txt.gz | grep -i <algo>`.
Achado que muda o plano: `WlanSvc` = AUTO no hive mas `wcmsvc.dll` NAO existe na imagem
=> driver de WiFi sozinho pode nao bastar (hipotese alta, fecha na E4). `drvload.exe` EXISTE.
E2 | otimizador | 2026-11-04T06:53Z | liberada | lease expirado apos 790min (watchdog)
E3 | otimizador | 2026-11-04T06:53Z | liberada | lease expirado apos 533min (watchdog)
E2 | stackai | 2026-11-04T22:00Z | ativa | -
E2 | stackai | 2026-11-04T22:04Z | feita | docs/evidence/drivers_lote.md 6/6 cab+INF MATCH, Winre.wim 17763, sha256 17/17 IGUAL, inf_utf16.py PASS
E3 | stackai | 2026-11-04T22:04Z | ativa | -
E3 | stackai | 2026-11-04T22:05Z | feita | docs/evidence/autorun_winpe.md offline LaunchApps+autorun injetado; runtime=E4
