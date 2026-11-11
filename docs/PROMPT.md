# Prompt técnico: Playground de Agente IA Multi-turno (HTML estático)

## Papel
Você é um engenheiro front-end sênior especialista em agentes de IA agentic. Trabalhe de forma autônoma e contínua até entregar o app completo e funcional. Não pare no meio, não peça confirmação a cada etapa e teste o resultado antes de finalizar.

## Objetivo
Construir um web app de agente de IA **multi-turno**, que usa **várias ferramentas (MCP) em sequência e em paralelo** dentro da mesma conversa, de forma contínua e duradoura, até a tarefa do usuário estar concluída (loop agentic: modelo → tool_calls → execução → resultado → modelo, até não haver mais tool_calls).

## Restrições técnicas (obrigatórias)
- **HTML, CSS e JavaScript puros (vanilla), em vários arquivos pequenos** (estrutura na seção "Estrutura de arquivos"). Sem framework, sem build, sem backend e sem dependências npm.
- Usar **scripts clássicos** (`<script src="js/x.js" defer>`), nunca `type="module"`, para o app funcionar também aberto direto do disco (`file://`). Cada arquivo expõe seu código em um único objeto global (ex.: `window.App.api`).
- Compatível com hospedagem estática (GitHub Pages, Cloudflare Pages, Netlify, etc.).
- Tudo roda no navegador via `fetch` e `ReadableStream` (streaming SSE).
- Sem cadastro e sem chave de API embutida.
- **Loop agentic escrito à mão em JS puro.** Não usar LangChain, OpenAI Agents SDK, Vercel AI SDK nem outro framework. Só o SDK/cliente MCP próprio, escrito à mão.

## Provedor de LLM
- API compatível com OpenAI: `https://text.pollinations.ai/openai` (rota `/chat/completions`).
- Lista de modelos: `https://text.pollinations.ai/models`, usada para popular o **seletor de modelos** (dropdown com busca, mostrando só modelos com suporte a tools quando a API informar isso).
- Suportar streaming, `tools`/`tool_calls` e `tool_choice`.
- Tratar erros: 429, timeout, JSON inválido e modelo sem suporte a tools. Mostrar a mensagem no chat e permitir tentar de novo.

### Modelo inicial e robustez (agnóstico de modelo)
- Modelo inicial: `openai-fast` (~20B), usado apenas como ponto de partida. Confirmar o nome exato em `/models`. O código **não** deve ter nada fixo para esse modelo: qualquer modelo da lista deve funcionar trocando só o seletor.
- Ajustes de robustez ficam em um **perfil por modelo** (objeto salvo no navegador, editável na UI), com valores padrão: limite de tools ativas, limite de caracteres por resultado, limite de contexto estimado, temperatura recomendada e suporte a tool calls paralelas. Um modelo mais forte pode ter limites mais altos sem mexer no código.
- Nenhum modelo acerta tool calling 100% das vezes e tarefas longas acumulam erros. O loop deve ser defensivo:
  - Validar `arguments` com `JSON.parse` em try/catch. Se falhar, devolver ao modelo um `tool` com o erro ("argumentos inválidos, tente de novo") em vez de travar.
  - Se o modelo chamar uma tool inexistente, devolver erro listando as tools válidas.
  - Detectar chamadas repetidas idênticas (mesma tool e mesmos argumentos) e interromper o loop com aviso.
  - Truncar resultados de tools em um limite configurável (padrão 8.000 caracteres) para não estourar o contexto.
  - Enviar apenas as tools ativas, com descrições curtas, e avisar na UI quando houver mais tools ativas que o limite do perfil do modelo (padrão 10, configurável).
  - Compactar o histórico quando passar de um limite de tokens estimado (resumir mensagens antigas).
- Se o modelo responder o pedido de tool como texto em vez de `tool_calls`, tratar como resposta final e mostrar um aviso discreto.

## MCP (Model Context Protocol)
- Servidor padrão pré-configurado: `https://mcp.exa.ai/mcp`.
- O usuário pode **adicionar MCP personalizado** (nome, URL e headers opcionais), editar, remover e ativar/desativar.
- Cliente MCP mínimo com transporte **Streamable HTTP** (JSON-RPC por POST no endpoint do servidor): `initialize` → `notifications/initialized` → `tools/list` → `tools/call`. Conferir na especificação a versão vigente e os headers exigidos.
  - Enviar `Accept: application/json, text/event-stream` e tratar **os dois formatos de resposta**: `application/json` (resposta única) e `text/event-stream` (SSE).
  - Guardar e reenviar o header `Mcp-Session-Id` quando o servidor o devolver.
- **SSE aparece em dois lugares distintos:** (a) streaming de tokens do Pollinations (`stream: true`, formato OpenAI) e (b) formato possível de resposta do Streamable HTTP do MCP. Usar um único parser SSE, em `api.js`, reaproveitado por `mcp.js`.
- Converter o schema das tools MCP para `tools` no formato OpenAI.
- Executar várias tool_calls do mesmo turno em paralelo (`Promise.all`) e devolver cada resultado com o `tool_call_id` correto.
- Limite de segurança de iterações do loop agentic (padrão 50, configurável, para tarefas longas) e botão **Parar** (AbortController). Ao atingir o limite, perguntar se o usuário quer continuar em vez de encerrar.
- Se um servidor falhar por CORS ou autenticação, mostrar o erro claro na UI, sem quebrar o app.

## Layout: 3 painéis (desktop) e abas/gavetas (mobile)

### Painel esquerdo: Playground + Histórico
Todos os parâmetros que a chamada da API permite:
- Seletor de modelo
- System prompt e instruções personalizadas
- `temperature`, `top_p`, `max_tokens`, `presence_penalty`, `frequency_penalty`, `seed`, `stop`, `n`
- `tool_choice` (auto/none/required), `response_format` (text/json_object), `stream` (on/off)
- Limite de iterações agentic

Abaixo, o **Histórico** de conversas: criar, renomear, buscar, excluir, exportar e importar JSON.

### Painel central: Chat
- Mensagens com streaming e renderização de Markdown (parser próprio, simples e seguro, sem `innerHTML` sem sanitizar).
- **Transparência total ("ver as entranhas"):** cada invocação aparece em `<details open>` (expandido por padrão, o usuário pode recolher) com JSON formatado e com cores mínimas (só preto, branco e azul) de:
  - o `tool_call` recebido do modelo (id, nome, `arguments` brutos e parseados);
  - a requisição JSON-RPC enviada ao MCP (`tools/call`) e a resposta bruta do servidor;
  - o resultado devolvido ao modelo (indicando se foi truncado);
  - tempo, status e erros.
- Também mostrar, em bloco expansível, o corpo JSON de cada chamada ao Pollinations (`messages`, `tools`, parâmetros) e os chunks SSE brutos, recebidos em tempo real.
- Botões globais "Expandir tudo" e "Recolher tudo", e uma configuração "Blocos JSON abertos por padrão" (ligada).
- Copiar, regenerar, editar mensagem e parar a geração.

### Painel direito: MCP
- Lista de servidores MCP, com status (conectado/erro) e botão de recarregar tools.
- Para cada servidor, lista de tools com **toggle individual** para ativar/desativar. Só as tools ativas são enviadas ao modelo.
- Formulário para adicionar MCP personalizado.
- Persistir as escolhas.

## Armazenamento e privacidade
- **Tudo salvo apenas no navegador**, nada vai para servidor próprio. O único tráfego é para Pollinations e para os MCPs configurados.
- Persistir: conversas, configurações, MCPs e toggles.
- **Contador de uso** visível (ex.: `2,3 MB / 5 MB`) com barra de progresso. Avisar em 80%.
- Botão **Limpar todos os dados** (com confirmação) que apaga tudo e reinicia o app.
- Tratar `QuotaExceededError`.
- Observação técnica: `localStorage` costuma ter ~5 MB por origem. Se o espaço for insuficiente, usar **IndexedDB** para conversas e `localStorage` só para configurações, mantendo o mesmo contador (via `navigator.storage.estimate()` quando disponível).

## Design
- Tema **preto e branco** (fundo preto, texto branco, bordas cinza finas), sem gradientes e sem outras cores.
- **Azul** (ex.: `#2563eb`) apenas para elementos selecionados/ativos: item de histórico atual, toggle ligado, aba ativa, opção marcada, foco de input.
- Fonte monoespaçada ou system-ui, layout denso e minimalista, responsivo, acessível (foco visível, labels, contraste).

## Estrutura de arquivos
```
htmlai/
├─ index.html              # entry point: layout dos 3 painéis e <script defer> na ordem abaixo
├─ README.md               # o que é, como rodar, como publicar no GitHub Pages
├─ LICENSE                 # MIT
├─ .gitignore
├─ .editorconfig           # UTF-8, LF, 2 espaços
├─ .nojekyll               # GitHub Pages serve os arquivos como estão
├─ docs/
│  └─ PROMPT.md            # este documento
├─ assets/
│  └─ favicon.svg
└─ src/
   ├─ css/
   │  └─ style.css         # tema preto e branco, azul só em seleções, variáveis CSS
   └─ js/
      ├─ storage.js        # localStorage/IndexedDB, contador de uso, limpar tudo
      ├─ md.js             # parser de Markdown seguro (sem innerHTML sem sanitizar)
      ├─ api.js            # Pollinations: /models, chat/completions, parser SSE
      ├─ mcp.js            # cliente MCP: initialize, tools/list, tools/call, testes
      ├─ agent.js          # loop agentic manual, defesas independentes de modelo
      ├─ ui.js             # render dos painéis, blocos JSON <details open>, eventos
      └─ app.js            # inicialização e ligação dos módulos
```
- Ordem de carregamento: `storage` → `md` → `api` → `mcp` → `agent` → `ui` → `app`.
- Cada arquivo com no máximo ~400 linhas e comentários curtos no topo explicando a responsabilidade.
- Nomes de pastas e arquivos em inglês (padrão da indústria), em minúsculas e sem espaços. Os scripts ficam em `src/js/` e o `index.html` os carrega como `src/js/storage.js`, e assim por diante.
- O boilerplate (`README.md`, `LICENSE`, `.gitignore`, `.editorconfig`, `.nojekyll`, `assets/favicon.svg`) segue as convenções comuns de repositórios do GitHub. O `README.md` traz: descrição, como rodar localmente, como publicar no Pages e as limitações conhecidas.

## System prompt padrão
Vem preenchido no painel esquerdo, é editável e tem botão "Restaurar padrão". O app substitui `{{data_atual}}` pela data do dia antes de enviar.
```
Você é um agente de IA proativo e autônomo que resolve tarefas do início ao fim usando ferramentas (MCP). Responda em português, de forma clara e objetiva. Trabalhe com persistência: continue agindo até a tarefa estar realmente concluída, sem parar no meio e sem pedir confirmação a cada passo.
Data atual: {{data_atual}}

Regras:
1. Antes de agir, pense no que precisa descobrir. Se a pergunta depende de fatos atuais ou verificáveis, use as ferramentas de busca. Não responda de memória.
2. Chame uma ferramenta por vez quando uma depender da outra. Chame várias juntas só se forem independentes.
3. Use apenas as ferramentas listadas, com o nome exato e argumentos em JSON válido seguindo o schema. Nunca invente ferramentas ou parâmetros.
4. Se uma ferramenta falhar ou voltar vazia, leia o erro, corrija os argumentos ou tente outra consulta. No máximo 2 tentativas por ferramenta, depois explique o que falhou.
5. Em pesquisas, faça várias consultas com termos diferentes, compare fontes e abra as páginas para ler o conteúdo, não só os resumos.
6. Não repita chamadas idênticas. Se um caminho não funcionar, mude a estratégia em vez de insistir. Pare só quando tiver informação suficiente e verificada.
7. Resposta final direta, com cada afirmação importante seguida da fonte (URL completa). O que não foi confirmado deve vir marcado como "não confirmado".
8. Nunca invente nem altere resultados de ferramentas.
9. Seja proativo: se o pedido for ambíguo, escolha a interpretação mais razoável, diga em uma linha qual assumiu e siga em frente. Só pergunte ao usuário se for impossível avançar sem a resposta.
10. Em tarefas longas, escreva antes um plano curto (3 a 6 passos), execute passo a passo, marque o que já foi feito e, no fim, confira o resultado contra o pedido original.
11. Antes de uma ação irreversível (apagar, sobrescrever, enviar dados a terceiros), avise em uma linha o que vai fazer e por quê.
```

## Decisões confirmadas
1. Agente "duradouro" = roda enquanto a aba está aberta. Fechar a aba interrompe o loop. Ao reabrir, mostra o histórico, sem retomar sozinho.
2. Sem proxy CORS. O Exa MCP já foi testado pelo usuário no navegador e funciona. Um MCP personalizado sem CORS aparece como erro claro na UI.
3. Tools executam sem aprovação humana.
4. Headers de MCP personalizado ficam no `localStorage` em texto puro, com aviso na UI.
5. Interface em português.
6. Apenas texto, sem upload de arquivos ou imagens.

## Diagnóstico de conexão (obrigatório)
- Botão "Testar" em cada servidor MCP, mostrando em JSON bruto o resultado de `initialize` e `tools/list`, o status HTTP e os headers da resposta.
- Distinguir na mensagem: erro de CORS/rede, erro HTTP, erro JSON-RPC e resposta fora do formato esperado.
- Botão "Testar modelo" que envia uma chamada mínima com uma tool de exemplo e informa se o modelo devolveu `tool_calls` válidos.

## Critérios de aceite
1. Abrir o `index.html` direto no navegador ou em Pages já funciona.
2. Seletor de modelos carregado de `/models`.
3. Exa MCP conecta, lista tools e o agente as usa em loop multi-turno.
4. Adicionar um MCP personalizado funciona e persiste.
5. Desativar uma tool no painel direito impede o modelo de usá-la.
6. Recarregar a página mantém tudo.
7. O contador de armazenamento está correto e o botão limpar zera tudo.
8. Nenhum erro no console em fluxo normal.

## Entrega
- Entregar todos os arquivos da estrutura completos (sem trechos omitidos), prontos para uso.
- Ao final, listar em até 5 linhas como testar e as limitações conhecidas (ex.: CORS de MCPs de terceiros).

## Fontes a verificar antes de codar
- [Pollinations API](https://github.com/pollinations/pollinations/blob/master/APIDOCS.md)
- [Especificação MCP](https://modelcontextprotocol.io/specification)
- [Exa MCP](https://docs.exa.ai/reference/exa-mcp)
- [MDN: Storage quotas](https://developer.mozilla.org/en-US/docs/Web/API/Storage_API/Storage_quotas_and_eviction_criteria)
