# Notas importantes (resumo em português)

## Situação

- Xiaomi Mi Pad 2, x64, Windows 10 build 17763.
- `C:` foi formatado rapidamente.
- Só restou o WinRE no `D:`.
- Sem USB, SD, Ethernet, teclado físico ou abrir o aparelho.
- Canais: tela, `cmd` do WinRE, Wi-Fi, Bluetooth e toque.
- O aparelho não consegue enviar arquivos; não há clipboard nem pasta compartilhada.

## Imagem fornecida

O repositório tem apenas o WIM de fábrica:

- `winre-fabrica-10586-424MB`: build 10586, x64, en-US/zh-CN/zh-TW, 21.867 arquivos, WIM de 444.856.529 bytes, LZX, SHA-256 `152addc420748815c2cad90d382229e249ec853d3842531ddcc2b9998248067a`.
- Pacotes Broadcom presentes: bcmdhd, bcmdhd64, bcmfn2 e bcmfn.
- **Não tem** `bcmwdidhdpcie.inf` nem pacote PCIe.
- Não tem nvram.
- É maior que a partição de recuperação de aproximadamente 398 MB; não cabe no `D:` como está.

O WIM de fábrica não reproduz o erro 10 sem injetar o pacote PCIe de 2017.

## Estado do alvo

Pasta: `drivers/estado-dispositivo/`.

O estado do alvo é mantido como o pacote quebrado de 2017. A imagem de origem não está mais no repositório.

- `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9` — 4 arquivos.
- `bcmdhd64.inf_amd64_e0bae6831f60ea5f` — 5 arquivos.
- `bcmfn2.inf_amd64_5ebadf201c5b5845` — 2 arquivos.

O pacote Wi-Fi do alvo tem:

- `bcmwdidhdpcie.inf`
- `bcmpciedhd63.sys`
- `4356a2rtecdc.bin`
- `43596a0rtecdc.bin`

Não tem nvram. O `43596a0` fica junto para manter a pasta idêntica ao DriverStore.

O `SHA256SUMS` fica um nível acima, em `drivers/estado-dispositivo/`.

## Versões

- Pacote quebrado de 2017: `bcmwdidhdpcie.inf` `1.558.53.25` (2017-04-21).
- OEM: `oem25.inf` `1.558.14.0` (2015-12-23).
- O Windows prefere o mais novo. Só adicionar o OEM antigo não resolve; é preciso remover o pacote de 2017 ou forçar o antigo.

## nvram

- Arquivo: `bcm94356wlpagbl_P3_150828M.txt`.
- SHA-256: `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667`.
- Tamanho: 5.361 bytes.
- Cópia da hipótese: `drivers/nvram-delta/4356r2nvram.txt`.
- O driver procura `System32\drivers\4356r2nvram.txt`.
- Não está no estado do alvo nem no WIM de fábrica.

## Diagnóstico

- O Wi-Fi dá erro 10 (`ConfigManagerErrorCode=10`).
- O caso é conhecido: selecionar manualmente o driver Broadcom 2015 resolve.
- H2 (regressão do pacote de 2017) é a hipótese principal.
- H1 (nvram ausente) é secundária.

## Fidelidade

- F1 — baseline do firmware: WIM de fábrica como está. Não tem `bcmwdidhdpcie.inf`; não reproduz o erro 10.
- F2 — estado sintético de trabalho: WIM de fábrica + pacote PCIe de 2017 injetado + pacote OEM 2015 + nvram. É aproximação, não é a partição real; o build é 10586.
- F3 — WIM real do aparelho, aproximadamente 398 MB. Não disponível.

A imagem de 398 MB só foi vista na tela e não pode ser transferida. Não exigir F3 no teste padrão.

Essas definições são de teste; não afirmam a origem do pacote de 2017 nem do WIM de fábrica.

## O que está verificado

- O WIM de fábrica tem bcmdhd, bcmdhd64, bcmfn2 e bcmfn.
- O WIM de fábrica não tem `bcmwdidhdpcie.inf`.
- Os arquivos do estado do alvo estão presentes com os hashes do `SHA256SUMS`.
- Os metadados do WIM de fábrica registrados acima.

## O que não está verificado

- A origem do WIM de fábrica. O usuário relata que é a recovery de fábrica; não foi comparado com um hash oficial independente.
- A origem do pacote PCIe de 2017 mantido no estado do alvo.
- Se F2 aproxima a partição real de 398 MB.
- Se o pacote de 2017 é original ou foi montado de outra fonte.

Consequência: F2 é um estado sintético de trabalho, não uma reprodução da partição real. Rotular assim em todo experimento.

## Limitação do QEMU

- O QEMU não emula o rádio BCM4356.
- Não reproduz o erro 10.
- Prova a troca de driver, os arquivos, o offline servicing e o canal HTTP de 1 KB.
- A validação do rádio é no hardware, lendo a tela e digitando comandos.

## Estado do repositório

- Branch `desafio`, commit inicial `2b51dd0`.
- Só há o WIM de fábrica versionado.
- Não há imagem completa do Windows.
- Nenhum experimento QEMU foi executado nesta montagem.
- Nada é commitado sem pedido explícito.

## Próximas verificações

- Confirmar o resultado offline de injetar o pacote PCIe de 2017 no WIM de fábrica.
- Confirmar a remoção do `bcmwdidhdpcie.inf` no WIM modificado.
- Confirmar se o PnP copia o nvram para `System32\drivers` no WinRE modificado.
- Confirmar se o driver 2015 sobe no hardware.
- Confirmar o caminho de instalação do Windows sem imagem completa.