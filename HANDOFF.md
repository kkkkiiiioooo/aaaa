# HANDOFF

Estado atual (snapshot; reescreva ao fim de cada rodada — não append).

## Fase
Quatro frentes, todas com evidência executada (não análise):
- **WinRE 1809 inspecionado** (conteúdo de imagem): `netsh wlan` **existe** (dispensa
  WinPE-WiFi-Package); `certutil.exe`/`powershell.exe` **não** existem; só um driver
  Wi-Fi de fábrica (`mrvlpcie8897`). Detalhes: `docs/evidence/winre_1809_evidencia.md`.
- **Ciclo completo do driver fechado** (o passo 4 do plano antigo, que dependia do ID
  do dono): `scripts/buscar_driver.py` acha o driver no Microsoft Update Catalog pelo
  `VEN_/DEV_`, baixa o `.cab` oficial e **confere se o INF cobre o dispositivo**;
  `scripts/injetar_driver.sh` grava o driver no **Winre.wim real 17763** (mesmos
  caminhos do DISM) e a verificação é por **hash byte a byte após reextrair**.
  Evidência: `docs/evidence/driver_injecao.md`.
- **Simulação de PAN + fdisk real** no guest QEMU: fdisk de verdade cria C: +
  partição de recuperação e prova (md5) que **formatar C: não apaga a recuperação**;
  PAN com network namespaces + `veth` prova que o PC usa o celular como gateway,
  com teste negativo. Suíte **27/27 PASS**. Evidência:
  `docs/evidence/ambiente-teste-pan-fdisk.md`.
- **`diag.cmd` corrigido**: o script anterior **não funcionaria** na máquina do dono
  (usava `findstr.exe`, que não existe no WinRE 1809, e buscava o ID em dados em vez
  do nome da chave). Inventário real do WinRE 1809 documentado.

## Próximo passo
1. **Dono roda `scripts/diag.cmd` no WinRE** (`diag`) e manda foto da tela: dá o
   `VEN_/DEV_` do Wi-Fi/Bluetooth. O script agora funciona (validado no `cmd.exe`).
   Também falta confirmar a fonte local do driver (partição OEM / backup), já que
   `C:` foi formatada.
2. Com o ID em mãos: `python3 scripts/buscar_driver.py busca 'PCI\VEN_xxxx&DEV_xxxx'`
   → `baixa` → `inf` (confere a compatibilidade). Leva ~2 min, sem depender do dono.
3. Na máquina real: `dism /Mount-Image ... /Add-Driver /Driver:<pasta> /Recurse`
   (o DISM registra no hive; o `wimlib` só grava os arquivos).
4. Executar o runbook na máquina real e registrar R1–R5.
5. `pnputil /enum-drivers` no WinRE: lista os drivers de terceiros já presentes — dá
   para checar se o OEM do Wi-Fi já está no DriverStore antes de procurar na rede.

## Riscos abertos
- A3 (Reset com nuvem) provavelmente exige Windows existente; `C:` formatada → tratar A1 + setup.exe
  via rede como caminho principal. Validar antes de confiar em A3.
- Perguntar ao dono se quer recuperar arquivos da `C:`; se sim, NÃO escrever nela até rodar
  testdisk/photorec.
- O `dism /Add-Driver` **não** foi executado (exige Windows). O `wimlib` grava os
  arquivos, mas quem registra o driver no hive (SYSTEM/SOFTWARE) e atualiza o
  catálogo de assinaturas é o DISM.

## Bloqueios
- Sandbox Linux: **não dá boot no WinRE** nem validar runtime/driver (erro 10); a evidência é
  de conteúdo de imagem + lógica de injeção → forte, mas a confirmação final exige a máquina real.
- Depende do dono: modelo do adaptador Wi-Fi (via `diag.cmd`) e confirmação da fonte local do driver.
- **Push travado**: o `h.sh` decifra o token do GitHub com uma senha (S) que só o dono
  tem. Sem ela, os commits ficam locais (`git log` mostra 6 commits nesta rodada).
