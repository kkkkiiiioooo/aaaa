# STATE — passagem de bastão entre chats (leia depois de `INDEX.md`)

Atualizado em: 21/11/2026 (criação do arquivo, a partir de `TODO.md` e `experiments/README.md`).
Regra: ao fim de cada chat, reescreva este arquivo (máx. 60 linhas) e salve com `scripts/salvar.sh "state" STATE.md`.
Fonte de verdade dos detalhes: `TODO.md` (plano) e `experiments/README.md` (quadro). Este arquivo só resume.

## Foco atual

E1b — fazer o WinRE inicializar sob QEMU/TCG até um `cmd` interativo, para destravar E3b e E7.

## Feito (resumo)

- Procedência do WinRE 1809 verificada (E0.1) e inventário das duas imagens (`inventory/`, `docs/07`).
- Regras de canais, sincronização e coordenação fixadas em `AGENTS.md` / `GOAL.md`.
- Ambiente UEFI com console de texto interativo (UEFI Shell, `FS0:`) e digitação via `keys.py`.
- Descartados por medição (E1b, células I–AJ): PCAT/SeaBIOS, ISO9660 em EFI (o firmware só monta o ESP `efisys.bin` como `FS0:`), modelo de CPU, controladora de storage, tamanho do ramdisk, `winload.efi`, trocar `recenv.exe` por `cmd.exe` em `winpeshl.ini`.
- Fato: o azul chapado `#2067B2` é real (não é artefato de captura) e vem do estágio depois do bootmgr; falhas do próprio bootmgr aparecem como texto preto (célula AF).

## Próximo passo imediato

1. Ler o STOP code do WinRE com `pmemsave`, `-d` ou `-debugcon` na mídia `qemu/work/winre-cmd.img`.
   Autorizado pelo dono em 21/11/2026 (regra em `AGENTS.md`). Antes de rodar, conferir `qemu/audit.sh`: `-serial file:`, `-virtfs`, 9p e portas redirecionadas continuam proibidos.
2. Com o STOP code, decidir a próxima variação de E1b ou registrar `bloqueado` em `experiments/README.md`.

## Bloqueios

| Tarefa | Depende de |
|---|---|
| E3b (nvram em ASCII + hash dentro do WinRE) | WinRE com `cmd` (E1b). Teste simulado não vale |
| E7 (escrita binária a partir de texto) | WinRE real (E1b). certutil, PowerShell, .NET e ADODB.Stream estão ausentes |
| E5 e E6 (erro 10 reproduzido) | Windows completo inicializável, de preferência com KVM. O sandbox atual só tem TCG |
| E4 (hardware) | O dono, no dispositivo físico |

## Decisões abertas do dono

- Nenhuma imagem-base aprovada (`experiments/README.md`, "Decisão atual de base").
- Teste de carga mínima: se só a nvram basta. Observação decisiva: `dir C:\Windows\System32\drivers\4356*` no aparelho vivo.

## Armadilhas

- A seção E1b de `TODO.md` (linhas 19–82) é muito longa: leia só as últimas linhas (`sed -n 76,82p TODO.md`).
- Nunca apresentar resultado de QEMU/mock como prova de hardware.
- Não editar os WIMs versionados; trabalhar em cópias em `qemu/work/` ou `/tmp`.
