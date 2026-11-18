# Experimento E3b — reconstrução da NVRAM em ASCII digitado e SHA-256 no WinRE

## Objetivo

Reconstruir a NVRAM de 5.361 bytes dentro de um **WinRE inicializado** a partir de texto ASCII digitado e
verificar o SHA-256 usando apenas as ferramentas da imagem. Este experimento **não está completo** até
os comandos rodarem num console WinRE real e o resultado na tela ser registrado.

## Nível de fidelidade

F1 (WinRE 1809 inicializado) é exigido para um pass. Este documento registra atualmente apenas o
**procedimento**; nenhum resultado no convidado foi observado. Segundo as regras de evidência do
`AGENTS.md`, verificações simuladas/simuladas/só-do-host são **inadmissíveis como prova** e não são usadas
aqui. Nenhum mock de host acompanha este experimento.

## Pré-condições

- O E1/E1b precisa primeiro alcançar o `cmd` interativo no WinRE. Isso segue bloqueado; qoder é o owner do E1/E1b.
- `cscript` + motor JScript + FileSystemObject precisam estar confirmados funcionando **dentro do WinRE**.
- Toda a entrada deve ser digitada pelo teclado virtual da tela touch; sem clipboard,
  pasta compartilhada, ACK serial, transferência de rede ou arquivo pré-colocado no convidado.
- O dispositivo físico não é modificado. Nada é instalado num diretório de drivers.

## Ambiente

- Data: 16/11/2026
- Host: sandbox Ubuntu 22.04, Node v22.13.1, Python 3.11.1
- Virtualização: nenhuma usada para este experimento
- Hashes da imagem: SHA-256 da NVRAM `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`

## Comandos

Gerar a folha de comandos digitados no host (só preparação):

```sh
python3 scripts/prepare-ascii-transfer.py --chunk-size 128 > /tmp/e3b-sheet.md
```

Depois, num **cmd de WinRE real inicializado**, digite `ascii.js` pelo Notepad e rode os comandos do shell
e dos pedaços da folha, um pedaço por vez, registrando cada ACK na tela.
Nenhum resultado no convidado existe ainda; não marque este experimento como pass por causa da geração no host.

## Saída observada

Nenhuma no WinRE ainda (bloqueado no E1/E1b). Nenhum "teste" simulado ou só-do-host é reivindicado como prova.

O gerador produz 42 pedaços de 128 bytes cada, exceto o último. O comando final
de verificação na tela deve ser:

```bat
cscript //nologo ascii.js verify 4356r2nvram.txt 5361 a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667
```

## Artefatos e hashes

| Caminho | SHA-256 | Tamanho |
|---|---|---|
| `drivers/nvram-delta/4356r2nvram.txt` | `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667` | 5361 |
| `scripts/winre-ascii.js` | veja `git hash-object` no registro do commit | — |
| `scripts/prepare-ascii-transfer.py` | veja `git hash-object` no registro do commit | — |

Nenhum artefato de teste simulado está incluído; veja as regras de evidência em `AGENTS.md`.

## Interpretação

### Fatos observados (apenas preparação no host — não é prova)

- `scripts/prepare-ascii-transfer.py` divide a NVRAM exata de 5.361 bytes do repositório em
  42 pedaços de 128 bytes e emite um comando digitado por pedaço com o seu SHA-256.
- O gerador usa `copy /b` em ordem explícita de nomes de arquivos, não coringas.
- A origem do verificador escreve com `CreateTextFile(path, true, false)` (ANSI, sem BOM)
  e relê com `OpenTextFile(path, 1, false, 0)` (ASCII), rejeitando bytes não suportados. Esses são fatos
  de código-fonte, não comportamento executado.

### Ainda não observado (exige WinRE real)

- Se `cscript`/JScript/`CreateTextFile`/`OpenTextFile` existem e rodam neste WinRE.
- Se a escrita/leitura ANSI preserva CRLF, espaços à direita e o último byte exatamente.
- Se o SHA-256 implementado em JScript produz o digest correto no motor do WinRE.

### Hipóteses

- JScript + FSO executam no WinRE 17763. A presença no inventário é observada;
  a execução ainda não é observada.
- `CreateTextFile(..., false)` e `OpenTextFile(..., 0)` preservam CRLF e
  espaços à direita neste WinRE. Isso deve ser provado com uma pequena sondagem digitada antes.

## Decisão

- Resultado: **bloqueado** — nenhuma execução real no convidado ainda; a preparação no host não é um pass.
- Motivo: o boot do WinRE (`cmd`) não está disponível neste sandbox; o E1/E1b é o dono dessa dependência.
- Próximo experimento: depois que o E1/E1b for bem-sucedido, digite `ascii.js`, rode `selftest`, depois digite um
  pequeno cenário de CRLF/metacaracteres antes da NVRAM completa de 42 pedaços. Só um pass na tela, num WinRE real,
  fecha o E3b.

## Limitações

- Nenhuma execução no QEMU; nenhum hardware. Não é correção de Wi-Fi, não é teste de erro-10 e não é prova do
  comportamento de JScript/FSO no dispositivo.
- Verificações simuladas/só-do-host são inadmissíveis como prova e foram deliberadamente não incluídas
  para este experimento.
- Os comportamentos de `WScript.Arguments`, `CreateTextFile` e `OpenTextFile` precisam ser confirmados
  no WinRE real antes de qualquer transferência completa.
- A evidência na tela é o único canal de saída válido no dispositivo; ACKs de serial foram usados só
  pelo convidado Linux do E3 anterior e não são reutilizados aqui.

## Reversão

- Nada necessário: nenhum convidado, dispositivo, WIM, BCD ou arquivo de driver foi alterado.
- Para descartar, apague os scripts recém-adicionados e este documento.

## Referências

- `GOAL.md` — Realidade dos canais
- `AGENTS.md` — Regra de canais, regras de evidência
- `docs/07-inventario-imagens.md` — inventário de ferramentas disponíveis
- `prompts/advisor-respostas/advisor-resposta-20261115-124958.md` — recomendação ASCII-primeiro
