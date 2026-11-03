# Ambiente de teste (QEMU) — scripts e evidência

Harness real e reutilizável: sobe uma VM Linux mínima no QEMU e roda a suíte dentro
dela. Espelha o fluxo do desafio (injetar driver → dispositivo aparece → rede).

## Reproduzir
```sh
sh scripts/ambiente.sh           # instala qemu + wimlib + busybox + squashfs-tools (idempotente)
sh scripts/tests/run-tests.sh    # baixa base, monta initramfs, sobe a VM e valida
NET=1 sh scripts/run-vm.sh 120   # variante COM interface de rede
```

## Estrutura
- `scripts/ambiente.sh` — instala dependências (apt/dnf/pacman), detecta KVM.
  (o nome antigo, `env-setup.sh`, nao existe mais; quem seguia este doc recebia "no such file"
   e conclusia que o ambiente era inviavel - ver `sh scripts/doctor.sh`)
- `scripts/fetch-base.sh` — baixa kernel (`vmlinuz-virt`) e módulos (`modloop-virt`).
- `scripts/build-initramfs.sh` — monta initramfs (busybox + módulos incl. deps + init).
- `scripts/run-vm.sh` — sobe a VM headless (serial→log, timeout).
- `scripts/tests/in-vm-tests.sh` — suíte executada DENTRO da VM.
- `scripts/tests/run-tests.sh` — orquestra tudo e valida o log.

## Ambiente detectado
- Ubuntu 24.04, x86_64, **sem `/dev/kvm`** → aceleração TCG (boot ~3 s).
- Base: Alpine v3.20 (`vmlinuz-virt` 6.6.134 + `modloop-virt`).

## Resultado — NET=0 (reproduz "WinRE sem rede")
```
[PASS] boot + /init + console serial funcionando
[PASS] disco detectado: /dev/sda
[PASS] wipe de C: simulado (dd em /dev/sda)
[PASS] imagem de recuperacao criada (tar)
[PASS] driver injetado e persistido na imagem
[PASS] sem rede (apenas lo) — premissa 'WinRE sem rede' reproduzida
RESULTADO: PASS (0 falhas)
SUITE: PASS
```

## Resultado — NET=1 (rede quando há NIC + driver)
```
[PASS] com interface de rede (NET=1): 2 ifaces
RESULTADO: PASS (0 falhas)
```

## Analogia com o desafio
- `modprobe sd_mod` ≈ injetar driver de disco; `modprobe virtio_net` ≈ injetar driver de rede.
- **Sem módulo/NIC → sem dispositivo** (espelha "adaptador erro 10 / sem rede no WinRE").
- **Com módulo+NIC → rede aparece** (espelha R1/R2 via A1).
- Diferença: é Linux, não Windows — WIM/DISM/`bthpan` não são reproduzidos aqui.
