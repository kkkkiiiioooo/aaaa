# imagens/ — as imagens que ficaram neste ramo

O dono (2026-11-13) separou as imagens em dois ramos: as duas maiores foram para a
**raiz do ramo `wwii`** (`winre-1809-254MB/` e `winre-fabrica-10586-424MB/`); aqui
ficaram o `boot.wim` 10586 e o subset de inspeção.

**Uma pasta por imagem**, com o tamanho no título. Os arquivos dentro mantêm o nome do WIM:

| pasta | arquivos | tamanho | o que é |
|---|---|---:|---|
| `mipad2-10586-boot-408MB/` | `mipad2-10586-boot.wim.part-00..04` | 427 727 859 B (408 MB) | `sources/boot.wim` do Windows de fábrica do Mi Pad 2 (10586), de `20160125-10586-oobe-16G.zip` |
| `inspecao-62MB/` | `subset-inspecao.tar.xz` | 65 534 392 B (62 MB) | subconjunto do sistema de arquivos do WinRE 1809 (249 MB extraídos, 1 917 arquivos) para inspeção offline |

Atenção: o `boot.wim` de fábrica (408 MB) é o WinPE da mídia de instalação, **não** a recovery. A recovery real de fábrica é o `winre-fabrica-10586-424MB`, no ramo `wwii`.

Remontar e conferir: `sh imagens/remontar.sh` (gera o `mipad2-10586-boot.wim`; o git ignora os `.wim`).
Só conferir as partes: `cd imagens && sha256sum -c MANIFEST.sha256`.
Pacote de inspeção + boot: `cd imagens && sha256sum -c MANIFEST-imagem.sha256`.
Inspecionar: `wimlib-imagex dir imagens/mipad2-10586-boot-408MB/mipad2-10586-boot.wim 1` (instalar: `apt-get install -y wimtools`).

Custo: +~490 MB em todo clone/checkout deste ramo. Para um clone leve sem as imagens: `git clone --filter=blob:none --sparse <url>` e `git sparse-checkout set --no-cone '/*' '!/imagens'`.
