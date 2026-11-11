# E5 escrita binaria no PE — desenho e medida N1

Data: 2026-11-11. Agente: stackai. Nivel: N1 (host). N3 pendente (T3 exige mem>=3072; este ambiente tem 1991 MB).

## O buraco

`download-js.js` ASCII (N3, 2026-11-07) grava byte a byte so quando o arquivo e ASCII.
FSO ASCII no cp1252 perde 0x81, 0x8D, 0x8F, 0x90, 0x9D (viram `?`). ESD assinado cai nesses bytes.
ADODB.Stream e certutil.exe ausentes (INVENTARIO). ftp.exe so faz PORT (NAT/slirp recusa).

## Duas camadas (nao misturar)

1. **Transporte** — `ResponseText` ja passa por codepage. Bytes crus so vêm de:
   - `ResponseBody` via MSXML2.DOMDocument `bin.hex` (msxml3.dll e msxml6.dll EXISTEM no PE 1809), ou
   - corpo **base64** (ASCII puro) + decoder JScript.
2. **Escrita** — depois de ter os bytes 0..255, FSO ASCII volta a perder 0x81..0x9F.
   Hipotese (claude m1119315048, N0): FSO Unicode grava wchar = 2 bytes (`lo | hi<<8`).
   BOM `FF FE` em arquivo novo; caminho P = ASCII vazio + append unicode (medir).
   Sidecar `<dest>.len` guarda o tamanho original (byte impar).

Unicode empacotando `ResponseText` **nao** recupera bytes ja perdidos no transporte.
Por isso o downloader tenta MSXML/base64 **antes** de empacotar.

## Risco UTF-16

Empacotar 0..255 gera 4 code units em 0xD800..0xDFFF (`0xD9D8` primeiro).
JScript/WSH pode substituir surrogates. `teste-fso-binario.js` e `teste-msxml-binario.js`
gravam o payload no disco do convidado para o host comparar.

## Como medir no proximo boot (agente com T3)

```
python3 scripts/servir_e5.py --porta 8000
# no harness: boot WinRE; autorun ja chama os dois testes + download b64/unicode
# host le C:\fso-t.u C:\msxml-t.u C:\wwii-256.bin C:\wwii-256.bin.len
python3 -c "from pathlib import Path
import scripts.tests.unit.fso_unicode_pack as p
b=Path('fso-t.u').read_bytes(); n=256
print(p.unpack_file(b,n)==bytes(range(256)))"
```

Gate: sha256 de 256 bytes 0x00..0xFF lido do disco do convidado = sha256 do original.

## N1 neste ambiente

`python3 scripts/tests/unit/fso_unicode_pack.py` → PASS (unpack BOM/sem BOM, base64, cp1252, impar).
T3 nao cabe: doctor mem=1991 < 3072.
