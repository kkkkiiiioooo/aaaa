# Construir um site de agente de IA (pedido único, autossuficiente)

> RASCUNHO. Seções marcadas como PENDENTE ainda estão sendo decididas na entrevista.

## 1. Objetivo
Construa um site leve que mistura **agente de IA** com **playground**: a pessoa conversa com um agente que usa ferramentas de servidores MCP, e **quase tudo é configurável pela própria pessoa**. Tudo que você precisa está neste arquivo. Não faça perguntas: tome decisões razoáveis, registre-as no README.md e termine o trabalho inteiro.

## 2. Navegador alvo (regra obrigatória)
- Mínimo preferido: Chrome 70. Aceito: Chrome 80 ou inferior.
- O front-end é HTML, CSS e JavaScript puros. Sem framework, sem etapa de build, sem pacotes pesados.
- NÃO use `?.` nem `??`. O Chrome só aceita essas sintaxes a partir da versão 80.
- Não use nenhuma sintaxe ou API mais nova que o Chrome 70. Na dúvida, confira os dados de compatibilidade da MDN antes de usar.
- Polyfills são permitidos, mas evite-os quando uma reescrita simples resolver.

## 3. Back-end
- Use Hono (`npm create hono@latest`), escrito só com APIs padrão da Web, para o mesmo código rodar em Cloudflare Workers, Node.js, Deno e Bun.
- Comece e teste no Cloudflare Workers.
- Toda parte específica de um ambiente (acesso ao modelo, segredos, armazenamento) fica atrás de uma interface pequena (adaptador). A Cloudflare usa bindings; os outros ambientes usam chaves de API em variáveis de ambiente.

## 4. Modelos
- Uma interface única, vários provedores. Cada provedor é um módulo pequeno que implementa as mesmas funções.
- Chaves de API e bindings ficam só no servidor. Nunca envie uma chave ao navegador.

## 5. Ferramentas MCP
- A pessoa cola a URL de um servidor MCP na tela.
- O navegador nunca chama essa URL. Ele chama o back-end Hono, que chama o servidor MCP (proxy).
- O proxy deve bloquear endereços internos e privados (localhost, faixas privadas, link-local, metadados de nuvem) para evitar SSRF.
- Por padrão, o agente pede confirmação antes de usar uma ferramenta. A pessoa pode desligar essa confirmação nas configurações.

## 6. Telas e funções
Telas e funções obrigatórias:
- Chat com resposta em tempo real (streaming).
- Lista das ferramentas MCP conectadas.
- Histórico de conversas.
- Troca de modelo direto na tela.

Tudo configurável pela pessoa, no mínimo:
- Streaming ligado ou desligado.
- System prompt editável.
- Confirmação de ferramenta ligada ou desligada (padrão: ligada).
- Escolha do modelo e do provedor.

PENDENTE: outros parâmetros configuráveis (por exemplo temperatura e limite de tokens) e onde guardar configurações e histórico.

## 7. Idioma
Todo o texto do site (telas, mensagens, erros) e este arquivo estão em português do Brasil.

## 8. Verificação
- A pessoa faz o primeiro teste por conta própria.
- Quando a pessoa disser que algo não funciona: escreva testes automáticos e um roteiro de teste que reproduzam o problema, corrija e rode tudo de novo até passar.
- A CONFIRMAR: entregar também um script único de verificação rápida (por exemplo `npm test`) já na primeira entrega.

## 9. Entregáveis e repositório
PENDENTE (depende da configuração do repositório no GH: pasta, branch, git push, README.md, comandos para rodar e publicar).
