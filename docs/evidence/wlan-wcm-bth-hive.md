# Evidência: wlansvc, wcmsvc e Bluetooth no WinRE 1809 — dados LIDOS, não inferidos

> **CORREÇÃO (claude, 2026-11-05):** a linha 8 da tabela ("`netsh wlan` NÃO existe") e a leitura 1 partiram de uma premissa errada (`wlancmds.dll`). O helper do contexto `wlan` é `wlancfg.dll` (registrado em `\Microsoft\NetSh`, com ajuda de `connect`/`add profile` no `.mui`). Ver `docs/evidence/netsh-wlan-existe.md`. O resto deste arquivo continua válido.


Responde a **C2** ("falta ServiceDll de WlansvcGroup, lido do hive SYSTEM"), **D1** ("testar sem
wcmsvc.dll primeiro") e **D4** ("procurar bthserv e bthprops no winre-caminhos.txt.gz") do
PLANO DO LÍDER. Tudo offline, dentro do WIM; nada depende da E4.

## Como reproduzir

```sh
# 1. hive SYSTEM de dentro do WIM já injetado (cai em .work/hive/SYSTEM, não na árvore completa)
wimlib-imagex extract .work/wim/Winre.lote.wim 1 '/Windows/System32/config/SYSTEM' --dest-dir=.work/hive
# 2. DLLs do stack de Wi-Fi
for f in wlansvc.dll wlanapi.dll wcncsvc.dll; do
  wimlib-imagex extract .work/wim/Winre.lote.wim 1 "/Windows/System32/$f" --dest-dir=.work/dll; done
# 3. leitura do hive (regipy está instalado neste sandbox; hivex NÃO)
python3 scripts/ler_hive.py .work/hive/SYSTEM
python3 - <<'PY'
from regipy.registry import RegistryHive
h = RegistryHive('.work/hive/SYSTEM')
sv = h.root.get_subkey('ControlSet001').get_subkey('Services')
k = next(x for x in sv.iter_subkeys() if x.name == 'WlanSvc')
print({v.name: v.value for v in k.iter_values()})
print({x.name: {y.name: y.value for y in x.iter_values()} for x in k.iter_subkeys()})
PY
# 4. imports PE
objdump -p .work/dll/wlansvc.dll | grep 'DLL Name:' | sort -u
strings -e l .work/dll/wlansvc.dll | grep -i wcm
# 5. presença de arquivo (lista de caminhos do WIM, já versionada no repo)
zcat docs/imagem/winre-caminhos.txt.gz | grep -icE 'wcmsvc|bth'
```

## O que foi medido

| # | pergunta | medida | resposta |
|---|---|---|---|
| 1 | `WlanSvc` existe e está ligado? | hive `ControlSet001\Services\WlanSvc`: `Start=2`, `Type=32`, `ObjectName=LocalSystem` | **sim, AUTO** (330 serviços no hive) |
| 2 | Qual é o ServiceDll? (C2) | subchave `Parameters`: `ServiceDll=%SystemRoot%\System32\wlansvc.dll`, `ServiceMain=WlanSvcMain`, `ServiceDllUnloadOnStop=1` | **lido, não inferido** — e o arquivo existe (`/Windows/System32/wlansvc.dll`, 2 630 144 B) |
| 3 | De quem `WlanSvc` depende? | `DependOnService = ['nativewifip', 'RpcSs', 'Ndisuio']` | **nenhuma dependência em wcmsvc** |
| 4 | As dependências existem? | `NativeWifiP` (Start=3, `system32\DRIVERS\nwifi.sys`), `RpcSs` (Start=2), `Ndisuio` (Start=3, `ndisuio.sys`) — os 4 arquivos (`nwifi.sys`, `vwifibus.sys`, `vwififlt.sys`, `WdiWiFi.sys`, `ndisuio.sys`) aparecem na lista de caminhos | **sim, stack completo** |
| 5 | `wcmsvc.dll` está na imagem? | grep na lista de caminhos: **0** ocorrências; hive: **nenhuma** chave de serviço com `wcm` no nome — a única aparição da string é `\ControlSet001\Control\SafeBoot\Network\Wcmsvc` (alias de Safe Boot herdado do SO base) | **wcmsvc não está instalado no WinRE** |
| 6 | Isso quebra o `wlansvc`? | `objdump -p wlansvc.dll` → 58 DLLs importadas, **nenhuma** com `wcm`; `strings -e l` mostra `WCMPresent` e `Software\Policies\Microsoft\Windows\WcmSvc\Local` | **não**: o `wlansvc.dll` **não importa** `wcmsvc.dll` e testa `WCMPresent` em tempo de execução, ou seja, a ausência é tratada por projeto |
| 7 | Bluetooth (D4)? | lista de caminhos: **0** arquivos batendo `bth`; hive: **0** chaves com `bth`; `bthserv.dll`/`bthprops.cpl`/`bthpan.sys`/`bthusb.sys`/`bthport.sys` ausentes | **sem pilha Bluetooth no WinRE** → PAN só funciona no Windows instalado (R5 parcial), exatamente a alternativa que o D4 previa |
| 8 | `netsh wlan` funciona? | `wlancmds.dll` (contexto `wlan` do netsh): **0** ocorrências; `netsh.exe`: 4; `netshell.dll`: presente; `wlanapi.dll`, `wlanext.exe`, `wlanutil.dll`, `wlancfg.dll`, `wlanui.dll`, `wlansec.dll`, `wlanmsm.dll`, `wlanhlp.dll`, `wlanpref.dll`, `wlandlg.dll`: presentes; `dwapi.dll`: 0 | **NÃO** — falta o contexto; `netsh wlan ...` não existe neste WinRE |

## Leitura (o que isso muda no plano)

1. **D1 não é executável como está escrito.** O critério de aceite do D1 usa `netsh wlan show
   drivers`, e o contexto `wlan` do `netsh` é implementado por **`wlancmds.dll`, que NÃO existe no
   WinRE 1809** (0 ocorrências na lista de caminhos; `netsh.exe` e `netshell.dll` existem — só
   falta o contexto). Medido junto: `wlanapi.dll`, `wlanext.exe`, `wlancfg.dll`, `wlandlg.dll`,
   `wlanhlp.dll`, `wlanmsm.dll`, `wlanpref.dll`, `wlansec.dll`, `wlansvc.dll`, `wlansvcpal.dll`,
   `wlanui.dll`, `wlanutil.dll` estão na imagem; `dwapi.dll` e `wcnapi.dll` não.
   Consequência: o autorun atual (`scripts/autorun-wwii.cmd`, bloco `netsh wlan`) vai imprimir
   "comando não encontrado" e nada mais. **Isso é um achado de projeto, não um bug de script.**
2. **Auto-conexão**: `WCM Iterate Trigger (Auto Connect)` e `Wcm trigger (Event)` estão dentro do
   próprio `wlansvc.dll`, e o WCM (`wcmsvc`) não existe. Restam dois caminhos, nenhum medido em
   runtime: (a) depositar o perfil XML em `%ProgramData%\Microsoft\Wlansvc\Profiles\Interfaces\
   {guid}\` depois do `drvload` e deixar o `wlansvc` conectar sozinho; (b) copiar `wlancmds.dll`
   do índice 3 do `Core_en-us.esd` (mesma regra de plano B que o D1 já previa para o `wcmsvc`) —
   exige ter o ESD em disco, o que este sandbox não tem agora.
   A terceira saída foi medida e **morreu**: `objdump -p wlancfg.dll` exporta só
   `GetResourceString` e `InitHelperDll`; `wlanutil.dll` (3 584 B) exporta helpers de sinal/SSID;
   `wlanui.dll` idem. **Nenhum binário da imagem exporta `WlanConnect`** para ser chamado por
   `rundll32`/`cscript` (os dois existem, 4 ocorrências cada). Ou seja: sem `wlancmds.dll` não há
   como chamar a WLAN API por linha de comando — só pelo caminho (a) ou (b).
   Registrado como `p0502061818` e escalado ao lead.
3. **p0402412842 encerrado**: a hipótese "driver de Wi-Fi sozinho pode não bastar por causa do
   wcmsvc" foi medida e **não se sustenta** — `wlansvc.dll` não importa `wcmsvc.dll`. O obstáculo
   real acabou sendo outro e está no item 1; virou problema próprio (`p0402452582` não é o mesmo
   assunto).
4. **D4 encerrado**: Bluetooth está fora (0 arquivos `bth`, 0 chaves `bth` no hive). PAN é plano B
   apenas no Windows instalado (R5 parcial).
