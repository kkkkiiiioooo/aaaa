# PLANO DE ACAO (documento do tech lead)

Unico arquivo que o lead escreve e que os agentes leem. Caminho inverso:
`RELATORIO.md` (branch `relatorio`) — resumo executivo que so o lead le.
Dono: tech lead. Agente nao edita (hook `pre-commit` recusa sem `LEAD=1`).

## Protocolo do lead (leia 1x; siga sempre)
1. Entrada unica: `RELATORIO.md` inteiro (resumo executivo <=2 KB: desafio,
   estado, problemas dificeis com evidencia, perguntas). Nada mais; nao investigue o projeto.
2. Reescreva ESTE arquivo inteiro (nunca append). Teto: 4 KB.
3. Seu valor e o que o modelo basico nao pensa: para cada frente deixe
   passos exatos, armadilha nao-obvia, aceite mensuravel e plano B.
4. Veredito -> acao: PASS = frente fechada; FAIL = plano B; PARCIAL =
   repriorizar; BLOQUEIO-EVIDENCIADO = reabrir com contorno novo.
5. Responda cada pergunta do resumo aqui; o agente a remove do RELATORIO.
6. Frente sem acrescento nao-obvio: remova-a (deixe "siga PROMPT.md").

## Instrucoes para os agentes
- Leia na ordem: PLANO.md > AGENTS.md > PROMPT.md > HANDOFF.md. PLANO manda em prioridade.
- Pegue a frente livre mais alta (`sh scripts/etapa.sh status`); registre antes de comecar.
- Execute os passos exatos; nao pule o aceite. Leia a armadilha antes de rodar.
- Falhou? Siga o plano B. Sem plano B? Registre em `ETAPAS.md` e va para a proxima frente; nao espere o lead.
- RELATORIO.md = resumo executivo do lead (<=2 KB), atualizado CONFORME os problemas
  surgem, so pelo `scripts/relatorio.sh`: `problema "P<n>: contexto+evidencia+tentado"` ·
  `problema -P<n>` (resolvido) · `pergunta "Q<n>: ..."` · `pergunta -Q<n>` (respondida
  no PLANO) · `estado "<provado + onde + proximo>"` no fim da rodada.

## Frentes
| # | Frente | Passos exatos | Armadilha | Aceite | Plano B |
|---|---|---|---|---|---|
| 1 | T3 real | `converter_iso.sh` -> ISO; trocar `sources/boot.wim` pelo WIM com driver; `winpeshl.ini` com `SetupCommandLine` para autorun | declarar inviavel sem cronometrar 1 boot em TCG | PE sobe, roda o script sozinho, grava log em disco, log lido no host | estourar tempo TCG: evidencia de conteudo + `winpeshl.ini` validado offline |
| 2 | Drivers sem ID | `buscar_driver.py` em lote (Intel/Realtek/Qualcomm/Broadcom/MediaTek/Marvell) -> `.cab` 1809 -> `injetar_driver.sh` | parar no `VEN_/DEV_` ausente | >=1 INF valido por fabricante injetado e verificado por hash | empacotar todos os chips comuns e deixar o PnP escolher |
| 3 | Autorun | script unico no WinRE: `drvload`, `netsh wlan`, PAN, `pnputil /enum-drivers`, log | `certutil`/`findstr`/`powershell` nao existem no 1809 | nenhuma tecla digitada | transporte por SMB (`net use`), VBScript+WinHTTP ou ftp |
| 4 | R3/R5 | `setup.exe` via rede + `Export-Driver`/`pnputil` pos-OOBE | confiar em A3 com C: formatada sem validar | reinstala e os drivers voltam | A5 (PXE/WDS) ou A3 (reset nuvem) |
