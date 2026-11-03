"""Inventario de servicos do WinRE 1809 extraido do proprio WIM.

Resolve uma duvida que trava a E2/E5: drivers de rede sem fio nao bastam se o
servico que fala com eles nao existe ou esta desligado.

Pre-requisito: pip install regipy      (testado com 6.5.0)
Extrair o hive antes:
  wimlib-imagex extract .work/uup/files/Core_en-us.esd 2 /Windows/System32/config/SYSTEM --dest-dir=.work/hive
  (atencao: cai em .work/hive/SYSTEM, nao na arvore completa)
Uso: python3 scripts/ler_hive.py .work/hive/SYSTEM
Saida: tabela texto; exit 0 sempre (isso e inventario, nao portao).
"""
import sys

from regipy.registry import RegistryHive

ALVOS = [
    # (servico, por que importa para 'recuperar sem conexao fisica')
    ("WlanSvc", "autoconfiguracao de rede sem fio"),
    ("dot3svc", "rede com fio 802.1X"),
    ("RasMan", "discador / VPN"),
    ("RemoteAccess", "roteamento e acesso remoto"),
    ("NlaSvc", "Network Location Awareness"),
    ("Dhcp", "cliente DHCP"),
    ("LanmanWorkstation", "acesso a \\ \\host\\compartilhado"),
    ("LanmanServer", "oferecer compartilhamento"),
    ("netprofm", "gerenciador de perfis de rede"),
    ("BITS", "download em segundo plano"),
    ("CryptSvc", "validacao de certificado (precisa p/ driver assinado)"),
    ("TrustedInstaller", "TiWorker - exigido por DISM /Add-Driver"),
    ("BFE", "Base Filtering Engine"),
    ("mpssvc", "firewall"),
    ("Winmgmt", "WMI"),
    ("Schedule", "agendador"),
    ("TermService", "area de trabalho remota"),
    ("profsvc", "perfis de usuario"),
    ("AppIDSvc", "política de aplicacao"),
]

START = {0: "BOOT", 1: "SISTEMA", 2: "AUTO", 3: "DEMANDA", 4: "DESATIVADO"}


def main():
    hive_path = sys.argv[1]
    h = RegistryHive(hive_path)
    root = h.root
    cur = 1
    try:
        for v in root.get_subkey("Select").iter_values():
            if v.name.lower() == "current":
                cur = v.value
    except Exception:  # noqa: BLE001
        pass
    cs = "ControlSet%03d" % cur
    services = root.get_subkey(cs).get_subkey("Services")
    todos = {k.name: k for k in services.iter_subkeys()}
    print("hive: %s" % hive_path)
    print("controlset atual: %s  |  %d servicos registrados" % (cs, len(todos)))
    print()
    print("%-20s %-11s %s" % ("SERVICO", "START", "IMAGEPATH / motivo"))
    print("-" * 92)
    presentes = 0
    for nome, motivo in ALVOS:
        k = todos.get(nome)
        if k is None:
            print("%-20s %-11s CHAVE AUSENTE - %s" % (nome, "-", motivo))
            continue
        vals = {v.name: v.value for v in k.iter_values()}
        st = START.get(vals.get("Start"), "?%s" % vals.get("Start"))
        img = vals.get("ImagePath") or vals.get("ServiceDll") or "-"
        print("%-20s %-11s %s" % (nome, st, img))
        presentes += 1
    print("-" * 92)
    print("dos %s itens de interesse: %d tem chave, %d nao tem"
          % (len(ALVOS), presentes, len(ALVOS) - presentes))


if __name__ == "__main__":
    main()
