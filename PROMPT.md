# DESAFIO: Recuperação do Windows sem conexões físicas

## Objetivo
Restaurar o Windows em uma partição C: formatada, sem cabos, pendrives ou adaptadores físicos.

## Contexto
- Windows 10 1809; WinRE funcional, com WRE.wim na partição de recuperação.
- Problema 1: WinRE sem driver Wi-Fi completo (erro 10 no adaptador).
- Problema 2: driver Bluetooth carrega, mas falta utilitário para configurar/usar.
- Acesso: cmd no WinRE, iniciado automaticamente no boot.
- Restrição crítica: nenhuma conexão física.

## Regras
Ver `AGENTS.md`.
