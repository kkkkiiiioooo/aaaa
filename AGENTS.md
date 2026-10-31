# AGENTS

## Objetivo
Voce esta em uma sandbox completa. Assuma que pode e deve usar terminal, navegador, instalacao de dependencias, execucao de scripts, testes, depuracao, leitura e alteracao de arquivos para resolver o problema.

Receber apenas o link do repositorio ja e uma instrucao suficiente para agir. Nao espere orientacao extra se houver caminhos tecnicos plausiveis para continuar.

## Modo de trabalho obrigatorio
- Trabalhe na branch do projeto atual. Nao altere a branch `main` nem a branch `0`.
- Mantenha a raiz do repositorio simples e previsivel.
- Registre descobertas, decisoes, estado atual e duvidas nos documentos deste repositorio sempre que fizer sentido.
- Faca commits pequenos e frequentes.

## Autorizacao completa e proatividade obrigatoria
- O agente tem AUTORIZACAO COMPLETA para agir: usar terminal, instalar dependencias, criar arquivos, commitar e pushar no repositorio, sem pedir permissao para cada passo.
- NAO pergunte ao dono o que pode ser descoberto, testado ou deduzido de forma autonoma. Perguntas ao dono sao reservadas apenas para informacoes que dependem dele (hardware fisico, preferencias, dados do mundo real).
- Seja EXAUSTIVO: esgote as opcoes antes de desistir; teste caminhos alternativos; registre tentativas fracassadas.
- Seja PROATIVO: nao espere instrucoes detalhadas; identifique o proximo passo mais util e execute-o.
- Nao finalize a tarefa deixando passos obvios pendentes que poderiam ser executados no ambiente disponivel.

## Persistencia obrigatoria
- Nao pare cedo.
- Nao faca apenas analise estatica.
- Tente executar o projeto, nao apenas ler arquivos.
- Se algo falhar, diagnostique o erro e tente outra abordagem.
- Se faltar dependencia, instale.
- Se faltar comando obvio, procure alternativas reais.
- Se faltar documentacao, deduza pela estrutura do projeto, nomes de arquivos, scripts e convencoes da stack.
- Pesquise, teste, corrija, valide e repita ate resolver ou provar um bloqueio externo real.

## Exploracao minima esperada
Ao receber uma tarefa ou apenas o link do repositorio, faca no minimo o seguinte, nessa ordem quando aplicavel:
1. Inspecionar a arvore de arquivos.
2. Procurar `README.md`, `AGENTS.md`, `Makefile`, `Dockerfile`, `docker-compose.yml`, `package.json`, `pyproject.toml`, `requirements.txt`, scripts e testes.
3. Identificar a stack e o fluxo de execucao mais provavel.
4. Instalar dependencias necessarias.
5. Rodar testes existentes.
6. Se nao houver testes, tentar subir o projeto e validar o comportamento real.
7. Se houver interface web, abrir no navegador e verificar o resultado.
8. Se houver erro, corrigir e tentar novamente.
9. Repetir o ciclo ate obter resultado util.

## Criterio de parada
Nao considere a tarefa concluida apenas por:
- listar arquivos,
- ler documentacao,
- relatar que faltam instrucoes,
- ou descrever hipoteses sem executar.

So finalize quando ocorrer um destes casos:
1. problema resolvido,
2. projeto funcional e validado,
3. ou bloqueio externo real comprovado com evidencia suficiente.

## Autonomia real: ambiente de testes e evidencias
- Nao entregue apenas analise estatica ou planos. Prepare um ambiente de testes proprio e execute.
- Recomenda-se fortemente montar uma VM com Windows 10 1809 o mais fiel possivel ao cenario (ex.: QEMU/KVM com imagem de teste do Windows 10 1809 e particoes WinRE), reproduzindo: formatar C:, bootar no WinRE com cmd e validar cada comando do plano (dism, bcdboot, pnputil, drvload).
- Documente no repositorio: como o ambiente foi montado, comandos usados, saida real, erros encontrados e correcoes.
- Pesquise de forma exaustiva (documentacao oficial Microsoft Learn, foruns, casos reais) antes de concluir que algo nao e possivel; registre as fontes.
- Explore alem do caminho principal: teste alternativas e registre os resultados, mesmo negativos. Evidencia negativa tambem e evidencia.

## Prioridade destas regras
Este arquivo na raiz vale para todo o repositorio e deve ser seguido como instrucao padrao automatica.
