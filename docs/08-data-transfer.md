# 08 — Transferência de dados (texto digitado → arquivo no WinRE)

Documento de referência: **o que está provado, o que não está, e o método exato** para levar dados ao aparelho.
Regra de evidência de `AGENTS.md`: QEMU/host nunca é prova de hardware; mock nunca é prova.

## 1. Resposta direta: existe registro de base64 funcionando?

**Não.** Busca em todo o repositório (`grep -ri base64`, histórico de commits, `experiments/`, `docs/`, `prompts/`):

- `base64` aparece só como **opção citada** (`GOAL.md`, `README.md`, `qemu/README.md`, `ANOTACOES-IMPORTANTES.md`: "hex/base64") e em `experiments/E7-binary-write-sink.md` ("MSXML decodifica base64 num array de bytes", **não provado**).
- Nenhum experimento registra base64 digitado e reconstruído, nem no WinRE real nem em convidado.
- Se um agente fez isso numa conversa antiga, **não foi registrado no repo**. Para registrar: informe qual agente/conversa (ou cole o método) e eu documento aqui como "relato do dono, não verificado" até haver experimento.

O que **está registrado e provado**:

| Item | Resultado | Onde | Limite |
|---|---|---|---|
| Hex digitado → arquivo, nvram 5.361 B, SHA-256 confere | PASS | `experiments/E3-typed-text-channel.md` | Convidado **Linux busybox**, não WinRE. Usou ACK pela serial, que **não existe no aparelho** |
| Mesmo canal sem ACK, ritmo fixo | FALHOU (5317/5361 B) | E3 (nota de método) | Teclas perdidas quando o convidado atrasa |
| Reconstrução no WinRE (E3b) | **Bloqueado** | `experiments/E3b-ascii-hash-prep.md` | Depende do E1/E1b alcançar o `cmd` |
| Sumidouro binário (E7) | **Não provado** | `experiments/E7-binary-write-sink.md` | Depende do E1/E1b |

## 2. Fatos medidos agora (host-only, NÃO é prova de WinRE)

Comando: `python3 scripts/compare-hex-b64.py <arquivos>` (decodificadores ES3 em `scripts/hex-b64-es3.js`, sem `atob`/`Buffer`, estilo JScript; linhas de 120 caracteres; round-trip com SHA-256).

| Arquivo | Bytes | Chars hex | Chars base64 | b64/hex | Especiais do `cmd` (hex/b64) | Round-trip hex | Round-trip b64 |
|---|---|---|---|---|---|---|---|
| `4356r2nvram.txt` | 5.361 | 10.722 | 7.148 | 0,667 | 0/0 | PASS | PASS |
| `4356a2rtecdc.bin` (firmware) | 641.951 | 1.283.902 | 855.936 | 0,667 | 0/0 | PASS | PASS |
| `bcmpciedhd63.sys` | 1.037.824 | 2.075.648 | 1.383.768 | 0,667 | 0/0 | PASS | PASS |

Leitura:

- **Algoritmo** de hex e de base64 reconstrói byte a byte (host). Isso só prova a matemática, não o WinRE.
- Base64 tem **33% menos caracteres** que hex.
- Base64 exige **muito mais maiúsculas e símbolos**: na nvram, 3.656 dos 7.148 caracteres não são minúscula nem dígito. No teclado touch isso significa trocar de modo (shift/símbolos) com frequência, mais toques por caractere e mais risco de autocorreção/auto-capitalização. Hex usa só `0-9a-f` (um modo do teclado, sem maiúscula) — **hipótese** H-B6/H-B7, não medida no TabTip.
- Nenhum dos dois contém caracteres especiais do `cmd` (`^ & | < > % ! " ( )`). `=` (padding), `+` e `/` do base64 não foram testados no `cmd` do WinRE.

Fatos da nvram (`drivers/nvram-delta/4356r2nvram.txt`):

- 5.361 B, 222 linhas, **terminadores LF (sem CRLF)**, último byte `0x0A`, 100% ASCII imprimível.
- Só **1** caractere especial do `cmd`: um `&`. Isso importa para quem pensar em digitar o texto direto com `echo`.
- SHA-256 `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
- Cuidado conhecido: o FSO no Windows pode converter LF em CRLF; só um teste no WinRE responde se o último byte e os LF saem idênticos (E3b "ainda não observado").

## 3. Ponto crítico: a escolha hex vs base64 não resolve o problema binário

- **nvram (texto ASCII):** não é problema binário. Hex ou base64 funcionam em tese; o que decide é o teclado e o decodificador disponível no WinRE.
- **firmware (641.951 B) e `.sys` (1.037.824 B):** são binários. Os dois encodings precisam de um **sumidouro binário** (escrever bytes 0x00–0xFF). Sem `certutil`, PowerShell, .NET e ADODB (ausentes, E7), o FSO escreve só texto. Proposta do E7: 256 arquivos de 1 byte + `copy /b` (**não provada**).
- **Volume digitado:** firmware em hex = 1.283.902 caracteres; em base64 = 855.936. Digitar isso à mão no touch é, na prática, inviável. Por isso a hipótese **H-B13** (o firmware já existe localmente e só precisa ser copiado/renomeado, sem digitar) é a mais valiosa a verificar antes de qualquer transferência binária.
- **MSXML + base64** (`dataType="bin.base64"`): decodifica para array de bytes, mas ainda falta como gravar esses bytes em arquivo. Só serve se existir um gravador binário.

## 4. Método exato conhecido (E3b) — texto ASCII, ainda não provado no WinRE

Fonte: `experiments/E3b-ascii-hash-prep.md`, `scripts/winre-ascii.js`, `scripts/prepare-ascii-transfer.py`.

1. Gerar a folha no host: `python3 scripts/prepare-ascii-transfer.py --chunk-size 128 > /tmp/e3b-sheet.md` (42 pedaços de 128 B, um comando por pedaço com SHA-256).
2. No `cmd` do WinRE: `md "%TEMP%\mipad-e3b"`, `cd /d "%TEMP%\mipad-e3b"`, `notepad ascii.js`.
3. Digitar o `ascii.js` no Notepad (salvar como **ANSI**, nome `ascii.js` e não `ascii.js.txt`).
4. `cscript //nologo ascii.js selftest`.
5. Digitar um pedaço por vez; conferir o ACK **na tela** (não há serial).
6. Verificar: `cscript //nologo ascii.js verify 4356r2nvram.txt 5361 a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`
7. Antes da nvram completa: sonda curta de CRLF/espaços finais/metacaracteres (`scripts/winre-fso-probe.js`).

Diferença chave em relação ao E3: no E3 o ACK vinha pela porta serial; no aparelho o único retorno é a **tela**. O controle de fluxo real é humano: digitar, ler o resultado, seguir.

## 5. O que falta para fechar (testes necessários)

Ordem recomendada, cada item com o que refuta:

1. **Alcançar o `cmd` no WinRE** (E1b, dono: qoder) — desbloqueia tudo. Sem isso, nada abaixo é prova.
2. H-B3: `cscript` + JScript + FSO executam? (`where cscript`, `cscript //nologo` com `.js` mínimo)
3. H-B1/H-B2: TabTip digita no `cmd`; limite de linha.
4. **Hex no WinRE** (E3b): nvram completa, hash confere. Refutação: bytes perdidos, LF virando CRLF, hash divergente.
5. **Base64 no WinRE:** repetir a mesma nvram em base64 com `scripts/hex-b64-es3.js` adaptado a `WScript`/FSO; comparar taxa de erro de digitação e tempo com o hex.
6. Sumidouro binário (E7): `fsutil file createnew` + FSO + `copy /b`; só então fazer sentido o firmware.
7. H-B13: procurar o firmware já local antes de qualquer digitação.

Decisão provisória (marcada como hipótese): **hex para a nvram primeiro**, porque é o único caminho com PASS registrado (E3), usa um único modo de teclado e não tem caracteres especiais; **base64 como segunda rodada** para comparar, pois reduz 33% o volume.

## 6. Artefatos desta rodada

- `scripts/hex-b64-es3.js` — decodificadores ES3 hex/base64 (teste de host).
- `scripts/compare-hex-b64.py` — comparação e round-trip (teste de host).
- Status: **host-only / não é prova**. Nenhuma execução em WinRE ou hardware.
