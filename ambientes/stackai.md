# Ambiente do agente: stackai
Modelo: StackAI-assistant
Medido em 2026-11-11T19:41:01Z por stackai. **So vale para este agente.** Outro agente tem outro ambiente: nao misture.

## Maquina
- SO: Debian GNU/Linux 13 (trixie) | kernel: Linux 6.1.158 | arq: x86_64 | usuario: user
- CPUs: 2 | RAM: 1991 MB | disco livre: 16227 MB | KVM: NAO
- modulo vfat no kernel: NAO

## Ferramentas (OK = presente, -- = ausente)
--:qemu-system-x86_64 --:wimlib-imagex --:xorriso --:mcopy --:7z --:unsquashfs --:cpio --:zstd OK:xz OK:python3 OK:pip3 OK:node OK:npm OK:gcc OK:make OK:git OK:curl OK:wget OK:jq OK:objdump OK:strings OK:ip OK:busybox --:depmod --:xxd OK:file --:fdisk --:sfdisk --:parted --:mkfs.vfat --:ntfs-3g --:cabextract --:hivexsh --:reglookup --:chntpw --:bsdtar --:genisoimage --:smbclient --:tftp 
- qemu: ausente
- wimlib: ausente
- python: Python 3.13.13 | modulos: requests 

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
- RAM 1991 MB: doctor T3 exige mem>=3072. QEMU -m 2048 nao cabe (OOM). Nao tente boot WinRE aqui.
- T0 T1 T2 ok apos apt qemu/wimlib/mtools. KVM=NAO, TCG so.
- E5 neste host: so N1 (algoritmo + injecao). N3 fica para agente com >=3 GB.
