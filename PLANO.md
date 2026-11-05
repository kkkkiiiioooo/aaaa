# PLANO DE ACAO (documento do tech lead)
Mora na branch `relatorio`. Agentes leem so este arquivo com `sh scripts/plano.sh`. Base de decisao: BRIEFING-LEAD.md.

## Ordem de execucao (rodada 2)
1. C1 (sem boot): ler `mrvlpcie8897.inf` no WinRE e dizer se cobre adaptador Wi-Fi. Retorno: docs/retorno/C1.md.
2. C2 (sem boot): extrair do hive SYSTEM o ServiceDll de WlansvcGroup. Retorno: docs/retorno/C2.md.
3. E4: confirmar se o run e2 terminou e se ha log. Se o lease expirou, `sh scripts/watchdog.sh` antes. Retorno: docs/retorno/E4.md.
4. D1, D2, D3 em VM (harness scripts/tests/run-tests.sh). Retorno por id.
5. Firmware: `python3 scripts/checar_firmware.py <pasta>` sobre o pacote real de cada fabricante. Retorno: docs/retorno/FW.md.

## Respostas do lead
D1: copiar wcmsvc.dll e chaves de servico do componente Client-Desktop-Required-Package somente se C2 confirmar o ServiceDll. Passos: wimlib extract do componente, update no boot.wim, reg load/unload das chaves. Aceite: sc query wlansvc sem erro 1060 e netsh wlan show interfaces listando a interface. Plano B: D4.
D2: download por SMB (net use) primeiro; HTTP por cscript/WinHttpRequest como segundo. Aceite: copia de 1 GB validada por tamanho e hash na VM. Plano B: FTP.
D3: dism /Online /Export-Driver para R:\DriversOEM antes do wipe de C:; pnputil no OOBE. Aceite: mesmo numero de INF antes e depois, verificado no harness. Plano B: refazer a coleta na maquina do dono com scripts/diag.cmd.
D4: PAN (R4) como fonte de rede se Wi-Fi nao subir. Aceite: rota e download dentro do WinRE simulado. Plano B: PXE via iPXE (C4).
D5: aceite antes da maquina real = todos os retornos CONFIRMADOS de C1, C2, D1, D2, D3.
D6: se E4 nao gravar log, trocar -hdb por -hda e repetir uma vez. Se falhar de novo, aceitar evidencia offline e registrar o limite.
C1: falta: texto exato do `mrvlpcie8897.inf` mostrando HWIDs de 802.11 (ou prova de que nao cobre).
C2: falta: valor de ServiceDll de WlansvcGroup extraido do hive. Sem ele, D1 nao avanca.
C3: falta: saida de run-tests.sh com a contagem oficial (PAN/fdisk e suite principal).
C4: decisao: iPXE fica como opcao de teste em emulador, nao como caminho de producao, ate haver teste em hardware.
Firmware: erro 10 com driver instalado. Aceite: checar_firmware.py OK sobre o pacote do adaptador do dono e codigo de erro zero em Device Manager ou sc query. Sem isso, nenhum driver conta como funcional.
