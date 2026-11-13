# PROGRESSO

Versão completa (49 linhas, 15 KB): `git show 42d65cc:PROGRESS.md`. Detalhe por etapa: `docs/evidence/`. Estado atual: `HANDOFF.md`.

- 2026-10-31: projeto iniciado com base enxuta; setup.sh, chat/mural e ambiente QEMU criados (suite 6/6 PASS em TCG). Branches antigas arquivadas em bundles.
- 2026-10-31: WinRE Home 1809 (17763.9376) inspecionado: netsh, wlancfg e wlanapi presentes; certutil e powershell ausentes. Ev: winre-1809-evidencia.md.
- 2026-11-02: ciclo do driver fechado (buscar_driver.py + injetar_driver.sh, hash conferido); suite PAN/fdisk 27/27 PASS: formatar C: não apaga a recuperação. Ev: driver-injecao.md, ambiente-teste-pan-fdisk.md.
- 2026-11-04: E2 lote de 6 fabricantes (INF UTF-16LE corrigido, sha256 17/17); E3 autorun offline via winpeshl.ini. Ev: drivers-lote.md, autorun-winpe.md.
- 2026-11-04: E4 INCONCLUSIVA no 1º ciclo (PE não chegou ao winpeshl.ini sob TCG+CD). BSOD também com WIM XPRESS e com controles sem injeção: a causa não era a injeção. Ev: boot-winre-iso.md.
- 2026-11-05: wlansvc não depende de wcm (p0402412842 resolvido); Bluetooth/PAN só no Windows instalado; netsh wlan existe via wlancfg.dll (premissa wlancmds.dll refutada). Ev: wlan-wcm-bth-hive.md, netsh-wlan-existe.md.
- 2026-11-07: E4 destravada: WinRE sobe sozinho em TCG (-cpu max), autorun roda inteiro, wlansvc inicia, 6/6 drivers carregam (faltava firmware/catálogo no pacote; inf_dependencias.py). O "BSOD" anterior era o OOBE laranja; detector corrigido. Ev: e4-*.md.
- 2026-11-07: E5 transporte: HTTP + ResponseText + FSO ASCII grava e confere sha256, mas perde bytes 0x81..0x9F; ADODB.Stream e certutil ausentes; ftp.exe só PORT. Ev: e5-transporte-download-pe.md.
- 2026-11-07: reestruturação do projeto (mural, evals, quem-primeiro, modelo por agente).
- 2026-11-11: E5 escrita binária N1 no host (download-js.js: MSXML ResponseBody ou base64+FSO Unicode); falta boot com ≥3 GB para medir. Ev: e5-escrita-binaria-pe.md.
- 2026-11-12: enxugamento: removidos logs brutos, PNGs duplicados, painel.sh e download_ftp.txt; PROGRESS, README e AGENTS reduzidos.
- 2026-11-12: E5 FEITA (N3, brianwoo-auto): 256 B sha256 ok 5/5 caminhos no PE real (b64, MSXML bin.hex, ResponseText+FSO Unicode); Arguments.Count nao existe em JScript; FSO ASCII Write quebra com 0..255; BOM FF FE universal; boot TCG exige XPRESS. Ev: e5-escrita-binaria-n3.md.
- 2026-11-12: 0b virou N2: bcmpciedhd63.sys monta %04Xr%dnvram.txt (4356r2nvram.txt), 0 nvram no WinRE; delta 5361 B em drivers/nvram-delta/ + passo no autorun. Ev: drivers/nvram-delta/README.md.
- 2026-11-13: imagens/ organizada em subpastas por WIM (winre-1809/, mipad2-10586-boot/, winre-fabrica-10586/, inspecao/) no ramo `extras`; ramos `extras` e `imagem` com os mesmos blobs, so muda o caminho. Hashes conferidos: 14/14 partes OK, 3/3 WIMs remontados com sha256 igual (1809 f9e30ca3.., boot 3f8f446a.., fabrica 152addc4..). `sh scripts/obter_imagem.sh --fs` rodou ponta a ponta. Ev: imagens/README.md.
- 2026-11-13: tamanho em MB no titulo das pastas de imagens: winre-1809-254MB/, mipad2-10586-boot-408MB/, winre-fabrica-10586-424MB/, inspecao-62MB/ (ramo `extras`) e imagens/mipad2-10586-boot-408MB/ (ramo `imagem`). Medido: 14/14 partes com sha256 OK, 3/3 WIMs remontados com hash igual, obter_imagem.sh --wim e --fs rodando. Os arquivos dentro das pastas mantem o nome do WIM, sem o sufixo.
