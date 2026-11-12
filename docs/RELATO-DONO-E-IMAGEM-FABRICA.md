# Relato do dono + imagem de fábrica Mi Pad 2 (10586) x WinRE 1809

2026-11-12. Fonte da imagem: https://archive.org/download/fr.twb.s_xiaomi_mipad2_factory (`20160125-10586-oobe-16G.zip`, citado no README de https://github.com/brianwoo/mipad2-win10-howto, Step 1 opção 1). Medido com `wimlib-imagex` 1.14.4 (N1/N2, offline).

## 1. Relato do dono (NÃO medido)
1. Atualização mal-sucedida (queda de energia ou bug) corrompeu o Windows.
2. Antes de formatar, havia acesso a uma recovery **diferente**: tinha PowerShell, era bem mais completa, enxergava o disco (mostrando 0 bytes/corrompido).
3. Depois de excluir e formatar, caiu na recovery atual (enxuta): driver Wi-Fi com só 3 arquivos na loja de drivers, erro 10.
4. Hipótese do dono: existem 2 recoveries; o driver incompleto pode vir do Windows (Update/loja), não do fabricante.

## 2. Onde fica a recovery (medido)
A partição de recuperação recebe o `Winre.wim`, que vem do **Windows instalado** (`\Windows\System32\Recovery\Winre.wim` + `ReAgent.xml`), não do `sources/boot.wim` da mídia (esse é WinPE/Setup). Confirmado dentro de `miwindows/split.swm`+`split2.swm` do zip de fábrica (índice 1 `miwindows`, Core, build 10586, 181 432 caminhos).

| Imagem | Bytes | PowerShell | netsh | `bcmpciedhd63.sys` | `4356r2nvram.txt` |
|---|---:|:-:|:-:|---|:-:|
| Windows de fábrica instalado (swm) | 19,8 GB desc. | sim | sim | sim, 1 041 320 B (1.558.14.0), 2 pastas na loja, completas | **sim** (`System32\drivers`, 5361 B) |
| `Winre.wim` de fábrica (extraído do swm) | 444 858 791 | não | sim | **não** | não |
| `sources/boot.wim` de fábrica | 427 727 859 | não | não | pasta OEM 1.536.0.0 (1 019 128 B, nvram `ccode=HK`) + pasta só com `.inf`+`.cat` | não |
| WinRE 1809 (`imagem`, 254 MB) | 266 283 250 | não | sim (sem `wlan`) | só o inbox 1.558.53.25 (1 037 824 B), sem nvram | não |

sha256: `Winre.wim` fábrica `152addc420748815c2cad90d382229e249ec853d3842531ddcc2b9998248067a`; `boot.wim` fábrica `3f8f446a99d0bf2742e4316a4868a0963622830e7b382b3f6070df6736ec8cc1`.

## 3. Driver: o do repositório é o de fábrica (medido)
`drivers/mipad2-oficial/wifi` x pasta `bcmwdidhdpcie.inf_amd64_0e612eeabadef583` do Windows de fábrica: **14 de 14 binários IGUAIS por sha256** (7 `.bin`, 3 `.txt`, 2 `bcmihv*.dll`, `.sys`, `.cat`) e `oem25.inf` = `bcmwdidhdpcie.inf` (26 405 B, mesmo sha256). `drivers/nvram-delta/4356r2nvram.txt` = `System32\drivers\4356r2nvram.txt` de fábrica (`a7a0a8fb…4667`). Logo o nvram que falta no WinRE existe no Windows de fábrica, no lugar e com o nome que o `.sys` pede.

Diferenças a não confundir: o `boot.wim` de fábrica traz outra versão (1.536.0.0, 2015-10-30; nvram `ccode=HK regrev=0`; o oficial/instalado tem `ccode=CN regrev=38`).

## 4. Inferências (não provadas)
- Pasta de loja só com `.inf`+`.cat` é o padrão de driver inbox da Microsoft (binários em `System32\drivers`). O "driver incompleto" do aparelho pode ser esse inbox 1809 (1.558.53.25, sem nvram nem `bcmihv*`), coerente com a hipótese 4 do dono. Para provar: listar a loja do aparelho (`dir X:\Windows\System32\DriverStore\FileRepository\bcm*` e `pnputil /enum-drivers`) e dizer quais são os 3 arquivos.
- A recovery "com PowerShell" **não foi identificada**: PowerShell só existe no Windows instalado; não está no WinRE 1809, nem no `Winre.wim` nem no `boot.wim` de fábrica. Candidatos: o próprio Windows (ou outro ambiente de outra mídia). Perguntar ao dono o que a tela mostrava.

## 5. Pendências
- `Winre.wim` de fábrica (444 MB) ainda NÃO está no repositório (só no sandbox do Composio). `boot.wim` 10586 completo (5 partes) está no ramo `imagem`.
- Confirmação no aparelho real: D5 (`HANDOFF.md`).
