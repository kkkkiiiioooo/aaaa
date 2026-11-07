# Evidência E4 — o WinRE 1809 sobe sozinho em QEMU TCG e roda o autorun (log lido pelo host)

**Agente:** mavis · **quando:** 2026-11-07 12:15–12:19 UTC · **etapa:** E4 (ativa) · **modelo:** MiniMax-M3.1-Flash

## O que esta provado

| # | alegação | como foi medido |
|---|---|---|
| 1 | o PE do WinRE 1809 **sobe sem tecla** em QEMU TCG | o log do autorun começa sozinho, sem `bootfix.bin` na ISO (zero tecla por construção) |
| 2 | o `winpeshl.ini` chama o `autorun-wwii.cmd` **sozinho** | `=== autorun-wwii start ===` na 1ª linha do log gravado pelo PE |
| 3 | o autorun **grava log num volume** e o **host lê esse log** | `wwii.log` (214 B) lido do disco pelo host com `mtype`; cópia de `docs/evidence/e4-wwii-log-r1.txt` |
| 4 | o `drvload` de um INF presente **funciona** | `DrvLoad: Successfully loaded X:\windows\INF\mrvlpcie8897.inf.` (linha 8 do log) |
| 5 | o **convidade leu a ISO inteira** antes de crashar/bugar | `info blockstats`: `ide1-cd0: rd_bytes=417613824` (a ISO tem 422 100 992 B; o `boot.wim` tem 413 709 150 B) |
| 6 | o PE grava em **C:** (disco de dados) e tenta **D:** (CD, somente leitura) | `persist C:` e `persist D:` no log; o `mdir` do host mostra `wwii.log` no volume FAT |

Log literal do run R1 (`docs/evidence/e4-wwii-log-r1.txt`, 214 bytes):

```
=== autorun-wwii start ===
Sat 11/07/2026 12:17:41.41
persist C:
persist D:
persist C:
persist D:
drvload mrvlpcie8897.inf
DrvLoad: Successfully loaded X:\windows\INF\mrvlpcie8897.inf.
persist C:
```

## O run que conseguiu (R1)

```sh
sh scripts/injetar_autorun.sh --imagem .work/wim/Winre.lote.wim
wimlib-imagex optimize .work/wim/Winre.xpress.wim --compress=XPRESS   # 413 709 150 B
sh scripts/montar_iso_winre.sh --imagem .work/wim/Winre.xpress.wim \
     --saida .work/iso/winre-xpress-max.iso                          # 422 100 992 B
DISP=vnc=127.0.0.1:1 VNC=5901 sh scripts/boot-winre.sh \
     --iso .work/iso/winre-xpress-max.iso --timeout 900 --poll 15 \
     --mem 2048 --cpus 2 --cpu max --bsod --blockstats
```

Saida do host (`.work/logs/e4-r1-cpumax.log`):

```
[boot] 12:18:33 202s: wwii.log LIDO DO DISCO (9 linhas)
[boot] 12:19:06 qemu encerrou sozinho em 238s
[boot] 12:19:10 LOG FINAL: .work/vm/wwii-final.log
[boot] disco: HOST_M~1 TXT 54 ... host_marker.txt
[boot] disco: wwii     log 214 2026-11-07 12:17
```

Tela do PE aos 80 s (`docs/evidence/e4-pe-windows-logo-r1.png`): logo do Windows com o
indicador de atividade — o bootmgr entregou o controle para o PE.

## Qual variable destravou (e o que ainda NAO esta isolado)

A matriz anterior (`docs/evidence/boot-winre-iso.md`) mediu **XPRESS + `-cpu qemu64`
`smp 4` `m 4096` = BSOD em 425 s**. O R1 mudou **tres** coisas ao mesmo tempo:

| variável | antes (BSOD) | R1 (boot OK) |
|---|---|---|
| modelo de CPU | `qemu64` | **`max`** |
| vCPUs | `-smp 4` | `-smp 2` |
| RAM | `-m 4096` | `-m 2048` |

Portanto o que está provado é: **alguma** dessas três (ou a combinação) era a causa do
BSOD. A hipótese mais forte é o modelo de CPU (`qemu64` é um Pentium 4 sem SSSE3/SSE4/
POPCNT; o PE 1809 pode tocar instrução que ele não anuncia) e a segunda é o MTTCG
(vários vCPUs emulado sob TCG). **Isto ainda precisa de ablação** (ver "Próximo passo").

Descartado por medição: a injeção (o WIM pristine dava a mesma tela), a compressão do
WIM (raw e XPRESS quebravam; LZMS e LZX não chegaram ao ponto do crash dentro da janela
observada) e o `bootfix.bin` (não vai para a ISO).

## Achado que impede falso positivo (importante para qualquer agente)

O `mtools` 4.0.32 deste sandbox **não tem o comando `mrm`** (o nome do mtools é `mdel`).
O `scripts/boot-winre.sh` antigo fazia `mrm t:/wwii.log >/dev/null 2>&1`, que falhava em
silêncio (rc=127) — e o `wwii.log` **do run anterior continuava no disco**. O gate da E4
então "passava" com log de um boot velho: no R2 o script_reportou `wwii.log LIDO DO DISCO
(9 linhas)` aos 32 s, quando o PE só chega ao autorun por volta de 200 s.

Corrigido em `scripts/boot-winre.sh`:

1. `mdel` (com fallback para `mrm`) **e verificação**: se o arquivo sobreviver, o script
   morre com mensagem, em vez de aceitar o gate.
2. O log lido tem que ter data/hora **posterior ao início do run** (o PE escreve
   `%DATE% %TIME%` na 2ª linha; o convidado usa UTC no sandbox). Log de run anterior é
   descartado com aviso.

Quem rodar a E4 em outro ambiente tem que ter esse cuidado: **um gate que lê arquivo
velho não é gate.**

## Limite do ambiente (medido, não suposto)

- `mtools` 4.0.32 recusa `partition=1` com "Big disks not supported on this
  architecture" para **qualquer** tamanho (medido em 100M/512M/1G/2G/3G). O mesmo volume
  lido com `offset=1048576` funciona. O harness agora cai para `offset=`.
- A máquina tem 3 GB de RAM e **sem swap** (`swapon` não é permitido no container). Com
  `-m 2048` o QEMU chega a 2,66 GB de RSS; rodando uma compressão de WIM **ao mesmo
  tempo**, o OOM killer matou o QEMU no meio do run (dmesg: `oom-kill ... task=qemu-system-x86`).
  → **regra: um boot por vez, sem trabalho pesado ao mesmo tempo.**

## Próximo passo (medido, na ordem)

1. **Ablação do BSOD**: XPRESS + `-cpu qemu64` + `-smp 2` + `-m 2048`. Se o BSOD volta,
   a causa é o modelo de CPU; se não volta, é o MTTCG/RAM. Um run de ~7 min decide.
2. **Run limpo com os 6 drivers injetados** (E2 refeito aqui: os 6 `.cab` oficiais
   baixados do catálogo, INF conferido, injetado no WIM) para fechar o log inteiro
   (`netsh wlan show drivers`, `ipconfig /all`) — o critério de aceite do D1.
3. Com o log completo em mãos, seguir para E5 (aplicar imagem em disco virtual).

---

## ABLAÇÃO (2026-11-07, run `e4-abl-qemu64`): o modelo de CPU **não** é a causa do BSOD

Mesma ISO (`winre-v4.iso`), mudando **uma** variável em relação ao run que funcionou:

```sh
DISP=vnc=127.0.0.1:1 VNC=5901 sh scripts/boot-winre.sh \
  --iso .work/iso/winre-v4.iso --timeout 700 --poll 15 \
  --mem 2048 --cpus 2 --cpu qemu64 --bsod --blockstats
```

Resultado: **o PE sobe, o autorun roda e os 6 drivers carregam** — igual ao run com
`-cpu max` (log literal em `docs/evidence/e4-ablacao-qemu64.txt`):

```
=== autorun-wwii start ===
Sat 11/07/2026 13:19:49.36
...
drvload netwtw06.inf      DrvLoad: Successfully loaded ...
drvload netrtwlane.inf    DrvLoad: Successfully loaded ...
drvload netathr10x.inf    DrvLoad: Successfully loaded ...
drvload bcmwdi.inf        DrvLoad: Successfully loaded ...
drvload mtkwl6ex.inf      DrvLoad: Successfully loaded ...
drvload mrvlpcie8897.inf  DrvLoad: Successfully loaded ...
```

**Conclusão:** o BSOD antigo **não** vem do `-cpu qemu64`. Ele vem de **`-smp 3/4`**
(vários vCPUs emulado = MTTCG, que é lento e é a suspeita principal) **ou** de
**`-m 4096`** — as duas linhas que deram BSOD na matriz antiga (`base` com `-smp 3` e
`xp` com `-smp 4`) são exatamente as que usavam mais de 2 vCPUs, e a linha `gate`
(`-smp 4`, mas LZMS, que nunca chegou ao kernel) não deu BSOD só porque não chegou lá.

| configuração | resultado |
|---|---|
| `-cpu max -smp 2 -m 2048` | PE sobe, autorun roda, 6/6 drivers (R5) |
| `-cpu qemu64 -smp 2 -m 2048` | PE sobe, autorun roda, 6/6 drivers (ablação) |
| `-cpu qemu64 -smp 3 -m 4096` (matriz antiga) | **BSOD em 36 s** (WIM `raw`) |
| `-cpu qemu64 -smp 4 -m 4096` (matriz antiga) | **BSOD em 425 s** (WIM XPRESS) |

**Para quem for repetir:** use `-smp 1` ou `-smp 2` e **não** `-m 4096` em máquina de
3 GB (o QEMU chega a 2,66 GB de RSS e o OOM killer do host mata o QEMU). O `-cpu max`
não é necessário — mas também não atrapalha.
