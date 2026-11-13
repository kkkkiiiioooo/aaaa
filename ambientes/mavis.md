# Ambiente do agente: mavis
Modelo: MiniMax-M3.1-Flash
Medido em 2026-11-13T10:23:01Z por mavis. **So vale para este agente.** Outro agente tem outro ambiente: nao misture.

## Maquina
- SO: Debian GNU/Linux 12 (bookworm) | kernel: Linux 5.10.134-18.0.12.lifsea8.x86_64 | arq: x86_64 | usuario: root
- CPUs: 2 | RAM: 3072 MB | disco livre: 483506 MB | KVM: NAO
- modulo vfat no kernel: NAO

## Ferramentas (OK = presente, -- = ausente)
OK:qemu-system-x86_64 OK:wimlib-imagex OK:xorriso OK:mcopy OK:7z OK:unsquashfs OK:cpio --:zstd OK:xz OK:python3 OK:pip3 OK:node OK:npm OK:gcc OK:make OK:git OK:curl OK:wget OK:jq OK:objdump OK:strings --:ip OK:busybox --:depmod --:xxd OK:file --:fdisk --:sfdisk --:parted --:mkfs.vfat --:ntfs-3g --:cabextract --:hivexsh --:reglookup --:chntpw --:bsdtar --:genisoimage --:smbclient --:tftp 
- qemu: QEMU emulator version 7.2.22 (Debian 1:7.2+dfsg-7+deb12u18+b3)
- wimlib: wimlib-imagex 1.13.5 (using wimlib 1.13.5)
- python: Python 3.11.2 | modulos: 

## Rede (HTTP, 6 s de limite)
- dl-cdn.alpinelinux.org: 200
- archive.ubuntu.com: 200
- github.com: 200
- pypi.org: 200
- registry.npmjs.org: 200
- catalog.s.download.windowsupdate.com: 200
- uupdump.net: 200
- learn.microsoft.com: 302
- www.catalog.update.microsoft.com: 200

## Limitacoes medidas
- sem KVM: QEMU so em TCG (boot do WinRE leva dezenas de minutos)
- sem vfat: ler disco FAT so por mtools
- cada teste de boot e limitado pelos CPUs/RAM acima

## Notas do agente
(escreva aqui o que so voce descobriu sobre este ambiente: limites, falhas, jeitos de contornar)
