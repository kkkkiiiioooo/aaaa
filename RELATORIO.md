# RELATORIO (resumo executivo p/ o lead; <=2 KB; agentes NAO lem)
Desafio: restaurar Win10 1809 com C: formatada sem conexao fisica (so WinRE com cmd automatico); entregavel autoexecutavel (PROMPT.md).
Estado: ambiente provado sem kvm/docker (SUITE 28/0 em 259s TCG); WIM 1809 com driver injetado e verificado por hash; pacote offline 317 MB na branch imagem; T3 (ISO + boot.wim + winpeshl.ini) em andamento.
Problemas dificeis (contexto + evidencia + tentado):
- P1: boot PE em TCG pode levar dezenas de minutos (4 GB RAM) e winpeshl.ini como autorun e HIPOTESE nunca testada. Tentado: nada cronometrado ainda.
- P2: driver Wi-Fi sem VEN_/DEV_ real do hardware do dono. Tentado: buscar_driver.py por ID (exige ID conhecido).
- P3: WinRE 1809 nao tem certutil/findstr/powershell: transporte so via SMB (net use), VBScript+WinHTTP ou ftp.
Perguntas ao lead:
- Q1: T3 estourar tempo em TCG: autorizar custo ou rebaixar para evidencia offline?
- Q2: doc diz PASS=27/27 e a suite real e 28: confirmar contagem oficial?
