# DECISIONS.md — Agente GLM

| ID | Data | Decisão | Justificativa | Impacto nos requisitos |
|----|------|---------|---------------|------------------------|
| D001 | 2026-10-27 | Priorizar A4 (restauração a partir da partição de recuperação) como alternativa principal | Única alternativa que ataca R3 **sem depender de rede** (R1/R2), sem risco de rede/conexão física e com a partição de recuperação íntegra. Atende ao critério da seção 5 do AGENTS.md: máximo de requisitos com menor risco. | R3 (alta prioridade) direto; R5 parcial |
| D002 | 2026-10-27 | Repriorizar A1 para plano B (antes de A2) | A1 depende de fonte local do driver .inf — incerta, mas inofensiva tentar. A2 (Bluetooth PAN) exige utilitário ausente no WinRE 1809 e não entrega R3 sozinho; mesmo com PAN, não há mecanismo nativo de download/reinstalação no cmd do WinPE. | R1, R2 (plan B) |
| D003 | 2026-10-27 | Descartar A5 (PXE/WDS) nesta fase | Sem servidor PXE/WDS na LAN (premissa do AGENTS.md) e sem rede funcional — dependência dupla bloqueante e risco alto. Revisita-se apenas se A1 e A2 liberarem rede. | — |
| D004 | 2026-10-27 | Tratar A3 (nuvem) como consequência da Fase 2, não como alternativa independente | “Download na nuvem” exige pipeline de rede funcional (R1) primeiro. Reordenado logicamente após A1. | R3 (plan C) |
| D005 | 2026-10-27 | Estratégia para R5: exportar drivers da imagem local antes do wipe final | Usar `DISM /Export-Driver` sobre a imagem de recuperação montada (se contiver driver store) e/ou copiar `C:\Windows\Inf` pós `/Apply-Image`, garantindo reinjeção no primeiro boot do Windows reinstalado. | R5 |
