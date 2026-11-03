# PLANO DE ACAO (documento do tech lead)

Unico arquivo que o lead escreve e que os agentes leem. Caminho inverso:
\`RELATORIO.md\` (branch \`relatorio\`) — agentes NAO leem.
Dono: tech lead. Agente nao edita (hook \`pre-commit\` recusa sem \`LEAD=1\`).

## Protocolo do lead (leia 1x; siga sempre)
1. Entrada minima: \`RELATORIO.md\` inteiro + \`tail -20 HANDOFF.md\` + \`tail -5 CHAT.md\`. Nada mais.
2. Reescreva ESTE arquivo inteiro (nunca append). Teto: 4 KB.
3. Seu valor e o que o modelo basico nao pensa: para cada frente deixe
   passos exatos, armadilha nao-obvia, aceite mensuravel e plano B.
4. Veredito -> acao: PASS = frente fechada; FAIL = plano B; PARCIAL =
   repriorizar; BLOQUEIO-EVIDENCIADO = reabrir com contorno novo.
5. Frente sem acrescento nao-obvio: remova-a (deixe "siga PROMPT.md").

## Instrucoes para os agentes
- Leia na ordem: PLANO.md > AGENTS.md > PROMPT.md > HANDOFF.md. PLANO manda em prioridade.
- Pegue a frente livre mais alta (\`sh scripts/etapa.sh status\`); registre antes de comecar.
- Execute os passos exatos; nao pule o aceite. Leia a armadilha antes de rodar.
- Falhou? Siga o plano B. Sem plano B? Registre em \`ETAPAS.md\` e va para a proxima frente; nao espere o lead.
- Fim de rodada = 1 linha: \`sh scripts/relatorio.sh "<veredito>" "<prova>" "<proximo>"\`.

## Frentes
| # | Frente | Passos exatos | Armadilha | Aceite | Plano B |
|---|---|---|---|---|---|
| 1 | T3 real | \`converter_iso.sh\` -> ISO; trocar \`sources/boot.wim\` pelo WIM com driver; \`winpeshl.ini\` com \`SetupCommandLine\` para autorun | declarar inviavel sem cronometrar 1 boot em TCG | PE sobe, roda o script sozinho, grava log em disco, log lido no host | estourar tempo TCG: evidencia de conteudo + \`winpeshl.ini\` validado offline |
| 2 | Drivers sem ID | \`buscar_driver.py\` em lote (Intel/Realtek/Qualcomm/Broadcom/MediaTek/Marvell) -> \`.cab\` 1809 -> \`injetar_driver.sh\` | parar no \`VEN_/DEV_\` ausente | >=1 INF valido por fabricante injetado e verificado por hash | empacotar todos os chips comuns e deixar o PnP escolher |
| 3 | Autorun | script unico no WinRE: \`drvload\`, \`netsh wlan\`, PAN, \`pnputil /enum-drivers\`, log | \`certutil\`/\`findstr\`/\`powershell\` nao existem no 1809 | nenhuma tecla digitada | transporte por SMB (\`net use\`), VBScript+WinHTTP ou ftp |
| 4 | R3/R5 | \`setup.exe\` via rede + \`Export-Driver\`/\`pnputil\` pos-OOBE | confiar em A3 com C: formatada sem validar | reinstala e os drivers voltam | A5 (PXE/WDS) ou A3 (reset nuvem) |

## Decisoes abertas do lead
1. Manter branch \`relatorio\` no remoto (criada no 1o teste).
2. Corrigir \`PASS=27/27\` na documentacao: contagem real e 28.
3. T3 estourar tempo em TCG: autorizar custo ou rebaixar para evidencia offline (ja no plano B da frente 1).
