# DÚVIDAS EM ABERTO

## Como Usar Este Arquivo
Este arquivo registra **todas as dúvidas técnicas** que surgem durante o processo de resolução.

**Formato para cada dúvida:**
```markdown
## [ID] - [Título da Dúvida]
- **Data:** AAAA-MM-DD
- **Agente:** [Nome do agente que levantou a dúvida]
- **Categoria:** [Técnica/Hardware/Software/Procedimento]
- **Descrição:** [Dúvida detalhada]
- **Contexto:** [Em qual alternativa/etapa a dúvida surgiu]
- **Status:** 🔍 Em aberto | ✅ Respondido | ❌ Inválido
- **Resposta:** [Resposta do criador ou análise técnica]
- **Respondido por:** [Nome de quem respondeu]
- **Data da resposta:** [AAAA-MM-DD]
- **Arquivos relacionados:** [Links para STATE.md, PLAN.md, etc.]
```

---

## Dúvidas em Aberto

## OQ003 - Qual é o Hardware ID do adaptador Wi-Fi e a arquitetura/firmware do equipamento?
- **Data:** 2026-10-27
- **Agente:** Agente-Beam-Free
- **Categoria:** Hardware
- **Descrição:** Qual o `DeviceID`/Hardware ID do adaptador Wi-Fi que apresenta erro 10? Qual a arquitetura real (`x86`/`x64`) e o firmware (UEFI/Legacy)? Sem o Hardware ID não é possível escolher um driver compatível; sem firmware não é possível definir `bcdboot /f`.
- **Contexto:** Fase 0 (diagnóstico) — bloqueia A1 e a etapa de boot de A4.
- **Status:** 🔍 Em aberto
- **Resposta:** [Aguardando execução de `wmic path Win32_PnPEntity where "ConfigManagerErrorCode=10" get Name,DeviceID` e `bcdedit /enum {fwbootmgr}` no WinRE]
- **Respondido por:** [N/A]
- **Data da resposta:** [N/A]
- **Arquivos relacionados:** PLAN.md (0.1 e 0.7), STATE.md, data.txt

## OQ004 - Existe imagem completa do Windows em algum volume local?
- **Data:** 2026-10-27
- **Agente:** Agente-Beam-Free
- **Categoria:** Software
- **Descrição:** A partição de recuperação contém apenas `Winre.wim` ou também `install.wim`/`install.esd`/`install.swm`? Existe pasta `Sources`, `Recovery\Customizations` ou imagem OEM em outro volume sobrevivente? Qual o espaço livre em C:?
- **Contexto:** Fase 0 (0.2 a 0.6) — determina se A4 é viável.
- **Status:** 🔍 Em aberto
- **Resposta:** [Aguardando `diskpart list volume`, `dir /s /b` de WIM/ESD e `dism /Get-WimInfo`]
- **Respondido por:** [N/A]
- **Data da resposta:** [N/A]
- **Arquivos relacionados:** PLAN.md (A4), STATE.md, data.txt

## OQ005 - Existe driver Wi-Fi OEM acessível localmente?
- **Data:** 2026-10-27
- **Agente:** Agente-Beam-Free
- **Categoria:** Técnica
- **Descrição:** Há arquivos `.inf`/`.sys`/`.cat` de Wi-Fi em volume sobrevivente, pasta OEM ou dentro do `WRE.wim`? Com C: formatada, o DriverStore da instalação antiga não existe. Se não houver driver local, A1 está definitivamente bloqueado.
- **Contexto:** Fase 0 (0.5) — condição de viabilidade de A1.
- **Status:** 🔍 Em aberto
- **Resposta:** [Aguardando busca por `.inf` e `pnputil /enum-drivers`]
- **Respondido por:** [N/A]
- **Data da resposta:** [N/A]
- **Arquivos relacionados:** PLAN.md (A1), STATE.md, data.txt

## OQ006 - O firmware oferece HTTP Boot ou PXE com interface suportada?
- **Data:** 2026-10-27
- **Agente:** Agente-Beam-Free
- **Categoria:** Hardware/Procedimento
- **Descrição:** O firmware UEFI possui "Network Boot"/"HTTP Boot" e driver para a interface de rede disponível (Wi-Fi ou Ethernet)? Existe servidor PXE/WDS/HTTP na LAN?
- **Contexto:** A5 — avaliar se há caminho de boot por rede sem cabo.
- **Status:** 🔍 Em aberto
- **Resposta:** [Aguardando verificação no menu de firmware e `bcdedit /enum {fwbootmgr}`]
- **Respondido por:** [N/A]
- **Data da resposta:** [N/A]
- **Arquivos relacionados:** PLAN.md (A5), STATE.md

## OQ007 - A imagem aplicada preserva o driver Wi-Fi para R5?
- **Data:** 2026-10-27
- **Agente:** Agente-Beam-Free
- **Categoria:** Software
- **Descrição:** A imagem de instalação local contém o driver Wi-Fi correspondente ao Hardware ID do adaptador? Caso contrário, será necessário injetar o driver OEM antes do reboot final.
- **Contexto:** R5 — preservação de drivers após reinstalação.
- **Status:** 🔍 Em aberto
- **Resposta:** [A ser confirmado após inventário da imagem e comparação com o Hardware ID (OQ003)]
- **Respondido por:** [N/A]
- **Data da resposta:** [N/A]
- **Arquivos relacionados:** PLAN.md (R5), DECISIONS.md (D007), STATE.md

---

## Dúvidas Respondidas / Encerradas

## OQ001 - Suporte a Bluetooth PAN no WinRE 1809
- **Data:** 2026-10-27
- **Agente:** Agente-Beam-Free
- **Categoria:** Técnica
- **Descrição:** O WinRE do Windows 10 1809 possui suporte nativo a Bluetooth PAN/NAP para tethering com celular?
- **Contexto:** Alternativa A2.
- **Status:** ✅ Respondido (análise técnica)
- **Resposta:** O WinRE 1809 **não** inclui o stack PAN/NAP nem utilitário de pareamento/configuração Bluetooth. Ainda que o driver HCI carregue, não há interface para parear o celular nem serviço de rede PAN. A2 é inviável.
- **Respondido por:** Agente-Beam-Free (análise técnica, não resposta oficial do criador)
- **Data da resposta:** 2026-10-27
- **Arquivos relacionados:** DECISIONS.md (D002), PLAN.md, STATE.md

## OQ002 - Arquivo .inf do driver Wi-Fi para A1
- **Data:** 2026-10-27
- **Agente:** Agente-Beam-Free
- **Categoria:** Técnica
- **Descrição:** Onde localizar o arquivo `.inf` do driver Wi-Fi compatível, sem conexões físicas?
- **Contexto:** Alternativa A1.
- **Status:** ❌ Inválida como fonte de driver
- **Resposta:** A resposta anterior indicava `C:\Windows\System32\DriverStore\FileRepository\`. **Essa premissa é incompatível com o enunciado:** C: está formatada, portanto o DriverStore não existe. A análise permanece útil apenas como referência de nomenclatura (`net*`, `iwl*`, `rtwlane*`, `bcmwl*`, `athw*`). A fonte real precisa ser buscada em volumes sobreviventes, pasta OEM ou dentro do `WRE.wim` (ver OQ005). Se nada existir localmente, A1 está bloqueado.
- **Respondido por:** Agente-Beam-Free (revisão crítica)
- **Data da resposta:** 2026-10-27
- **Arquivos relacionados:** DECISIONS.md (D003, D005), PLAN.md (Fase 0.5), OPEN_QUESTIONS.md (OQ005)

---

## Categorias de Dúvidas

### 🔧 Técnicas
- Comandos, ferramentas ou procedimentos técnicos.

### 🖥️ Hardware
- Compatibilidade, drivers ou dispositivos.

### 💻 Software
- Windows, WinRE ou sistemas operacionais.

### 📋 Procedimento
- Fluxo de trabalho ou como proceder.

---

## Instruções para Agentes

1. **Antes de adicionar uma dúvida:** verifique se já existe dúvida semelhante, se a resposta está em DECISIONS.md ou se a informação está em STATE.md/PLAN.md.
2. **Ao adicionar:** use o formato padrão, seja específico e inclua o contexto.
3. **Ao responder:** preencha a resposta, mude o status, inclua autor/data e atualize STATE.md se destravar um bloqueio.
4. **Se inválida:** marque ❌, explique o motivo e mantenha o histórico.
5. **Não confunda análise de agente com resposta oficial do criador.**
