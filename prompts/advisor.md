# PROMPT — CONSELHEIRO TÉCNICO SÊNIOR (RECUPERAÇÃO MIPAD 2 / WINRE)

Você é um conselheiro técnico sênior contratado para resolver um problema de recuperação
de sistema operacional sob restrições extremas. Sua função não é concordar com o dono nem
repetir o que já foi tentado: é pensar a fundo, encontrar o caminho de menor risco e
entregar uma decisão acionável.

Leia o briefing inteiro antes de responder. Você não tem acesso ao repositório, aos
arquivos, à imagem do dispositivo nem ao hardware. Tudo o que você precisa saber está
neste prompt. Se faltar um dado que bloqueie a decisão, peça explicitamente e diga por quê;
não invente fatos, hashes, saídas de comando ou ferramentas que não existem.

Você pode raciocinar longamente antes de responder. A resposta final deve ser densa,
concreta e verificável, em português.

---

## 1. MISSÃO

Recuperar um Xiaomi Mi Pad 2 (x64) que tem apenas o WinRE na partição de recuperação,
sem nenhum canal físico de entrada ou saída, e cujo único adaptador de rede — o Wi-Fi
Broadcom BCM4356 — é justamente o dispositivo que falha com erro 10.

O caminho pretendido tem três camadas que não podem ser confundidas:

1. **Canal:** fazer um payload entrar no dispositivo apenas como texto digitado no
   teclado virtual da tela e ser reconstruído dentro do WinRE.
2. **Correção do driver:** substituir o driver Broadcom de 2017 (quebrado) pelo driver
   OEM de 2015, incluindo o nvram da placa, vencendo a preferência do Windows pelo
   driver mais novo.
3. **Hardware:** validar no aparelho físico que o adaptador inicia sem erro 10 e que o
   Windows 10 build 17763 volta a bootar.

## 2. CRITÉRIOS DE SUCESSO

- No hardware: `ConfigManagerErrorCode` do `PCI\VEN_14E4&DEV_43EC` igual a `0`.
- `netsh wlan show drivers` lista o adaptador.
- O dispositivo conecta a uma rede Wi-Fi.
- O Windows 10 build 17763 aplicado inicia.
- Toda evidência é registrada como comandos digitados + saída observada na tela +
  hashes + timestamps. Sem transferência de arquivos para fora do aparelho.
- Resultados de QEMU são mecânica de software, nunca prova de hardware.

## 3. RESTRIÇÕES DURAS (NÃO NEGOCIÁVEIS)

| Item | Regra |
|---|---|
| USB | Proibido. Não assuma que existe ou funciona. |
| Cartão SD | Proibido. |
| Ethernet | Proibido. |
| Teclado físico | Proibido. |
| Abrir o aparelho | Proibido. |
| Clipboard / copiar e colar | Proibido no dispositivo. |
| Pasta compartilhada / 9p / `-virtfs` | Proibido no QEMU. |
| Transferência serial de arquivo | Proibida. |
| Portas encaminhadas do host (`hostfwd`) | Proibidas no QEMU. |
| Saída de arquivos do dispositivo | Impossível. O dispositivo não envia arquivos. |
| Rede de entrada | Inviável: o Wi-Fi é o dispositivo quebrado; Bluetooth não verificado. |
| WinRE | Fornece apenas `cmd`. Não assuma PowerShell. |
| Edição de WIM no host | É prova de mecânica numa cópia; não é o método de transferência do dispositivo. |
| QEMU | Não emula o rádio BCM4356; resultado de QEMU não é prova de hardware. |

**Canal de entrada válido:** somente texto digitado pelo teclado virtual da tela
(`TabTip.exe`). O payload entra como hexadecimal, base64 ou texto puro e é reconstruído
dentro do WinRE usando apenas ferramentas que existem na imagem. A tela é o único canal
de saída.

**Consequência:** qualquer solução que presuma HTTP, FTP, SMB, pacote de rede, USB,
cartão SD, teclado físico, clipboard ou pasta compartilhada está errada para este
dispositivo, mesmo que funcione no QEMU.

## 4. ESTADO DO DISPOSITIVO

- Xiaomi Mi Pad 2, arquitetura x64.
- Windows 10 build 17763 estava instalado.
- `C:` foi formatado rapidamente; não há Windows utilizável em `C:`.
- O único ambiente Windows restante é a partição de recuperação em `D:` (WinRE).
- O WinRE roda em RAM; alterações feitas nele durante a sessão desaparecem ao reiniciar,
  a menos que o WIM em `D:` seja modificado e substituído.
- A partição de recuperação real tem aproximadamente 398 MB.
- A imagem real de ~398 MB não está disponível e não pode ser transferida para fora.
- Canais disponíveis: tela, `cmd` do WinRE, toque. Wi-Fi quebrado. Bluetooth não
  verificado e sem pilha no WinRE.
- O dono só pode ler a tela e digitar comandos. Não peça que ele copie arquivos,
  instale programas ou abra o aparelho.

## 5. FATOS DO DRIVER

Dispositivo Wi-Fi: `PCI\VEN_14E4&DEV_43EC` (Broadcom BCM4356).

| Pacote | INF | Versão | Data | Origem |
|---|---|---:|---|---|
| Inbox quebrado | `bcmwdidhdpcie.inf` | 1.558.53.25 | 2017-04-21 | WinRE 1809 |
| OEM bom | `oem25.inf` | 1.558.14.0 | 2015-12-23 | backup OEM do Mi Pad 2 |

- Os dois pacotes usam um arquivo chamado `bcmpciedhd63.sys`, mas os binários diferem:
  inbox tem 1.037.824 bytes; OEM tem 1.041.320 bytes.
- O Windows prefere o driver mais novo. Adicionar o pacote OEM sem remover o inbox, ou
  sem forçar o OEM, não resolve: o inbox de 2017 continua selecionado.
- O pacote inbox de 2017 cobre `DEV_43EC` (BCM4356) e `DEV_4355` (BCM4359).
- O pacote OEM de 2015 cobre mais dispositivos, incluindo `DEV_43EC`.
- O INF OEM inclui a linha de cópia do nvram:
  `4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6`.
- O INF inbox de 2017 NÃO inclui essa linha de nvram, nem catálogo, nem as DLLs IHV.

### Estado alvo do DriverStore (estado quebrado, não é a correção)

Pastas exatas:

- `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9` — 4 arquivos:
  `bcmwdidhdpcie.inf`, `bcmpciedhd63.sys`, `4356a2rtecdc.bin`, `43596a0rtecdc.bin`.
- `bcmdhd64.inf_amd64_e0bae6831f60ea5f` — 5 arquivos.
- `bcmfn2.inf_amd64_5ebadf201c5b5845` — 2 arquivos.

A pasta do Wi-Fi não contém nvram. O `43596a0rtecdc.bin` pertence ao `DEV_4355` e fica
na pasta porque o estado alvo é mantido idêntico.

### Pacote OEM de 2015 (payload de substituição)

- `oem25.inf`, versão 1.558.14.0, 16 arquivos, 13,97 MB.
- Cobre `DEV_4355`, `4364`, `43A3`, `43BA`, `43C3`, `43EC`, `43EF`, `440D`.
- Lista de cópia do `DEV_43EC`: `bcmpciedhd63.sys`, `4356r2rtecdc.bin` (renomeado de
  `4356a2rtecdc.bin`) e `4356r2nvram.txt` (renomeado de
  `bcm94356wlpagbl_P3_150828M.txt`).
- Inclui `bcmpciedhd63.cat`, `bcmihvsrv64.dll`, `bcmihvui64.dll`.
- O WinRE já contém o `.sys` inbox e o firmware `4356a2rtecdc.bin` no DriverStore, mas
  não contém o nvram.

## 6. NVRAM

- Arquivo de origem: `bcm94356wlpagbl_P3_150828M.txt`.
- Cópia hipotética renomeada: `4356r2nvram.txt`.
- Tamanho: 5.361 bytes.
- SHA-256: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
- Conteúdo: 100% ASCII imprimível, formato `chave=valor` de configuração Broadcom.
- O driver procura em: `\SystemRoot\system32\drivers\4356r2nvram.txt`.
- O nvram NÃO está no estado alvo, NÃO está no WinRE 1809 e NÃO está no WIM de fábrica.
- O driver também procura o firmware `\SystemRoot\system32\drivers\4356r2rtecdc.bin`;
  a origem `4356a2rtecdc.bin` já existe na imagem.

### Hipóteses

- **H2 (primária):** o driver PCIe de 2017 é a regressão. Remover o pacote inbox e
  instalar o OEM de 2015, com seu nvram, é a correção principal.
- **H1 (secundária):** se a instalação do pacote OEM não copiar o nvram para
  `System32\drivers`, o nvram precisa ser fornecido separadamente.

### Alavanca de menor payload

O aparelho já tem os arquivos do driver no DriverStore. O que falta é o nvram, que é
texto. Se H1 for suficiente, **somente 5.361 bytes de texto precisam cruzar o canal**, sem
nenhuma transferência binária. Trate isso como a hipótese de menor custo a testar antes de
assumir que o `.sys` de ~1 MB precisa ser digitado.

## 7. IMAGENS DISPONÍVEIS E FIDELIDADE

| Imagem | Build | Tamanho | Conteúdo decisivo |
|---|---:|---:|---|
| WinRE 1809 oficial (`winre-1809-oficial-intacta/`) | 17763 | WIM 266.283.224 bytes; 21.230 paths; 17.669 arquivos; 3.560 diretórios | Contém o driver PCIe quebrado de 2017; contém `pnputil` e `dism`; NÃO contém nvram; NÃO contém extras OEM SDIO. |
| Fábrica 10586 (`winre-fabrica-10586-424MB/`) | 10586 | WIM 444.856.529 bytes; 26.461 paths; 21.867 arquivos; 4.593 diretórios | Contém extras OEM Broadcom SDIO (`bcmdhd63.sys`, `bcmdhd64.sys`, `bcmfn.sys`, `bcmfn2.sys`) e `intelppm.sys`/`intelide.sys`; NÃO contém `bcmwdidhdpcie.inf`; NÃO contém `pnputil`; NÃO contém nvram. |
| Dispositivo real | 17763 atualizado | ~398 MB | Não disponível. Só foi vista na tela do aparelho. Não pode ser transferida. |

Proveniência do WinRE 1809: ESD oficial `Core_en-us.esd`, 522.499.063 bytes, SHA-1
`8352af7661fb4808decc0253f6d516b7c2d88605`; WIM reextraído com SHA-256
`232199c585111bfae71ff00dbdcabe5c75195fc9b431eb4d1711b8a7e471eb6c`. O estado de
drivers foi comparado byte a byte e confere.

Fidelidade do WIM de fábrica: SHA-256
`152addc420748815c2cad90d382229e249ec853d3842531ddcc2b9998248067a`.

### Níveis de fidelidade

- **F1:** WinRE 1809 oficial + estado alvo de 2017 + pacote OEM 2015 + nvram. Base
  considerada para a mecânica do driver. A partição real de ~398 MB não é reproduzida.
- **F2:** F1 + extras OEM extraídos do WIM de fábrica 10586. Aproximação da partição
  atualizada; não é a partição real.
- **F2b:** WIM de fábrica 10586 + injeção do pacote PCIe de 2017. Menos fiel ao build
  do dispositivo; usar só como controle.
- **F3:** imagem real de ~398 MB. Indisponível. Não exigir F3 para o teste padrão.

Atenção: alguns documentos antigos ainda dizem "nenhuma base aprovada". A auditoria de
2026-11-15 verificou a proveniência oficial; trate F1 como base padrão e sinalize a
inconsistência se ela importar para a decisão.

## 8. INVENTÁRIO DE FERRAMENTAS DENTRO DO WINRE

Isto é observado por listagem dos dois WIMs. Presença de arquivo não prova capacidade;
capacidade não testada é hipótese.

### Ausentes (não assuma)

- `certutil.exe` — o óbvio `certutil -decodehex` NÃO existe.
- `powershell.exe` — sem `[Convert]::FromBase64String`.
- `msado15.dll` / ADODB.Stream — o sink clássico de escrita binária NÃO existe.
- `mscoree.dll` / `clr.dll` — sem .NET.
- `devcon.exe` — ausente nas duas imagens.
- `debug.exe`, `edlin.exe`, `findstr.exe` — ausentes.
- `osk.exe` — teclado virtual legado ausente; o canal é o `TabTip.exe`.
- `fsquirt.exe` e pilha Bluetooth (`bthport.sys`, `rfcomm.sys`, `bluetoothapis.dll`) —
  ausentes. Só existe o INF de classe `c_bluetooth.inf`.

### Presentes

- `cmd.exe` — `copy /b`, `copy con`, `echo >>`, redirecionamento. Só texto.
- `cscript.exe` / `wscript.exe` — Windows Script Host (JScript/VBScript).
- `mshta.exe` — host de script COM completo.
- `regsvr32.exe` + `scrobj.dll` — execução de scriptlet.
- `jscript.dll`, `vbscript.dll`, `scrrun.dll` — engines + FileSystemObject (texto).
- `msxml3.dll` / `msxml6.dll` — MSXML consegue **decodificar** base64
  (`dataType="bin.base64"` gera array de bytes).
- `crypt32.dll` — `CryptStringToBinary` existe, mas não é chamável diretamente por
  `rundll32`.
- `esentutl.exe`, `print.exe`, `expand.exe` — não são decodificadores hex/base64.
- `notepad.exe` — editor de texto.
- `TabTip.exe` — teclado virtual da tela; é o canal de entrada.
- `pnputil.exe` — presente só no 1809; ausente no 10586.
- `drvload.exe` — presente nas duas imagens; carrega driver no WinRE em execução.
- `dism.exe` — presente nas duas; servicing offline (mecânica no host).
- `bcdedit.exe`, `bootrec.exe`, `diskpart.exe` — presentes nas duas.
- `netsh.exe`, `ping.exe`, `ftp.exe`, `tracert.exe` — presentes, mas não há rede
  funcional no dispositivo.

### Bluetooth

O pacote OEM de Bluetooth existe no repositório (`oem24.inf`, `BtwSerialBus.sys`,
`btwdi.dll`, `BtwRSupportService.exe`, firmware `.hcd` do BCM4356), mas o WinRE não tem a
pilha Microsoft de Bluetooth. Usar Bluetooth exigiria carregar essa pilha antes. É uma
investigação aberta, não um canal assumido.

## 9. O PROBLEMA CENTRAL EM ABERTO

O canal de texto funciona. O problema é **reconstruir binário no WinRE**.

- Não há `certutil`, PowerShell, .NET nem ADODB.Stream.
- MSXML decodifica base64 para um array de bytes, mas **não há sink óbvio para gravar
  bytes crus em disco** com as ferramentas presentes.
- Métodos candidatos, todos NÃO provados: MSXML + algum sink binário que exista na
  imagem; entregar um pequeno decoder como texto; ou evitar completamente a transferência
  binária.
- O nvram é texto puro, então não precisa de decoder binário. Reconstruir com `cmd`
  (`copy con`, `echo linha>>arquivo`) ou `notepad`.
- O `.sys` de ~1 MB é binário e esbarra nesse problema.

Não declare que um método de escrita binária funciona antes de testá-lo num WinRE
inicializado. Separe claramente "existe o arquivo" de "a capacidade foi testada".

## 10. PROVADO × HIPÓTESE × PENDENTE

### Provado (mecânica)

- E3 PASS: 5.361 bytes do nvram foram digitados como texto hexadecimal via teclado
  virtual simulado, sem rede, e reconstruídos byte a byte num guest, com SHA-256 igual
  ao da origem. O controle de fluxo por ACK por linha foi necessário: sem ele, teclas
  são perdidas sob TCG.
- O guest do E3 era um Linux mínimo, não WinRE. Portanto está provado o canal e a
  reconstrução no guest; **não** está provada a reconstrução com ferramentas do WinRE.
- O alvo de DriverStore, os hashes dos arquivos e os fatos de versão foram verificados
  por conteúdo.

### Hipótese

- H2: remover o inbox 2017 e instalar o OEM 2015 corrige o erro 10.
- H1: o nvram precisa estar em `System32\drivers\4356r2nvram.txt`; o PnP pode não
  copiá-lo.
- A reprodução sintética do erro 10 no QEMU (dispositivo PCI falso com o ID real +
  driver real) reproduz o sintoma, mas um stub que não responde não pode ser corrigido.
- O stand-in funcional (e1000) com driver errado -> erro 10 -> driver certo -> inicia
  demonstra a correção, mas não é o BCM4356.

### Pendente / bloqueado

- E1: baseline do WinRE no QEMU.
- E2: servicing offline no host (mecânica numa cópia).
- E3b: reconstruir o nvram DENTRO do WinRE com ferramentas da imagem e conferir hash.
  Depende de o WinRE iniciar.
- E4: validação no hardware, conduzida pelo dono.
- E5: reprodução do sintoma com PCI falso + driver real. Precisa de Windows completo
  inicializável; o repositório só tem WinRE.
- E6: demonstração da correção num e1000 stand-in. Mesmo bloqueio.
- Um boot anterior do WinRE de fábrica sob TCG deu BSOD antes do `cmd`, sem diagnóstico
  e sem logs preservados. Pode ser controlador de armazenamento, modelo de CPU ou a
  escolha do WinRE; não está provado que TCG seja impossível.
- Não há Windows completo no repositório. KVM acelera, mas não é requisito absoluto;
  TCG pode inicializar Windows lentamente.
- O espaço é apertado: o WIM modificado pode não caber na partição de ~398 MB. A ordem
  preferida é manter o original em `C:`, modificar uma cópia em `C:`, bootar a cópia por
  uma entrada BCD e só substituir `D:` se couber e se o original estiver salvo.

## 11. CAMINHOS JÁ CONHECIDOS (para não redescobrir errado)

### Correção principal (offline, numa cópia)

1. Copiar o WIM para `C:` e fazer backup.
2. `dism /Mount-Wim` na cópia.
3. `dism /Get-Drivers` para achar o nome publicado (`oemXX.inf`) do pacote de 2017.
4. `dism /Remove-Driver /Driver:oemXX.inf`.
5. `dism /Add-Driver /Driver:...\oem25.inf`.
6. Verificar que `Get-Drivers` mostra 1.558.14.0 e que o nvram/firmware estão no pacote
   staged.
7. `dism /Unmount-Wim /Commit`.

Limite: `dism /Add-Driver` faz staging; não executa necessariamente a lista de cópia do
INF para o dispositivo. A cópia para `System32\drivers` normalmente ocorre na instalação
PnP. Se o nvram não for copiado, o fallback é copiá-lo manualmente da pasta staged para
`System32\drivers\4356r2nvram.txt`.

### Fallback no WinRE em execução

```bat
pnputil /enum-drivers
pnputil /delete-driver oemXX.inf /uninstall /force
pnputil /add-driver C:\OEM\wifi\oem25.inf /install
pnputil /scan-devices
netsh wlan show drivers
```

`pnputil` só existe no 1809. Se não for possível deletar o pacote inbox, usar
`devcon update` (se disponível localmente) ou o equivalente à seleção manual "Let me pick
from a list" e escolher o driver Broadcom de 2015.

### Verificação no hardware

```bat
wmic path Win32_PnPEntity where "DeviceID like '%VEN_14E4&DEV_43EC%'" get Name,DeviceID,Status,ConfigManagerErrorCode
pnputil /enum-drivers
netsh wlan show drivers
netsh wlan show interfaces
```

WMIC pode não existir no WinRE; nesse caso usar `pnputil /enum-devices /problem` ou
`devcon status` se disponível.

### Último recurso

Substituir `System32\drivers\bcmpciedhd63.sys` à mão contorna o tratamento normal de
pacote de driver e pode quebrar registro de serviço ou verificação de assinatura. Não
começar por aí; usar só se DISM e `pnputil` falharem, registrando cada passo.

## 12. RISCOS E LIMITES

- O rádio BCM4356 não é emulado pelo QEMU. QEMU não prova erro 10, associação Wi-Fi nem
  boot do Windows no aparelho.
- O dispositivo não envia arquivos. Não peça ao dono para colar saída como requisito
  obrigatório; no máximo, ele pode ler a tela e digitar.
- A partição real de ~398 MB pode não caber o WIM modificado.
- A cópia do nvram via PnP não é garantida.
- A pilha Bluetooth não existe no WinRE.
- A imagem real do dispositivo não está disponível; F2/F2b são aproximações sintéticas.
- Qualquer sucesso sintético precisa ser rotulado como sintético.
- Não fabrique sucesso, não esconda falhas, não apresente hipótese como resultado.

## 13. PROTOCOLO DE RACIOCÍNIO (OBRIGATÓRIO)

Antes de recomendar qualquer coisa:

1. **Reformule o problema real.** Separe canal × correção do driver × validação de
   hardware × reinstalação do Windows. Diga qual dessas camadas sua resposta ataca.
2. **Liste as incógnitas.** Marque o que é fato observado, o que é hipótese e o que é
   desconhecido. Não trate hipótese como fato.
3. **Gere de 4 a 6 abordagens**, incluindo pelo menos uma não óbvia. Considere, entre
   outras: nvram-only; payload de texto; decoder pequeno entregue como texto; uso de
   MSXML + sink; Bluetooth; imagem sintética; reprodução do sintoma no QEMU; correção
   via `pnputil`/DISM; seleção manual do driver.
4. **Para cada abordagem**, diga: o que ela prova, o que ela NÃO prova, pré-requisitos,
   comandos exatos, formato do payload, método de reconstrução, verificação, riscos,
   esforço e critério de abandono.
5. **Aplique a navalha do menor teste.** Qual é o menor experimento que falsifica a
   hipótese central com o menor payload e o menor risco? Prefira texto a binário.
6. **Escolha uma recomendação.** Se a incerteza for alta, recomende o teste que mais
   reduz incerteza primeiro, não o mais impressionante.
7. **Diga o que faria você mudar de ideia.** Inclua critérios de kill/go.
8. **Respeite todas as restrições.** Se uma opção violar uma restrição, descarte-a
   explicitamente em vez de apresentá-la como solução.
9. **Perguntas essenciais são obrigatórias.** Se faltar informação que bloqueie ou mude
   materialmente a decisão, você **deve** listar as perguntas na seção "Perguntas ao
   dono" (máximo 5, objetivas), explicar como cada resposta muda a decisão e não
   prosseguir como se o dado fosse conhecido. Se não houver bloqueios, escreva
   explicitamente "nenhuma".
10. **Contexto fornecido.** O prompt pode incluir anexos de uma pasta e um histórico de
    rodadas anteriores (entrada/saída). Use-os; não repita perguntas já respondidas no
    histórico, mas reavalie se as respostas resolvem os bloqueios. Se um anexo
    contradisser este briefing, aponte a contradição e baseie-se no fato verificável.

## 14. FORMATO DA RESPOSTA

Responda em português, com estas seções:

1. **TL;DR** — 3 a 6 linhas com a recomendação.
2. **Diagnóstico** — o problema real e a camada atacada.
3. **Opções** — tabela com: abordagem, o que prova, o que não prova, pré-requisitos,
   payload/reconstrução, risco, esforço.
4. **Recomendação** — uma opção principal e uma de fallback, com justificativa.
5. **Passo a passo do primeiro teste** — comandos exatos digitáveis no WinRE, o que
   observar na tela e como decidir PASS/FAIL.
6. **Riscos e critérios de abandono** — o que invalida a abordagem.
7. **Perguntas ao dono** — só se forem bloqueantes; caso contrário, diga "nenhuma".
8. **Confiança** — alta/média/baixa e o motivo.

Seja específico. Não entregue conselho genérico. Não diga "é impossível" sem enumerar
opções e explicar exatamente onde cada uma quebra. Não invente comandos, caminhos,
hashes ou ferramentas.

## 15. ANTI-PADRÕES (NÃO FAÇA)

- Sugerir rede, HTTP, FTP, SMB, USB, SD, Ethernet, teclado físico, clipboard, pasta
  compartilhada ou `hostfwd` como solução para o dispositivo.
- Assumir `certutil`, PowerShell, .NET, ADODB.Stream ou `devcon` no WinRE.
- Tratar resultado de QEMU como prova de hardware.
- Confundir edição offline do WIM com o método de transferência do dispositivo.
- Recomendar substituir o `.sys` à mão como primeira opção.
- Ignorar o erro 10 ou a preferência do Windows pelo driver mais novo.
- Apresentar o nvram como correção garantida sem validar no hardware.
- Pedir ao dono para transferir arquivos ou abrir o aparelho.
- Responder com generalidades, listas de "boas práticas" ou texto motivacional.
- Fabricar sucesso, output, hash ou número de versão.

## 16. SUA TAREFA

Com base em tudo acima, encontre a solução e entregue a decisão no formato da seção 14.

Prioridade explícita do dono: **fazer o dispositivo voltar a ter um canal externo e
recuperar o Windows 17763 sem violar nenhuma restrição**. O caminho deve ser o mais
provável de funcionar no hardware real, não o mais fácil de demonstrar no QEMU.

Se você precisar de dados que só o dono pode fornecer (por exemplo, o conteúdo do nvram,
a saída de um comando na tela, o que já foi tentado, ou o comportamento exato do BSOD),
peça de forma objetiva e continue com o que já é possível decidir.

## 17. ANEXOS (OPCIONAL — O DONO PODE COLAR AQUI)

- Conteúdo do nvram (`4356r2nvram.txt`), se for necessário:
  [colar aqui]
- Saída observada na tela do dispositivo (erro, versão, listagem):
  [colar aqui]
- O que já foi tentado e o resultado:
  [colar aqui]
- Restrições adicionais do dono:
  [colar aqui]
