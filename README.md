# Projeto wwii

Recuperação do Windows sem conexões físicas (WinRE 1809).

Entrada de agente: `sh iniciar.sh A=<nome> M=<modelo-exato> P=wwii S_ARQ=<arquivo-da-passphrase>`. Sem prompt: `sh auto.sh`.
Leitura obrigatória, nesta ordem: `sh scripts/plano.sh` (plano do lead) · `AGENTS.md` · `PROMPT.md` · `HANDOFF.md` · `sh scripts/mural.sh ler`.
Consulta: `docs/imagem/INVENTARIO.md` (o que existe no WinRE) · `EVALS.md` (como medir avanço e comparar modelos) · `scripts/README.md` · `ETAPAS.md`.
Regra: trabalhe até se esgotar (AGENTS.md). Ambiente é por agente: `ambientes/<nome>.md`.
Branches: `wwii` (trabalho) · `lider` (decisões do lead) · `info` (prompt final) · `imagem` (WIM em partes). Nunca `main`, `0`, `backup`.
Avanço real: `sh scripts/evals.sh`. Quem citou uma ideia primeiro: `sh scripts/quem-primeiro.sh "<termo>"`.
