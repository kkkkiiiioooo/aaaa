# scripts/ — kit reutilizável (para qualquer agente/máquina)

Scripts POSIX `sh`, idempotentes e **adaptáveis**: detectam gerenciador de pacotes,
privilégios, ferramentas e recursos (KVM/docker/qemu) e instalam só o que falta.
Nenhum depende de estado herdado — rode-os no começo da sua rodada.

## Ordem recomendada

```sh
sh scripts/ambiente.sh                 # 1) prepara o ambiente (deps + dirs + diagnostico)
sh scripts/uup_links.sh                # 2) resolve links diretos oficiais (nao baixa nada)
sh scripts/baixar_uup.sh '\.esd$'      # 3) baixa (filtro opcional; retomavel/paralelo)
sh scripts/inspecionar_winre.sh <img>  # 4) examina o WinRE (netsh/WLAN/drivers)
sh scripts/converter_iso.sh            # 5) opcional: monta a ISO completa a partir dos UUP
sh scripts/tests/run-tests.sh          # 6) ambiente de teste: VM QEMU + suite (termina em SUITE: PASS)
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
| `uup_links.sh` | Consulta a API do uupdump e gera `.tsv` com **links diretos dos domínios oficiais Microsoft**. `--search 1809` lista builds |
| `baixar_uup.sh` | Baixa os arquivos com retomada (`-c`); usa `aria2c` paralelo se existir. Aceita **filtro regex** para baixar só o necessário |
| `inspecionar_winre.sh` | Acha o `Winre.wim` (inclusive aninhado em `install.wim`/ESD/ISO) e verifica `netsh.exe`, `wlanapi.dll`, `wlanmsm.dll`, `certutil.exe`, drivers `Net*.inf` |
| `converter_iso.sh` | Usa o conversor oficial uup-dump (wimlib, multiplataforma) para gerar a ISO |
| `buscar_driver.py` | Acha o driver de um dispositivo no **Microsoft Update Catalog** pelo hardware ID (`VEN_/DEV_` ou `VID_/PID_`), baixa o `.cab` oficial e **confere se o INF cobre o dispositivo** (ignora `SUBSYS_`/`REV_`, como o Windows). `busca` / `baixa` / `inf` / `catalogo` / `lote` (um `.cab` por fabricante, tabela `drivers-1809.tsv`, cache, INF UTF-16) |
| `lote_drivers.sh` | E2 ponta a ponta: `buscar_driver.py lote` + injeta cada fabricante no Winre.wim e confere hash |
| `injetar_driver.sh` | Injeta um driver numa imagem Windows/WinRE (WIM/ESD) via `wimlib`, nos mesmos caminhos do `dism /Add-Driver`: `/Windows/INF`, `DriverStore/FileRepository`, `System32/drivers`. Faz backup e verifica. `--listar` mostra o que já está na imagem |
| `diag.cmd` | **Roda no WinRE** (não no Linux): coleta os IDs de hardware (Wi-Fi/Bluetooth) e o inventário de drivers. Detalhes em `docs/evidence/driver-injecao.md` |
| `download.vbs` | **Roda no WinRE** (não no Linux): baixa arquivo por HTTP(S) via `cscript` — supre a ausência de `certutil`/PowerShell |
| `download_ftp.txt` | Modelo de comandos para `ftp.exe -s:` no WinRE (alternativa de download) |
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
| `dossie.sh` | Inventário da imagem baixada, grava `docs/imagem/`; quem baixar a imagem roda primeiro |
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
UUP_ID=814acacb-6203-4083-b0f0-21746910e3a9  # Win10 1809 amd64 (17763.9376)
UUP_EDITION=core                             # core=Home, professional, education, enterprise
UUP_LANG=en-us                               # pt-br tambem funciona
UUP_RING=retail                              # retail | wif | dev
UUP_OUT=.work/uup                            # onde ficam lista e arquivos
UUP_DIR=.work/uup/files                      # destino do download
WORK=.work                                   # area de trabalho (ignorada pelo git)
```

Sem `aria2c`? O `baixar_uup.sh` cai para `wget`/`curl` sequencial.
Sem `wimlib`? O `ambiente.sh` tenta instalar (`wimtools` no Debian/Ubuntu,
`wimlib-utils` no Fedora, `wimlib` no Alpine/Arch). Se não conseguir, ele avisa
em vez de falhar silenciosamente.

## Links diretos oficiais

Os links saem da API pública do uupdump e apontam para **domínios da Microsoft**
(ex.: `dl.delivery.mp.microsoft.com`, `software-static.download.prss.microsoft.com`).
Eles expiram — **gere a lista fresca** com `uup_links.sh` em vez de reusar URL antiga.

Build usado neste desafio (Windows 10 **Home** 1809, amd64):
`Feature update to Windows 10, version 1809 (17763.9376)` →
`https://api.uupdump.net/get.php?id=814acacb-6203-4083-b0f0-21746910e3a9&lang=en-us&edition=core&ring=retail`
(33 arquivos, ~3,61 GB — bem menor que a ISO de avaliação do Server 2019, 5,9 GB)

## Cuidados

- **Rate limit** na API por IP: chame `uup_links.sh` poucas vezes e reaproveite o `.tsv`.
- Tudo pesado vai para `.work/` (no `.gitignore`) — nunca commite ISO/WIM.
- Rode downloads longos **em segundo plano** com log; nunca fique travado esperando.

## Setup e ambiente por agente (adicionado 2026-11-05)
- `../setupenvclaude.sh` — setup idempotente do agente `claude`: instala dependências, kernel/módulos de teste, registra o ambiente. Cada agente pode ter o seu (`setupenv<nome>.sh`).
- `registrar_ambiente.sh <agente>` — mede ESTE ambiente (CPU, RAM, ferramentas, rede) e grava `ambientes/<agente>.md`. Ambiente é por agente: nunca copie o de outro.
- `fetch-modulos-ubuntu.sh` — fallback do modloop: módulos do kernel Ubuntu via apt (quando o Alpine CDN não responde).
- `../auto.sh` — um comando, sem ler nada: setup + plano + problemas abertos + handoff.
