# Histórico do advisor (entrada/saída)

`scripts/advisor-request.py` salva aqui, a cada execução, uma transcrição `advisor-transcript-<timestamp>.md`
contendo o INPUT (prompt + anexos) e o OUTPUT (resposta). Nas execuções seguintes, os últimos pares são
incluídos como histórico na conversa enviada ao modelo (padrão: 4 pares; `--history-limit N`, `--no-history`).

Isso preserva contexto entre rodadas (perguntas essenciais feitas pelo advisor, respostas do dono, decisões).
