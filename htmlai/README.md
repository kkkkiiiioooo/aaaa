# htmlai

Playground de agente de IA multi-turno em HTML/CSS/JS puros (sem build, sem backend).
Modelos via Pollinations (`text.pollinations.ai/openai`), ferramentas via MCP (Exa por padrão).

## Rodar
- Abra `index.html` no navegador, ou publique a pasta no GitHub Pages.
- Local: `python3 -m http.server 8000` e acesse `http://localhost:8000`.

## Recursos
- 3 painéis: playground e histórico (esq.), chat com JSON expandido (centro), MCP com toggle por ferramenta (dir.).
- Loop agentic manual, streaming SSE, MCP via Streamable HTTP (resposta JSON ou SSE).
- Tudo salvo no navegador (localStorage), com contador de uso e botão de limpar.

## Limitações conhecidas
- Headers de MCP personalizado ficam em texto puro no localStorage.
- MCP sem CORS não conecta direto do navegador.
- Sem compactação de contexto, export/import, perfil por modelo ou JSON-RPC/SSE bruto na UI (ver `docs/PROMPT.md`).
