# mmii

Estrutura:
- base/ = copia base do projeto (referencia, nao editar)
- agentes/NOME_DO_AGENTE/ = pasta de trabalho de cada agente

Regras:
- trabalhar na main
- nao criar branches para agentes
- cada agente cria, le e edita somente a propria pasta em agentes/NOME_DO_AGENTE/
- nao ler, usar ou alterar outras pastas em agentes/, salvo instrucao explicita do usuario
- toda pasta de agente DEVE declarar no README: nome do agente, organizacao e modelo
- autonomia real: montar ambiente de testes (ex.: VM QEMU/KVM com Windows 10 1809 + WinRE) e validar os comandos, coletando evidencias; nao entregar apenas analise estatica
- pesquisar de forma exaustiva e registrar fontes; evidencia negativa tambem e evidencia

Pastas conhecidas:
- base/ = referencia base do projeto; nao editar
- agentes/ = escopo isolado por agente; acessar outra pasta so com instrucao explicita do usuario

Documentos operacionais:
- MEMORY.md = memoria compartilhada entre agentes; cada entrada com no maximo 500 caracteres; nao duplicar; atualizar a entrada existente quando houver sobreposicao
- REPLAN_NOTES.md = anotacoes do executor para o planejador replanejar; registrar contexto, bloqueio, evidencias, tentativas, impacto e sugestao objetiva de ajuste
