# scripts/ — kit reutilizável (para qualquer agente/máquina)

Scripts POSIX `sh`, idempotentes e **adaptáveis**: detectam gerenciador de pacotes,
privilégios, ferramentas e recursos (KVM/docker/qemu) e instalam só o que falta.
Nenhum depende de estado herdado — rode-os no começo da sua rodada.

## Ordem recomendada

```sh
sh scripts/ambiente.sh                 # 1) prepara o ambiente (deps + dirs + diagnostico)
sh scripts/obter_imagem.sh --wim       # 2) WinRE 1809 (raiz do ramo wwii; o script busca la)
sh scripts/inspecionar_winre.sh <img>  # 3) examina o WinRE (netsh/WLAN/drivers)
sh scripts/tests/run-tests.sh          # 4) ambiente de teste: VM QEMU + suite (termina em SUITE: PASS)
```

## Driver: do hardware ID ao Winre.wim (ciclo fechado)

```sh
python3 scripts/buscar_driver.py busca 'PCI\VEN_14E4&DEV_4365'                  # 1) localiza no catalogo MS
python3 scripts/buscar_driver.py baixa 'PCI\VEN_14E4&DEV_4365' --dir .work/drivers # 2) baixa o .cab oficial
python3 scripts/buscar_driver.py inf   'PCI\VEN_14E4&DEV_4365' --dir .work/drivers/extracted  # 3) confere se o INF serve
sh scripts/injetar_driver.sh --imagem .work/wim/Winre.wim --driver .work/drivers/extracted  # 4) injeta
```

## O que cada um faz

| Script | Função |
|---|---|
| `ambiente.sh` | Detecta SO/gerenciador (apt/dnf/yum/apk/pacman/brew), instala `curl wget wimlib 7z aria2 python3 qemu busybox squashfs-tools`, cria `.work/` e reporta disco/memória/virtualização |
| `inspecionar_winre.sh` | Acha o `Winre.wim` (inclusive aninhado em `install.wim`/ESD/ISO) e verifica `netsh.exe`, `wlanapi.dll`, `wlanmsm.dll`, `certutil.exe`, drivers `Net*.inf` |
| `buscar_driver.py` | Acha o driver de um dispositivo no **Microsoft Update Catalog** pelo hardware ID (`VEN_/DEV_` ou `VID_/PID_`), baixa o `.cab` oficial e **confere se o INF cobre o dispositivo** (ignora `SUBSYS_`/`REV_`, como o Windows). `busca` / `baixa` / `inf` / `catalogo` / `lote` (um `.cab` por fabricante, tabela `drivers-1809.tsv`, cache, INF UTF-16) |
| `lote_drivers.sh` | E2 ponta a ponta: `buscar_driver.py lote` + injeta cada fabricante no Winre.wim e confere hash |
| `injetar_driver.sh` | Injeta um driver numa imagem Windows/WinRE (WIM/ESD) via `wimlib`, nos mesmos caminhos do `dism /Add-Driver`: `/Windows/INF`, `DriverStore/FileRepository`, `System32/drivers`. Faz backup e verifica. `--listar` mostra o que já está na imagem. **Desde 2026-11-07**: injeta o pacote **inteiro** (inclusive o firmware `.dat/.bin/.msc/.txt`), põe **os arquivos exigidos pelo INF e o `.cat` ao lado do INF** (sem o `.cat` o setupapi responde `0xE000022F`) e **verifica arquivo por arquivo** — "injetado" não é "carregável" |
| `inf_dependencias.py` | Lista os arquivos que um INF exige em disco: `[SourceDisksFiles]` (com ou sem sufixo `.amd64`), `[CopyFiles]`, seções `.files.*`, `[ServiceInstall]` e `[CatalogFile]` / `CatalogFile.NTamd64`. INFs UTF-16LE e ASCII. É o que o `injetar_driver.sh` usa para não deixar nada de fora |
| `boot-winre.sh` | **Harness da E4**: sobe a ISO do WinRE em QEMU TCG, cria o disco FAT32 de dados, lê o `wwii.log` do convidado pelo host (mtools), tira telas (screendump + cliente RFB) e `--bsod`/`--blockstats` diagnosticam o boot. Opções novas (2026-11-07): `--cpu` (o `qemu64` é o que dava BSOD), `--bsod` (classifica o quadro e pede a página técnica do bugcheck), `--blockstats`, `--debugcon`. **Cuidado:** apaga o `wwii.log` antigo com `mdel` (o `mrm` não existe no mtools 4.0.32 e falhava em silêncio) e **verifica que o log lido é deste run** |
| `detectar-bsod.py` | Classifica um quadro (PPM) como `bsod` / `tecnico` / `normal`. **O OOBE do WinPE ("Choose your keyboard layout") é laranja como o BSOD**: o detector exige a cor saturada do bugcheck **ou** o bloco branco do QR code |
| `ppm2png.py` | Converte PPM (P6) em PNG sem PIL (este sandbox não tem PIL) — a evidência do projeto é PNG |
| `diag.cmd` | **Roda no WinRE** (não no Linux): coleta os IDs de hardware (Wi-Fi/Bluetooth) e o inventário de drivers. Detalhes em `docs/evidence/driver-injecao.md` |
| `download.vbs` | **Roda no WinRE** (não no Linux): baixa arquivo por HTTP(S) via `cscript` — supre a ausência de `certutil`/PowerShell |
| `doctor.sh` | Diz o que este ambiente executa (níveis T0–T4); sai com código ≠ 0 se nada for executável. Rode antes de gastar a rodada |
| `agente.sh` | Identidade `A=<nome>` (git config) e linha `nome inicio <data UTC>` em `PRESENCA.md`; o hook post-commit grava `nome push <data UTC> <sha>` após cada push ok |
| `etapa.sh` | Orquestra `ETAPAS.md`: `status`, `pegar`, `fechar`, `liberar` (lease de 90 min) |
| `mural.sh` | Praça comum dos agentes (`MURAL.md`): `ler`, `proposta`, `achado`, `pergunta`, `apoio`, `critica`, `refuta`, `resposta`, `resumo`; carimba agente/modelo |
| `quem-primeiro.sh` | Quem (agente/modelo) citou um termo primeiro, no git de todas as branches, mural e problemas |
| `evals.sh` | Avanço real medido (etapas, problemas, requisitos, placar por modelo, commits); critérios em `EVALS.md` |
| `inventario.py` | Gera `docs/imagem/INVENTARIO.md` (executáveis e bibliotecas do WinRE) a partir de `winre-caminhos.txt.gz` |
| `plano.sh` | Imprime o `PLANO-DO-LIDER.md` do lead (branch `lider`) sem abrir o `INDICE-PARA-O-LIDER.md` |
| `problema.sh` | Quadro de problemas compartilhado (`PROBLEMAS.md`): `abertos`, `buscar`, `novo`, `tentou`, `resolveu`; commita para os outros verem |
| `escalar.sh` | Dossiê de decisão para o lead (`casos/<id>.md` na branch `lider` + 1 linha no índice); exige 2 tentativas |
| `sugerir.sh` | Registra perda ou ideia de processo em `SUGESTOES.md` (só escrita) |
| `relatorio.sh` | Mantém `INDICE-PARA-O-LIDER.md` na branch `lider` (`estado`, `problema`, `pergunta`; só escrita) |
| `obter_imagem.sh` | Baixa o pacote offline da imagem 1809 (`--fs` 62 MB, `--wim` 254 MB) |
| `listar_hwid.py` | Lista os HWIDs presentes no WinRE (os INF são UTF-16LE; grep ASCII devolve zero) |
| `ler_hive.py` | Inventário de serviços do WinRE lido do próprio WIM |

## Ambiente de teste (VM QEMU) — `tests/`

Sobe uma VM Linux mínima headless e roda a suíte dentro dela, espelhando o fluxo do
desafio: **injetar driver → dispositivo aparece → rede**. Sem KVM usa emulação TCG (boot ~3 s).

| Script | Função |
|---|---|
| `tests/run-tests.sh` | Orquestra: deps (via `ambiente.sh`), baixa base, monta initramfs, roda a VM e valida o log → `SUITE: PASS/FAIL` |
| `fetch-base.sh` | Baixa kernel `vmlinuz-virt` + módulos `modloop-virt` (Alpine) para `.work/downloads` |
| `build-initramfs.sh` | Monta o initramfs (busybox + `sd_mod`/`virtio_net` + deps + `init`) |
| `run-vm.sh` | Sobe a VM (`[segundos]`, `NET=1`, `DISK_MB=`) e despeja a serial em `.work/logs/vm.log` |
| `tests/in-vm-tests.sh` | Suíte DENTRO da VM: disco, wipe de C:, imagem de recuperação, injeção de driver, rede |
| `tests/in-vm-fdisk-pan.sh` | Suíte DENTRO da VM: `fdisk` **real** (C: + partição de recuperação; prova por md5 que formatar C: não apaga a recuperação) e **PAN** com network namespace + `veth` (celular como gateway, com teste negativo) |

Evidência da última execução: `docs/evidence/ambiente-teste.md`.

## Como adaptar ao seu ambiente

Todos aceitam variáveis de ambiente (nenhuma é obrigatória):

```sh
WORK=.work                                   # area de trabalho (ignorada pelo git)
```

Sem `wimlib`? O `ambiente.sh` tenta instalar (`wimtools` no Debian/Ubuntu,
`wimlib-utils` no Fedora, `wimlib` no Alpine/Arch). Se não conseguir, ele avisa
em vez de falhar silenciosamente.

## Cuidados

- Tudo pesado vai para `.work/` (no `.gitignore`) — nunca commite ISO/WIM.
- Rode downloads longos **em segundo plano** com log; nunca fique travado esperando.

## Setup e ambiente por agente (adicionado 2026-11-05)
- `../setup/agents/claude.sh` — setup do agente `claude` (comum a todos em `../setup/common/`): instala dependências, kernel/módulos de teste, registra o ambiente. Cada agente pode ter o seu (`setupenv<nome>.sh`).
- `registrar_ambiente.sh <agente>` — mede ESTE ambiente (CPU, RAM, ferramentas, rede) e grava `ambientes/<agente>.md`. Ambiente é por agente: nunca copie o de outro.
- `fetch-modulos-ubuntu.sh` — fallback do modloop: módulos do kernel Ubuntu via apt (quando o Alpine CDN não responde).
- `../auto.sh` — um comando, sem ler nada: setup + plano + problemas abertos + handoff.

Scripts UUP e dossie.sh removidos: a imagem ja esta na branch `imagem`. Historico: `git show f76aab8:scripts/uup_links.sh`.
