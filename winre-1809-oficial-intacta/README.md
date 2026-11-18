# WinRE 1809 — fonte oficial intacta

Esta pasta substitui `winre-1809-254MB/`, que foi removida porque o WIM de 254 MB
ali era um arquivo **derivado** sem cadeia de procedência. Esta pasta foi reconstruída
a partir do ESD oficial verificado em 15/11/2026. Ela carrega o ponteiro oficial, os
dados de verificação e o WinRE extraído da mídia oficial.

"Intacta" significa que o **conteúdo** veio da Microsoft sem modificação e foi verificado
contra os digests oficiais antes da extração. O contêiner WIM é produzido
localmente pelo wimlib, então os seus bytes não são um fluxo da Microsoft: não existe
arquivo oficial de 254 MB.

## Procedência verificada (15/11/2026)

| Passo | Comando | Resultado |
|---|---|---|
| Fonte oficial | URL assinada devolvida por `api.uupdump.net get.php` | `Core_en-us.esd`, 522.499.063 bytes |
| SHA-1 | `sha1sum Core_en-us.esd` | `8352af7661fb4808decc0253f6d516b7c2d88605` — confere |
| SHA-256 | `sha256sum Core_en-us.esd` | `b4d37e913b7cd5bf6de0b3c61ba05054e45e81e090d1767f649e825078115887` — confere |
| Extração | `wimlib-imagex export Core_en-us.esd 2 winre-1809-oficial.wim --compress=LZMS --boot` | 266.283.224 bytes |
| WIM SHA-256 | `sha256sum winre-1809-oficial.wim` | `232199c585111bfae71ff00dbdcabe5c75195fc9b431eb4d1711b8a7e471eb6c` |
| Metadados | `wimlib-imagex info ... 1` | build 17763, 17.669 arquivos, 3.560 diretórios, 2.169.435.125 bytes |
| Lista de arquivos | diff de `wimlib-imagex dir` contra o antigo WIM derivado | 21.230 caminhos idênticos |
| Estado de drivers | `diff -r` contra `drivers/estado-dispositivo/` | 11 arquivos idênticos byte a byte |
| nvram | `wimlib-imagex dir ... | grep nvram` | ausente |

Consequência: o antigo WIM derivado era equivalente em conteúdo a esta extração oficial.
A diferença era só o contêiner: o antigo não tinha digest que o vinculasse à Microsoft.

## Artefato oficial

| campo | valor |
|---|---|
| Build | Feature update to Windows 10, version 1809 (17763.9376), amd64 |
| Edição / idioma | `core` (Home) / `en-us` |
| Arquivo de origem | `Core_en-us.esd` |
| Tamanho | 522.499.063 bytes |
| SHA-1 | `8352af7661fb4808decc0253f6d516b7c2d88605` |
| SHA-256 | `b4d37e913b7cd5bf6de0b3c61ba05054e45e81e090d1767f649e825078115887` |
| WinRE | índice 2 do ESD — `Microsoft Windows Recovery Environment (x64)`, Edition ID `WindowsPE`, build 17763 |

## Link direto

`winre10-1809-254mb.url` aponta para a página do build:

```
https://uupdump.net/selectlang.php?id=814acacb-6203-4083-b0f0-21746910e3a9
```

Endpoint resolvedor que devolve as URLs do CDN da Microsoft exatamente para este build:

```
https://api.uupdump.net/get.php?id=814acacb-6203-4083-b0f0-21746910e3a9&lang=en-us&edition=core&ring=retail
```

As URLs por arquivo dentro da resposta da API são **links assinados da Microsoft que expiram**.
Resolva-os de novo a cada download. Ferramentas históricas:

```sh
git show f76aab8:scripts/uup_links.sh    # resolver -> .tsv (url, name, size, sha1)
git show f76aab8:scripts/baixar_uup.sh   # download com aria2c do arquivo selecionado
```

A branch `backup` guarda um único arquivo, `wwii-2026-11-09_2325.zip`. Ele foi extraído
e os seus membros `.gz` (`winre-caminhos.txt.gz`, `setupmedia-caminhos.txt.gz`)
descomprimidos: são só listas de caminhos e não contêm URL de download. O link acima vem
do resolvedor, não do backup.

## Arquivos aqui

| Arquivo | Bytes | SHA-256 |
|---|---:|---|
| `winre-1809-oficial.wim.part-00` | 99.614.720 | `bb45f28686202ff5cebbc361b9e9afacde2d890cf88758929a5b59a172b7b46b` |
| `winre-1809-oficial.wim.part-01` | 99.614.720 | `d230b55c81b41f176c330418fa9c9a601ba5de327f94833def3d94dec0b4b1a9` |
| `winre-1809-oficial.wim.part-02` | 67.053.784 | `b8b6aacfc5b6582ab76f20faaf5a290fb89850b7f52a0dd1944215ef1347bad0` |

`SHA256SUMS` cobre as partes. `SHA256SUMS.reassembled` cobre o
`winre-1809-oficial.wim` unido, para que quem juntar as partes possa provar o resultado com
`sha256sum -c SHA256SUMS.reassembled`. `SHA1SUMS` cobre o ESD oficial. Dividido
porque o GitHub rejeita arquivos acima de 100 MiB; cada parte fica abaixo de 95 MiB.

## Remontar e verificar

```sh
cat winre-1809-oficial.wim.part-* > winre-1809-oficial.wim
sha256sum -c SHA256SUMS
sha256sum -c SHA256SUMS.reassembled   # o arquivo unido
wimlib-imagex info winre-1809-oficial.wim 1
```

Um comando faz tudo e imprime uma única linha — use isto em vez de ler
hashes na conversa:

```sh
scripts/verify-images.sh                 # as duas imagens versionadas
scripts/verify-images.sh winre-1809-oficial-intacta
KEEP=1 scripts/verify-images.sh          # mantém o WIM unido e imprime o caminho dele
```

Ele confere cada parte, junta-as, compara o resultado com `SHA256SUMS.reassembled` e
com o digest registrado, e (quando o wimlib está instalado) o build e as contagens de
arquivos e diretórios. Saída 0 significa verificado. `scripts/verify-repo.sh` faz o mesmo dentro da
verificação mais ampla do repositório, e também confere as pastas do DriverStore, a ausência da nvram e o
alvo do `.url`.

Para baixar a origem de novo e repetir a cadeia: obtenha a URL assinada do
endpoint resolvedor, confira os dois digests acima, e então execute o comando de extração.

`official-manifest.txt` é a listagem oficial completa dos 33 arquivos deste build
(nome, tamanho, SHA-1), transcrita de `docs/imagem/manifest.txt` (histórico do git, removido
em `92bf46d`).

A revisão de cada documento e item de evidência que usou a antiga imagem derivada está em
`docs/06-auditoria-imagem-1809.md`.

## Não commitado de propósito

O ESD (522 MB) não é commitado: o `.gitignore` exclui `*.esd` e o `AGENTS.md`
proíbe commitar imagens. A extração do WinRE é commitada por pedido explícito do usuário,
dividida em partes, com os digests da fonte oficial registrados acima.
