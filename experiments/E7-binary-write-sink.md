# Experimento E7 — Sumidouro de escrita binária (hex digitado → bytes brutos)

## Objetivo

Existe um jeito consistente com as restrições de transformar hex/base64 digitado num
arquivo binário bruto dentro do WinRE **sem** certutil, PowerShell, .NET ou ADODB.Stream?

## Nível de fidelidade

`somente metadados` para os fatos sobre as ferramentas da imagem (presença de arquivos nas listagens verificadas).
Algoritmo no lado do host = mecânica de concatenação, **não** uma prova do WinRE e
**não** prova de hardware. O comportamento de FSO/`copy /b` no convidado está **não provado** até
que o E1 entregue um `cmd` interativo.

## Pré-condições

- Inventário em `docs/07-inventario-imagens.md` + `inventory/names-only/`.
- Python 3 no host para o selftest do alfabeto.
- Boot do WinRE (E1) antes de reivindicar que o sumidouro funciona.

## Ambiente

- Data: 16/11/2026
- Host: sandbox Linux, sem `/dev/kvm`, sem QEMU (nesta sessão)
- Hashes da imagem: não remontados aqui; listagens já verificadas em docs/07

## Fatos do inventário (observados)

Presentes (ambas as imagens, salvo indicação): `cmd.exe`, `cscript.exe`/`wscript.exe`,
`mshta.exe`, `jscript.dll`/`vbscript.dll`/`scrrun.dll`/`wshom.ocx`/`scrobj.dll`,
`msxml3.dll`/`msxml6.dll`, `crypt32.dll`, `fsutil.exe`, `expand.exe`,
`print.exe`, `esentutl.exe`, `pnputil.exe` (só 1809), WMI (`WMIC.exe`,
`wbemdisp.dll`, `stdprov.dll`).

Ausentes (ambas): `certutil.exe`, `powershell.exe`, `msado15.dll`, `mscoree.dll`,
`clr.dll`, `debug.exe`, `edlin.exe`, `findstr.exe`, `makecab.exe`,
`extrac32.exe`, `tar.exe`, `zipfldr.dll`, `wiaaut.dll`, `cdosys.dll`
(só `cdosys.dll.mui` — CDO.Message inutilizável), `bitsadmin.exe`.

MSXML decodifica base64 num array de bytes (`dataType="bin.base64"`). Nenhum sumidouro
COM de *arquivo* binário está na listagem. O WMI não tem classe identificada de arquivo de bytes brutos.
`crypt32!CryptStringToBinary` não é chamável por rundll32.

`fsutil file createnew <nome> 1` (comportamento documentado do fsutil) cria um
arquivo de 1 byte `0x00`. Essa é a única forma identificada dentro da imagem de obter um
byte NUL como texto digitado. **Não provado neste WinRE até o E1.**

## Método proposto (não provado no WinRE)

Alfabeto + `copy /b`:

1. Digitar a carga como hex (o canal já provado para *texto* no E3, convidado Linux).
2. Digitar um pequeno JScript (`scripts/winre-alphabet-decode.js`).
3. Construir 256 arquivos de um byte: `fsutil` para `0x00`; `Write(String.fromCharCode(i))` do FSO
   para `1..255`.
4. `copy /b` concatena-os em ordem hex (lotes de 16 para ficar sob os limites do cmd).

Sondagem de liberação: `scripts/winre-fso-probe.js` — cada byte deve resultar `size=1`.
Se `0x0A` virar tamanho 2 (CRLF) ou `0x00` tamanho 0, esses bytes precisam ser
obtidos de outro jeito; `0x00` está coberto pelo fsutil *se* o comando funcionar.

Plano B se o FSO corromper muitos bytes: ainda viável só para o alfabeto sobrevivente;
caso contrário só-a-nvram (texto, E3) continua a única classe de carga provada.

## Comandos

```sh
python3 scripts/alphabet-decode.py --selftest
```

## Saída observada

```text
selftest PASS
bytes 274
sha256 26925aa383aec0b40a2d1589fff0a9bb944b1833f1c5ec6ce0c9da3e1fee7eeb
```

A concatenação no host de 256 arquivos de um byte fez o round-trip de `bytes(range(256))` mais
`00 0A 0D 1A FF` mais `bcmwdidhdpcie`. Isso prova o *algoritmo*, não o FSO,
não o fsutil no WinRE, não o rádio.

## Artefatos e hashes

- `scripts/alphabet-decode.py` — selftest no host
- `scripts/winre-fso-probe.js` — sondagem de liberação no convidado (não executada)
- `scripts/winre-alphabet-decode.js` — decodificador no convidado (não executado)

## Resultado

- **Fato:** nenhum sumidouro binário clássico em nenhuma das imagens.
- **Fato:** a concatenação do alfabeto no host reconstrói bytes arbitrários.
- **Hipótese:** o WinRE consegue construir esse alfabeto com fsutil + FSO + `copy /b`.
- **Bloqueado:** a sondagem no convidado precisa do `cmd` interativo do E1.
- Não digite o driver de ~1 MB até a sondagem dar PASS.

## Limites da conclusão

QEMU/host não é prova de hardware. O E3 provou um canal de *texto* num convidado Linux,
não o WinRE e não um sumidouro binário. O caminho de carga mínima (só o texto da nvram) ainda
evita este problema por completo (hardware, E4).
