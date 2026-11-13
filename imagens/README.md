# imagens/ — as 2 imagens para comparação

Pedido do dono (2026-11-13): as duas imagens na raiz do `wwii`. Cópia exata dos arquivos do ramo `imagem` (mesmos blobs, mesmos hashes).
Partes de 95 MiB porque o limite rígido do GitHub é 100 MiB por arquivo.

| WIM | partes | bytes | o que é |
|---|---|---:|---|
| `winre-1809` | `winre-1809.wim.part-00..02` | 266 283 250 | WinRE 1809 (padrão, ~254 MB), o ambiente real do desafio |
| `mipad2-10586-boot` | `mipad2-10586-boot.wim.part-00..04` | 427 727 859 | `sources/boot.wim` do Windows de fábrica do Mi Pad 2 (10586), de `20160125-10586-oobe-16G.zip` |

Atenção: o `boot.wim` de fábrica é o WinPE da mídia, **não** a recovery da partição. A recovery real de fábrica (`Winre.wim`, 444 858 791 B) ainda não está aqui; ver `docs/RELATO-DONO-E-IMAGEM-FABRICA.md`.

Remontar e conferir: `sh imagens/remontar.sh` (gera `winre-1809.wim` e `mipad2-10586-boot.wim` aqui; o git ignora os `.wim`).
Só conferir as partes: `cd imagens && sha256sum -c MANIFEST.sha256`.
Inspecionar: `wimlib-imagex dir imagens/mipad2-10586-boot.wim 1` (instalar: `apt-get install -y wimtools`).

Custo: +~700 MB em todo clone/checkout do `wwii` (o ramo `imagem` existia para evitar isso). Para um clone leve sem as imagens: `git clone --filter=blob:none --sparse <url>` e `git sparse-checkout set --no-cone '/*' '!/imagens'`.
