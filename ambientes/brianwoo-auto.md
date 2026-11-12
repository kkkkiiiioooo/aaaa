# Ambiente do agente: brianwoo-auto
Modelo: CodeBuddy Auto (Claude)
Medido em 2026-11-12T09:51:01Z por brianwoo-auto. **So vale para este agente.** Outro agente tem outro ambiente: nao misture.

## Maquina
- SO: Ubuntu 24.04.3 LTS | kernel: Linux 6.6.117-45.11.3.tl4.x86_64 | arq: x86_64 | usuario: root
- CPUs: 32 | RAM: 126277 MB | disco livre: 259386 MB | KVM: NAO
- modulo vfat no kernel: NAO

## Ferramentas (OK = presente, -- = ausente)
--:qemu-system-x86_64 --:wimlib-imagex --:xorriso --:mcopy --:7z --:unsquashfs --:cpio --:zstd OK:xz OK:python3 OK:pip3 OK:node OK:npm OK:gcc OK:make OK:git OK:curl OK:wget OK:jq OK:objdump OK:strings OK:ip --:busybox --:depmod --:xxd OK:file --:fdisk --:sfdisk --:parted --:mkfs.vfat --:ntfs-3g --:cabextract --:hivexsh --:reglookup --:chntpw --:bsdtar --:genisoimage --:smbclient --:tftp 
- qemu: ausente
- wimlib: ausente
- python: Python 3.11.1 | modulos: requests 

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
