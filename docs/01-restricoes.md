# Restrições

## Restrições do dispositivo

| Item | Regra |
|---|---|
| USB | Não permitido. Não assuma que existe ou funciona. |
| Cartão SD | Não permitido. |
| Ethernet | Não permitido. |
| Teclado físico | Não permitido. |
| Abrir o dispositivo | Não permitido. |
| Clipboard | Não permitido. |
| Pasta compartilhada | Não permitido. |
| Transferência de arquivo por serial | Não permitido. |
| Portas redirecionadas do host | Não permitido no QEMU. |
| `-virtfs` / 9p | Não permitido no QEMU. |

## Canais permitidos do dispositivo

- Saída de tela.
- Entrada de `cmd` no WinRE.
- Wi-Fi.
- Bluetooth.
- Touch.

**Realidade dos canais:** o dispositivo **não tem conexão de rede funcional**. Sua única
NIC, o Wi-Fi BCM4356, é o dispositivo que falha com o erro 10; o Bluetooth está
não verificado. Qualquer transferência de rede (HTTP, FTP, SMB, ...) pressupõe uma conexão que
não existe e é **não** um canal válido de dispositivo. O endpoint HTTP do NAT em modo usuário
do QEMU (`10.0.2.2`) funciona só porque o QEMU emula uma NIC e1000 funcional; ele não
modela o dispositivo e é só uma linha de base de mecânica, nunca o canal da solução.

| Canal | Serve para colocar uma carga DENTRO do dispositivo? | Por quê |
|---|---|---|
| Teclado virtual da tela touch (texto digitado) | **Sim — o único canal de entrada confiável** | Funciona independente do Wi-Fi quebrado. A carga entra como texto hex/base64, reconstruída no WinRE. |
| Tela | Só saída | O agente lê os resultados da tela. |
| Wi-Fi | Não (quebrado) | O BCM4356 é o dispositivo com o erro 10; sem conexão até corrigi-lo. |
| Bluetooth | Incerto | Presença de pilha/driver não verificada; não assumido. |
| HTTP / FTP / SMB / qualquer rede | **Não** | Pressupõe uma rede funcional que o dispositivo não tem. |
| USB / SD / Ethernet / teclado físico | Não | Proibido pelas restrições rígidas. |
| Clipboard / pasta compartilhada / arquivo serial / hostfwd | Não | Construções antitrapaça proibidas. |

A carga (os bytes do driver e/ou a nvram) deve entrar como **texto digitado** (hex ou base64)
e ser reconstruída dentro do WinRE usando apenas as ferramentas presentes lá (não assuma
`certutil`, `curl` ou `bitsadmin`). Edição do WIM no lado do host é prova de mecânica numa
cópia, não o método de transferência do dispositivo.

## Restrições do WinRE

- O WinRE fornece apenas `cmd`.
- Não assuma PowerShell.
- Não assuma uma instalação completa do Windows.
- Não assuma que `devcon` está presente.
- Não assuma que `curl`, `bitsadmin` ou `certutil` estão presentes.
- `pnputil` pode existir, mas o seu conjunto de recursos depende do build do WinRE.
- WMIC pode não existir no WinRE.

## Restrições do QEMU

O ambiente não deve expor arquivos ou serviços do host. Um endpoint HTTP em modo usuário é permitido apenas como linha de base de mecânica; não é o canal de transferência do dispositivo (veja a seção Realidade dos canais acima).

Proibido:

- `-virtfs`
- Montagens 9p
- Pastas compartilhadas
- `-netdev user,hostfwd=...`
- `-serial file:...`
- `-chardev file:...`
- Integração de clipboard
- Proxy oculto ou redirecionamento de porta

Permitido:

- Firmware UEFI OVMF.
- KVM quando disponível.
- Um servidor HTTP local pelo NAT em modo usuário do QEMU em `10.0.2.2` — só linha de base de mecânica, não o canal do dispositivo.
- Um disco qcow2 criado pelo ambiente.
- Um ISO de WinRE ou mídia de boot equivalente criada a partir das partes versionadas do WIM.

## Restrições de evidência

- Não apresente saída do QEMU como prova de hardware.
- Não reivindique que o rádio funciona sem um resultado no dispositivo físico.
- Não reivindique sucesso sem os comandos, saídas, hashes e carimbos de tempo.
- Não esconda tentativas falhas nem reversões.
- Não faça commit de imagens geradas, logs ou segredos.

## Restrições de escopo

Este repositório monta o desafio. Ele não autoriza contornar as restrições, fabricar uma recuperação ou atacar qualquer sistema de terceiros.
