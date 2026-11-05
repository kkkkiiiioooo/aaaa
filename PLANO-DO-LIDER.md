# PLANO DO LIDER
STATUS: AGUARDANDO DECISAO DO LIDER. Nenhuma decisao foi tomada ainda.
Este arquivo NAO contem diretrizes para os agentes. Ate o lider escrever aqui, os agentes NAO devem executar nenhuma frente deste plano.

## Perguntas para o lider decidir (sem resposta ainda)
- D1: copiar wcmsvc.dll e chaves de servico do componente Client-Desktop-Required-Package? Depende de C2 (ServiceDll de WlansvcGroup). Opcoes: (a) copiar; (b) pular e ir ao D4.
- D2: rede para baixar a reinstalacao: SMB, HTTP por cscript/WinHttpRequest ou FTP. Escolha e criterio de aceite.
- D3: preservacao de drivers: Export-Driver para R: antes do wipe de C:, ou outra fonte. Escolha e aceite.
- D4: PAN (R4) como fonte de rede se o Wi-Fi nao subir: sim ou nao.
- D5: criterio de aceite antes da maquina real: quais retornos precisam estar CONFIRMADOS.
- D6: se o run E4 nao gravar log: repetir com -hda, aceitar evidencia offline, ou outro caminho.
- C1: confirmar se mrvlpcie8897.inf cobre adaptador 802.11 (o DOSSIE diz que nao ha driver sem fio; a evidencia do WinRE lista esse arquivo).
- C2: ServiceDll de WlansvcGroup (nao esta no repositorio).
- C3: contagem oficial de testes (27/27 ou 28/28).
- C4: iPXE como opcao de producao ou so de emulador.
- FW: erro 10 com driver instalado: firmware ausente? Aceite com checar_firmware.py e codigo de erro.

## Respostas do lider
(vazio)
