# PROMPT DE PESQUISA PROFUNDA — Recuperação do Windows 10 1809 sem conexões físicas

**Você é o pesquisador.** Não executa nada na máquina do dono e não depende do ambiente do executor. Sua tarefa é **pesquisar a fundo, com fontes**, as perguntas abaixo e entregar `RESULTADO-PESQUISA.md` nesta branch (`pesquisador`). Contexto completo e o que já foi medido: branch `info`, `README.md` (https://github.com/kkkkiiiioooo/aaaa/blob/info/README.md). Leia-o primeiro; **não repita o que já está medido**, procure o que contradiz ou completa.

## Como pesquisar
1. **Trabalhe até se esgotar.** Não pare numa resposta plausível. Para cada pergunta: ao menos 3 buscas com termos diferentes, fonte primária primeiro (Microsoft Learn/Docs, documentação de ADK/WinPE/DISM, MS-Open-Specs, changelogs, repositórios oficiais), depois fontes técnicas secundárias (fóruns técnicos, projetos de WinPE da comunidade). Só marque "sem resposta" depois de listar as buscas tentadas.
2. **Cada afirmação técnica leva fonte**: URL direta + local exato (seção/título/versão) + trecho curto entre aspas (até 15 palavras; o resto, parafraseie). Nunca "dizem por aí".
3. **Separe**: `[FATO-FONTE]` (a fonte diz), `[INFERÊNCIA]` (você concluiu), `[NÃO VERIFICADO]`. Dê confiança alta/média/baixa.
4. **Contradiga** o executor e o líder quando a fonte mandar. Se algo que o `info` chama de "medido" parecer errado, diga e mostre por quê.
5. **Versão importa**: tudo é para **Windows 10 1809 (build 17763) / WinRE / WinPE 10.0.17763**. Anote a versão em que cada recurso passou a existir.
6. **Pense em possibilidades que ninguém listou.** Se achar uma rota nova para R1–R5, registre mesmo fora das perguntas.
7. Anote no topo do resultado as **limitações do seu próprio ambiente** (ferramentas, rede, acesso). Seu ambiente é seu: não o confunda com o do executor.

## Perguntas (ordem de valor)

**P1. `netsh wlan` no WinRE/WinPE 1809.** O executor mediu (estático) que `wlancfg.dll` está registrado como helper do netsh (`HKLM\SOFTWARE\Microsoft\NetSh`) e que o `wlancfg.dll.mui` traz a ajuda de `connect`/`add profile`; antes ele havia concluído o contrário por procurar `wlancmds.dll`. Pesquise: (a) **confirme ou refute** que o contexto `wlan` do netsh vive em `wlancfg.dll` no Windows 10 1809 e se `wlancmds.dll` sequer existe em alguma versão; (b) o que o `netsh wlan` exige para funcionar em WinPE/WinRE (`wlansvc` rodando? `nativewifip`/`Ndisuio`? WCM?) e se o pacote **WinPE-WiFi-Package** do ADK é necessário no 1809, em que versão do ADK surgiu e que arquivos adiciona; (c) relatos de `netsh wlan connect` funcionando ou falhando em WinPE/WinRE sem `wcmsvc`; (d) alternativas documentadas se não funcionar (API WLAN por script, perfil XML no store, ferramentas de terceiros).

**P2. Perfil Wi-Fi XML e auto-conexão.** Documente o armazenamento de perfis do `wlansvc` (`%ProgramData%\Microsoft\Wlansvc\Profiles\Interfaces\{GUID}`): formato, quando o GUID é criado, se o serviço conecta sozinho sem o WCM (`wcmsvc`) ausente, e como sustentar isso em WinPE (onde `%ProgramData%` pode nem existir).

**P3. Drivers Wi-Fi inbox do Windows 10 1809 Home.** Quais chipsets (Intel, Realtek, Qualcomm, Broadcom, MediaTek, Marvell) têm driver **dentro** do `install.wim`/DriverStore do 1809? Se a partição de recuperação do dono guardar a imagem de fábrica, dá para tirar o driver dela sem rede? Onde fabricantes (OEM) costumam guardar imagem e drivers na partição (`\Recovery\OEM`, `\Recovery\Customizations`, `install.wim`/`.esd`, `reagentc /info`)?

**P4. Erro 10 em adaptador Wi-Fi.** Causas documentadas (firmware ausente, `CM_PROB_FAILED_START`, driver incompatível) e **como ler o código de erro no WinRE 1809**, onde `pnputil /enum-devices` não existe. Que ferramentas do WinRE (`reg query` em `HKLM\SYSTEM\CurrentControlSet\Enum`, `wmic`, `devcon`, `drvload` retornando erro) mostram HWID e problema?

**P5. A3 (reset com download na nuvem) em 1809.** "Cloud download" no "Reset this PC" **existe** no WinRE do 1809? Em que versão surgiu? Se não existir, A3 está morta para este dono. Confirme com fonte.

**P6. Reinstalar sem mídia (R3).** Caminhos oficiais com ESD/WIM em disco: `setup.exe /installfrom`, `dism /Apply-Image` + `bcdboot` + `bcdedit`, arquivo de resposta (`unattend.xml`). Passo a passo mínimo para um disco com C: formatado e partição de recuperação intacta. E **R5**: dá para injetar drivers (`dism /Image:C:\ /Add-Driver`) na imagem aplicada **antes** do primeiro boot, evitando exportar/importar depois?

**P7. Digitação mínima.** O dono digita tudo à mão. Menor sequência de caracteres para, no WinPE 1809, buscar um script por HTTP e executá-lo, sem `certutil`/`powershell`/`bitsadmin` (opções: `cscript //e:jscript`, `mshta` com `javascript:`, `ftp -s:`, `net use`, `for /f`). Compare tamanho, confiabilidade e pré-requisitos. Quanto menor, melhor, **desde que funcione**.

**P8. Editar o `Winre.wim` do próprio dono.** Como o BCD/`reagentc` aponta para o `Winre.wim` (ramdisk, `boot.sdi`)? Dá para `dism /Mount-Image` dentro do próprio WinRE (precisa de espaço gravável: usar C: formatado como rascunho)? Como fazer o WinRE modificado ser o usado no próximo boot sem quebrar a recuperação (`reagentc /setreimage`)? O que muda com BitLocker/Secure Boot/UEFI?

**P9. Bluetooth PAN (R4).** Existe método documentado ou da comunidade para incluir pilha Bluetooth (`bthserv`, `bthport`, `bthpan`, `bthusb`) em WinPE 1809? Lista de arquivos e serviços. Se for inviável, confirme que PAN só existe no Windows instalado e como habilitá-lo em OOBE sem rede.

**P10. Testar o WinRE/WinPE em QEMU/TCG.** Há relatos e receitas para `SYSTEM_THREAD_EXCEPTION_NOT_HANDLED` no boot de WinPE sob QEMU (modelo de CPU `-cpu max`/`qemu64`/`Skylake`, `-machine q35` vs `pc`, IDE/SATA/AHCI, enlightenments Hyper-V, memória, `boot.sdi`)? Como reduzir o tempo de boot sem KVM? É possível emular adaptador Wi-Fi para um convidado Windows (ou só passthrough USB)?

**P11. Identificar o hardware do dono sem rede.** Como listar HWIDs PCI/USB de rede em WinRE para escolher entre os 6 pacotes de driver? Como automatizar "tentar todos os drivers" com `drvload` até o adaptador subir, sem travar?

**P12. Casos reais.** Procure relatos de quem já recuperou Windows 10 só com WinRE/cmd e Wi-Fi (fóruns técnicos, issues de projetos como WinPE da comunidade, relatos de OEM). Qual caminho deu certo e qual deu errado?

## Entrega
Arquivo `RESULTADO-PESQUISA.md` nesta branch, com:
1. **Resumo (≤15 linhas):** a melhor rota para R1–R5 e o que muda no plano atual.
2. **Uma seção por pergunta (P1…P12):** resposta, fontes (URL + local + trecho curto), confiança, e "o que isso muda para o executor".
3. **Ideias novas** que não estavam nas perguntas.
4. **Buscas sem resultado** (termos tentados).
5. **Ambiente do pesquisador** (limitações).

Regras: sem copiar textos longos; sem inventar URL; sem executar nada no dono. Termine só quando todas as perguntas tiverem resposta com fonte ou registro de esgotamento.
