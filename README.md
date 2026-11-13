# Branch `imagem` — apenas o `boot.wim` 10586 (Mi Pad 2)

Branch órfã. Contém **somente** `mipad2-10586-boot.wim.part-00..04` (427 727 859 B, 5 partes de até 95 MiB).

- É o `sources/boot.wim` da ISO de fábrica `20160125-10586-oobe-16G` (WinPE do instalador). **NÃO é a recovery.**
- A recovery real do aparelho é o `Winre.wim` de fábrica (444 858 791 B, sha256 `152addc4…067a`): fica em `imagens/winre-fabrica-10586.wim.part-*` no ramo `wwii`.
- WinRE 1809 e `subset-inspecao.tar.xz` também foram para `imagens/` no `wwii`.

Remontar e conferir: `cat mipad2-10586-boot.wim.part-* > mipad2-10586-boot.wim; sha256sum -c MANIFEST.sha256`
(o sha256 do WIM remontado está no comentário do MANIFEST: `3f8f446a…c1`).
