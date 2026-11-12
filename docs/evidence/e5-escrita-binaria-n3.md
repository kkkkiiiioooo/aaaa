# Evidência E5 — escrita binária no PE real: GATE FECHADO (N3, 5 caminhos)

**Agente:** brianwoo-auto (CodeBuddy Auto/Claude) · **quando:** 2026-11-12 10:18–10:28 UTC · **etapa:** E5 · **ambiente:** 32 CPU, 126 GB RAM, TCG sem KVM, QEMU 8.2.2, mem=4096, `-cpu max -smp 2`, ISO XPRESS 423 MB

## Gate

sha256 de 256 bytes `0x00..0xFF` lidos **do disco do convidado** = `40aff2e9d2d8922e47afd4648e6967497158785fbd1da870e7110266bf944880` (igual ao servido por `servir_e5.py`). **5/5 caminhos batem**, cada um com desempacotamento `lo|hi<<8` + remoção de BOM:

| artefato (disco do convidado) | caminho | tamanho no disco | sha256 ok |
|---|---|---|---|
| `wwii-256.bin` | b64 (URL `.b64`) + FSO Unicode | 258 (BOM+256) | SIM |
| `wwii-256.raw` | WinHttp ResponseBody → MSXML `bin.hex` + FSO Unicode | 258 | SIM |
| `wwii-js.bin` (4747 B ASCII) | msxml+unicode-append | 4750 | (conteúdo servido divergiu, ver "Em aberto") |
| `msxml-t.u` | roundtrip MSXML `bin.base64`→`bin.hex` in-PE, `mismatches=0` | 258 | SIM |
| `fso-t.u` / `fso-t.p` | FSO Unicode novo / append | 258 / 258 | SIM / SIM |

Log literal: `docs/evidence/e5-run1-log.txt` (run 2 = `.work/vm/wwii-final.log`, trechos citados abaixo).

## Medidas novas (mudam o entendimento)

1. **`WScript.Arguments.Count` NÃO existe em JScript** (só VBScript): `Object doesn't support this property or method` na própria linha — matou `download-js.js` e `teste-msxml-binario.js` na 1ª linha do run 1 (`e5-run1-log.txt` linhas 480/485/490). Correção: `.length`. **Isto provavelmente derrubou medições de agentes anteriores** ("base64 no PE não fecha" m072009116 testou decodificadores, mas o downloader nem chegou a rodar?).
2. **FSO ASCII `Write` QUEBRA com chars 0..255**: `Invalid procedure call or argument` (run 1, linha 480; `fso-t.a` ficou com 0 B). Não "perde com ?" — lança exceção. O caminho ASCII só serve para printable estrito (controle `.s`=36 B OK).
3. **Substitutos UTF-16 sobrevivem**: `packBytes` gera 0xD800..0xDFFF (ex. 0xD9D8) e o `Write` Unicode do PE grava sem substituir — os 256 bytes saem intactos.
4. **Hipótese "P sem BOM" REFUTADA**: append Unicode em arquivo pré-criado ASCII **também** produz BOM (258 B em `.p` e em `unicode-append` do downloader). Todo arquivo precisa do corte `FF FE` no host.
5. **MSXML2.DOMDocument.6.0 funciona no PE**: `bin.base64` e `bin.hex` com `mismatches=0` (linha 491) — conversão binária sem ADODB está disponível no WinRE 1809.
6. **WinHttpRequest no PE**: `status=200`, `ResponseText` e `ResponseBody` (tipo=unknown, SAFEARRAY) ambos utilizáveis; `SetTimeouts` aceito.

## Receita que fechou (para reproduzir)

```sh
sh scripts/obter_imagem.sh --wim
cp .work/winre-1809.wim .work/wim/Winre-e5.wim
sh scripts/injetar_autorun.sh --imagem .work/wim/Winre-e5.wim
wimlib-imagex optimize .work/wim/Winre-e5.wim --compress=XPRESS   # LZX trava no spinner TCG
sh scripts/montar_iso_winre.sh --imagem .work/wim/Winre-e5.wim --saida .work/iso/winre-e5.iso
python3 scripts/servir_e5.py --porta 8000 &
DISP=vnc=127.0.0.1:1 VNC=5901 BSOD=1 VGA=cirrus sh scripts/boot-winre.sh \
  --iso .work/iso/winre-e5.iso --timeout 2400 --poll 20 --mem 4096 --cpus 2 --cpu max
# host: mtype t:/wwii-256.bin -> cortar FF FE -> desempacotar -> sha256
```

2 runs anteriores com WIM LZX (não-XPRESS): convidado leu 271 MB da ISO e parou no spinner, 0 escritas, sem log — **XPRESS é pré-requisito do boot TCG**, não otimização opcional.

## Em aberto

- `wwii-js.bin`: servido 5515 B ASCII, ResponseText veio com 4747 chars (falta 768) — apurar (charset/chunked do `http.server`?). Não afeta o gate (256 B fechou por 3 caminhos independentes).
- **E5 ≠ canal externo**: este run usou NIC slirp do QEMU. Para a máquina real (sem rede), os bytes ainda precisam do canal teclado/tela — **E6** (`-nic none` + `sendkey`). A escrita binária agora provada é a metade de SAÍDA do pipeline; a ENTRADA continua sem prova.
