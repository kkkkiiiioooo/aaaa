# Experimentos

Cada experimento registra uma pergunta, os comandos exatos, a saída observada, os artefatos e os limites da conclusão.

## Índice (quadro de tarefas compartilhado)

Este é o único quadro compartilhado. Um agente trabalha por vez, então não há reivindicação de linhas: atualize o Status ao trabalhar e envie. Veja a regra de coordenação em `AGENTS.md`.

| ID | Título | Owner | Status |
|---|---|---|---|
| E0.1 | Procedência da imagem base | — | Feito — ESD oficial verificado, WinRE re-extraído (`winre-1809-oficial-intacta/`) |
| E1 | Linha de base WinRE no QEMU | qoder | Em andamento — só TCG (sem `/dev/kvm`); veja `E1-winre-boot-tcg.md` |
| E1b | Matriz de causa-raiz do boot do WinRE sob TCG (CPU, máquina, memória, layout da mídia) | qoder | Em andamento — a linha EFI-ISO está fechada como beco sem saída: o firmware monta apenas o ESP `efisys.bin` de 1.474.560 bytes como `FS0:` e nunca monta o volume ISO9660 que contém `\sources\boot.wim` (célula Y), e o bootmgr da Microsoft lançado do UEFI Interactive Shell para na cancela press-any-key do DVD, que 5.117 teclas injetadas não conseguiram abrir porque o shell — e não o bootmgr — as consumiu (células X, Z, AB, AC). A matriz agora se volta para a mídia em disco FAT32: a célula AD provou com `-device bochs-display` que o quadro chapado `#2067B2` é real (modo texto, o logo gráfico do TianoCore e o preenchimento de cor única vêm da mesma fonte de quadros) e que o convidado então pede desligamento por conta própria. Célula AE em andamento (reivindicada agora): mesmo disco com `winpeshl.ini` apontando `cmd.exe` em vez de `X:\sources\recovery\recenv.exe` — resultado: idêntico ao AD, então o shell do WinPE nunca é alcançado. AG (`q35`/AHCI + `-cpu max`) também terminou na mesma cor única, fechando o eixo da controladora. **O AF é o pivô**: com `\sources\boot.wim` renomeado para fora, a mesma mídia renderiza a tela de erro em texto do bootmgr (`Status: 0xc000000f`, `A required device isn't connected or can't be accessed`), então o azul é pintado só depois que o bootmgr entrega ao winload. Próxima célula em fila: AH (apagar `winload.efi` dentro do ramdisk). AH e AJ voltaram: apagar `winload.efi` do ramdisk dá o azul idêntico, e encolher o WIM para 0,89 GiB — dentro do volume de 1,51 GiB que o SDI declara — também dá o azul idêntico, então a aritmética do ramdisk também está eliminada. Toda variável do lado da mídia e da máquina alcançável sem um canal de debug termina na mesma cor única. Veja `E1-winre-boot-tcg.md` |
| E3b | Reconstrução da nvram em ASCII e SHA-256 dentro do WinRE | gpt | Ferramentas preparadas; NÃO é um pass — bloqueado no E1/E1b. Exige execução real no WinRE; testes simulados são inadmissíveis. Veja `E3b-ascii-hash-prep.md`. |
| E4 | Validação no hardware | user | Planejada; guiada pelo usuário |
| E5 | Reprodução do sintoma do erro 10: dispositivo PCI falso (`VEN_14E4&DEV_43EC`) + driver real | agente com KVM | Proposto; precisa de Windows completo inicializável; KVM recomendado. Veja `docs/04` |
| E7 | Sumidouro de escrita binária: hex/base64 digitado -> bytes brutos com ferramentas da imagem apenas | stackai | Planejado — só vale no WinRE real; bloqueado no E1 |
| E6 | Demo da correção de seleção de driver numa substituta e1000 funcional (driver errado -> erro 10, driver correto -> inicia) | agente com KVM | Proposto; fidelidade menor; precisa de Windows completo inicializável. Veja `docs/04` |

Atribua por capacidade: E5/E6 (erro-10 de Windows) precisam de um Windows completo inicializável e são melhor executados por
um agente com KVM. O efeito funcional da nvram sobre o rádio é o E4 (hardware).

## Regras

- Use `experiments/templates/experimento.md`.
- Declare o nível de fidelidade: F1, F2, F2b, F3 ou `somente metadados`.
- Separe fatos observados de hipóteses.
- Registre os comandos exatos e a saída observada.
- Registre os valores de SHA-256 de cada artefato.
- Declare as limitações do QEMU explicitamente.
- Nunca apresente um resultado do QEMU como prova de hardware.
- Não modifique as partes versionadas dos WIMs. Trabalhe em cópias em `qemu/work/` ou `/tmp`.
- Não faça commit de imagens geradas, logs ou segredos.

## Decisão atual de base

Nenhuma base está aprovada. O WinRE 1809 é a única imagem fornecida observada com `bcmwdidhdpcie.inf`, mas era um WIM derivado (reempacotamento wimlib do ESD oficial) e a sua origem não está verificada independentemente. A imagem de fábrica 10586 fornece apenas extras do OEM. F2 é candidato só depois que a procedência da 1809 for verificada; F1 é o teste de replano só-do-driver. Veja `winre-1809-oficial-intacta/` e `docs/06-auditoria-imagem-1809.md`.
