# PLANO DE ACAO (documento do tech lead)

> Mora na branch `relatorio` (a unica que o lead acessa). Agentes leem so este arquivo com `sh scripts/plano.sh`; o lead le `RELATORIO.md` e reescreve este aqui, sem tocar na branch do projeto.

Unico arquivo que o lead escreve e que os agentes leem. Caminho inverso:
`RELATORIO.md` (branch `relatorio`) — resumo executivo que so o lead le.
Dono: tech lead. Agente nao edita.

## Instrucoes para os agentes
- Leia na ordem: este PLANO > AGENTS.md > PROMPT.md > HANDOFF.md. O PLANO manda em prioridade.
- Pegue a frente livre mais alta (`sh scripts/etapa.sh status`); registre antes de comecar.
- Execute os passos exatos; nao pule o aceite; leia a armadilha antes. Falhou: plano B. Sem plano B: `problema.sh` e proxima frente; nao espere o lead.
- Duvida que so o lead resolve: `sh scripts/escalar.sh` (apos 2 tentativas). A resposta aparece abaixo, por id.

## Respostas do lead (por id; o lead reescreve)
(nenhuma)

## Frentes
| # | Frente | Passos exatos | Armadilha | Aceite | Plano B |
|---|---|---|---|---|---|
| 1 | T3 real | `converter_iso.sh` -> ISO; trocar `sources/boot.wim` pelo WIM com driver; `winpeshl.ini` com `SetupCommandLine` para autorun | declarar inviavel sem cronometrar 1 boot em TCG | PE sobe, roda o script sozinho, grava log em disco, log lido no host | estourar tempo TCG: evidencia de conteudo + `winpeshl.ini` validado offline |
| 2 | Drivers sem ID | `buscar_driver.py` em lote (Intel/Realtek/Qualcomm/Broadcom/MediaTek/Marvell) -> `.cab` 1809 -> `injetar_driver.sh` | parar no `VEN_/DEV_` ausente | >=1 INF valido por fabricante injetado e verificado por hash | empacotar todos os chips comuns e deixar o PnP escolher |
| 3 | Autorun | script unico no WinRE: `drvload`, `netsh wlan`, PAN, `pnputil /enum-drivers`, log | `certutil`/`findstr`/`powershell` nao existem no 1809 | nenhuma tecla digitada | transporte por SMB (`net use`), VBScript+WinHTTP ou ftp |
| 4 | R3/R5 | `setup.exe` via rede + `Export-Driver`/`pnputil` pos-OOBE | confiar em A3 com C: formatada sem validar | reinstala e os drivers voltam | A5 (PXE/WDS) ou A3 (reset nuvem) |
