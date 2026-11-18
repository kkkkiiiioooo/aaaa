# Auditoria — documentos e evidências construídos sobre a imagem WinRE 1809 derivada

Data: 15/11/2026. Escopo: todo arquivo versionado neste repositório que nomeie
`winre-1809-254MB/`, os hashes das suas partes, ou o SHA-256 remontado
`f9e30ca308aa23e83d852ccefcfe7bca09a23d7c5b759ae655557612487879b8`.

## Objeto da auditoria

A imagem de 254 MB era uma **derivação local**, não um artefato da Microsoft:

- origem: `Core_en-us.esd`, build 17763.9376, amd64, core/Home, en-us;
- digest oficial: SHA-1 `8352af7661fb4808decc0253f6d516b7c2d88605`, 522.499.063 bytes;
- derivação: `wimlib-imagex export Core_en-us.esd 2 winre-1809.wim`, LZMS, `--boot`
  aplicado (Boot Index 1);
- resultado: 266.283.250 bytes em três partes, SHA-256 `f9e30c…`, 17.669 arquivos.

Medido em 15/11/2026 a partir do histórico do git: as três partes batem com o
`SHA256SUMS` publicado, e remontá-las reproduz `f9e30c…` exatamente. Então o arquivo
versionado é o arquivo gerado; nada mudou depois da divisão. Isso não é o mesmo
que provar procedência da Microsoft: o WIM foi recomprimido e o cabeçalho reescrito pelo wimlib,
então nenhum digest oficial pode nunca conferir com ele.

## Achados

Legenda de status:

- **qualificado** — o documento já diz que a procedência não está verificada.
- **condicional** — afirma fatos retirados da imagem (presença de arquivos, versões,
  tamanhos); válido só se o conteúdo conferir com o ESD oficial. **Fechado:** o ESD
  oficial foi baixado e verificado, e a re-extração conferiu (veja *Fechamento* abaixo).
- **só-mecânica** — um teste de runtime ou servicing executado sobre o WIM derivado; a
  conclusão é sobre o procedimento, não sobre mídia oficial.
- **distribuição** — publica ou serve a imagem derivada como se fosse uma base.
- **corrigido aqui** — atualizado nesta branch por este commit.

## Fechamento (15/11/2026, ainda no mesmo dia)

A auditoria está fechada para a árvore `desafio`. A fonte oficial foi reobtida pela API
do UUP dump (URL assinada do CDN da Microsoft) e verificada antes do uso:

| Item | Valor |
|---|---|
| ESD | `Core_en-us.esd`, build 17763.9376, amd64, core/Home, en-us |
| Tamanho do ESD | 522.499.063 bytes |
| ESD SHA-1 | `8352af7661fb4808decc0253f6d516b7c2d88605` |
| ESD SHA-256 | `b4d37e913b7cd5bf6de0b3c61ba05054e45e81e090d1767f649e825078115887` |
| Extração | `wimlib-imagex export Core_en-us.esd 2 … --compress=LZMS --boot` |
| Novo WIM | 266.283.224 bytes |
| Novo WIM SHA-256 | `232199c585111bfae71ff00dbdcabe5c75195fc9b431eb4d1711b8a7e471eb6c` |
| Lista de caminhos | 21.230 entradas, idêntica ao WIM derivado |
| Metadados | 17.669 arquivos, 3.560 diretórios, 2.169.435.125 bytes, build 17763 |
| Estado de drivers | 11 arquivos nas três pastas do DriverStore, idênticos byte a byte (`diff -r`) |
| nvram | 0 ocorrências na imagem |

Consequências:

- toda linha **condicional** abaixo agora está **verificada**: os fatos foram medidos sobre
  conteúdo extraído do ESD oficial verificado;
- o WIM `f9e30c…` anterior era um contêiner diferente (recompressão do wimlib, diferença de
  250 bytes no tamanho) com o mesmo conteúdo lógico; foi superado, não estava errado;
- os resultados só-mecânica continuam só-mecânica, mas agora descrevem conteúdo
  oficial, não um arquivo de origem desconhecida.

### Branch `desafio` (desafio atual)

| Arquivo | Uso da imagem | Status |
|---|---|---|
| `docs/03-driver-wifi-erro-10.md` | versões dos pacotes inbox e tamanhos de arquivos | verificado; banner atualizado |
| `docs/04-fidelidade-mimetizacao.md` | imagem base F1/F2 e tabela de base de drivers | verificado; caminho e nota atualizados |
| `docs/05-offline-servicing.md` | pré-condição "WIM base deve conter 1.558.53.25" | verificado; caminho aponta para a extração oficial |
| `drivers/README.md`, `drivers/README.pt-BR.md` | "Origem do inbox: WIM WinRE 1809" | verificado; banner e caminho atualizados |
| `drivers/estado-dispositivo/README.md` | retrato do DriverStore extraído do WIM | verificado (11 arquivos idênticos byte a byte); banner atualizado |
| `drivers/nvram-delta/README.md` | afirmação de que não existe nvram na imagem | verificado (0 ocorrências); banner atualizado |
| `experiments/README.md` | nota da decisão de base | feito; link da auditoria presente |
| `scripts/verify-repo.sh` | partes 1809, tamanho, hash e metadados esperados | corrigido: verifica as partes de `winre-1809-oficial-intacta/` |
| `.gitattributes` | regra `winre-1809-254MB/**` | corrigido: regra obsoleta removida |
| `winre-1809-254MB/` | as partes derivadas | removida em `a04f538`; substituída por `winre-1809-oficial-intacta/` |

### Branch `wwii` (não editada neste commit)

| Arquivo | Uso da imagem | Status |
|---|---|---|
| `winre-1809-254MB/` (partes + `SHA256SUMS`) | a própria imagem derivada, ainda versionada | **distribuição** |
| `experiments/E0.1-base-provenance.md` | registra os metadados do WIM e diz que não há hash oficial de referência | qualificado |
| `experiments/E0.2-repo-verification.md` | contagem de partes e hashes de remontagem | só-mecânica |
| `experiments/E2-offline-servicing-wimlib.md` | remove/adiciona drivers numa cópia do WIM | só-mecânica |
| `docs/03-*`, `docs/04-*`, `docs/05-*` | mesmo texto da `desafio` antes desta auditoria | condicional |
| `drivers/README*`, `drivers/estado-dispositivo/README.md`, `drivers/nvram-delta/README.md` | mesmas afirmações de extração | condicional |
| `scripts/verify-repo.sh` | espera as partes derivadas | só-mecânica |

### Branch `extras` (não editada neste commit)

| Arquivo | Uso da imagem | Status |
|---|---|---|
| `docs/imagem/DOSSIE.md`, `docs/imagem/INVENTARIO.md`, `docs/evidence/winre-1809-evidencia.md` | inspeção estática do **índice 2 do ESD** (fonte oficial), não do WIM derivado | sólido sob o digest do ESD oficial; não herda o defeito |
| `docs/evidence/driver-injecao.md` | injeta um driver de catálogo no WIM e re-extrai | só-mecânica |
| `docs/evidence/drivers-lote.md` | 6 pacotes de fornecedor injetados; 254 MB para 274 MB | só-mecânica |
| `docs/evidence/e4-*.md` | boot do WIM no QEMU, autorun, carregamento de driver | só-mecânica |
| `docs/evidence/e5-*.md` | transporte HTTP/FTP dentro do WIM inicializado | só-mecânica |
| `docs/RELATO-DONO-E-IMAGEM-FABRICA.md` | linha da tabela "WinRE 1809 (`imagem`, 254 MB)" | condicional |
| `scripts/obter_imagem.sh` | distribui o WIM derivado como base 1809 | **distribuição** |
| `MURAL.md`, `PROGRESS.md`, `PROBLEMAS.md`, `PROMPT.md` | hashes, afirmações de inventário, planos | condicional/só-mecânica |
| `imagens/winre-1809/` (quando em checkout) | as partes derivadas | **distribuição** |

### Branch `info`

| Arquivo | Uso da imagem | Status |
|---|---|---|
| `README.md` | inventário do WinRE 1809 e o resultado "6/6 drivers injetados, 254 MB para 274 MB" | só-mecânica/condicional |

### Branch `htmlai`

| Arquivo | Uso da imagem | Status |
|---|---|---|
| `artefatos/manifest.tsv` | publica URLs cruas do GitHub e SHA-256 das três partes derivadas | **distribuição** |

## Veredito

Nenhum documento afirma que `f9e30c…` é um digest da Microsoft, e
`experiments/E0.1-base-provenance.md` já havia registrado que não existe hash
oficial de referência. Logo, não há reivindicação de procedência fabricada.

Para a `desafio`, a questão aberta agora está respondida: o ESD oficial foi reobtido,
verificado por digest e re-extraído; o resultado confere com a imagem derivada anterior caminho
por caminho e byte por byte no estado de drivers. O desafio, portanto, se apoia em
conteúdo oficial verificado, e os resultados só-mecânica agora descrevem esse conteúdo.

Restando fora da `desafio`: as cópias derivadas ainda publicadas na `wwii`
(`winre-1809-254MB/`) e na `htmlai` (`artefatos/manifest.tsv`). Elas continuam com o
rótulo **distribuição** e precisam de decisão nessas branches (remover, ou rotular como
derivadas com o digest oficial ao lado).

## Como a auditoria foi fechada

1. `Core_en-us.esd` baixado pelo link registrado em
   `winre-1809-oficial-intacta/winre10-1809-254mb.url`, conferindo `SHA1SUMS` e a
   contagem de bytes: 522.499.063 bytes, SHA-1 `8352af76…`. Feito.
2. Índice 2 extraído com o wimlib; novo SHA-256 do WIM registrado (`232199c5…`) e a
   lista de 21.230 entradas. Feito; a lista é idêntica à do WIM derivado.
3. `drivers/estado-dispositivo/` comparado byte a byte com a extração nova:
   `diff -r` limpo para os 11 arquivos. Feito.
4. `scripts/verify-repo.sh` re-executado contra as partes novas. Feito.
5. Decisão sobre as cópias derivadas na `wwii` e na `htmlai`: ainda aberta, acompanhada acima.
