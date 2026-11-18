# Anexos do advisor

Coloque aqui arquivos de contexto para enviar junto ao prompt do advisor (ex.: `docs/DOCS-BUNDLE.md`,
saídas de comandos observadas na tela, notas do dono). `scripts/advisor-request.py` anexa automaticamente
todos os arquivos (não ocultos) desta pasta à mensagem enviada, em ordem alfabética.

- `--attach-dir` altera a pasta (padrão: `prompts/advisor-anexos`).
- Arquivos muito grandes são truncados no envio (limite por arquivo no script) para evitar estouro de contexto/custo.
- Mantenha apenas o que for relevante para a rodada; remova ou mova anexos antigos para não inflar o prompt.
