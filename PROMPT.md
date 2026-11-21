# PROMPT.md — Painel Operacional do Desafio Mi Pad 2

> **Documento vivo de entrada para qualquer agente.**
> Teto de tamanho: ~150 linhas. Toda descoberta nova deve ser resumida aqui em 1 linha, apontando para o arquivo de detalhe. Ao concluir um turno, atualize as seções 2 e 4 antes de salvar.

---

## 1. Missão & Restrições Rígidas (Invariantes)

- **Objetivo:** Recuperar o Windows 10 build 17763 e o Wi-Fi Broadcom BCM4356 (`PCI\VEN_14E4&DEV_43EC`, Erro 10) em um tablet Xiaomi Mi Pad 2, partindo apenas da tela do WinRE e prompt `cmd`, sem nenhuma conexão física.
- **Restrições inegociáveis do dispositivo:**
  - Sem USB, SD, Ethernet, teclado físico ou abertura de carcaça.
  - O dispositivo não envia arquivos para fora (saída apenas pela tela).
  - O dispositivo não tem rede ativa (o Wi-Fi quebrado é o próprio alvo). O HTTP modo usuário do QEMU é apenas teste de mecânica do host, não canal do dispositivo.
  - Entrada válida no dispositivo: apenas texto digitado via teclado virtual touch (hex/base64 reconstruído localmente no WinRE).
  - No WinRE não existem: `certutil`, `PowerShell`, `.NET` nem `ADODB.Stream`.
- **Regras do QEMU:** Sem pastas compartilhadas (`-virtfs`/9p), sem serial file transfer, sem portas redirecionadas. `qemu/audit.sh` deve passar.
- **Regras de agente:** Trabalho exclusivo na branch `desafio`. Sincronize (`git fetch origin desafio && git merge --ff-only origin/desafio`) antes e publique com `scripts/salvar.sh` ao terminar.

---

## 2. Foco Atual & Experimento Ativo

- **Experimento em foco:** `E1b` — Inicialização do WinRE sob QEMU/TCG até obter um console `cmd` interativo.
- **Objetivo do foco:** Desbloquear os experimentos a jusante (`E3b` de hash/transferência ASCII e `E7` de escrita binária).
- **Problema imediato:** Tela azul chapada `#2067B2` após o estágio de bootmgr. Necessário capturar o STOP code real da inicialização.

---

## 3. Fatos Comprovados vs. Hipóteses Descartadas

- **[FATO]** O WIM WinRE 1809 oficial (build 17763) tem integridade verificada (digest SHA-256 bate com catálogo UUP dump).
- **[FATO]** O driver inbox quebrado de 2017 (`bcmwdidhdpcie.inf`) não faz referência à nvram da placa; o driver OEM funcional de 2015 (`oem25.inf`) exige `4356r2nvram.txt`.
- **[FATO]** No QEMU com OVMF UEFI, o firmware monta apenas o ESP `efisys.bin` como `FS0:` (ISO9660 em EFI direto não sobe).
- **[DESCARTADO]** PCAT / SeaBIOS (o dispositivo alvo é estritamente UEFI x64).
- **[DESCARTADO]** Substituição de `recenv.exe` por `cmd.exe` em `winpeshl.ini` (não contorna o travamento no estágio atual).
- **[DESCARTADO]** Supor presença de ferramentas de rede ou decodificadores nativos dentro do WinRE de recuperação.

---

## 4. Próxima Ação Imediata (Para o próximo agente)

1. **Capturar STOP code do WinRE:**
   - Executar inspeção com `pmemsave`, `-d` ou `-debugcon` utilizando a imagem `qemu/work/winre-cmd.img` sem violar as regras de auditoria (`sh qemu/audit.sh`).
2. **Avaliar resultado:**
   - Se obtiver o código de parada (BSOD/BugCheck), registrar em `experiments/README.md` e formular a variação correspondente de `E1b`.
   - Se o boot persistir bloqueado sem diagnóstico, registrar o bloqueio com evidência em `experiments/E1b-resultado.md`.
3. **Persistir:**
   - Atualizar a seção 2 e 4 deste `PROMPT.md` e salvar via `sh scripts/salvar.sh "descrição"`.

---

## 5. Índice Rápido de Recursos

| Recurso | Localização | Descrição |
| :--- | :--- | :--- |
| **Documentação Profunda** | `docs/00-visao-geral.md` | Detalhamento técnico completo da arquitetura |
| **Restrições de Canais** | `docs/01-restricoes.md` | Matriz de canais permitidos e proibidos |
| **Drivers Extraídos** | `drivers/estado-dispositivo/` | Drivers extraídos do estado real do Mi Pad 2 |
| **Driver OEM + NVRAM** | `drivers/mipad2-oficial/` | Driver OEM 2015 e nvram funcional comprovada |
| **Harness QEMU** | `qemu/` | Scripts de montagem de disco e inicialização do emulador |
| **Validação Geral** | `scripts/verify-repo.sh` | Validador de integridade e regras do repositório |
