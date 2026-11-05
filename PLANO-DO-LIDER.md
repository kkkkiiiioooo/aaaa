# PLANO DO LIDER
STATUS: DECIDIDO (rodada 2). Formato: decisao | passos | aceite | plano B. Nada destrutivo na maquina do dono antes de D5.

## Respostas do lider
D1: Testar sem wcmsvc.dll primeiro | injetar driver, drvload, sc query wlansvc, netsh wlan show drivers | wlansvc RUNNING e netsh lista a interface | so se falhar por wcmsvc, copiar dele do install.wim indice 1 (Core) | D4.
D2: HTTP (cscript+WinHttpRequest), nao SMB | script baixa ESD para R:\ em partes, retoma por Range | dism /Get-WimInfo le o arquivo e tamanho igual ao manifest | FTP (ftp -s:arquivo).
D3: Export antes do wipe | dism /Image:C:\ /Export-Driver /Destination:R:\DriversOEM, so se C: ainda existir | .inf em R:\DriversOEM > 0 e sobrevive ao wipe no teste | exportar de pasta do pacote do fabricante.
D4: Sim, plano B, mas verificar antes | procurar bthserv e bthprops no winre-caminhos.txt.gz | componentes presentes; senao PAN morre | sem BT no WinRE: PAN so no Windows instalado (R5 parcial).
D5: Nao ir a maquina real sem: E4 com log do autorun + download HTTP em NIC emulada + dism apply em disco virtual; e diag.cmd (somente leitura) rodado no hardware do dono | Wi-Fi so se prova la | tudo CONFIRMADO | rodar so diag.cmd.
D6: Repetir UMA vez com -hda e log por -serial file: (nao depender do disco) | 90 min de lease | log com marca do autorun | se falhar, aceitar so evidencia offline para E3 e marcar E4 INCONCLUSIVO, nao CONFIRMADO.
C1: DOSSIE errado em "zero sem fio" | mrvlpcie8897.inf e 802.11, mas cobre so Marvell 88W8897, nao e generico | grep UTF-16LE por Class=Net + ID do chip | nao assumir caminho sem injecao para outro hardware.
C2: falta ServiceDll de WlansvcGroup, lido do hive SYSTEM do WinRE (hivexsh/reglookup) | tratar 80% como hipotese | dado lido, nao inferido | decidir pelo teste de D1.
C3: Contagem oficial = a que o runner imprime ao rodar a suite agora | rodar e corrigir o documento errado | um numero so em ETAPAS e evidence | n/a.
C4: iPXE so emulador | sem cabo, PXE nao serve ao dono | A5 fora da producao | A1+A3.
FW: Erro 10 = firmware ausente (hipotese) | checar_firmware.py no pacote REAL do dono | exit 0 e codigo de erro lido | falta <ferramenta que leia codigo de erro no WinRE 1809, pois pnputil /enum-devices e 1903+>.
