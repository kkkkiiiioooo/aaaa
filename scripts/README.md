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
```

## O que cada um faz

| Script | Função |
|---|---|
| `ambiente.sh` | Detecta SO/gerenciador (apt/dnf/yum/apk/pacman/brew), instala `curl wget wimlib 7z aria2 python3`, cria `.work/` e reporta disco/memória/virtualização |
| `uup_links.sh` | Consulta a API do uupdump e gera `.tsv` com **links diretos dos domínios oficiais Microsoft**. `--search 1809` lista builds |
| `baixar_uup.sh` | Baixa os arquivos com retomada (`-c`); usa `aria2c` paralelo se existir. Aceita **filtro regex** para baixar só o necessário |
| `inspecionar_winre.sh` | Acha o `Winre.wim` (inclusive aninhado em `install.wim`/ESD/ISO) e verifica `netsh.exe`, `wlanapi.dll`, `wlanmsm.dll`, `certutil.exe`, drivers `Net*.inf` |
| `converter_iso.sh` | Usa o conversor oficial uup-dump (wimlib, multiplataforma) para gerar a ISO |
| `download.vbs` | **Roda no WinRE** (não no Linux): baixa arquivo por HTTP(S) via `cscript` — supre a ausência de `certutil`/PowerShell |
| `download_ftp.txt` | Modelo de comandos para `ftp.exe -s:` no WinRE (alternativa de download) |

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
