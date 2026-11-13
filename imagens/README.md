# imagens/ — as imagens para comparação (3 WIMs)

Pedido do dono (2026-11-13): as imagens dentro do repo. Cópia exata dos arquivos do ramo `imagem` (mesmos blobs, mesmos hashes).
Partes de 95 MiB porque o limite rígido do GitHub é 100 MiB por arquivo.

**Uma pasta por WIM** — cada uma com as suas partes e o `.wim` remontado ao lado:

| pasta | partes | bytes | o que é |
|---|---|---:|---|
| `winre-1809/` | `winre-1809.wim.part-00..02` | 266 283 250 | WinRE 1809 (padrão, ~254 MB), o ambiente real do desafio |
| `mipad2-10586-boot/` | `mipad2-10586-boot.wim.part-00..04` | 427 727 859 | `sources/boot.wim` do Windows de fábrica do Mi Pad 2 (10586), de `20160125-10586-oobe-16G.zip` |
| `winre-fabrica-10586/` | `winre-fabrica-10586.wim.part-00..04` | 444 858 791 | `Winre.wim` de fábrica: a **recovery real** do Mi Pad 2 (10586), extraída de `\Windows\System32\Recovery\` dentro de `miwindows/split.swm` do mesmo zip |
| `inspecao/` | `subset-inspecao.tar.xz` | 65 534 392 | subconjunto do sistema de arquivos do WinRE 1809 (249 MB extraídos, 1 917 arquivos) para inspeção offline |

Atenção: o `boot.wim` de fábrica (427 MB) é o WinPE da mídia de instalação, **não** a recovery. A recovery real de fábrica é `winre-fabrica-10586` (444 MB); ver `docs/RELATO-DONO-E-IMAGEM-FABRICA.md`.

Remontar e conferir: `sh imagens/remontar.sh` (gera os 3 `.wim`, cada um na sua pasta; o git ignora os `.wim`).
Só conferir as partes: `cd imagens && sha256sum -c MANIFEST.sha256`.
Pacote da imagem 1809 (partes + subset): `cd imagens && sha256sum -c MANIFEST-imagem.sha256`.
Inspecionar: `wimlib-imagex dir imagens/mipad2-10586-boot/mipad2-10586-boot.wim 1` (instalar: `apt-get install -y wimtools`).

Custo: +~700 MB em todo clone/checkout do repo (o ramo `imagem` existia para evitar isso). Para um clone leve sem as imagens: `git clone --filter=blob:none --sparse <url>` e `git sparse-checkout set --no-cone '/*' '!/imagens'`.
