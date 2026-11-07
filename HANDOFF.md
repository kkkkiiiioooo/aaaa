# HANDOFF
Snapshot (reescreva ao fim de cada rodada, sem histórico). Histórico: `PROGRESS.md` (só o fim). Última reescrita: 2026-11-07, mavis (MiniMax-M3.1-Flash).

## Fase
**E4 resolvida no essencial. E2 refeita de verdade (runtime).**
O WinRE 1809 sobe sozinho em QEMU TCG, o `autorun-wwii.cmd` roda **inteiro** e o host lê
o log do disco. **Os 6 drivers da E2 carregam no PE** (`DrvLoad: Successfully loaded` 6/6).

- E1–E3 feitas (E3 agora com evidência de runtime, não só offline).
- E4: PE sobe sozinho + autorun completo + log lido pelo host (N3).
- E2 refeita: 6/6 `.cab` oficiais, INFs conferidos, **injetados de forma carregável** e
  **carregados de fato no PE**.
- E5 e E6 livres. Nada bloqueia o próximo passo.

## O que era o bloqueio da E4 (e como foi destravada)

A matriz anterior (`docs/evidence/boot-winre-iso.md`) mediu BSOD em toda config.
O run que destravou trocou 3 variáveis juntas: **`-cpu max`** (antes `qemu64`),
**`-smp 2`** (antes 4), **`-m 2048`** (antes 4096) — com `boot.wim` em **XPRESS**
(decompressão rápida: é o que leva o PE ao kernel em ~190 s).

**Atenção: a causa do BSOD ainda NÃO está isolada** (3 variáveis mudaram juntas).
Ablação sugerida no mural (m0712244859): uma variável por vez, ~7 min por run.

## Fatos corrigidos (não refazer)

- **O gate da E4 tinha falso positivo**: o `mtools` 4.0.32 **não tem `mrm`** (é `mdel`).
  O `mrm` falhava em silêncio (rc=127) e o `wwii.log` do run anterior ficava no disco —
  o gate "passava" com log velho. O harness agora apaga com `mdel`, **verifica que sumiu**
  (morre se não) e **exige data do log posterior ao início do run**.
- **O `mtools` recusa `partition=1`** ("Big disks not supported on this architecture") em
  qualquer tamanho → o harness cai para `offset=1048576`.
- **Drivers: "injetado" ≠ "carregável".** Três camadas de causa, todas medidas:
  1. `0x80070002` (ERROR_FILE_NOT_FOUND) → faltava o **firmware** que o INF pede em
     `[SourceDisksFiles]` (`.dat/.bin/.msc/.txt`); o script de injeção copiava só 5 extensões.
  2. `0xE000022F` ("driver package does not contain a catalog file") → faltava o **`.cat`
     ao lado do INF** em `/Windows/INF/`.
  3. Broadcom usa **`CatalogFile.NTamd64=BCM43XX64.CAT`** (catálogo 64-bit diferente do
     32-bit) → o parser pegava só a primeira linha.
  Hoje: `scripts/injetar_driver.sh` injeta o pacote inteiro + os arquivos exigidos + o
  catálogo ao lado do INF, e **verifica arquivo por arquivo** (falha se faltar).
  Detalhe: `scripts/inf_dependencias.py` lê `[SourceDisksFiles.amd64]`, `[CopyFiles]`,
  seções `.files.*`, `[ServiceInstall]`, `[CatalogFile]` e `CatalogFile.NTamd64`.
- **O co-instalador do Realtek (`rtlCoInst.*`) não existe em nenhum pacote do catálogo**
  (medido em 3 pacotes) — **e nem faz falta**: o `netrtwlane.inf` carrega mesmo assim.
- **O OOBE do WinPE é LARANJA como o BSOD.** O detector de bugcheck já confundiu os dois
  (falso positivo em 2026-11-07). Agora exige a cor saturada do bugcheck **ou** o bloco
  branco do QR code; o caso do OOBE virou regressão no teste.
- O PE 1809 **não tem COM1**: `serial.log` fica vazio. **O canal com o host é o disco.**
- Descartado por medição: a injeção (WIM pristine dava o mesmo BSOD) e a compressão do
  WIM (raw e XPRESS quebravam; LZMS e LZX não alcançavam o ponto do crash na janela).

## Próximo passo (nesta ordem)

1. **E5**: aplicar a imagem em disco virtual a partir do PE (D2/D3 do lead: HTTP para
   baixar o ESD + export de drivers antes do wipe). O caminho está aberto: o PE roda.
2. **Ablação do BSOD** (para o registro do BSOD antigo): uma variável por vez.
3. **Para a máquina do dono**: os drivers já carregam; falta provar a **interface** Wi-Fi
   (o QEMU não tem hardware Wi-Fi) e resolver o **transporte** do WIM modificado até a
   partição de recuperação (p0402452582).
4. **O OOBE** ("Choose your keyboard layout") fica esperando input depois do autorun —
   para a entrega "zero tecla" é preciso pré-configurar o layout ou não chamar `wpeinit`.

## Premissas

- Ambiente do agente mavis: 2 CPUs, **3 GB de RAM sem swap** (`swapon` negado no
  container). QEMU com `-m 2048` chega a 2,66 GB de RSS → **um boot por vez, nada pesado
  ao mesmo tempo** (o OOM killer do host mata o QEMU, não o PE).
- O PE escreve `%DATE% %TIME%` em UTC no sandbox → dá para datar o log do convidado.
- XPRESS é o caminho que funciona: o PE chega ao autorun em ~190 s; LZMS não chega.
- O QEMU **não tem hardware Wi-Fi** (só a NIC e1000): `netsh wlan show interfaces`
  responde "There is no wireless interface on the system" — ausência de adaptador, não
  falha do netsh.
- Hardware do dono desconhecido: o lote E2 cobre 6 fabricantes e **todos carregam**; o
  PnP escolhe.

## Riscos

- Chamar E4/E2 de "confirmadas" sem o log: o gate tem histórico de falso positivo (ver
  "fatos corrigidos") — sempre exigir data do log posterior ao run.
- Concluir que `-cpu max` é a causa do BSOD sem a ablação.
- `wimlib-imagex optimize --compress=None` (raw) segue **proibido** no engolidor de teste
  (produz o caso que dá BSOD em 36 s).

## Bloqueios
- Nenhum bloqueio duro. Limites do ambiente: tempo de boot em TCG (~190 s até o autorun,
  ~12 min até o fim) e 3 GB de RAM.
