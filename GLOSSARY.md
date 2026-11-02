# Site de Agente IA

Site onde uma pessoa conversa com um agente de IA conectado a ferramentas externas, feito para rodar em navegadores antigos. O prompt.md é o documento que manda construí-lo.

## Language

**Agente-playground**:
O site em si: mistura de agente de IA com playground, onde a pessoa configura quase tudo (streaming, system prompt, modelo, confirmação de ferramenta).
_Avoid_: Chatbot, IDE web

**Prompt.md**:
O documento único que contém tudo que um construtor precisa para entregar o site pronto.
_Avoid_: Pedido, briefing, instruções soltas

**Pedido único**:
Entregar o Prompt.md uma só vez, sem o usuário precisar fazer nenhum outro pedido ao construtor.
_Avoid_: Prompt inicial, primeira mensagem

**Construtor**:
Qualquer agente que lê o Prompt.md e constrói o site; o mesmo texto vale para todos.
_Avoid_: IDE, gerador, plataforma

**Navegador alvo**:
O navegador mais antigo em que o site deve funcionar: preferência Chrome 70 ou superior, aceitando Chrome 80 ou inferior.
_Avoid_: Navegador antigo, navegador legado

**Conector MCP**:
A ligação entre o site e ferramentas externas por meio do protocolo MCP.
_Avoid_: Plugin, integração

**Proxy MCP**:
A parte do servidor Hono que chama o servidor MCP no lugar do navegador e bloqueia endereços internos.
_Avoid_: Ponte, gateway

**Provedor de modelo**:
Um módulo pequeno que liga o site a uma fonte de modelo de IA por meio de uma interface única.
_Avoid_: Backend de IA, integração de modelo

**Confirmação de ferramenta**:
A pergunta feita à pessoa antes de o agente usar uma ferramenta MCP; vem ligada por padrão e a pessoa pode desligar.
_Avoid_: Permissão, autorização
