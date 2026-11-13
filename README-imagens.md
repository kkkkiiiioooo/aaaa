# Imagens do ramo `wwii`

As duas imagens grandes do projeto, na **raiz do repo**. Pedido do dono (2026-11-13).
Partes de 95 MiB porque o limite rígido do GitHub é 100 MiB por arquivo.

| pasta | arquivos | tamanho | o que é |
|---|---|---:|---|
| `winre-1809-254MB/` | `winre-1809.wim.part-00..02` | 266 283 250 B (254 MB) | WinRE 1809 (padrão), o ambiente real do desafio |
| `winre-fabrica-10586-424MB/` | `winre-fabrica-10586.wim.part-00..04` | 444 858 791 B (424 MB) | `Winre.wim` de fábrica: a **recovery real** do Mi Pad 2 (10586), extraída de `\Windows\System32\Recovery\` dentro de `miwindows/split.swm` do Windows de fábrica |

Atenção: a recovery real de fábrica é o `winre-fabrica-10586` (424 MB). O `boot.wim` de fábrica (408 MB, WinPE do instalador) **não** é a recovery — ele ficou no ramo `extras`, em `imagens/mipad2-10586-boot-408MB/`.

Remontar os 2 `.wim`: `sh remontar.sh` (o git ignora os `.wim` gerados).
Inspecionar: `wimlib-imagex dir winre-1809-254MB/winre-1809.wim 1` (instalar: `apt-get install -y wimtools`).

O ramo traz também os drivers em `drivers/` (Broadcom do Mi Pad 2, Wi-Fi e Bluetooth) — ver `drivers/README.md`.

Custo: +~700 MB em todo clone/checkout deste ramo. Para um clone leve sem as imagens: `git clone --filter=blob:none --sparse <url>` e `git sparse-checkout set --no-cone '/*' '!/winre-1809-254MB' '!/winre-fabrica-10586-424MB'`.
