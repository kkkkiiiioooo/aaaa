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
Tudo executável por agente, sem o dono (ver `AGENTS.md` > Autonomia total):
1. **Cobertura sem ID**: rodar `buscar_driver.py` em lote nos fabricantes Wi-Fi/BT comuns
   (`VEN_8086` Intel, `10EC` Realtek, `168C`/`17CB` Qualcomm, `14E4` Broadcom, `14C3`
   MediaTek, `11AB` Marvell), baixar os `.cab` compatíveis com 1809 e conferir os INF.
2. Injetar todos no `Winre.wim` com `injetar_driver.sh`: o PnP escolhe o que casa com o
   hardware real, então o ID deixa de ser necessário.
3. **Autorun**: criar script para o cmd que inicia sozinho no WinRE: `drvload` dos drivers,
   `netsh wlan`, PAN, `pnputil /enum-drivers`, tudo com log em arquivo, sem digitar nada.
   `diag.cmd` vira etapa de log, não de entrada.
4. Reinstalação sem mídia: A1 + `setup.exe` via rede; validar A3 em simulação e documentar.
5. Simular tudo no QEMU, registrar R1–R5 e entregar `Winre.wim` pronto + runbook de uma linha.

## Premissas (assumidas, sem dono)
- Hardware desconhecido: cobrir todos os chips comuns (item 1) em vez de descobrir um.
- Dados da `C:`: prioridade é restaurar o Windows; se der de graça, tentar `testdisk` antes de gravar.
- Fonte local do driver: procurar na própria imagem WinRE/partição de recuperação.

## Riscos abertos
- A3 (Reset com nuvem) provavelmente exige Windows existente; `C:` formatada → tratar A1 + setup.exe
  via rede como caminho principal. Validar antes de confiar em A3.
- Arquivos da `C:`: ver Premissas (não perguntar a ninguém).
- O `dism /Add-Driver` **não** foi executado (exige Windows). O `wimlib` grava os
  arquivos, mas quem registra o driver no hive (SYSTEM/SOFTWARE) e atualiza o
  catálogo de assinaturas é o DISM.

## Bloqueios
- Sandbox Linux: **não dá boot no WinRE** nem validar runtime/driver (erro 10); a evidência é
  de conteúdo de imagem + lógica de injeção → forte, mas a confirmação final exige a máquina real.
- Nenhum bloqueio depende do dono: modelo do Wi-Fi e fonte do driver são cobertos por
  Premissas e pelo item 1 do Próximo passo.
- Push: o `h.sh` configura o acesso; se falhar, diagnosticar e repetir (ver `AGENTS.md`).
