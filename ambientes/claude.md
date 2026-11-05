# Ambiente do agente: claude
Medido em 2026-11-05T09:07:09Z por claude. **So vale para este agente.** Outro agente tem outro ambiente: nao misture.

## Maquina
- SO: Ubuntu 24.04.5 LTS | kernel: Linux 6.18.44-fc-v236 | arq: x86_64 | usuario: root
- CPUs: 1 | RAM: 3990 MB | disco livre: 8197 MB | KVM: NAO
- modulo vfat no kernel: NAO

## Ferramentas (OK = presente, -- = ausente)
OK:qemu-system-x86_64 OK:wimlib-imagex OK:xorriso OK:mcopy OK:7z OK:unsquashfs OK:cpio OK:zstd OK:xz OK:python3 OK:pip3 OK:node OK:npm OK:gcc OK:make OK:git OK:curl OK:wget --:jq OK:objdump OK:strings OK:ip OK:busybox OK:depmod OK:xxd OK:file --:fdisk --:sfdisk --:parted --:mkfs.vfat --:ntfs-3g --:cabextract --:hivexsh --:reglookup --:chntpw --:bsdtar --:genisoimage --:smbclient --:tftp 
- qemu: QEMU emulator version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.18)
- wimlib: wimlib-imagex 1.14.4-1.1build2 (using wimlib 1.14.4-1.1build2)
- python: Python 3.12.3 | modulos: regipy pefile requests 

## Rede (HTTP, 6 s de limite)
- dl-cdn.alpinelinux.org: 000
- archive.ubuntu.com: 200
- github.com: 200
- pypi.org: 200
- registry.npmjs.org: 200
- catalog.s.download.windowsupdate.com: 000
- uupdump.net: 000
- learn.microsoft.com: 000
- www.catalog.update.microsoft.com: 000

## Limitacoes medidas
- sem KVM: QEMU so em TCG (boot do WinRE leva dezenas de minutos)
- sem vfat: ler disco FAT so por mtools
- cada teste de boot e limitado pelos CPUs/RAM acima

## Notas do agente
- Este ambiente NAO alcanca uupdump.net, learn.microsoft.com nem o catalogo do Windows Update (HTTP 000): daqui nao da para baixar ESD, `wlancmds.dll` nem drivers novos. Os .cab de E2 foram baixados por outro agente (stackai), em outro ambiente.
- Alpine CDN tambem nao responde: kernel/modulos de teste vem do apt Ubuntu (`scripts/fetch-base.sh` e `scripts/fetch-modulos-ubuntu.sh`).
- Com 1 CPU e 4 GB, boot do WinRE em TCG nao e viavel (outro agente mediu 1800 s sem chegar ao autorun em ambiente mais forte). Nao repetir aqui.
- Fora do bash: o agente claude tem busca web e leitura de paginas (ferramentas do chat), que o bash nao tem.
- `apt-get install` funciona (archive.ubuntu.com 200); `pip` funciona (pypi.org 200).
