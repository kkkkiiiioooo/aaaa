# Evidência — driver real: da busca no catálogo à injeção no Winre.wim

**Método:** execução real, ponta a ponta, sem mock. O hardware de referência é um
Broadcom BCM4365 (`PCI\VEN_14E4&DEV_4365`), adaptador Wi-Fi típico de notebook.

```
VEN_/DEV_ do adaptador
   ↓ scripts/buscar_driver.py busca      → Microsoft Update Catalog (API oficial)
   ↓ scripts/buscar_driver.py baixa      → .cab do driver (URL oficial do catálogo)
   ↓ scripts/buscar_driver.py inf         → confere se o INF cobre o dispositivo
   ↓ scripts/injetar_driver.sh            → injeta no Winre.wim real (17763)
   ↓ wimlib-imagex extract                → reextrai e compara hash
```

## 1. Busca no Microsoft Update Catalog

O catálogo tem uma API pública. A busca por hardware ID devolve o update GUID:

```sh
python3 scripts/buscar_driver.py busca 'PCI\VEN_14E4&DEV_4365'
```

```
1 driver(s) no catalogo para PCI\VEN_14E4&DEV_4365

 1. Broadcom - Net - 11/22/2016 12:00:00 AM - 7.35.352.0
    data=11/21/2016  tamanho=8.3 MB
    guid=bf1b8abf-9e4a-48f2-9b4e-967604711a65
```

## 2. Download do pacote

`DownloadDialog.aspx` devolve a URL do `.cab` no domínio oficial
`catalog.s.download.windowsupdate.com`:

```sh
python3 scripts/buscar_driver.py baixa 'PCI\VEN_14E4&DEV_4365' --dir .work/drivers
```

```
baixado: 898cc945-...-e41c70b0d890.cab (8670650 bytes)
  extraido em extracted/: bcm43xx.cat, bcm43xx64.cat, bcmihvsrv.dll,
                          bcmihvui.dll, bcmwdi.inf, bcmwl63.sys, bcmwl63a.sys
```

Conteúdo do `.cab` (8,3 MB): `bcmwdi.inf` + `bcmwl63.sys`/`bcmwl63a.sys` (driver) +
`bcm43xx.cat`/`bcm43xx64.cat` (catálogo de assinatura) + `bcmihvsrv*.dll`,
`bcmihvui*.dll` (serviços).

## 3. O INF cobre o dispositivo? (match e não-match)

O INF declara o ID na seção `[BROADCOM.NTamd64]`:

```
%BCM430N_DeviceDesc% = BCM43XNG_NT64, PCI\VEN_14E4&DEV_4365&SUBSYS_2230103C
%BCM430N_DeviceDesc% = BCM43XNG_NT64, PCI\VEN_14E4&DEV_4365&SUBSYS_22D3103C
%BCM430N_DeviceDesc_HPY% = BCM43XNG_NT64, PCI\VEN_14E4&DEV_4365&SUBSYS_2232103C
...
```

> `SUBSYS_` (subsistema/placa) e `REV_` podem faltar: o match do Windows é por
> `PCI\VEN_xxxx&DEV_xxxx`. O script compara só VEN/DEV (ou VID/PID para USB).

**Positivo:**

```
$ python3 scripts/buscar_driver.py inf 'PCI\VEN_14E4&DEV_4365' --dir .work/drivers/extracted
[MATCH ] .../bcmwdi.inf
         PCI\VEN_14E4&DEV_4365&SUBSYS_22D4103C
         PCI\VEN_14E4&DEV_4365&SUBSYS_22D3103C
         PCI\VEN_14E4&DEV_4365&SUBSYS_2232103C
         PCI\VEN_14E4&DEV_4365&SUBSYS_804A103C
         PCI\VEN_14E4&DEV_4365&SUBSYS_2230103C

OK: driver compativel com PCI\VEN_14E4&DEV_4365 encontrado.
```

**Negativo (driver errado para o dispositivo):**

```
$ python3 scripts/buscar_driver.py inf 'PCI\VEN_8086&DEV_9A60' --dir .work/drivers/extracted
[nao   ] .../bcmwdi.inf  (13 ids declarados)

FALHA: nenhum INF em .../extracted serve para PCI\VEN_8086&DEV_9A60
```

É o teste que importa: **injetar o driver errado não resolve o erro 10.**
A verificação é barata (só lê o INF) e evita uma ida à máquina real à toa.

## 4. Injeção no Winre.wim real

Imagem usada: **WinRE 17763 (WindowsPE)** exportada do `Core_en-us.esd` oficial
(build 1809 Home, `uupdump` → `scripts/uup_links.sh` + `scripts/baixar_uup.sh`).
Confirmação de que é o WinRE certo:

```
$ wimlib-imagex info .work/uup/files/Core_en-us.esd 2
Index:                  2
Name:                   Microsoft Windows Recovery Environment (x64)
Edition ID:             WindowsPE
Build:                  17763
File Count:             17669
```

Injeção (equivalente Linux/offline do `dism /Add-Driver`):

```sh
sh scripts/injetar_driver.sh --imagem .work/wim/Winre.wim --driver .work/drivers/extracted
```

```
[injetar] INF: .work/drivers/extracted/bcmwdi.inf
[injetar]   -> /Windows/INF/bcmwdi.inf
[injetar]   -> /Windows/System32/DriverStore/FileRepository/bcmwdi.inf_amd64_5879811a439944eb/
[injetar] arquivos a injetar: 12 (de 1 INF)
[injetar] resultado: INJECAO VERIFICADA
```

Arquivos gravados (mesmos caminhos que o DISM usa):

| Caminho na imagem | Papel |
|---|---|
| `/Windows/INF/bcmwdi.inf` | INF registrado |
| `/Windows/System32/DriverStore/FileRepository/bcmwdi.inf_amd64_<hash>/` | pacote do driver (inf + sys + cat + dll) |
| `/Windows/System32/drivers/bcmwl63.sys` | binário carregado no boot |
| `/Windows/System32/drivers/bcmwl63a.sys` | binário carregado no boot |

### Prova end-to-end: reextrair e comparar hash

```sh
wimlib-imagex extract .work/wim/Winre.wim 1 @lista.txt \
  --dest-dir=.work/verif --preserve-dir-structure
```

| arquivo | sha256 (16) original | sha256 (16) reextraído | |
|---|---|---|---|
| `bcmwdi.inf` | `2594a0a42a46d98b` | `2594a0a42a46d98b` | IGUAL |
| `bcmwl63.sys` | `a32c39030a251f64` | `a32c39030a251f64` | IGUAL |
| `bcm43xx.cat` | `b725e41c7aa0b831` | `b725e41c7aa0b831` | IGUAL |

O driver gravado na imagem é **byte a byte** o driver do catálogo.

## 5. Inventário real do WinRE 1809 (o que existe e o que não)

Verificado na imagem extraída (21.230 arquivos) e por strings nos binários:

| ferramenta | status | consequência |
|---|---|---|
| `reg.exe`, `netsh.exe`, `pnputil.exe`, `find.exe`, `more.com` | **presente** | usáveis no `diag.cmd` |
| **`findstr.exe`** | **AUSENTE** | o `diag.cmd` antigo quebraria aqui |
| `sort.exe` | **AUSENTE** | idem |
| `wmic`, `msinfo32`, `powershell`, `certutil` | **AUSENTE** | sem WMI, sem download por `certutil` |
| `pnputil /enum-drivers` | **presente** (confirmado por strings) | lista drivers de terceiros |
| `pnputil /enum-devices` | **AUSENTE** | só existe a partir do Windows 10 **1903** |
| `dism.exe` | **presente** | dá para montar/injetar offline na máquina real |

Consequência prática: `pnputil /enum-devices` **não** pode ser usado no WinRE 1809
(o que quase todo tutorial de diagnóstico manda usar). A alternativa é o registro,
via `reg query`.

## 6. Limite desta evidência

- Prova: o driver oficial existe, casa com o dispositivo, e pode ser gravado na
  imagem do WinRE sem erro, com integridade byte a byte.
- **Não** prova: que o driver carregue e funcione no hardware real (o sandbox não
  tem o adaptador, nem Windows, nem boot de WinRE). O erro 10 do desafio só
  aparece na máquina do dono.
- `wimlib-imagex update` grava os arquivos, mas **não** faz o que o DISM faz:
  registrar o driver no hive (SYSTEM/SOFTWARE), atualizar o catálogo de
  assinaturas e o `setupapi.dev.log`. Na máquina real o passo continua sendo
  `dism /Image:C:\mnt /Add-Driver /Driver:<pasta> /Recurse`.

## Reproduzir tudo

```sh
sh scripts/uup_links.sh                              # links oficiais do build 1809
sh scripts/baixar_uup.sh 'Core_en-us\.esd'           # ~498 MB
wimlib-imagex export .work/uup/files/Core_en-us.esd 2 .work/wim/Winre.wim --compress=none

python3 scripts/buscar_driver.py busca  'PCI\VEN_14E4&DEV_4365'
python3 scripts/buscar_driver.py baixa  'PCI\VEN_14E4&DEV_4365' --dir .work/drivers
python3 scripts/buscar_driver.py inf    'PCI\VEN_14E4&DEV_4365' --dir .work/drivers/extracted
sh scripts/injetar_driver.sh --imagem .work/wim/Winre.wim --driver .work/drivers/extracted
sh scripts/injetar_driver.sh --imagem .work/wim/Winre.wim --listar
```
