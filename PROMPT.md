# DESAFIO: Recuperação do Windows sem conexões físicas

## Objetivo
Restaurar o Windows em uma partição C: formatada, sem cabos, pendrives ou adaptadores físicos.

## Contexto
- Windows 10 1809; WinRE funcional, com Winre.wim (enunciado original: "WRE.wim") na partição de recuperação.
- Problema 1: WinRE sem driver Wi-Fi completo (erro 10 no adaptador).
- Problema 2: driver Bluetooth carrega, mas falta utilitário para configurar/usar.
- Acesso: cmd no WinRE, iniciado automaticamente no boot.
- Restrição crítica: nenhuma conexão física.

## Requisitos
- R1 rede no WinRE (adaptador sem erro 10, IP válido) · R2 driver Wi-Fi instalado e operacional · R3 reinstalar o Windows sem mídia física (boot até a tela inicial) · R4 Bluetooth PAN (celular/PC) · R5 drivers preservados após reinstalação.

## Alternativas
- A1 injetar driver Wi-Fi no WinRE via DISM pelo cmd · A2 Bluetooth PAN com celular · A3 reset do PC com download na nuvem · A4 restaurar pela partição de recuperação · A5 reinstalação por rede (PXE/WDS).

## Como decidir
Atender o máximo de requisitos (R1–R5) com o menor risco.

## Autonomia
Ninguém ajuda: o dono não responde nem executa nada durante o trabalho. O agente resolve sozinho, com o próprio ambiente, e entrega algo que roda sozinho na máquina.

## Regras
Ver `AGENTS.md`.
