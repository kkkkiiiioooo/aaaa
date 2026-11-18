# Inventário

Material bruto extraído das duas imagens WIM verificadas (remontadas em `/tmp`, nunca na árvore de trabalho).
Resumo curado e as descobertas decisivas: `docs/07-inventario-imagens.md`.

| Arquivo | Conteúdo |
|---|---|
| `winre-1809-files.txt` | Listagem completa de caminhos do WinRE 1809 oficial (21230 caminhos). |
| `winre-fabrica-10586-files.txt` | Listagem completa de caminhos do firmware de fábrica 10586 (26461 caminhos). |
| `delta-fabrica-only-active.txt` | Binários ativos (exe/dll/sys, sem WinSxS) apenas na imagem de fábrica. |
| `delta-1809-only-active.txt` | Binários ativos (sem WinSxS) apenas na 1809. |
| `delta-fabrica-only-binaries.txt` | Delta binário completo apenas na fábrica (inclui WinSxS). |
| `delta-1809-only-binaries.txt` | Delta binário completo apenas na 1809 (inclui WinSxS). |

Para regenerar: remonte as partes, rode `wimlib-imagex dir <wim> 1` e compare os conjuntos de caminhos.
Estas são listagens de texto derivadas das imagens versionadas (não são imagens geradas); ficam versionadas para
que os agentes possam buscar qualquer ferramenta/arquivo com grep sem refazer a listagem.
