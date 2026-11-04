# HANDOFF

Estado atual (snapshot; reescreva ao fim de cada rodada, não faça append).
Histórico e causas das rodadas anteriores: `PROGRESS.md` (só o fim).

## Fase
Otimização de documentos e agentes (2026-11-04), em paralelo ao desafio:
- Nomes sem número: projeto chama `wwii` em README, PROGRESS e testes (assinatura `WINRE_WIM_SIGNATURE_WWII`).
- Ambiente de teste provado sem KVM e sem docker: `sh scripts/ambiente.sh` + `sh scripts/tests/run-tests.sh` termina em `SUITE: PASS` (28 PASS / 0 FAIL, ~259 s sob TCG).
- `ambiente.sh` agora instala `xorriso` (o `converter_iso.sh` precisa).
- `PRESENCA.md` automático: `agente.sh` grava `nome inicio <data UTC>`; o `post-commit` grava `nome push <data UTC> <sha>` após cada push ok. CHAT.md removido.
- `scripts/README.md` lista todos os scripts; contagens fixas de PASS removidas dos docs.

## Próximo passo
1. E2: drivers em lote por `VEN_` (`buscar_driver.py` → `.cab` 1809 → `injetar_driver.sh`).
2. E3: autorun no WinRE via `winpeshl.ini` (`SetupCommandLine`). HIPÓTESE, nunca testada aqui.
3. E4: ISO por `converter_iso.sh` (UUP 3,61 GB) e boot do PE em QEMU/TCG, com timeout alto, em segundo plano.
4. Lead: `PLANO.md` usa "frentes 1–4" e `ETAPAS.md` usa E1–E6. Sugerir ao lead unificar (via `relatorio.sh pergunta`).

## Premissas (assumidas, sem dono)
- Hardware desconhecido: cobrir chips comuns em lote.
- Runtime do driver Wi-Fi (erro 10) exige o adaptador real: limite do método, não do esforço.

## Riscos abertos
- T3 sem KVM: boot do PE sob TCG pode levar dezenas de minutos; 4 GB de RAM é o mínimo. Disco: 3,61 GB de UUP + ~5 GB de ISO.
- `HANDOFF.md` não tem `merge=union`: dois agentes simultâneos conflitam e o rebase do `post-commit` aborta. Um agente por vez reescreve.

## Bloqueios
- Nenhum depende do dono.
