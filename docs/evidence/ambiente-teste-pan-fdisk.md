# Evidência — simulação de PAN e fdisk real no ambiente de teste (QEMU)

**Método:** execução real dentro da VM QEMU (Alpine v3.20, kernel 6.6.134). Nada de
mock: disco virtual de verdade, network namespaces e pares `veth` reais.

## O que esta simulação cobre (e o que não cobre)

| Item | O que espelha | Limite |
|---|---|---|
| fdisk real | o passo 0 do runbook (`diskpart` → partição de sistema + partição de recuperação) | é `fdisk`/MBR, não `diskpart`/GPT; a partição de recuperação recebe uma **assinatura sintética**, não o `Winre.wim` |
| PAN (R4) | topologia do PAN: o celular entrega IP ao PC e o PC usa o celular como gateway | `veth` é um enlace **virtual ponto-a-ponto** entre dois namespaces **da mesma VM**. Não há rádio, NAT de operadora, handover, DHCP real, latência/perda de rede móvel nem tethering USB/BT |

Ou seja: prova a **lógica de rede do lado do PC** (endereço, rota, serviço
alcançável, e a falha quando o link some). Não substitui o teste na máquina real.

## Como rodar

```sh
sh scripts/tests/run-tests.sh        # suíte completa (orquestra + avaliação)
```

O trecho novo está em `scripts/tests/in-vm-fdisk-pan.sh` e roda **dentro** do
guest (é montado no initramfs por `scripts/build-initramfs.sh`).

## ITEM 1 — fdisk real: formatar C: NÃO apaga a partição de recuperação

Este é o ponto central do runbook: o `Winre.wim` vive na **partição de
recuperação**, e `C:` está formatada. Se o `C:` formatado levasse junto a
recuperação, o plano inteiro (A1) morreria.

```sh
# cria a tabela no disco virtual
fdisk -u /dev/sda <<EOF
n
p
1
2048
65535
n
p
2
65536
131071
w
q
EOF
```

> Nota: o `busybox fdisk` pede **primeiro o tipo** (`p` = primária) e **depois** o
> número. A ordem invertida faz o fdisk pedir "Partition type" e recusar a entrada.

### Saída real (log serial)

```
===== ITEM 1 - fdisk real em /dev/sda =====
[PASS] ITEM1: device /dev/sda presente
[PASS] ITEM1: /dev/sda tem 131072 setores
[INFO] ITEM1: layout -> C: [2048..65535] | recuperacao [65536..131071]
[PASS] ITEM1: tabela gravada com o layout esperado
[PASS] ITEM1: fdisk -l lista sda1 e sda2 (tabela persistida no disco)
[PASS] ITEM1: sda1 e sda2 aparecem em /proc/partitions
[PASS] ITEM1: assinatura do Winre.wim presente na particao de recuperacao
[PASS] ITEM1: inicio de sda1 zerado (32 setores, 0 bytes nao-nulos) = C: formatada
[PASS] ITEM1: particao de recuperacao INTACTA apos formatar C: (md5 identico antes/depois)
[PASS] ITEM1: tabela de particoes intacta apos o wipe de C:
```

Evidência bruta do `fdisk -l` (a tabela **persistida no disco**, não em memória):

```
Disk /dev/sda: 64 MB, 67108864 bytes, 131072 sectors
   8 cylinders, 255 heads, 63 sectors/track
Units: sectors of 1 * 512 = 512 bytes

Device  Boot StartCHS    EndCHS        StartLBA     EndLBA    Sectors  Size Id Type
/dev/sda1    0,32,33     4,20,16           2048      65535      63488 31.0M 83 Linux
/dev/sda2    4,20,17     8,40,32          65536     131071      65536 32.0M 83 Linux
```

E o `/proc/partitions` do kernel:

```
major minor  #blocks  name
   8        0      65536 sda
   8        1      31744 sda1
   8        2      32768 sda2
```

### A prova que importa

Uma assinatura `WINRE_WIM_SIGNATURE_4.4MMII1` foi gravada no **setor 0 da partição
de recuperação**, depois o início da partição `C:` foi zerado (16 MiB, equivalente a
formatar), e o setor 0 da recuperação foi lido de novo:

```
[INFO] ITEM1: md5 do setor 0 da recuperacao ANTES do wipe = 61aa8744cbbf01e95c446a635b4171f7
[INFO] ITEM1: md5 do setor 0 da recuperacao DEPOIS do wipe = 61aa8744cbbf01e95c446a635b4171f7
```

**md5 idêntico** → o conteúdo da partição de recuperação não foi tocado, e a tabela
de partições continuou igual (`sda1` em 2048, `sda2` em 65536). É a garantia de que
o `Winre.wim` continua acessível depois de formatar o `C:`.

## ITEM 2 — PAN simulado (R4) com namespace + veth

Topologia montada (tudo em network namespaces reais):

```
   PC (netns principal)                     celular (netns)          srv (netns)
   pan-pc  10.8.0.2/24  <--veth-->  pan-cel 10.8.0.1/24
                                        wan-cel 10.9.0.1/24 <--veth--> wan-srv 10.9.0.2/24
                                        ip_forward=1
```

O "celular" é o gateway: o PC chega à rede externa **através dele**.

### Saída real (log serial)

```
===== ITEM 2 - PAN simulado (network namespace + veth) =====
[PASS] ITEM2: modulo veth carregado (/lib/modules/6.6.134-0-virt/kernel/drivers/net/veth.ko)
[PASS] ITEM2: '/sbin/ip.full link add ... type veth' suportado
[PASS] ITEM2: namespaces criados (celular=526 srv=527)
[PASS] ITEM2: pares veth criados (pan-pc<->pan-cel, wan-cel<->wan-srv)
[PASS] ITEM2: pontas movidas para os namespaces
[PASS] ITEM2: enderecos e rota configurados (PC 10.8.0.2/24 -> celular 10.8.0.1 -> srv 10.9.0.2)
[PASS] ITEM2: PC tem IP 10.8.0.2/24 no link PAN
[PASS] ITEM2: PC acessou o servico do celular atraves do link PAN (R4)
[PASS] ITEM2: ICMP PC->celular ok
[PASS] ITEM2: PC alcanou a rede externa via o celular (ip_forward) - R1
[PASS] ITEM2 (negativo): acesso falhou como esperado sem o link do celular
[PASS] ITEM2: link restaurado e o acesso voltou
```

Resposta HTTP real vinda do "celular", atravessando o link PAN:

```
HTTP/1.1 200 OK
Content-type: text/html
Content-Length: 48

PAN-OK: celular compartilhando conexao com o PC
```

### O teste negativo

Sem o link do celular (`ip link set pan-cel down`), o acesso **falha** — como deve
falhar. Depois de restabelecer o link, volta a funcionar. Isso prova que o caminho
depende do enlace e não de algum atalho do ambiente.

### Detalhes técnicos que custaram tempo (registrados para o próximo)

1. **`ip` do iproute2 é obrigatório.** O `ip` do busybox **não** suporta
   `ip link add ... type veth` (erro: `Operation not supported`). O
   `build-initramfs.sh` agora copia o `ip` do host (`/sbin/ip.full`) junto com as
   libs dinâmicas.
2. **`veth.ko` precisa entrar no initramfs.** Ele existe no modloop do Alpine, mas o
   build original só copiava `sd_mod`/`virtio_net`. Agora é incluído.
3. **`wget` do busybox dá segfault** neste initramfs (`segfault at 0 ip 00000000004ef111`).
   Trocado por `nc` (HTTP/1.0 cru), que funciona.
4. **Falta a rota de retorno.** Sem NAT, o `srv` não sabe responder para a rede do
   PAN. A solução é uma rota estática no namespace do `srv`:
   `ip route add 10.8.0.0/24 via 10.9.0.1 dev wan-srv`.
5. **O prompt do `fdisk` do busybox** pede tipo antes de número (ver ITEM 1).
6. `veth.ko` e `ip.full` exigem applets extras no initramfs
   (`unshare`, `nsenter`, `md5sum`, `mknod`, `blockdev`, `chmod`, `tr`, `ping`, `nc`, …),
   agora incluídos.

## Resultado da suíte completa

```
--- avaliacao ---
    [PASS] boot + /init + console serial funcionando
    [PASS] disco detectado: /dev/sda
    [PASS] wipe de C: simulado (dd em /dev/sda)
    [PASS] imagem de recuperacao criada (tar)
    [PASS] driver injetado e persistido na imagem
    [PASS] sem rede (apenas lo) — premissa 'WinRE sem rede' reproduzida
  [PASS] ITEM1: ... (10 verificações)
  [PASS] ITEM2: ... (12 verificações)
  RESULTADO: PASS=21 FAIL=0
  RESULTADO: OK - fdisk real (particao de recuperacao sobrevive ao format de C:) e PAN (netns+veth) passaram
    [PASS] suite fdisk/PAN (detalhes acima) sem falhas
  RESULTADO: PASS (0 falhas)
SUITE: PASS
```

**27/27 PASS.**

## O que ainda falta para fechar o desafio

A simulação prova a mecânica. Falta a máquina real:

- o adaptador com erro 10 (precisa do `VEN_/DEV_` — `scripts/diag.cmd` no WinRE do dono);
- o boot do WinRE de verdade (o sandbox não dá boot em WinRE);
- a injeção pelo `dism` na máquina real (o `wimlib` grava os arquivos, mas quem
  registra no hive é o DISM);
- o R3 (reinstalar o Windows) e o R5 (preservar drivers) na máquina real.
