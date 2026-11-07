# EVALS — como medir avanço real e comparar modelos (wwii)

Medir: `sh scripts/evals.sh` (só lê). Primeira menção de uma ideia: `sh scripts/quem-primeiro.sh "<termo>"`.
Todo agente informa o modelo exato ao entrar (`iniciar.sh ... M=<modelo>` ou `sh scripts/registrar_ambiente.sh <nome> <modelo>`).

## 1. Níveis de evidência (N, para não confundir com etapas E)
| Nível | Significa | Vale como |
|---|---|---|
| N0 | hipótese, nada medido | ideia |
| N1 | medido offline (arquivo, hive, PE, lista de caminhos) | fato sobre a imagem |
| N2 | emulado/VM (namespaces, QEMU TCG) | simulação, diferença documentada |
| N3 | WinRE bootado com log lido no host | prova de execução |
| N4 | máquina real do dono (`diag.cmd`) | prova final |

## 2. Requisitos: nível máximo provado hoje (atualize com evidência, nunca por opinião)
| Req | Nível | Prova |
|---|---|---|
| R1 rede no WinRE | N1 | driver injetado e hash conferido (`docs/evidence/drivers-lote.md`); sem boot real |
| R2 driver Wi-Fi operacional | N1 | `netsh wlan` provavelmente existe via `wlancfg.dll` (`docs/evidence/netsh-wlan-existe.md`); sem runtime |
| R3 reinstalar sem mídia | N0 | plano HTTP do lead (D2); nada executado |
| R4 Bluetooth PAN | N1 | 0 arquivos `bth` no WinRE: PAN só no Windows instalado (`docs/imagem/INVENTARIO.md` §4) |
| R5 drivers preservados | N1 | `R:` sobrevive ao wipe de C: no teste fdisk (`docs/evidence/ambiente-teste-pan-fdisk.md`) |

Regra: subir de nível exige comando + saída literal em `docs/evidence/`. Presença de arquivo não prova funcionamento.

## 3. Como avaliar uma proposta (0–2 por critério, máximo 12)
1. **Cobertura**: quantos de R1–R5 atende, e em que nível.
2. **Risco**: nada destrutivo na máquina do dono antes de passar por N3 (decisão D5 do lead).
3. **Comandos curtos**: o dono digita tudo à mão, sem copiar e colar.
4. **Ambiente real**: usa só o que existe no WinRE (`docs/imagem/INVENTARIO.md`); nomeia o que falta.
5. **Honestidade**: separa hipótese de fato, registra a tentativa que refutou a própria ideia.
6. **Novidade**: ideia que ninguém havia registrado (ver `quem-primeiro.sh`); repetir o que já falhou vale 0.
Registro: `sh scripts/mural.sh proposta "<ideia>" R1,R3 N1`. Outros agentes pontuam com `apoio`, `critica` ou `refuta`.

## 4. Pegadinhas conhecidas (cada uma já custou uma rodada; quem cai perde ponto de honestidade)
| # | Pegadinha | Verdade medida |
|---|---|---|
| T1 | "Não há driver Wi-Fi no WinRE" | `mrvlpcie8897.inf` existe, mas só cobre Marvell 88W8897 |
| T2 | "`netsh wlan` não existe (falta `wlancmds.dll`)" | o helper é `wlancfg.dll`; `wlancmds.dll` era premissa errada |
| T3 | "Sem `wcmsvc.dll` o Wi-Fi não sobe" | `wlansvc.dll` não importa wcm e testa `WCMPresent` |
| T4 | grep ASCII em INF = zero resultado | INF do WinRE é UTF-16LE |
| T5 | "Wi-Fi operacional" porque o arquivo está lá | só vale com código de erro lido (`Device Manager`/`pnputil` na VM ou real) |
| T6 | `certutil`, `powershell`, `findstr`, `sc`, `curl` no WinRE | ausentes (ver INVENTARIO §2) |
| T7 | Repetir o boot TCG+CD de 1800 s | já falhou; mude uma variável estrutural (transporte ou máquina real) |
| T8 | Medir "o sandbox tem X" e generalizar | cada agente tem ambiente próprio (`ambientes/<nome>.md`) |

## 5. Placar por agente/modelo (preencha a partir do `evals.sh`; uma linha por rodada concluída)
Formato: `data | agente | modelo | proposta (id do mural) | nota 0-12 | nível máximo | cai em pegadinha?`
| data | agente | modelo | proposta | nota | nível | pegadinha |
|---|---|---|---|---|---|---|
| (vazio: nenhuma rodada pontuada ainda) | | | | | | |

## 6. A ideia do dono
O dono tem uma solução em mente que ainda não apareceu. Para descobrir quem a cita primeiro, ele roda
`sh scripts/quem-primeiro.sh "<palavra-chave>"` (aceita regex) quando quiser. Nada precisa ser escrito aqui.
