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

## 3. Requisitos

| ID | Requisito | Critério de sucesso | Prioridade |
|----|-----------|---------------------|------------|
| R1 | Estabelecer conectividade de rede dentro do WinRE | Adaptador de rede sem erro 10 e endereço IP válido atribuído | Alta |
| R2 | Obter driver Wi-Fi compatível | Driver corretamente instalado e operacional | Alta |
| R3 | Reinstalar Windows sem mídia física | Sistema bootando até a tela inicial de configuração | Alta |
| R4 | Utilizar Bluetooth como rede (PAN) | Conexão funcional com celular ou outro PC | Média |
| R5 | Preservar drivers após reinstalação | Wi-Fi ativo e funcional após o primeiro boot do sistema reinstalado | Média |

## 4. Alternativas

| # | Alternativa | Requisitos | Nível de risco |
|---|-------------|------------|---------------|
| A1 | Injeção de driver Wi-Fi no WinRE via DISM pelo cmd | Arquivo .inf do driver acessível | Médio |
| A2 | Conexão Bluetooth PAN com celular | Dispositivo móvel com suporte a tethering via Bluetooth | Baixo |
| A3 | Redefinição do PC com download na nuvem | Conexão de rede funcional | Baixo |
| A4 | Restauração a partir da partição de recuperação | Partição de recuperação intacta e acessível | Baixo |
| A5 | Reinstalação por rede (PXE/WDS) | Servidor PXE/WDS disponível na LAN | Alto |

## 5. Critério de seleção
Selecionar a alternativa que atenda ao maior número de requisitos (R1 a R5) com o menor nível de risco associado.

---

## 6. Regras para agentes
- **Responder sempre em português:** Todas as respostas, análises e comunicações devem ser feitas exclusivamente em português brasileiro.
- **Padronização técnica:** Utilizar linguagem técnica clara e objetiva, seguindo os padrões de documentação de engenharia.
- **Commits imediatos:** Qualquer alteração nos arquivos do repositório deve ser cometada e enviada para o remoto imediatamente após a modificação.
- **Tudo documentado:** NENHUMA informação, resposta ou discussão deve ser feita no bate-papo. TODAS as interações, progressos, dúvidas e soluções devem ser registradas exclusivamente nos documentos deste repositório (DECISIONS.md, OPEN_QUESTIONS.md, PLAN.md, STATE.md).
