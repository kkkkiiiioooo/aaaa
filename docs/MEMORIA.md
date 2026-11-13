# MEMORIA (ler primeiro numa conversa nova)

Existe porque conversas acabam e o contexto some. Estado + descobertas + receitas ficam aqui, no repositório.

## Protocolo (obrigatório para quem trabalha neste repo)
1. Conversa nova: clonar (skill aaaa), ler este arquivo inteiro e `docs/RELATO-DONO-E-IMAGEM-FABRICA.md`, depois `HANDOFF.md`.
2. A cada etapa concluida ou descoberta medida: `sh scripts/mem.sh "o que foi feito/descoberto + onde esta o dado"` (1 a 3 linhas, antes de seguir). O hook envia.
3. Mudou o estado geral (secao "Estado")? Reescreva a secao. O diario (fim do arquivo) so recebe linhas novas, nunca apague.
4. Nunca gravar segredo (token, passphrase) aqui nem em commit. Registrar so "onde pegar".
5. Separar sempre: MEDIDO (com arquivo/hash/comando) x RELATO do dono x INFERENCIA.

## Estado (2026-11-12)
Alvo: Xiaomi Mi Pad 2 (x86, Broadcom BCM4356 Wi-Fi). Problema: WinRE sem Wi-Fi funcional, erro 10; loja de drivers do aparelho com so 3 arquivos.
- MEDIDO: driver `drivers/mipad2-oficial/wifi` e `drivers/nvram-delta/4356r2nvram.txt` sao IDENTICOS (sha256, 14/14 + INF) ao Windows 10 10586 de fabrica instalado. Detalhes e tabela: `docs/RELATO-DONO-E-IMAGEM-FABRICA.md`.
- MEDIDO: a recovery real (`Winre.wim`) sai do Windows instalado (`\Windows\System32\Recovery\`), nao do `boot.wim`. `Winre.wim` de fabrica = 444 858 791 B, sha256 `152addc420748815c2cad90d382229e249ec853d3842531ddcc2b9998248067a`; sem Wi-Fi/nvram/PowerShell (igual a 1809 em espirito).
- MEDIDO: PowerShell so existe no Windows instalado. A "recovery com PowerShell" do relato do dono NAO foi identificada.
- RELATO: dono tinha uma recovery diferente, completa, antes de formatar; depois caiu na enxuta. Hipotese dele: driver incompleto vem do Windows, nao do fabricante (coerente com pasta so `.inf`+`.cat` = padrao inbox; nao provado).
- Pasta `imagens/` no ramo `wwii` (desde 2026-11-13, pedido do dono; agora com 3 WIMs: 1809, `boot.wim` 10586 e `Winre.wim` de fábrica `winre-fabrica-10586` em 5 partes, 444 858 791 B, Build 10586, Boot Index 1, também no ramo `imagem`; exceção `!imagens/*.wim.part-*` no `.gitignore`): WinRE 1809 (3 partes) + `boot.wim` 10586 de fábrica (5 partes), com `MANIFEST.sha256`, `WIMS.sha256`, `remontar.sh` (`sh imagens/remontar.sh`). Verificado em clone novo do GitHub: hashes OK, `wimlib` abre. Custo: +~700 MB por clone (README tem comando de clone leve).
- Ramo `imagem` (origem, continua existindo) (github.com/kkkkiiiioooo/aaaa): `winre-1809.wim.part-00..02` (254 MB) e `mipad2-10586-boot.wim.part-00..04` (427 727 859 B, completo, `sha256sum -c MANIFEST.sha256` OK). Remontar: `git archive origin/imagem 'mipad2*' | tar -x && cat mipad2-10586-boot.wim.part-0? > m.wim`.
- PENDENTE: listar a loja de drivers do aparelho (quais 3 arquivos); D5/E6 em `HANDOFF.md`; identificar a recovery com PowerShell (perguntar ao dono o que a tela mostrava).
- SEGURANCA: um token GitHub foi exposto no chat de 2026-11-12 e usado no sandbox do Composio (apagado de la). Dono deve gerar novo e revogar o antigo.

## Receitas (para nao refazer)
- Fonte da imagem: https://archive.org/download/fr.twb.s_xiaomi_mipad2_factory/20160125-10586-oobe-16G.zip (6,5 GB). Entradas uteis: `20160125-10586-oobe-16G/sources/boot.wim`; `.../miwindows/split.swm` (3,49 GB) + `split2.swm` (1,92 GB) = imagem completa (indice 1 `miwindows`, Core, build 10586).
- Rede: o `bash_tool` local so alcanca github/npm/pip/cargo (NAO archive.org). Baixar/processar em `COMPOSIO_REMOTE_BASH_TOOL` (carregar com `tool_search` query `COMPOSIO_REMOTE_BASH_TOOL`, limit 1). Sandbox remoto: usuario sem root, 20 GB livres, 3 min por chamada: tarefas longas com `nohup ... &` e conferir depois.
- Composio desta conta: so Box, Dropbox e Apify conectados (sem GitHub). Enviar ao repo exige token temporario no sandbox (apagar depois: `rm ~/.git-credentials`).
- Extrair so um arquivo do zip: `pip install remotezip`; `RemoteZip(url).open(nome)` em streaming. `.swm` vem com deflate no zip: ler por Range pela posicao COMPRIMIDA e descomprimir com `zlib.decompressobj(-15)`; retomar reconectando em `inicio+bytes_comprimidos_lidos` (~9 MB/s por arquivo, 2 em paralelo). Download simples travou a 0 MB/s uma vez.
- `wimlib-imagex` local: `apt-get install -y wimtools`. No remoto (sem root): baixar https://wimlib.net/downloads/wimlib-1.14.4.tar.gz, `./configure --prefix=$HOME/wl/inst --without-fuse --without-ntfs-3g && make && make install`; usar `LD_LIBRARY_PATH=$HOME/wl/inst/lib`.
- WIM dividido: `wimlib-imagex dir|extract split.swm 1 <caminho> --ref='split*.swm' --dest-dir=ex --no-acls` (nao existe `--ref` no `info`).
- O sandbox do Composio pode ser REINICIADO (id muda) e perder `/home/user`; guardar so no GitHub. Envio sem checkout: clone `--depth 1 --no-checkout --filter=blob:none`, indice temporario (`GIT_INDEX_FILE`, `read-tree`, `hash-object -w`, `update-index --cacheinfo`, `write-tree`, `commit-tree`, `push <sha>:refs/heads/<ramo>`), uma parte por commit; o push para o 2º ramo sai quase de graça (blobs já no servidor). `curl` pelo Range do zip levou ~40 MB/s na 2ª vez.
- Armadilha: `pkill -f dl2.py` num comando cujo texto contem `dl2.py` mata a propria sessao; usar `pkill -f "[d]l2.py"`.
- Comparar driver: sha256 por arquivo (INF do repo `oem25.inf` = `bcmwdidhdpcie.inf` de fabrica; mesmos 26 405 B).

## Diario (so acrescentar; usar scripts/mem.sh)
- 2026-11-12T19:00Z ramo imagem completo (boot.wim 10586, 5 partes) + MANIFEST ok; commits cf68b85, 1d18a57.
- 2026-11-12T19:45Z imagem de fabrica (swm) aberta: Winre.wim de fabrica 444 858 791 B sem Wi-Fi; driver do repo identico ao de fabrica (14/14); doc 01922c6.
- 2026-11-13T07:52Z teste do mem.sh: memoria automatica ativa; skill de memoria agora manda ler docs/MEMORIA.md e gravar a cada etapa
- 2026-11-13T08:01Z pasta imagens/ no wwii (1809 + boot.wim 10586, 8 partes) publicada e verificada em clone novo (commit e00563d); falta Winre.wim de fabrica (so no sandbox Composio)
- 2026-11-13T08:11Z Winre.wim de fabrica (444858791 B, sha256 152addc4...067a) enviada: imagens/ (wwii, d37a59c) e ramo imagem; remontar.sh OK nos 3 WIMs; wimlib abre como WinRE x64 build 10586; token apagado do sandbox Composio
- 2026-11-13: MEDIDO `Winre.wim` de fabrica so tem Broadcom SDIO (BCM4324/43341), sem PCIe 43EC/4356 (`docs/evidence/winre-fabrica-10586-drivers.md`). Ramo `imagem` agora so tem `mipad2-10586-boot.wim` (boot.wim do instalador, NAO e a recovery); WinRE 1809, subset e Winre de fabrica ficam em `imagens/` (wwii).
