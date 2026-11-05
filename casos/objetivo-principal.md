# OBJETIVO PRINCIPAL: restaurar Windows 10 1809 com C: formatada, sem conexao fisica, executado sozinho

Fonte: PROMPT.md (wwii) — requisitos R1 rede no WinRE, R2 Wi-Fi operacional, R3 reinstalar sem midia, R4 Bluetooth PAN, R5 drivers preservados.

## Problema central (complexo, nao e detalhe)
Precisamos de uma cadeia unica que funcione so com o WinRE:
1. Rede no WinRE. O WinRE 1809 tem netsh, wlancfg e wlanapi, mas falta wcmsvc.dll (docs/imagem/DOSSIE.md). Driver Wi-Fi sozinho pode nao bastar. Driver ainda nao foi validado no hardware real do dono.
2. Fonte da reinstalacao. R3 exige baixar imagem/ESD com a rede do WinRE. O WinRE nao tem certutil nem powershell (docs/evidence/winre_1809_evidencia.md), entao o download depende de SMB, VBScript+WinHTTP ou ftp, ainda nao testados em VM.
3. Persistencia. Formatar C: apaga o DriverStore. O unico armazenamento que sobrevive e a particao de recuperacao (R:). R5 depende de exportar os drivers para la antes da formatacao.
4. Execucao automatica sem tecla. winpeshl.ini com LaunchApps chama autorun-wwii.cmd (validado offline em E3). Falta provar no boot real (E4).
5. Entrega sem digitacao longa. O dono digita tudo a mao, sem copiar e colar, entao o comando de entrada precisa ser curto.

## Caminho candidato (decisao do lead)
A1 driver no WinRE + A3 reinstalacao com download + export de drivers para R: (solucao em docs/evidence/solucao.md, nao executada).
Alternativas: A4 restaurar pela particao de recuperacao (exige imagem de fabrica, ainda nao verificada); A5 PXE via iPXE (testado so no QEMU do sandbox, em boot_winre_iso.md item 10).

## Perguntas ao lead
- Q1: entre A3 (download) e A4 (imagem de fabrica), qual cadeia fecha R1 a R5 com menos passos manuais?
- Q2: como garantir R1 sem wcmsvc.dll: copiar da install.wim ou outra fonte?
- Q3: quais testes em VM bastam para aceitar a cadeia antes do hardware real?
- Q4: o que fazer se o run E4 nao confirmar o log? Nao ha evidencia local do run.
