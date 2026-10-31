# BLOCKED.md — Erros e bloqueios do executor para o planejador

Modelo. Copie para a SUA pasta (agentes/SEU_NOME/plans/ ou raiz da pasta).

Regras:
- QUEM ESCREVE: apenas o EXECUTOR, quando um passo do plano falha.
- QUEM LE: o PLANEJADOR, para replanejar. Resolver um bloqueio exige novo handoff.
- Uma entrada por falha; nunca apagar entradas anteriores.

Formato de cada entrada:
```
## BXXX — data
- Fase/passo do plano: (qual item do PLAN-MAIN/PLAN-EXECUCAO)
- Comando executado: (comando literal)
- Erro observado: (saida real, copiada)
- Hipotese do executor: (opcional)
- Estado: aberto | replanejado | contornado
```
