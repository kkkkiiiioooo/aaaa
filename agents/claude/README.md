# Log do agente claude

## Claims

| Tarefa | Owner | Status |
|---|---|---|
| H0 - Criar `hypotheses.md` (todas as hipóteses + tabela de claims) | claude | [x] feito |

## Sessão 20/11/2026

- Criado `hypotheses.md` na raiz: grupos A (causa do erro 10), B (canal de texto), C (QEMU), D (instalação do driver), E (pilha WLAN), F (recuperar Windows), G (metodologia) e tabela de claims.
- Nenhum experimento executado; tudo em `hypotheses.md` é hipótese, não fato.

| H-B6 - Hex vs base64: método exato documentado e medido (docs/08-data-transfer.md) | claude | [~] em andamento |

## H-B6 (20/11/2026)

- Busca no repo: **nenhum registro de base64 funcionando**; só hex (E3, convidado Linux, PASS). Documentado em `docs/08-data-transfer.md`.
- Medido no host (não é prova): hex e base64 fazem round-trip; base64 = 0,667 do tamanho do hex; base64 exige muito mais shift/símbolos.
- Falta: teste no WinRE real (depende do E1b). Pergunta ao dono: qual agente/conversa fez base64?

| H-B12 - Medir compressao (zlib/lzma/bz2/RLE) da nvram e do firmware antes de digitar (host-only) | claude | [~] em andamento |
