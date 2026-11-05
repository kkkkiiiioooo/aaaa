# Evidência: `netsh wlan` provavelmente EXISTE no WinRE 1809 (corrige p0502061818)

**Agente:** claude · **quando:** 2026-11-05 · **método:** inspeção estática do `Winre.lote.wim` (índice 1), ambiente do claude (ver `ambientes/claude.md`). Nada executado em runtime.

## O que corrige
`docs/evidence/wlan_wcm_bth_hive.md` (linha 8) concluiu que `netsh wlan` **não existe** porque `wlancmds.dll` tem 0 ocorrências na imagem. A premissa estava errada: **o helper do contexto `wlan` é `wlancfg.dll`, não `wlancmds.dll`**. Não há evidência de que `wlancmds.dll` exista em nenhum Windows 10; a ausência dele não prova nada.

## Medidas
| # | pergunta | medida | resultado |
|---|---|---|---|
| 1 | o helper está registrado no netsh? | hive SOFTWARE `\Microsoft\NetSh`: `wlancfg = wlancfg.dll`, `WcnNetsh = WcnNetsh.dll` (+ `ifmon`, `dhcpclient`, `rasmontr`, `wshelper`, `nshwfp`, `netiohlp`) | **sim** |
| 2 | `wlancfg.dll` é um helper do netsh? | `objdump -p`: importa `NETSH.EXE` e `wlanapi.dll`; exporta `InitHelperDll` e `GetResourceString` (entrada padrão de helper) | **sim** |
| 3 | tem os comandos? | `en-US/wlancfg.dll.mui` (presente na imagem) traz a ajuda: "Connect to the wireless network given by ssid...", "Add a wireless network profile on an interface...", exemplos `%1!s! filename="Profile1.xml" interface=...`, `export`, `delete`, `show` | **sim** |
| 4 | outros indícios | `wlancfg.dll` usa `WpParseProfileXml`, `WlanStringToSsid` e o comando interno `netsh.exe wlan show all` (WlanReport) | coerente |
| 5 | `wlancmds` aparece em algum lugar? | `strings` ASCII e UTF-16 em `wlancfg.dll`: 0 | nada depende dele |

## Consequência
- A rota **(a) perfil XML** passa a ter comando direto: `netsh wlan add profile filename=<x.xml>` e `netsh wlan connect name=<perfil>`. Não é preciso depositar o XML à mão no store do `wlansvc` nem copiar DLL do ESD.
- O bloco `netsh wlan` do `autorun-wwii.cmd` **não é decorativo**.
- **D1 volta a ser executável** como o líder escreveu. O que continua não provado em runtime: `wlansvc` iniciar sem `wcmsvc`, o driver carregar (erro 10), o `drvload` + `wlansvc` enxergarem a interface.

## Limite
Strings e registro não provam execução. Só a máquina real (ou WinPE em VM Windows) confirma `netsh wlan show interfaces`.

## Como reproduzir
```sh
wimlib-imagex extract .work/wim/Winre.lote.wim 1 /Windows/System32/config/SOFTWARE /Windows/System32/wlancfg.dll /Windows/System32/en-US/wlancfg.dll.mui --dest-dir=.work/hive2 --no-acls
python3 -c "from regipy.registry import RegistryHive as H;k=H('.work/hive2/SOFTWARE').get_key('\\\\Microsoft\\\\NetSh');print({v.name:v.value for v in k.iter_values()})"
objdump -p .work/hive2/wlancfg.dll | grep -E 'NETSH|wlanapi'
strings -e l .work/hive2/wlancfg.dll.mui | grep -iE 'Connect to the wireless|Add a wireless network profile'
```
