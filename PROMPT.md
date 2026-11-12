# DESAFIO: Recuperação do Windows sem conexões físicas

## Objetivo
Restaurar o Windows em uma partição C: formatada, sem cabos, pendrives ou adaptadores físicos.

## Contexto
- Windows 10 1809; WinRE funcional, com Winre.wim (enunciado original: "WRE.wim") na partição de recuperação.
- Problema 1: WinRE sem driver Wi-Fi completo (erro 10 no adaptador).
- Problema 2: driver Bluetooth carrega, mas falta utilitário para configurar/usar.
- Acesso: cmd no WinRE, iniciado automaticamente no boot.
- Restrição crítica: nenhuma conexão física.

## Ponto central (leia antes de propor qualquer solução)

**OBJETIVO ZERO: CONECTAR O PC AO MUNDO EXTERNO. INJETAR DRIVER NÃO É O OBJETIVO E NÃO CONECTA NADA.** Driver só usa bytes que já estão no PC; ele não transporta arquivos nem cria rede. Não proponha, feche etapa ou marque requisito como atendido com base apenas em injeção/`drvload`. Preencha: `CANAL EXTERNO=...; ORIGEM DOS BYTES=...; CUSTO (teclas/tempo)=...`. Rede/download como meio de obter o primeiro payload é circular. Ordem obrigatória: **canal externo → bytes no PC → driver → rede/IP → reinstalação**. Exceção: bytes locais comprovados (OEM/recuperação/EFI), com caminho e evidência.
- A máquina real **não tem rede, Wi-Fi, cabo nem mídia**. Injetar driver no Winre.wim (A1) só serve se os bytes do driver **já estiverem na máquina**. Sem um canal de dados, "injetar o driver" não resolve nada.
- Canal garantido: **teclado (entrada) e tela (saída)**. Tudo que entra passa por digitação; tudo que sai, pela leitura da tela. Rede só existe depois de R1, então R1 não pode depender de baixar nada.
- Prova que falta: transferir um **binário intacto** por esse canal. E2–E5 usaram o host (wimlib) e a NIC do QEMU: provam que o driver carrega e que o download funciona **com rede**, não o cenário real.
- Toda proposta diz **por qual canal os bytes chegam** e quantas teclas custa. Sem isso, está errada.
- Cubra também: driver já presente em disco no próprio PC (partições OEM/recuperação/EFI) e Bluetooth como canal (o enunciado diz que o driver carrega; `docs/evidence/wlan-wcm-bth-hive.md` mediu 0 arquivos `bth` no WinRE: confronte).

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

## Regra de persistência
Não pare por conta própria: ao fim de uma tarefa pegue a próxima (AGENTS.md, "Trabalhe até se esgotar"). Ambiente é por agente: `ambientes/<nome>.md`.
