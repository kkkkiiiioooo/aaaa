# PLANO DE ACAO (resposta do tech lead)

Unico arquivo que o lead escreve e que os agentes leem. O caminho inverso e
`RELATORIO.md`, na branch `relatorio`, que os agentes NAO leem.

Dono: tech lead. Agente nao-edita (o hook `pre-commit` recusa sem `LEAD=1`).
Regra de formato do lead: 1 linha por frente, com veredito e criterio de aceite.

## Direcao atual
| # | Frente | O que fazer | Criterio de aceite | Nao fazer |
|---|---|---|---|---|
| 1 | T3 real | `converter_iso.sh` -> ISO; trocar `sources/boot.wim` pelo WIM com driver; `winpeshl.ini` com `SetupCommandLine` para autorrun | PE sobe, roda o script sozinho e grava log em disco; log lido no host | declarar inviavel sem ter cronometrado 1 boot em TCG |
| 2 | Drivers sem ID | `buscar_driver.py` em lote (Intel/Realtek/Qualcomm/Broadcom/MediaTek/Marvell) -> `.cab` 1809 -> `injetar_driver.sh` | >=1 INF valido por fabricante injetado e verificado por hash | parar no `VEN_/DEV_` ausente |
| 3 | Autorun | script unico no WinRE: `drvload`, `netsh wlan`, PAN, `pnputil /enum-drivers`, log | sem nenhuma tecla digitada | `certutil`/`findstr`/`powershell` (nao existem no 1809) |
| 4 | R3/R5 | `setup.exe` via rede + `Export-Driver`/`pnputil` pos-OOBE | reinstala e os drivers voltam | confiar em A3 com C: formatada sem validar |

## Padrao de reporte do agente (fim da rodada)
`sh scripts/relatorio.sh "<veredito>" "<prova>" "<proximo>"` - 1 linha, sem prosa.
Veredito e uma palavra: PASS / FAIL / PARCIAL / BLOQUEIO-EVIDENCIADO.

## O que o lead precisa decidir agora
1. Manter a branch `relatorio` no remoto (foi criada automaticamente no primeiro teste).
2. Substituir `PASS=27/27` da documentacao pela contagem real da suíte (28 linhas).
3. Se o T3 estourar tempo em TCG: autorizar custo (espera longa) ou rebaixar para
   evidencia de conteudo + `winpeshl.ini` validado offline.
