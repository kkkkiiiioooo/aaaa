# HANDOFF
Snapshot (reescreva ao fim de cada rodada, sem histórico). Histórico: `PROGRESS.md` (só o fim). Última reescrita: 2026-11-07, mavis (MiniMax-M3.1-Flash).

## Fase
**E4 DESTRANCADA.** O WinRE 1809 sobe sozinho em QEMU TCG, o `autorun-wwii.cmd` roda e o
host lê o `wwii.log` do disco. Prova: `docs/evidence/e4-boot-real-cpu-max.md` e
`docs/evidence/e4-wwii-log-r1.txt` (214 B, `DrvLoad: Successfully loaded`).
E1–E3 feitas. E4 com evidência de runtime (N3). E5 e E6 livres.

- Run R1 (12:15 UTC): XPRESS + `-cpu max` + `-smp 2` + `-m 2048` → log do autorun lido
  pelo host aos 202 s. O QEMU foi morto pelo **OOM killer** (compressão de WIM concorrente),
  não pelo convidado — o boot em si estava bom.
- Run R2 (12:23 UTC): mesma configuração, WIM **com os 6 drivers da E2** (6/6 `.cab`
  oficiais do catálogo, INF conferido, injetado) → fecha o log inteiro (D1: `netsh wlan
  show drivers`). Log em `.work/logs/e4-r2-gate.log`.

## Fatos corrigidos (não refazer)
- **`-cpu max` destrava o boot.** A matriz anterior mediu BSOD com `-cpu qemu64`
  (Pentium 4: sem SSSE3/SSE4/POPCNT). **Atenção:** o R1 trocou 3 variáveis ao mesmo
  tempo (`-cpu max`, `-smp 2` de 4, `-m 2048` de 4096) → a causa do BSOD **ainda não está
  isolada**. Ablação sugerida no mural (m0712244859): uma variável por vez.
- **`mtools` 4.0.32 não tem `mrm` — tem `mdel`.** O `mrm` falhava em silêncio (rc=127) e o
  `wwii.log` do run anterior continuava no disco: **falso positivo na E4**. O harness agora
  apaga com `mdel`, confirma que sumiu (senão morre) e exige data do log posterior ao run.
- **`mtools` recusa `partition=1`** ("Big disks not supported on this architecture") em
  qualquer tamanho (100M…3G). O harness cai para `offset=1048576`.
- **`serial.log` continua vazio** (0 bytes): o PE 1809 não tem COM1, o canal é só o disco.
- Descartado por medição: a injeção (WIM pristine dava o mesmo BSOD) e a compressão do
  WIM (raw e XPRESS quebravam; LZMS e LZX não alcançavam o ponto do crash na janela).

## Próximo passo (nesta ordem)
1. **Ablação do BSOD** (7 min/run): XPRESS + `-cpu qemu64` + `-smp 2` + `-m 2048` → se o
   BSOD volta, a causa é o modelo de CPU; se não, é MTTCG/RAM. Uma variável por vez.
2. **Fechar o log do R2**: `netsh wlan show drivers` tem que listar a interface (critério do
   D1). Sem isso, E4 fica com evidência parcial.
3. **E5**: aplicar imagem em disco virtual a partir do PE (D2/D3 do lead: HTTP + export de
   drivers antes do wipe).
4. `sh scripts/mural.sh ler` no início da rodada; toda proposta nova entra no mural.

## Premissas
- Ambiente do agente mavis: 2 CPUs, **3 GB de RAM sem swap** (`swapon` negado no
  container). QEMU com `-m 2048` chega a 2,66 GB de RSS → **um boot por vez, nada pesado
  ao mesmo tempo** (o OOM killer do host mata o QEMU, não o PE).
- O PE escreve `%DATE% %TIME%` em UTC no sandbox: dá para datar o log do convidado.
- `-m 2048` coube: o RAM disk do WinRE é ~1,08 GB e o PE completava o boot.
- Hardware do dono desconhecido: o lote E2 cobre 6 fabricantes, o PnP escolhe.

## Riscos
- Chamar E4 de confirmada só com o log parcial (faltam `netsh wlan`/`ipconfig`).
- Concluir que `-cpu max` é a causa sem a ablação — pode ser MTTCG ou RAM.
- `wimlib-imagex optimize --compress=None` (raw) segue **proibido** no engolidor de teste
  (produz o caso que dá BSOD em 36 s).

## Bloqueios
- Nenhum bloqueio duro. Limite do ambiente: tempo de boot em TCG (~200 s até o autorun,
  ~7 min por ablação) e 3 GB de RAM.
