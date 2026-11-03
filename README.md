# Branch `imagem` — pacote offline do Windows 1809

Branch **órfã**: não tem histórico com `main`/`wwii`. Você não a baixa "por acidente"
se clonar com `--filter=blob:none` (é o que o `iniciar.sh` faz).

Existe para um caso concreto: **agente sem condição nenhuma de rodar emulação**
(sem TCG disponível, sem tempo, sem disco). Esse agente ainda pode inspecionar o
conteúdo real do ambiente de recuperação e raciocinar sobre solução, em vez de
esperar pela E1.

## Conteúdo e custo medido

| arquivo | bytes | o que é |
|---|---|---|
| `winre-1809.wim.part-00..02` | 99 614 720 ×2 + 67 053 810 | WinRE exportado do índice 2 de `Core_en-us.esd`, LZMS, **`--boot` aplicado** (`Boot Index: 1`). Juntos = 266 283 250 bytes = 254 MB |
| `subset-inspecao.tar.xz` | 65 534 392 | 249 MB extraídos, 1 917 arquivos: `Windows/INF`, `System32/config` (hives), `System32/drivers`, `System32/DriverStore`, `Windows/Boot`, `sources` |
| `MANIFEST.sha256` | — | hash de tudo acima |

Por que dividido: o limite **rígido** do GitHub é 100 MiB por arquivo (104 857 600
bytes) — rejeição no push, sem plano pago que mude isso. 95 MiB por parte dá folga.
O `subset` coube num arquivo só.

Por que NÃO está aqui o WinRE extraído por inteiro: medido, ele são 1,2 GB em 17 669
arquivos e o git empacota isso em **450 MB** — permanente em todo clone, para sempre.
O subconjunto acima cobre o que se consulta em inspeção offline por ~1/7 disso.
Nenhum arquivo individual passa de 26 MB, então o gargalo é volume, não o limite
por arquivo.

## Obter

```sh
sh scripts/obter_imagem.sh --fs     # so o sistema de arquivos de inspecao (62 MB)
sh scripts/obter_imagem.sh --wim    # so o WIM do WinRE montavel (254 MB)
sh scripts/obter_imagem.sh --all    # os dois
```

O script confere `MANIFEST.sha256` antes de desfazer a divisao e de extrair. Se o hash
bater, o que voce tem e bit a bit o que foi medido na E2/na geracao do dossier.

## Uso tipico sem emulacao

```sh
zcat docs/imagem/winre-caminhos.txt.gz | grep -i <hwid-ou-binario>   # nao precisa de nada daqui
# com o --fs baixado:
grep -ril "<HWID>" .work/fs/Windows/INF/            # que INF cobre este hardware
python3 scripts/ler_hive.py .work/fs/Windows/System32/config/SYSTEM   # servicos presentes/ausentes
```

## Limites do que esta aqui

- WinRE **de fabrica**, edicao `Core`/en-us, build 17763. Nada de OEM.
- O `.wim` e a imagem de recuperacao isolada; **nao** e uma ISO inicializavel (falta
  `bootmgr`/BCD do indice 1 montados em midia — ver `scripts/converter_iso.sh`).
- E estatico. Nao prova comportamento em runtime — ver a hipotese do `wcmsvc.dll` em
  `docs/imagem/DOSSIE.md` §4, que so fecha com boot de verdade.
