# Branch `imagem` — apenas o `boot.wim` 10586 (Mi Pad 2)

Branch órfã. Contém **somente** o `boot.wim` 10586 em `imagens/mipad2-10586-boot-408MB/` (427 727 859 B = 408 MB, 5 partes de até 95 MiB).

- É o `sources/boot.wim` da ISO de fábrica `20160125-10586-oobe-16G` (WinPE do instalador). **NÃO é a recovery.**
- A recovery real do aparelho é o `Winre.wim` de fábrica (444 858 791 B = 424 MB, sha256 `152addc4…067a`): fica em `imagens/winre-fabrica-10586-424MB/` no ramo `extras`.
- WinRE 1809 e `subset-inspecao.tar.xz` também foram para `imagens/` no `extras`.

Remontar e conferir:
`cat imagens/mipad2-10586-boot-408MB/mipad2-10586-boot.wim.part-* > imagens/mipad2-10586-boot-408MB/mipad2-10586-boot.wim`
(o sha256 do WIM remontado está no comentário do MANIFEST: `3f8f446a…c1`).

Só conferir as partes: `sha256sum -c MANIFEST.sha256` (a partir da raiz da branch).
