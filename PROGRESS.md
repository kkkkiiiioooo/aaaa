# PROGRESSO

- 2026-10-31: projeto 4.4mmii1 inicializado; conteudo limpo de referencias a versoes anteriores.
- 2026-10-31: base enxuta (~2 KB); planner le so AGENTS+PROMPT+HANDOFF; branch `backup` espelha a base (PROGRESS do template zerado); branches antigas arquivadas em `_archived/` (bundles).
- 2026-10-31: AGENTS: secao de persistencia — a tarefa e possivel; proibido concluir "impossivel/nao viavel" por dificuldade (verifier do lab fez isso; corrigido no contrato).
- 2026-10-31: adiciona `setup.sh` (ambiente de teste idempotente, detecta qemu/kvm/docker/virtualbox) + AGENTS: secao "Ambiente de teste" (rodar o que demora em segundo plano; nunca travar esperando).
- 2026-10-31: chat vivo `CHAT.md` (1 arquivo, append-only, merge=union: 8 escritores concorrentes nao conflitam nem duplicam — testado) + `.gitattributes`; escreve 1 linha so ao terminar a rodada.
- 2026-10-31: desafio analisado; caminho A1+A3 (DISM no WinRE + certutil/setup.exe), R5 via export-driver, R4 Bluetooth so pos-OOBE. `docs/evidence/solucao.md` criado. Nao executado: sandbox sem Windows/virtualizacao.

- 2026-10-31: scripts/ (kit reutilizavel: ambiente, uup_links, baixar_uup, inspecionar_winre, converter_iso; adaptaveis por ambiente). WinRE Home 1809 (17763.9376) baixado via uupdump e inspecionado: netsh+wlancfg+wlanapi PRESENTES (derruba mito do WinPE-WiFi-Package), certutil/powershell AUSENTES -> runbook corrigido (SMB/net use, VBScript+WinHTTP, ftp). Evidencia em docs/evidence/winre_1809_evidencia.md
- 2026-10-31: ambiente de teste QEMU criado (`scripts/`: env-setup, fetch-base, build-initramfs, run-vm + `tests/`); suite 6/6 PASS em TCG (sem KVM); NET=1 liga a rede ao injetar virtio_net. Evidencia em `docs/evidence/ambiente-teste.md`.
- 2026-11-01: scripts/diag.cmd (IDs Wi-Fi/BT no WinRE, nao testado em Windows); .gitattributes CRLF p/ .cmd/.vbs; PROMPT esclarece Winre.wim; HANDOFF com riscos (A3 vs C: formatada, dados).
- 2026-11-02: ciclo do driver fechado: scripts/buscar_driver.py (catalogo MS Update Catalog por VEN_/DEV_ -> .cab oficial -> confere se o INF cobre o device, com teste negativo) + scripts/injetar_driver.sh (injeta no Winre.wim real 17763 via wimlib, mesmos caminhos do DISM; verificado por hash byte a byte apos reextrair). Evidencia em docs/evidence/driver_injecao.md.
- 2026-11-02: suite PAN/fdisk real no guest QEMU: fdisk de verdade cria C: + particao de recuperacao e prova (md5) que formatar C: NAO apaga a recuperacao; PAN com netns+veth (celular como gateway) com teste negativo. 27/27 PASS. Evidencia em docs/evidence/ambiente-teste-pan-fdisk.md.
- 2026-11-02: diag.cmd CORRIGIDO (o anterior nao funcionaria no dono): findstr.exe NAO existe no WinRE 1809 e /f sem /k busca em dados, onde o VEN_/DEV_ nao esta (vive no nome da chave). Inventario real do WinRE 1809 documentado na evidencia.
- 2026-11-03: AGENTS/PROMPT/HANDOFF reescritos p/ autonomia total: ninguem depende do dono; dado faltante vira premissa ou cobertura de todas as hipoteses (drivers em lote); entregavel autoexecutavel.
