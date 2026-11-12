# HANDOFF
Snapshot (reescreva ao fim de cada rodada, sem historico). Historico: `PROGRESS.md` (so o fim). Ultima reescrita: 2026-11-12T10:45Z, brianwoo-auto (CodeBuddy Auto/Claude).

## Fase
**E5 FEITA (N3). Front 0b: hipotese do nvram virou N2 (prova no binario). Falta E6 (entrada por teclado) e a maquina real.**

- E1–E5 feitas. E5 fechada por brianwoo-auto: gate 256 B sha256 ok **5/5 caminhos** no PE real (`docs/evidence/e5-escrita-binaria-n3.md`).
- E6 sob lease de `claude` (2026-11-12T09:53Z, ativa) — nao toquei.
- Front 0b entregue: `drivers/nvram-delta/` + passo no `autorun-wwii.cmd` + PROMPT.md atualizado.

## Fatos que nao refazer (novos, medidos nesta rodada)
- **JScript no PE nao tem `WScript.Arguments.Count`** (so VBScript): `Object doesn't support...` na propria linha; use `.length`. Isto matava `download-js.js`/`teste-msxml-binario.js` na 1a linha antes de qualquer teste.
- **FSO ASCII `Write` lanca excecao** (`Invalid procedure call`) com chars 0..255 — nao substitui por `?`. So printable estrito (controle `.s` OK). Escrita binaria = FSO **Unicode** empacotado `lo|hi<<8` + cortar BOM `FF FE` no host.
- **Substitutos 0xD800..0xDFFF sobrevivem** ao Write Unicode do PE (256 bytes saem intactos).
- **BOM `FF FE` em TODO caminho Unicode**, inclusive append em arquivo pre-criado (hipotese P refutada).
- **MSXML2.DOMDocument.6.0 funciona no PE**: `bin.base64`/`bin.hex` roundtrip `mismatches=0`; WinHttpRequest: status 200, ResponseText e ResponseBody utilizaveis.
- **Boot TCG exige WIM XPRESS**: com LZX o convidado le a ISO inteira (271 MB) e para no spinner, 0 escritas no disco, sem log (2 runs medidos). XPRESS + `-cpu max -smp 2` + mem 4096: autorun completo em ~3 min.
- **Nvram (0b, N2)**: `bcmpciedhd63.sys` monta `\SystemRoot\system32\drivers\%04Xr%dnvram.txt` (= `4356r2nvram.txt`) e o WinRE tem **0** nvram.txt; strings `dhd_bus_download_firmware() failed`/`dongle nvram file download failed` no binario. Delta = 1 arquivo 5361 B: `drivers/nvram-delta/4356r2nvram.txt` (sha256 `a7a0a8fb..`).
- Drivers: ver `PROMPT.md`. E2–E5 mediram com host e NIC do QEMU (slirp); nada disso e canal externo para a maquina real.
- ftp.exe so PORT; slirp recusa. certutil e ADODB ausentes. `wwii-js.bin` grande (5515 B servidos, 4747 recebidos via ResponseText): apurar charset/chunked antes de confiar em ASCII grande.

## Proximo passo (nesta ordem)
1. **E6 (com claude)**: PE com `-nic none`, bytes so por `sendkey`/QMP, reconstrucao com ferramentas do INVENTARIO, conferir sha256 lendo o disco. Medir bytes/s, teto e perda 0x81..0x9F. A escrita no PE ja esta provada (E5); falta a ENTRADA.
2. **0b CONFIRMADO so na maquina real (D5)**: `diag.cmd` do dono copia `4356r2nvram.txt` (se existir em algum volume) + `pnputil /scan-devices` + `netsh wlan show drivers` — o autorun da branch ja faz. Antes: checar_firmware.py no pacote real do dono.
3. Apurar o `wwii-js.bin` truncado (ResponseText 4747/5515) se ASCII grande vier a ser usado.
4. D1 (wlansvc sem wcmsvc) ja medido em E4 (wlansvc sobe); revalidar so se a maquina real divergir.

## Premissas
- Ambiente brianwoo-auto: 32 CPU, 126 GB RAM, sem KVM, Ubuntu, QEMU 8.2.2 (apt), mtools/xorriso/wimlib via apt. T0–T3 todos viaveis; boot TCG ~3 min com XPRESS.
- Nome do nvram derivado do INF oficial (`4356r2`); rev do chip nao confirmada no aparelho.

## Riscos
- Chamar de solucao um passo que nao diz por qual canal os bytes chegam a maquina (E5 usou slirp; maquina real nao tem rede).
- `4356r2nvram.txt` pode nao bastar se o subsys/rev divergir: o INF oficial cobre 8 DEVs; so o aparelho decide.

## Bloqueios
- Nenhum ativo. E6 e com claude; 0b depende da maquina real (D5 do lead).
