# DECISÕES TOMADAS

## Como Usar Este Arquivo
Este arquivo registra **todas as decisões importantes** tomadas durante o processo de resolução do desafio.

**Formato para cada decisão:**
```markdown
## [ID] - [Título da Decisão]
- **Data:** AAAA-MM-DD
- **Decisor:** [Nome do agente ou "Criador"]
- **Contexto:** [Explicação do problema/opção]
- **Decisão:** [O que foi decidido]
- **Justificativa:** [Por que esta decisão foi tomada]
- **Impacto:** [Como isso afeta o projeto]
- **Alternativas descartadas:** [O que não foi escolhido e por quê]
- **Arquivos relacionados:** [Links para STATE.md, PLAN.md, etc.]
```

---

## D001 - Priorizar A4 como alternativa principal
- **Data:** 2026-10-27
- **Decisor:** Agente-Beam-Free
- **Contexto:** Necessidade de reinstalar o Windows com C: formatada, sem rede, sem mídia física e sem conexões físicas.
- **Decisão:** Priorizar A4 (restauração a partir da partição de recuperação) como caminho principal para R3.
- **Justificativa:** É a única alternativa que pode produzir um Windows completo sem rede e sem mídia física, desde que exista imagem de instalação local. Também preserva drivers OEM, atendendo R5.
- **Impacto:** O foco passa a ser a Fase 0 (inventário) para confirmar a existência de `install.wim`/`install.esd`.
- **Alternativas descartadas:** A3 (depende de rede), A5 (depende de firmware/rede), A1 como prioridade 1 (depende de `.inf` local).
- **Arquivos relacionados:** PLAN.md (A4), STATE.md, OPEN_QUESTIONS.md (OQ004).

---

## D002 - Descartar A2 (Bluetooth PAN) por inviabilidade no WinRE 1809
- **Data:** 2026-10-27
- **Decisor:** Agente-Beam-Free
- **Contexto:** O WinRE 1809 carrega o driver Bluetooth, mas não possui stack PAN/NAP nem utilitário de pareamento/configuração.
- **Decisão:** Descartar A2. Registrar a inviabilidade técnica.
- **Justificativa:** Sem interface para parear o celular e sem serviço de rede PAN, não é possível iniciar tethering via Bluetooth no WinRE 1809.
- **Impacto:** R4 não será atendido por este caminho; foco em A4/A1.
- **Alternativas descartadas:** A2 (Bluetooth PAN).
- **Arquivos relacionados:** OPEN_QUESTIONS.md (OQ001), STATE.md.

---

## D003 - Invalidar o DriverStore como fonte de driver Wi-Fi (C: formatada)
- **Data:** 2026-10-27
- **Decisor:** Agente-Beam-Free
- **Contexto:** A análise anterior considerava `C:\Windows\System32\DriverStore\FileRepository` como fonte do driver Wi-Fi. O enunciado afirma que C: está formatada.
- **Decisão:** Invalidar essa premissa. A1 só é viável se houver `.inf`/`.sys`/`.cat` em volume sobrevivente, pasta OEM ou partição de recuperação.
- **Justificativa:** Com C: formatada, o DriverStore da instalação antiga não existe. Buscar driver lá seria especulação.
- **Impacto:** A1 passa a ser condicional e bloqueado até a Fase 0.5.
- **Alternativas descartadas:** A1 como prioridade 1 com base no DriverStore.
- **Arquivos relacionados:** CONFIG (fatos restritivos), PLAN.md (0.5), OPEN_QUESTIONS.md (OQ002, OQ005).

---

## D004 - Critério formal de impossibilidade
- **Data:** 2026-10-27
- **Decisor:** Agente-Beam-Free
- **Contexto:** O desafio impõe ausência total de conexões físicas, C: formatada e ausência de rede. É necessário distinguir "ainda não tentado" de "impossível nas condições dadas".
- **Decisão:** Declarar o desafio impossível se, simultaneamente: (1) não houver imagem completa do Windows em volume local; (2) não houver driver Wi-Fi compatível em volume local; (3) não houver rede funcional nem boot de rede pelo firmware.
- **Justificativa:** Sem qualquer fonte local de bits e sem rede, não existe sequência de comandos capaz de reinstalar o Windows.
- **Impacto:** O relatório final deve apresentar a árvore de decisão e a evidência do inventário, em vez de afirmar sucesso não comprovado.
- **Alternativas descartadas:** Declarar sucesso presumido com base apenas em documentação teórica.
- **Arquivos relacionados:** PLAN.md (critérios de impossibilidade), STATE.md (evidências pendentes).

---

## D005 - Não confundir análise de agente com resposta oficial do criador
- **Data:** 2026-10-27
- **Decisor:** Agente-Beam-Free
- **Contexto:** Dúvidas técnicas podem ser respondidas por análise, mas não devem ser marcadas como resposta oficial do criador sem evidência do equipamento.
- **Decisão:** Respostas técnicas de agentes são registradas como análise; dúvidas que dependem de dados do equipamento permanecem em aberto até inventário ou resposta do criador.
- **Justificativa:** Auto-respostas podem consolidar premissas erradas, como ocorreu com o DriverStore.
- **Impacto:** OQ002 passa a ❌ inválida como fonte de driver, mantendo a análise como histórico.
- **Alternativas descartadas:** Marcar auto-respostas como oficiais.
- **Arquivos relacionados:** OPEN_QUESTIONS.md, STATE.md, AGENTS.md (seção 7, quando aplicável).

---

## D006 - Executar inventário antes de qualquer tentativa de recuperação
- **Data:** 2026-10-27
- **Decisor:** Agente-Beam-Free
- **Contexto:** Tentativas de DISM/driver sem conhecer os bits disponíveis são especulação e podem corromper a partição de recuperação.
- **Decisão:** A Fase 0 é bloqueante. Nenhuma injeção de driver ou aplicação de imagem antes de concluir 0.1 a 0.7.
- **Justificativa:** Reduz risco de perda da única fonte de recuperação disponível.
- **Impacto:** Todas as alternativas aguardam o inventário.
- **Alternativas descartadas:** Tentar A1 imediatamente.
- **Arquivos relacionados:** PLAN.md (Fase 0), STATE.md.

---

## D007 - Estratégia de preservação de drivers para R5
- **Data:** 2026-10-27
- **Decisor:** Agente-Beam-Free
- **Contexto:** R5 exige Wi-Fi ativo após o primeiro boot do sistema reinstalado.
- **Decisão:** Se A4 for usado, injetar drivers OEM na imagem aplicada com `dism /Image:C:\ /Add-Driver` antes do reboot; se A1 for usado, injetar o driver Wi-Fi na imagem aplicada. Validar com `netsh wlan show drivers` após OOBE.
- **Justificativa:** Garante que o driver esteja no DriverStore do novo sistema, evitando dependência de rede pós-instalação.
- **Impacto:** Adiciona etapa obrigatória antes do reboot final.
- **Alternativas descartadas:** Confiar apenas nos drivers inbox da imagem.
- **Arquivos relacionados:** PLAN.md (R5), STATE.md.
