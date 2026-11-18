# Experimento E3 — Canal de entrada de texto digitado (nvram primeiro)

## Objetivo

Uma carga real consegue cruzar o único canal de entrada consistente com as restrições — texto digitado no
teclado virtual da tela touch — sem NENHUMA rede, e ser reconstruída byte a byte no convidado?
Teste com a menor carga significativa: a nvram da placa (5361 bytes, TEXTO).

## Nível de fidelidade

`mecânica de canal` (não F1/F2/F3). Um convidado Linux busybox mínimo substitui o caminho de entrada do
dispositivo. Isto NÃO é o WinRE e NÃO é o rádio BCM4356. Prova apenas o canal de texto digitado e a
reconstrução no convidado. A reconstrução com ferramentas do WinRE é o E3b; o efeito no rádio é o E4
(hardware). Nenhum resultado do QEMU é prova de hardware.

## Pré-condições

- Carga: `drivers/nvram-delta/4356r2nvram.txt` (5361 bytes, ASCII 100% imprimível).
- Convidado só-com-teclado construído por `qemu/make-guest-kbd.sh` (sem rede configurada).
- Kernel do host `/boot/vmlinuz-5.15.0-203-generic`; QEMU 6.2; busybox; python3.

## Ambiente

- Data: 15/11/2026
- Host: sandbox Linux na nuvem, 4 vCPU, ~8 GB
- Kernel (convidado): 5.15.0-203-generic
- Virtualização: QEMU 6.2.0 TCG (sem `/dev/kvm`)
- Versões das ferramentas: qemu-system-x86_64 6.2.0; busybox (host); python3
- Hashes da imagem: não usados (convidado Linux, não um WIM)

## Comandos

```sh
sh qemu/make-guest-kbd.sh           # constrói o convidado só-com-teclado (sem rede)
bash qemu/run-keyboard-transfer.sh  # padrão: a carga da nvram
```

`run-keyboard-transfer.sh` codifica a carga em hex, inicializa o convidado SEM `-netdev`/dispositivo de
rede, roda `qemu/audit.sh` (antitrapaça), espera `KEYBOARD-TRANSFER-READY`, digita o hex via
`qemu/sendhex.py` (`sendkey` do monitor do QEMU = teclado touch simulado), e compara o
SHA-256 do convidado com o da origem no host.

## Saída observada

```text
== audit: PASS (no host sharing, hostfwd, serial file, clipboard, or proxy)
sendhex: typed 10722 hex chars in 42 lines + end via simulated keyboard (ACK flow control)
KEYBOARD-TRANSFER-READY
guest-reconstructed-bytes=5361
guest-reconstructed-sha256=a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667  /tmp/payload.bin
KEYBOARD-TRANSFER-DONE
== host source sha256:
a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667  drivers/nvram-delta/4356r2nvram.txt
== RESULT: PASS - payload reconstructed in-guest from typed text, hash matches (no network used)
```

## Artefatos e hashes

- Origem da carga: `drivers/nvram-delta/4356r2nvram.txt`, 5361 bytes,
  SHA-256 `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
- Binário reconstruído no convidado: 5361 bytes, mesmo SHA-256 (confere).
- Gerados `qemu/work/payload.hex`, `qemu/guest-kbd/initrd.img`, log de serial: não versionados
  (gitignored); o hash conferido acima é a evidência.

## Nota de método — quedas de teclas e a correção

Uma primeira tentativa com ritmo fixo (0,015 s/tecla, linhas enviadas seguidas) reconstruiu apenas
5317/5361 bytes (106 caracteres hex perdidos): o convidado ficou para trás sob TCG. Correção: **controle
de fluxo ACK por linha** — o convidado imprime `ACK <n>` na porta serial depois de decodificar cada linha, e
o `sendhex.py` espera esse ACK antes de digitar a próxima linha (passo travado). Com isso, os 5361
bytes chegam todos e o hash confere. Ritmo fixo sozinho não é confiável; o controle de fluxo é necessário.

## Conclusão

PASS para o canal: a nvram cruza como texto digitado sem rede e é reconstruída
byte a byte. Isso valida a abordagem do dono de "enviar a nvram pequena primeiro".

## Limites / próximo

- Convidado Linux, não WinRE: a reconstrução usou `printf`+`sed` do busybox, não ferramentas do WinRE. O E3b deve
  reconstruir dentro do WinRE com ferramentas da imagem (`cmd`/`notepad`; a nvram é texto, nenhum
  decodificador binário é necessário). Precisa que o WinRE inicialize (diagnóstico de BSOD pendente).
- O efeito funcional da nvram sobre o erro 10 NÃO é testado aqui — isso é o E4 (hardware).
- O driver binário de ~1 MB ainda precisa de um método texto->binário (certutil/ADODB/PowerShell ausentes;
  veja docs/07). A nvram ser texto é o que a torna a primeira carga viável.
