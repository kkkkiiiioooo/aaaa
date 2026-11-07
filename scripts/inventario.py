#!/usr/bin/env python3
"""inventario.py - inventario do ambiente REAL do desafio (WinRE 1809), gerado de docs/imagem/winre-caminhos.txt.gz.

Uso:  python3 scripts/inventario.py > docs/imagem/INVENTARIO.md
Saida pensada para o LEAD: tudo o que existe/nao existe no WinRE, sem precisar da imagem em disco.
Medicao por NOME EXATO na lista de caminhos (nao e documentacao da Microsoft).
"""
import gzip, os, re, collections, sys

AQUI = os.path.dirname(os.path.abspath(__file__))
GZ = os.path.join(AQUI, '..', 'docs', 'imagem', 'winre-caminhos.txt.gz')
P = [l.rstrip('\n') for l in gzip.open(GZ, 'rt', errors='replace') if l.strip()]
base = lambda p: p.rsplit('/', 1)[-1]
exes = sorted({base(p) for p in P if p.lower().endswith(('.exe', '.com'))}, key=str.lower)
exl = {e.lower() for e in exes}
dlls = sorted({base(p) for p in P if p.lower().endswith('.dll')}, key=str.lower)
dll_l = {d.lower() for d in dlls}
sys_ = sorted({base(p) for p in P if p.lower().endswith('.sys')}, key=str.lower)
infs = [p for p in P if p.lower().endswith('.inf')]
ext = collections.Counter((base(p).rsplit('.', 1)[-1].lower() if '.' in base(p) else '(sem)') for p in P)

def tem(n):
    n = n.lower()
    return n in exl or n + '.exe' in exl or n + '.com' in exl or n in dll_l

# ferramentas que um script de recuperacao costuma querer
FERR = {
 'rede': 'netsh ipconfig ping net net1 ftp tftp telnet nslookup tracert route arp nbtstat netstat hostname getmac pathping curl wget bitsadmin certutil',
 'script/exec': 'cmd cscript wscript mshta powershell rundll32 regsvr32 wmic schtasks start more sort find findstr xcopy robocopy tar expand where timeout',
 'driver': 'drvload pnputil dism wpeutil wpeinit drvcfg drvinst newdev devcon driverquery InfDefaultInstall',
 'disco/boot': 'diskpart bcdedit bcdboot bootsect bootrec chkdsk format fsutil mountvol convert mbr2gpt attrib icacls takeown manage-bde setup',
 'sistema': 'reg regedit sc tasklist taskkill net whoami shutdown sfc systeminfo msiexec setx notepad',
}
# bibliotecas por tema (nomes que contem o padrao)
TEMAS = [
 ('wlan/wifi', r'wlan|wifi|nwifi|nativewifi|wcm|wwan|eapp|onex|dot3|wifidisplay'),
 ('bluetooth', r'bth|bluetooth|bluet'),
 ('http/rede alto nivel', r'winhttp|wininet|urlmon|webio|msxml|wsock|ws2_|mswsock|dnsapi|dhcp|netapi|netman|netprof|rasapi|rasman|iphlp|nlaapi|nsi\.|fwpuclnt|schannel|crypt32|sspicli|winnsi'),
 ('script/COM', r'^jscript|^vbscript|^scrrun|^wshom|^wscript|^cscript|^msscript'),
 ('driver/PnP', r'^setupapi|^newdev|^cfgmgr|^drvstore|^dism|^wimgapi|^devobj|^drvsetup|^pnpui|^umpnpmgr'),
]
SYSRX = r'wifi|wlan|nwifi|ndis|net|bth|tcpip|afd|http|rdbss|mrv|rtl|rt6|rtw|athr|bcm|b57|e1|ibt|iwl|usb|vwifi|ndiswan|nativewifi'

out = []
w = out.append
w('# INVENTARIO DO AMBIENTE REAL — WinRE 1809 do desafio')
w('')
w('Gerado por `python3 scripts/inventario.py` a partir de `docs/imagem/winre-caminhos.txt.gz` '
  f'({len(P)} caminhos, lista COMPLETA do indice 2 de `Core_en-us.esd`). Medicao por nome exato, nao documentacao.')
w('Serve para o lead decidir sem perguntar "existe X?". Fonte unica; se a imagem mudar, rode o script e comite.')
w('')
w('## 1. Identidade')
w('- Windows 10 build 17763 (1809), edicao Core (Home), en-us; imagem WinRE = indice 2 do ESD (UUP dump).')
w('- Cuidado: o WinRE do dono pode ter sido alterado pelo OEM e ser Pro (componentes mudam). Nao verificado.')
w(f'- Contagem: {len(exes)} executaveis unicos (.exe/.com), {len(dlls)} DLLs unicas, {len(sys_)} drivers .sys, {len(infs)} .inf (UTF-16LE: grep ASCII engana).')
w('')
w('## 2. Ferramentas de linha de comando: PRESENTE / AUSENTE')
for tema, nomes in FERR.items():
    ok = [n for n in nomes.split() if tem(n)]
    no = [n for n in nomes.split() if not tem(n)]
    w(f'- **{tema}** — PRESENTES: {" ".join(ok) or "-"}')
    w(f'  AUSENTES: {" ".join(no) or "-"}')
w('- Observacao: `format`, `more`, `xcopy`, `sort`, `find` etc. podem ser `.com`/`.exe` ou builtin do cmd; "ausente" aqui = sem arquivo na lista.')
w('- `wpeinit`/`wpeutil`: o PE usa `winpeshl.ini` ([LaunchApps]); sem `wpeinit` a rede do PE nao sobe sozinha (ver docs/evidence/autorun-winpe.md).')
w('')
w('## 3. TODOS os executaveis (.exe/.com) do WinRE')
w(' '.join(exes))
w('')
w('## 4. Bibliotecas por tema (nome exato)')
for tema, rx in TEMAS:
    r = re.compile(rx, re.I)
    l = [d for d in dlls if r.search(d)]
    w(f'- **{tema}** ({len(l)}): {" ".join(l) or "-"}')
w('- Ausencias que importam (medidas): `wcmsvc.dll`, `netprofm.dll`, `certutil.exe`, `powershell.exe`, `bitsadmin.exe`, `findstr.exe`, `sc.exe`, `tasklist.exe`, `taskkill.exe`, `curl.exe`, `tar.exe`.')
w('  Verifique cada uma pelo nome na secao 2/3/4 antes de decidir; este arquivo e a fonte.')
w('')
w('## 5. Drivers (.sys) relacionados a rede/USB/Bluetooth (nome exato)')
r = re.compile(SYSRX, re.I)
w(' '.join(s for s in sys_ if r.search(s)))
w('')
w('## 6. Drivers .inf: contagem por pasta')
c = collections.Counter('/'.join(p.split('/')[:-1]) for p in infs)
for k, v in c.most_common(6):
    w(f'- `{k}`: {v}')
w('- Wi-Fi no WinRE sem injecao: apenas `mrvlpcie8897.inf` (Marvell 88W8897, nao generico). Detalhe: docs/imagem/DOSSIE.md §6b e docs/evidence/winre-1809-evidencia.md.')
w('')
w('## 7. Extensoes (visao geral)')
w(', '.join(f'{k}={v}' for k, v in ext.most_common(12)))
sys.stdout.write('\n'.join(out) + '\n')
