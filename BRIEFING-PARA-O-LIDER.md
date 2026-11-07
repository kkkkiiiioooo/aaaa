# BRIEFING DO LEAD — projeto wwii (recuperacao do Windows sem conexao fisica)

## 0. Papel e forma de trabalho
Voce e o tech lead do projeto wwii. Os agentes executam; voce decide o caminho, define a ordem e a aceitacao, e responde no `PLANO-DO-LIDER.md` (branch `lider`). Voce nao investiga o repositorio: use este briefing, o `INDICE-PARA-O-LIDER.md` e os caminhos citados abaixo. Quando um dado faltar, responda `<id>: falta <dado exato>`.

Fontes primarias do wwii, todas no branch `wwii`: `PROMPT.md` (objetivo), `AGENTS.md` (contrato dos agentes), `HANDOFF.md` (estado), `ETAPAS.md` (gates), `PROBLEMAS.md` (quadro), `docs/imagem/DOSSIE.md` (imagem), `docs/evidence/*` (provas).

## 0b. Atualizacao (2026-11-07, reestruturador)
- Ambiente real do desafio (todos os executaveis e bibliotecas do WinRE, presente/ausente): `AMBIENTE-DO-DESAFIO.md` nesta branch. Perguntas do tipo "existe X no WinRE?" estao respondidas la; nao gaste raciocinio nelas.
- E4 foi encerrada INCONCLUSIVA (D6 executado); leases de E4/E5 expiradas. Falta o lead fixar qual transporte vale como aceite (caso p0423333970).
- C2 resolvido por medicao: `wlansvc.dll` nao importa `wcmsvc.dll`. `netsh wlan` provavelmente existe via `wlancfg.dll` (p0502061818). D4 respondido: 0 arquivos `bth` no WinRE.
- Nomes dos arquivos citados abaixo foram atualizados (hifen no lugar de sublinhado; branch `lider`, antes `relatorio`).

## 1. Objetivo (PROMPT.md, secao Objetivo e Requisitos)
Restaurar o Windows 10 1809 com a particao C: formatada, sem cabos, pendrives ou adaptadores. Requisitos:
- R1: rede no WinRE, adaptador sem erro 10 e IP valido.
- R2: driver Wi-Fi instalado e operacional.
- R3: reinstalar o Windows sem midia fisica, do boot ate a tela inicial.
- R4: Bluetooth PAN com celular.
- R5: drivers preservados apos a reinstalacao.
Criterio (PROMPT.md, Como decidir): atender o maximo de R1 a R5 com o menor risco.
Autonomia (PROMPT.md, Autonomia): o dono nao executa nada durante o trabalho. O entregavel precisa rodar sozinho na maquina do dono.
Restricao: o dono digita comandos a mao, sem copiar e colar, entao o caminho precisa de comandos curtos.

## 2. O nucleo complexo (o que voce precisa resolver)
Nao sao problemas isolados. Ha uma cadeia unica que so funciona se cada elo fechar:
1. Rede no WinRE (R1/R2). Sem rede, nao ha download.
2. Fonte da reinstalacao (R3). A imagem tem de chegar ao C: por rede (SMB, HTTP por script ou FTP), porque certutil e powershell nao existem no WinRE (docs/evidence/winre-1809-evidencia.md, tabela "Componente").
3. Preservacao dos drivers (R5). Formatar C: apaga o DriverStore. A particao de recuperacao (R:) sobrevive: o teste fdisk confirma que o md5 do setor 0 nao muda apos o wipe de C: (docs/evidence/ambiente-teste-pan-fdisk.md, ITEM 1).
4. Execucao automatica sem tecla. winpeshl.ini com LaunchApps chama autorun-wwii.cmd (docs/evidence/autorun-winpe.md). Validado offline, nao em boot real.
5. Entrega com comandos curtos (PROMPT.md, Restricao critica).

Dependencia critica: o passo 2 usa rede, e a rede do passo 1 depende de Wi-Fi ou de PAN. O dono nao tem cabo. Se o Wi-Fi falhar no WinRE, SMB e HTTP falham juntos. Por isso o passo 1 e o gargalo do projeto, e o R4 (PAN) e o plano B mais concreto.

## 3. Fatos verificados (com caminho exato)
- Imagem: UUP dump, edicao Core, build 17763 (1809), indice 2 do Core_en-us.esd e o WinRE (docs/imagem/DOSSIE.md, secao 1). sha1 33/33 conferem.
- Tamanho util: o WinRE exportado tem 254 MB, nao os 3,7 GB do download (DOSSIE.md, secao 1b).
- Presentes no WinRE (docs/evidence/winre-1809-evidencia.md, tabela): netsh.exe, netshell.dll, wlancfg.dll, wlanapi.dll, wlanmsm.dll, wlansvc.dll, dism.exe, wpeutil.exe, net.exe, ftp.exe, cscript.exe, winhttp.dll, pilha TCP/IP.
- Ausentes: certutil.exe, powershell.exe, bitsadmin.exe, msiexec.exe, findstr.exe, pnputil /enum-devices (so a partir do 1903; docs/evidence/driver-injecao.md, secao 5).
- Verificado por mim agora no indice 21 230 caminhos (docs/imagem/winre-caminhos.txt.gz): wlansvc.dll e wlancfg.dll presentes; wcmsvc.dll ausente (zero ocorrencias); netprofm.dll ausente; mrvlpcie8897.inf presente em /Windows/INF/.
- INF do WinRE sao UTF-16LE. grep ASCII devolve zero e engana (DOSSIE.md, secao 6b).
- Injecao de driver e reversivel e verificada byte a byte para 6 fabricantes (docs/evidence/drivers-lote.md, secao 4: 17/17 IGUAL).

## 4. Contradicoes que voce precisa decidir (nao foram resolvidas pelos agentes)
C1. Driver Wi-Fi no WinRE. DOSSIE.md (secao 6b) diz que nenhum dos 987 INF do WinRE e sem fio. Mas winre-1809-evidencia.md (conclusao 2) lista mrvlpcie8897.inf (Marvell 88W8897, adaptador Wi-Fi). Eu confirmei o arquivo no indice. Logo, a afirmacao "zero drivers sem fio" esta errada ou usa um criterio que excluiu o Marvell. Impacto: se existe um driver Wi-Fi generico, o R1 pode ter um caminho sem injecao.
C2. wcmsvc.dll. DOSSIE.md (secao 4) afirma, com confianca de cerca de 80 por cento, que o servico WlansvcGroup aponta para wcmsvc.dll, que nao esta na imagem. Confirmei a ausencia do arquivo, mas a ligacao servico para DLL veio de um parser de hive que nao esta no repositorio. O log do boot real (E4) e o teste que fecha isso, e ele nao esta disponivel (secao 5).
C3. Contagem de testes. docs/evidence/ambiente-teste-pan-fdisk.md diz 27/27 PASS. ETAPAS.md diz SUITE 28 PASS / 0 FAIL para E1. A contagem nao foi reconciliada.
C4. Caminho de boot. docs/evidence/solucao.md (versao antiga) previa A1 + A3 e descartava A5 PXE. Depois, boot-winre-iso.md (item 10) mostrou iPXE funcionando no QEMU do sandbox. A5 voltou a ser opcao, mas so testada no emulador.

## 5. Estado das etapas (ETAPAS.md e HANDOFF.md)
- E1 feita: ambiente de teste (QEMU sem KVM) provado. Ver docs/evidence/ambiente-teste.md.
- E2 feita: 6 fabricantes injetados e verificados (drivers-lote.md). O driver e necessario, nao suficiente (DOSSIE, secao 6).
- E3 feita offline: autorun-wwii.cmd, winpeshl.ini, diag.cmd. Teste autorun_offline.py PASS.
- E4 ativa (qoder, desde 22:55Z). Boot real do WinRE em QEMU. Pendencias em docs/evidence/boot-winre-iso.md (secao "Estado do aceite"). A ISO ja bootou (etfsboot carregou o BOOTMGR, item 5).
- Nao verificado: o log do run e2 (.work/logs/e4-boot2.log) nao existe no clone local. Ninguem confirmou se o PE rodou o autorun. O lease da E4 e de 90 min e pode estar expirado.
- E5 e E6 livres.

## 6. Decisoes que cabem a voce
D1. Caminho para R1: copiar wcmsvc.dll e as chaves de servico do componente Client-Desktop-Required-Package (DOSSIE, secao 5) OU injetar o driver Wi-Fi e testar sem o servico (ja consta em C2).
D2. Caminho para R3: download por SMB (net use), por HTTP (cscript + WinHttpRequest) ou por FTP. Sem rede, nao ha R3.
D3. Caminho para R5: export-driver antes do wipe para R:\DriversOEM, depois pnputil no OOBE (winre-1809-evidencia.md, runbook corrigido, passo 4).
D4. Plano B se o Wi-Fi nao subir: PAN (R4) como fonte de rede. Ja simulado em namespaces (ambiente-teste-pan-fdisk.md, ITEM 2), nao em radio real.
D5. Criterio de aceite antes de ir a maquina real: que teste em VM voce exige.
D6. Se a E4 nao confirmar o log: reexecutar, trocar -hdb por -hda, ou aceitar evidencia offline?

## 7. Riscos
- Hardware do dono e desconhecido (HANDOFF.md, Premissas). O PnP escolhe entre os 6 fabricantes.
- A imagem e Core (Home). Se a maquina for Pro, os componentes mudam (DOSSIE, secao 8).
- O WinRE de fabrica pode ter sido alterado por OEM. Nao foi verificado.
- Erro 10 do adaptador (PROMPT.md, Problema 1) so pode ser confirmado com o VEN_/DEV_ do dono, obtido por scripts/diag.cmd no WinRE dele.
- Sem KVM, o boot leva dezenas de minutos (HANDOFF.md, Premissas). Um run pode gastar a janela de lease.

## 8. O que quero de voce (formato de resposta no PLANO-DO-LIDER.md)
Uma entrada por decisao D1 a D6 e por contradicao C1 a C4, ate 600 bytes cada: decisao | passos exatos | criterio de aceite | plano B. Reescreva o PLANO inteiro, sem append.

## 9. Mapa de leitura (para quem for aprofundar)
- Objetivo e requisitos: PROMPT.md.
- Regras dos agentes: AGENTS.md. Arquitetura de cooperacao: docs/ARQUITETURA.md.
- Estado: HANDOFF.md, ETAPAS.md, PROBLEMAS.md, PROGRESS.md (so o fim).
- Imagem e WinRE: docs/imagem/DOSSIE.md, docs/evidence/winre-1809-evidencia.md, docs/imagem/indices.txt, docs/imagem/manifest.txt, docs/imagem/sha1.txt.
- Drivers: docs/evidence/drivers-lote.md, docs/evidence/driver-injecao.md.
- Boot e PE: docs/evidence/autorun-winpe.md, docs/evidence/boot-winre-iso.md.
- Ambiente e PAN: docs/evidence/ambiente-teste.md, docs/evidence/ambiente-teste-pan-fdisk.md.
- Solucao proposta: docs/evidence/solucao.md (desatualizada em A5, ver C4).
- Melhorias de processo (nao afetam o objetivo): SUGESTOES.md. Avanco medido e comparacao de modelos: EVALS.md.

## 10. Correcao (2026-11-05): driver instalado NAO e driver funcionando
- O que a E2 provou: o arquivo existe, o INF casa com o VEN_/DEV_ e os bytes do WinRE conferem (drivers-lote.md, secao 4).
- O que a E2 NAO provou: que o dispositivo inicia. Nao houve boot, nem Device Manager, nem codigo de erro. A propria driver-injecao.md (secao 6) diz isso.
- Sintoma do dono: driver instalado, erro 10. Causa provavel: firmware exigido pelo INF ausente. A E2 nunca verificou arquivos de firmware.
- Acao: `python3 scripts/checar_firmware.py <pasta-do-driver>` (criado nesta rodada, testado com pastas sinteticas, NAO testado em pacote real). Gate E2 no ETAPAS.md foi atualizado para exigir isso.
- Consequencia para D1: qualquer driver Wi-Fi so conta como funcional com codigo de erro observado (sc query, pnputil ou Device Manager) no WinRE ou na maquina do dono.
