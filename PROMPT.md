# DESAFIO: Recuperação do Windows sem conexões físicas

## 1. Objetivo
Restaurar o sistema operacional Windows em uma partição C: formatada, sem o uso de cabos, pendrives ou adaptadores físicos.

## 2. Contexto
- **Sistema operacional:** Windows 10 1809
- **Ambiente de recuperação:** WinRE (Windows Recovery Environment) funcional, contendo a imagem WRE.wim na partição de recuperação
- **Problema 1:** WinRE não possui driver Wi-Fi completo, resultando em erro 10 (dispositivo não pode ser iniciado) no adaptador de rede sem fio
- **Problema 2:** Driver Bluetooth é carregado pelo sistema, porém não há utilitário disponível para sua configuração e uso
- **Acesso disponível:** Terminal (cmd) acessível no WinRE, iniciado automaticamente durante o boot
- **Restrição crítica:** Ausência total de conexões físicas (cabos, adaptadores, dispositivos de armazenamento externo)

## 3. Regras para agentes
- **Responder sempre em português:** Todas as respostas, análises e comunicações devem ser feitas exclusivamente em português brasileiro.
- **Padronização técnica:** Utilizar linguagem técnica clara e objetiva, seguindo os padrões de documentação de engenharia.
- **Commits imediatos:** Qualquer alteração nos arquivos do repositório deve ser cometada e enviada para o remoto imediatamente após a modificação.
- **Tudo documentado:** NENHUMA informação, resposta ou discussão deve ser feita no bate-papo. TODAS as interações, progressos, dúvidas e soluções devem ser registradas exclusivamente nos documentos deste repositório (DECISIONS.md, OPEN_QUESTIONS.md, plans/PLAN_GOAL_MAIN.md, STATE.md, MEMORY.md).
- **Memoria compartilhada:** Registrar descobertas reutilizaveis em MEMORY.md, com no maximo 500 caracteres por entrada e sem duplicacao.
