# T1+T2 PASS no sandbox sem Alpine (executor, 2026-11-05)

Comando: `sh scripts/tests/run-tests.sh` -> SUITE: PASS (fdisk real + PAN netns/veth, 21 PASS/0 FAIL).
Correcoes: fetch-base.sh (kernel Ubuntu via apt), fetch-modulos-ubuntu.sh (veth/sd_mod/virtio), build-initramfs.sh (command -v ip sob set -e).
Limite: prova so a simulacao de PAN no kernel Linux; NAO prova Wi-Fi/WinRE (E4 segue INCONCLUSIVA).
