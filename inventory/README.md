# Inventário

Nomes de arquivo (sem caminho) das duas imagens WIM verificadas: WinRE 1809 oficial e firmware de fábrica 10586.
Resumo curado e descobertas decisivas: `docs/07-inventario-imagens.md`.

As listagens com caminho completo foram removidas (eram grandes, ~7 MB); continuam no histórico do git
(commit anterior a este) se for preciso consultar um caminho.

## Estrutura

```
names-only/
  winre-1809/<tipo>.txt            nomes únicos, ordenados, um por linha
  winre-fabrica-10586/<tipo>.txt
  delta-*.names.txt                binários só numa das imagens (ativos = sem WinSxS; binaries = com WinSxS)
```

Tipos: `executaveis` (.exe .com .scr .efi), `bibliotecas` (.dll .ocx .cpl .drv .ax .tlb), `drivers` (.sys),
`inf` (.inf .inf_loc .pnf), `catalogos` (.cat), `manifestos` (.manifest .mum), `idiomas` (.mui .nls),
`scripts` (.js .vbs .cmd .bat .ps1 ...), `config` (.ini .xml .xsd .reg .mof .mfl .cdxml .dat .cdf-ms),
`fontes` (.fon .ttf .otf), `outros` (resto, inclui arquivos sem extensão).

Exemplo de busca: `grep -ri cscript inventory/names-only/winre-1809/executaveis.txt`
Busca em tudo: `grep -rix 'expand.exe' inventory/names-only`

## Para regerar (scripts)

```sh
wimlib-imagex dir <wim> 1 > /tmp/lista.txt                       # caminhos completos (só em /tmp)
scripts/extract-basenames.py /tmp/lista.txt -o /tmp/nomes         # tira o caminho
scripts/dividir-inventario.py /tmp/nomes/lista.names.txt -o inventory/names-only/<imagem>
```

Limite: sem caminho, não dá para saber se um `.exe`/`.dll` está em `System32` (utilizável pelo `cmd`) ou só em
`WinSxS`. Existir como nome não prova que roda no WinRE.
