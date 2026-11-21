# Inventário de imagens (o que os agentes têm disponível)

> **Procedência:** os dois WIMs foram remontados a partir das partes versionadas em `/tmp` (nunca na
> árvore de trabalho) e verificados: fábrica 10586 SHA-256 `152addc4…`, 1809 oficial SHA-256
> `232199c5…` (conferem com `scripts/verify-repo.sh`). Listagens produzidas com `wimlib-imagex dir`.
> O material bruto está em `inventory/names-only/` (só nomes de arquivo, divididos por tipo, + deltas binários). Este documento é o
> resumo curado para que os agentes raciocinem sobre soluções sem repetir a listagem das imagens.

## Por que isto existe

Os agentes precisam saber, desde o começo, quais ferramentas e arquivos existem dentro das duas imagens, para
poderem propor soluções consistentes com as restrições (métodos de reconstrução, canais, carga mínima)
em vez de assumir ferramentas que não estão lá.

## Contagens

| Imagem | Build | Caminhos | .exe | .dll | .sys | Binários ativos (sem WinSxS) |
|---|---:|---:|---:|---:|---:|---:|
| `winre-1809-oficial-intacta/` | 17763 | 21230 | 381 | 2785 | 958 | 2073 |
| `winre-fabrica-10586-424MB/` | 10586 | 26461 | 335 | 2625 | 876 | 1846 |

As contagens incluem duplicatas do componente WinSxS. "Ativo" exclui `/Windows/WinSxS/`.

## Ferramentas de reconstrução — a descoberta decisiva

O canal de entrada é texto digitado (hex/base64). Para usar uma carga **binária**, ela precisa ser
decodificada e escrita em disco dentro do WinRE. Disponibilidade de ferramentas (ambas as imagens, salvo indicação):

| Ferramenta | Presente? | Nota |
|---|---|---|
| `certutil.exe` | **AUSENTE (ambas)** | O óbvio `certutil -decodehex` NÃO está disponível. Não assuma. |
| `powershell.exe` | **AUSENTE** | Sem `[Convert]::FromBase64String`. |
| `msado15.dll` (ADODB.Stream) | **AUSENTE** | O clássico sumidouro de escrita binária por script NÃO está disponível. |
| `mscoree.dll` / `clr.dll` | **AUSENTE** | Sem .NET. |
| `cmd.exe` | SIM | `copy /b`, `copy con`, `echo >>`, redirecionamento. Somente texto. |
| `cscript.exe` / `wscript.exe` | SIM | Windows Script Host (JScript/VBScript). |
| `mshta.exe` | SIM | Aplicação HTML, host de script COM completo. |
| `regsvr32.exe` + `scrobj.dll` | SIM | Execução de scriptlets. |
| `jscript.dll` / `vbscript.dll` / `scrrun.dll` | SIM | Motores de script + FileSystemObject (texto). |
| `msxml3.dll` / `msxml6.dll` | SIM | MSXML consegue **decodificar** base64 (`dataType="bin.base64"` → array de bytes). |
| `crypt32.dll` | SIM | A API `CryptStringToBinary` existe, mas não é diretamente chamável por rundll32. |
| `fsutil.exe` | SIM | `file createnew nome 1` tem a hipótese de produzir um `0x00` de 1 byte (E7, não provado no WinRE). |
| `wshom.ocx` | SIM | `WScript.Shell` (rodar `copy /b`, `fsutil`). |
| `cdosys.dll` / `wiaaut.dll` / `makecab.exe` / `extrac32.exe` / `tar.exe` / `zipfldr.dll` | **AUSENTE** | Sem sumidouro binário CDO/WIA/cab/tar/zip. `cdosys.dll.mui` existe sem a DLL. |
| WMI (`WMIC.exe`, `wbemdisp.dll`, `stdprov.dll`) | SIM | Nenhuma classe identificada de escrita de bytes brutos em arquivo. |
| `esentutl.exe` / `print.exe` / `expand.exe` | SIM | Não são decodificadores hex/base64. |
| `notepad.exe` | SIM | Editor de texto. |
| `findstr.exe` / `debug.exe` / `edlin.exe` | AUSENTE | |

**Consequência:** a *decodificação* base64 é possível (MSXML), mas **escrever bytes brutos em disco ainda
está não provado no WinRE** — não há certutil, nem PowerShell, nem .NET, nem ADODB.Stream.
O E7 (owner: stackai) propõe um alfabeto de arquivos de 1 byte (`fsutil` para `0x00`, `Write` do FSO
para `1..255`, depois `copy /b`) e um algoritmo PASS no lado do host; o comportamento de
FSO/fsutil precisa ser sondado num WinRE inicializado (`scripts/winre-fso-probe.js`). Não reivindique
que funciona antes dessa sondagem. Evitar transferência binária (nvram primeiro) continua o caminho de menor risco.

## A nvram é TEXTO — a primeira carga viável

`drivers/nvram-delta/4356r2nvram.txt` (5361 bytes) é **ASCII 100% imprimível** (0 bytes não imprimíveis): uma configuração chave=valor de nvram da Broadcom. Ela precisa **de nenhum decodificador binário** — reconstrua com
`cmd` (`copy con` / `echo linha>>arquivo`) ou `notepad`. É por isso que "enviar a nvram primeiro" é a
primeira transferência mais viável (E3). O `.sys` do driver (~1 MB) é binário e esbarra no
problema aberto de escrita binária acima.

**Hipótese de carga mínima (ideia do dono):** o dispositivo já tem os arquivos do driver no seu
DriverStore; o que falta é a nvram (texto). Se o H1 (delta de nvram) for a correção, **só a
nvram em texto precisa cruzar o canal — nenhuma transferência binária.** Verifique no hardware se
só a nvram basta antes de assumir que o binário do driver de ~1 MB precisa ser digitado.

## Ferramentas de canal

| Ferramenta | Presente? | Nota |
|---|---|---|
| `TabTip.exe` | SIM (ambas) | O teclado virtual da tela touch — o canal de entrada. |
| `osk.exe` | AUSENTE | Teclado virtual na tela (legado) não está no WinRE. |
| `fsquirt.exe` | **AUSENTE** | O assistente de transferência de arquivos Bluetooth não está no WinRE. |
| Pilha Bluetooth (`bthport.sys`, `rfcomm.sys`, `bluetoothapis.dll`, …) | **AUSENTE (ambas)** | Só a INF de classe `c_bluetooth.inf` está presente. O WinRE não consegue usar Bluetooth como está. |
| `netsh.exe`, `ping.exe`, `ftp.exe`, `tracert.exe` | SIM | Ferramentas de rede existem, mas o dispositivo não tem rede funcional (Wi-Fi = erro 10). |

**Nuance do Bluetooth:** o pacote de driver Bluetooth OEM ESTÁ no repositório
(`drivers/mipad2-oficial/bt-uart/`: `oem24.inf`, `BtwSerialBus.sys`, `btwdi.dll`,
`BtwRSupportService.exe` e o firmware `.hcd` BCM4356). Mas o WinRE não tem a pilha
Bluetooth da Microsoft, então um canal Bluetooth exigiria carregar essa pilha primeiro. Se o BT
consegue carregar uma carga menor que o driver é investigação aberta (TODO), não um canal assumido.

## Gestão de drivers

| Ferramenta | 1809 | fábrica | Nota |
|---|---|---|---|
| `pnputil.exe` | SIM | **AUSENTE** | Gestão da loja de drivers; só na 1809. |
| `drvload.exe` | SIM | SIM | Carrega um driver no WinRE em execução. |
| `dism.exe` | SIM | SIM | Servicing offline (mecânica no lado do host). |
| `devcon.exe` | AUSENTE | AUSENTE | Não está em nenhuma das imagens. |
| `bcdedit.exe`, `bootrec.exe`, `diskpart.exe` | SIM | SIM | Recuperação de boot/disco. |

## Descompasso de firmware e o delta (por que nenhuma imagem é o dispositivo)

O dispositivo foi **atualizado depois da fábrica**. A sua partição de recuperação real tem ~398 MB e NÃO
está disponível. As duas imagens versionadas a delimitam, mas nenhuma é idêntica:

- **Fábrica 10586 (~424 MB):** tem os extras **SDIO** da Broadcom OEM — `bcmdhd63.sys`,
  `bcmdhd64.sys`, `bcmfn.sys`, `bcmfn2.sys` (DriverStore) — mais `intelppm.sys`, `intelide.sys`.
  **Não** contém a `bcmwdidhdpcie.inf` PCIe (o driver 2017 quebrado).
- **1809 oficial (~254 MB):** imagem limpa da Microsoft; contém o pacote PCIe 2017 quebrado
  `bcmwdidhdpcie`; não tem os extras SDIO do OEM.
- **Dispositivo (~398 MB, indisponível):** base 1809 atualizada **mais** extras do OEM. A diferença
  de tamanho sugere extras (bibliotecas/drivers/programas) que nenhuma das imagens versionadas reproduz por completo.

Delta de binários ativos (sem WinSxS): só-fábrica = 265, só-1809 = 492. Veja
`inventory/names-only/delta-fabrica-only-active.names.txt` e `inventory/names-only/delta-1809-only-active.names.txt`. Saber
o delta é necessário, mas pode não ser suficiente: uma biblioteca extra presente só no dispositivo
poderia importar. Aproximar a imagem atualizada do dispositivo (instalar fábrica, atualizar, depois listar
programas / construir um ISO) é um TODO aberto — veja `TODO.md`.

## Arquivos brutos de inventário

- `inventory/names-only/winre-1809/<tipo>.txt` e `inventory/names-only/winre-fabrica-10586/<tipo>.txt` — só nomes, únicos, por tipo (executaveis, bibliotecas, drivers, inf, catalogos, manifestos, idiomas, scripts, config, fontes, outros).
- `inventory/names-only/delta-*.names.txt` — delta de binários (ativos e completo com WinSxS), só nomes.

## Regra de relato

Este inventário é fato observado (presença de arquivos nas imagens verificadas). Reivindicações de
*capacidade* de ferramenta (ex. "MSXML consegue escrever binário aqui") são hipóteses até testadas num WinRE inicializado.
Nenhum resultado do QEMU é prova de hardware.
