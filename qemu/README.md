# Ambiente QEMU

## Realidade dos canais (leia primeiro)

O dispositivo **não tem conexão de rede funcional**: a sua única NIC, o Wi-Fi
BCM4356, é o dispositivo que falha com o erro 10. **Transferência por rede/HTTP NÃO é um
canal de dispositivo válido.** O endpoint HTTP do NAT em modo usuário do QEMU (`10.0.2.2`)
funciona só porque o QEMU emula uma NIC e1000 funcional; ele não modela o dispositivo e é uma
linha de base de mecânica apenas.

O **único canal de entrada válido é texto digitado pelo teclado virtual da tela
touch.** A carga entra como texto hex/base64, digitado pelo teclado
(`sendkey` do QEMU), e é reconstruída como binário dentro do convidado. A tela é
o único canal de saída. Edição do WIM no lado do host é prova de mecânica em uma cópia, não
o método de transferência do dispositivo. Veja a seção Realidade dos canais de `GOAL.md` e `docs/01-restricoes.md`.

## Estado

Scripts montados. Não há reivindicação de resultado do erro 10 no dispositivo aqui. O QEMU não emula
o rádio BCM4356; nenhum resultado do QEMU é prova de hardware.

- **Canal de texto digitado (o método consistente com as restrições):** prototipado num convidado
  Linux mínimo (busybox). A carga é codificada em hex no host, digitada via
  `sendkey` do QEMU (teclado touch simulado), reconstruída no convidado com `printf`+`sed`,
  e verificada por SHA-256. Demonstrado para uma carga pequena; isso é mecânica de canal,
  não WinRE e não o rádio. A transferência em tamanho real precisa de ritmo confiável (o modo
  canônico do Linux limita uma linha a 4096 caracteres; envie em linhas curtas).
- **Canal HTTP (`run-channel.sh`) e servicing no lado do host (`service.sh`):
  linhas de base de mecânica SUPERADAS.** Elas não modelam o dispositivo isolado e
  não são a solução. Mantidas apenas como referências históricas de mecânica.
- **Boot do WinRE (`run-winre*.sh`):** o "BSOD antes do `cmd` interativo,
  sem diagnóstico" registrado **não era um BSOD**. `experiments/E1-winre-boot-tcg.md` reproduziu a parada
  em dois modelos de CPU (`qemu64` e `max`) como um erro do **Windows Boot Manager** —
  `File: \EFI\Microsoft\Boot\BCD`, `Status: 0xc000000f`, "The Boot Configuration Data for
  your PC is missing or contains errors" — então o kernel nunca foi alcançado. A causa estava
  no ambiente: `build-iso.sh` colocava o BCD só no lado ISO9660, enquanto o OVMF carrega
  `bootx64.efi` da imagem ESP El Torito e o `bootmgfw.efi` lê o seu BCD desse mesmo
  volume. Corrigido copiando `EFI/Microsoft/Boot/BCD` também para o `efi.img`. Mesmo depois
  dessa correção o ISO para em `0xc000000f` "a required device isn't connected or can't be
  accessed"; `build-disk.sh` (volume único FAT32) é a mídia que realmente alcança o
  Windows boot manager, e é essa que deve ser usada. **Segundo bloqueio independente: tanto
  `run-winre.sh` quanto `run-winre-disk.sh` fixam `-m 2048`, mas o WIM do WinRE expande para
  um disco em RAM de 2,02 GiB (1809) / 2,08 GiB (10586), então 2 GiB não inicializa nenhuma das imagens — use
  `-m 4096` ou mais.** KVM continua sendo um acelerador de velocidade, não um requisito. Uma reprodução
  fiel do erro-10 de Windows ainda precisa de um Windows completo inicializável (o repositório tem só o WinRE).
  Evidências e a matriz completa de células: `experiments/E1-winre-boot-tcg.md`.
- **Reprodução do erro 10 (proposto, não provado):** veja a seção Fidelidade da emulação de dispositivo em `docs/04`.
  Abordagem A: um dispositivo PCI falso com o ID real
  (`x-pci-vendor-id=0x14e4,x-pci-device-id=0x43ec`) mais o driver real reproduz o
  sintoma do erro 10, mas um stub sem resposta não pode depois ser corrigido. Abordagem B: uma
  substituta e1000 funcional mais a seleção de driver demonstra a correção ponta a ponta (fidelidade menor).
  Ambas precisam de um Windows completo inicializável (o repositório tem só o WinRE); KVM recomendado (TCG possível, mas
  lento). Não demonstrado aqui. Nenhum script para isso existe ainda. A transferência de
  texto digitado da nvram pequena (E3) é viável agora sem KVM.

## Scripts

| Caminho | Papel |
|---|---|
| `audit.sh` | Porta antitrapaça no argv do QEMU. Deve passar antes de uma execução. |
| `make-guest-kbd.sh` | Constrói o convidado Linux só-com-teclado (sem rede) para o canal de texto digitado. |
| `sendhex.py` | Digita uma carga hex no convidado via `sendkey` do QEMU (teclado touch simulado). |
| `run-keyboard-transfer.sh` | Canal de texto digitado: inicializa o convidado só-com-teclado, digita a carga, reconstrói + verifica o hash no convidado. |
| `mon.py` | Envia um comando HMP ao soquete de monitor do QEMU (screendump/status). |
| `build-media.sh` | Remonta as partes versionadas do WIM numa cópia sob `qemu/work/`. |
| `build-iso.sh` | Constrói um ISO UEFI WinRE (El Torito) a partir de uma cópia do WIM. |
| `build-disk.sh` | Constrói um disco de boot UEFI FAT32 a partir de uma cópia do WIM. |
| `run-winre.sh` | Inicializa o ISO WinRE sob OVMF; screendumps periódicos. |
| `run-winre-disk.sh` | Inicializa o disco UEFI WinRE sob OVMF; screendumps periódicos. |
| `make-guest.sh` | Constrói um convidado Linux busybox+e1000 (usado pela linha de base HTTP superada). |
| `run-channel.sh` | SUPERADO: linha de base HTTP em modo usuário. Não é o canal do dispositivo. |
| `service.sh` | SUPERADO: linha de base de servicing com wimlib no lado do host. Não é a transferência do dispositivo. |
| `wwii/` | O ambiente mínimo de 3 arquivos da branch `wwii` (`audit.sh`, `build-iso.sh`, `run.sh`), preservado por referência. |

`run-keyboard-transfer.sh`, `run-channel.sh` e `run-winre-disk.sh` são bash
(arrays); o resto é POSIX sh.

## Restrições antitrapaça (de `docs/01-restricoes.md`)

Proibido (imposto pelo `audit.sh`): `-virtfs`; 9p; `-fsdev local`; pastas compartilhadas;
`hostfwd=`; `guestfwd=`; `-serial file:`; `-chardev file`; clipboard/vdagent;
tap/bridge/hubport; SMB embutido. O canal de texto digitado não usa rede nenhuma.

## Regras

- Nunca modifique as partes versionadas dos WIMs. Trabalhe em cópias em `qemu/work/` ou `/tmp`.
- Nunca apresente um resultado do QEMU como prova de hardware. Rotule os resultados sintéticos.
- Não faça commit de WIMs gerados, imagens de disco, ISOs, logs, screendumps ou segredos.
- `audit.sh` deve passar antes de qualquer experimento ser considerado válido.
- Trabalhe e envie apenas na `desafio` (veja a regra de branch de `AGENTS.md`).

## Referências

- `GOAL.md` (Realidade dos canais), `docs/01-restricoes.md`, `AGENTS.md`.
