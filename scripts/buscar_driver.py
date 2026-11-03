#!/usr/bin/env python3
r"""buscar_driver.py — acha e baixa o driver de um dispositivo no Microsoft Update Catalog.

Resolve o passo "pegar o ID (VEN_/DEV_) -> achar o driver -> injetar com DISM"
do desafio, sem depender de pagina web aberta a mao.

Fluxo:
  1. busca o hardware ID no catalogo (https://www.catalog.update.microsoft.com)
  2. resolve a URL de download do .cab/.exe/.msi via DownloadDialog.aspx
  3. baixa o pacote e extrai (cab/exe)
  4. le os HardwareID de cada .inf e diz se o driver serve para o dispositivo
     (match exato de PCI\VEN_xxxx&DEV_xxxx, ignorando SUBSYS/REV)

Uso:
  python3 scripts/buscar_driver.py busca   "PCI\\VEN_14E4&DEV_4365"
  python3 scripts/buscar_driver.py baixa   "PCI\\VEN_14E4&DEV_4365" [--guid GUID] [--dir DIR]
  python3 scripts/buscar_driver.py inf     "PCI\\VEN_14E4&DEV_4365" --dir DIR
  python3 scripts/buscar_driver.py catalogo "USB\\VID_0A5C&PID_21E1"

Exit codes: 0 ok · 1 erro de uso/rede · 2 nenhum driver encontrado · 3 nenhum INF casa
"""

import argparse
import http.cookiejar
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

CATALOG = "https://www.catalog.update.microsoft.com"
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
TIMEOUT = 40


# ---------------------------------------------------------------- infra http

def _opener():
    """Opener com cookiejar: o catalogo exige sessao entre Search e DownloadDialog."""
    cj = http.cookiejar.CookieJar()
    op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    op.addheaders = [("User-Agent", UA)]
    return op


def _get(op, url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with op.open(req, timeout=TIMEOUT) as r:
        return r.read().decode("utf-8", "ignore")


def _post_form(op, url, fields, referer=None):
    headers = {"Content-Type": "application/x-www-form-urlencoded", "User-Agent": UA}
    if referer:
        headers["Referer"] = referer
    req = urllib.request.Request(url, data=urllib.parse.urlencode(fields).encode(),
                                 headers=headers)
    with op.open(req, timeout=TIMEOUT) as r:
        return r.read().decode("utf-8", "ignore")


# ------------------------------------------------------------- 1. buscar

def search(op, hwid):
    """Busca o hardware ID e devolve a lista de updates do catalogo."""
    url = f"{CATALOG}/Search.aspx?q={urllib.parse.quote(hwid)}"
    html = _get(op, url)
    if "encountered a problem" in html:
        raise RuntimeError("catalogo recusou a busca (tente de novo em alguns minutos)")
    out = []
    # cada linha da tabela de resultados: <tr id="<GUID>_R0"> ... titulo ... data ... tamanho
    for m in re.finditer(r'<tr id="([0-9a-f-]{36})_R\d+".*?</tr>', html, re.S):
        guid, row = m.group(1), m.group(0)
        cells = re.findall(r"<td[^>]*>(.*?)</td>", row, re.S)

        def text(cell):
            t = re.sub(r"<[^>]+>", " ", cell)
            return re.sub(r"\s+", " ", t).strip()

        title = text(cells[1]) if len(cells) > 1 else ""
        if not title:
            continue
        date = text(cells[4]) if len(cells) > 4 else ""
        size = text(cells[6]) if len(cells) > 6 else ""
        out.append({"guid": guid, "title": title, "date": date, "size": size,
                    "url": f"{CATALOG}/Details.aspx?updateid={guid}"})
    return out


# --------------------------------------------------------- 2. url do arquivo

def resolve_download(op, hwid, guid):
    """DownloadDialog devolve a lista de arquivos (.cab/.exe/.msi) do update."""
    body = {"updateIDs": json.dumps([{"size": 0, "updateID": guid, "uidInfo": hwid}])}
    html = _post_form(op, f"{CATALOG}/DownloadDialog.aspx", body,
                      referer=f"{CATALOG}/Search.aspx?q={urllib.parse.quote(hwid)}")
    files = []
    for m in re.finditer(r"files\[(\d+)\]\.url\s*=\s*'([^']+)'", html):
        url = m.group(2).replace("&amp;", "&")
        name = url.rsplit("/", 1)[-1]
        files.append({"url": url, "name": name})
    for m in re.finditer(r"files\[(\d+)\]\.fileName\s*=\s*'([^']+)'", html):
        for f in files:
            if not f.get("name") and m.group(2) == f["name"]:
                f["name"] = m.group(2)
    return files


# ------------------------------------------------------------ 3. baixar

def download(op, url, dest):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with op.open(req, timeout=300) as r, open(dest, "wb") as fh:
        shutil.copyfileobj(r, fh, 1024 * 64)
    return os.path.getsize(dest)


def extract(path, dest_dir):
    """Extrai .cab (7z/cabextract) ou .exe (7z) — devolve a lista de arquivos extraidos."""
    os.makedirs(dest_dir, exist_ok=True)
    if shutil.which("7z"):
        cmd = ["7z", "x", "-y", f"-o{dest_dir}", path]
    elif shutil.which("cabextract"):
        cmd = ["cabextract", "-d", dest_dir, path]
    else:
        return []
    try:
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       timeout=300, check=False)
    except subprocess.TimeoutExpired:
        return []
    return sorted(os.listdir(dest_dir))


# ------------------------------------------------------------ 4. ler INF

def inf_hardware_ids(path):
    """Extrai os HardwareID declarados no INF.

    O INF traz o ID na secao [Manufacturer] (%Mfg% = Modelo, PCI\\VEN_...&DEV_...)
    e/ou na secao de modelos, via HardwareID=.
    """
    ids = set()
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as fh:
            text = fh.read()
    except OSError:
        return ids
    # forma "PCI\VEN_14E4&DEV_4365&SUBSYS_..." em linhas de modelo
    for m in re.finditer(r"((?:PCI|USB|USBSTOR|ACPI|ROOT)\\[A-Za-z0-9_&\\.\-]+)", text, re.I):
        ids.add(m.group(1))
    # forma "HardwareID=PCI\VEN_...\DEV_..." (mais de um por linha, separados por &)
    for line in text.splitlines():
        if "HardwareID" not in line:
            continue
        for part in line.split("=")[1:]:
            for m in re.finditer(r"((?:PCI|USB|USBSTOR)\\[A-Za-z0-9_&\\.\-]+)", part, re.I):
                ids.add(m.group(1))
    return ids


def _base_id(hwid):
    """PCI\\VEN_14E4&DEV_4365&SUBSYS_... -> (VEN_14E4, DEV_4365)."""
    up = hwid.upper()
    ven = re.search(r"VEN_([0-9A-F]{4})", up)
    dev = re.search(r"DEV_([0-9A-F]{4})", up)
    if ven and dev:
        return ("PCI", ven.group(1), dev.group(1))
    vid = re.search(r"VID_([0-9A-F]{4})", up)
    pid = re.search(r"PID_([0-9A-F]{4})", up)
    if vid and pid:
        return ("USB", vid.group(1), pid.group(1))
    return None


def _matches(driver_id, target):
    """True se o HardwareID do INF serve para o dispositivo alvo.

    Regra do Windows: o match e por PCI\\VEN_x&DEV_y; SUBSYS/REV podem faltar
    no INF (ou no alvo) e ainda assim o driver e compativel.
    """
    d, t = _base_id(driver_id), _base_id(target)
    if not d or not t:
        return False
    if d[0] != t[0]:
        return False
    return d[1] == t[1] and d[2] == t[2]


def check_infs(target, directory):
    """Analisa todos os .inf do diretorio e diz quais servem para o alvo."""
    found = []
    for root, _dirs, files in os.walk(directory):
        for name in files:
            if not name.lower().endswith(".inf"):
                continue
            path = os.path.join(root, name)
            ids = inf_hardware_ids(path)
            hit = [i for i in ids if _matches(i, target)]
            found.append({"inf": path, "ids": sorted(ids), "match": hit})
    return found


# ---------------------------------------------------------------- cli

def cmd_search(args):
    op = _opener()
    try:
        res = search(op, args.hwid)
    except Exception as e:  # noqa: BLE001
        print(f"ERRO: {e}", file=sys.stderr)
        return 1
    if not res:
        print(f"nenhum driver encontrado para {args.hwid}")
        return 2
    print(f"{len(res)} driver(s) no catalogo para {args.hwid}\n")
    for i, r in enumerate(res, 1):
        print(f"{i:2}. {r['title']}")
        print(f"    data={r['date'] or '?'}  tamanho={r['size'] or '?'}")
        print(f"    guid={r['guid']}")
        print(f"    {r['url']}")
    return 0


def cmd_download(args):
    op = _opener()
    outdir = os.path.abspath(args.dir)
    os.makedirs(outdir, exist_ok=True)

    guid = args.guid
    if not guid:
        try:
            res = search(op, args.hwid)
        except Exception as e:  # noqa: BLE001
            print(f"ERRO: {e}", file=sys.stderr)
            return 1
        if not res:
            print(f"nenhum driver encontrado para {args.hwid}")
            return 2
        # o primeiro resultado costuma ser o driver mais especifico do device
        guid = res[0]["guid"]
        print(f"usando guid={guid} ({res[0]['title']})")

    try:
        files = resolve_download(op, args.hwid, guid)
    except Exception as e:  # noqa: BLE001
        print(f"ERRO ao resolver download: {e}", file=sys.stderr)
        return 1
    if not files:
        print("ERRO: catalogo nao devolveu arquivos para este update")
        return 1

    for f in files:
        dest = os.path.join(outdir, f["name"])
        if os.path.exists(dest) and os.path.getsize(dest) > 0:
            print(f"ja existe: {f['name']}")
        else:
            try:
                size = download(op, f["url"], dest)
            except Exception as e:  # noqa: BLE001
                print(f"ERRO ao baixar {f['name']}: {e}", file=sys.stderr)
                continue
            print(f"baixado: {f['name']} ({size} bytes)")
        ex = extract(dest, os.path.join(outdir, "extracted"))
        if ex:
            print(f"  extraido em extracted/: {', '.join(ex[:8])}"
                  f"{' ...' if len(ex) > 8 else ''}")

    print(f"\npacote em: {outdir}")
    return 0


def cmd_inf(args):
    directory = os.path.abspath(args.dir)
    if not os.path.isdir(directory):
        print(f"ERRO: {directory} nao existe", file=sys.stderr)
        return 1
    res = check_infs(args.hwid, directory)
    if not res:
        print(f"nenhum .inf em {directory}")
        return 3
    any_match = False
    for r in res:
        if r["match"]:
            any_match = True
            print(f"[MATCH ] {r['inf']}")
            for m in r["match"]:
                print(f"         {m}")
        else:
            print(f"[nao   ] {r['inf']}  ({len(r['ids'])} ids declarados)")
    print()
    if any_match:
        print(f"OK: driver compativel com {args.hwid} encontrado.")
        print("injetar no WinRE com:")
        print(f"  dism /Image:C:\\mnt /Add-Driver /Driver:<pasta do .inf> /Recurse")
        return 0
    print(f"FALHA: nenhum INF em {directory} serve para {args.hwid}")
    return 3


def cmd_catalog(args):
    op = _opener()
    try:
        res = search(op, args.hwid)
    except Exception as e:  # noqa: BLE001
        print(f"ERRO: {e}", file=sys.stderr)
        return 1
    print(json.dumps(res, indent=2, ensure_ascii=False))
    return 0 if res else 2


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("busca", help="lista drivers do catalogo para o hardware ID")
    p.add_argument("hwid")
    p.set_defaults(func=cmd_search)

    p = sub.add_parser("baixa", help="baixa e extrai o pacote do driver")
    p.add_argument("hwid")
    p.add_argument("--guid", help="updateID especifico (default: primeiro resultado)")
    p.add_argument("--dir", default=".work/drivers")
    p.set_defaults(func=cmd_download)

    p = sub.add_parser("inf", help="confere se os INFs do diretorio servem para o device")
    p.add_argument("hwid")
    p.add_argument("--dir", required=True)
    p.set_defaults(func=cmd_inf)

    p = sub.add_parser("catalogo", help="saida JSON da busca")
    p.add_argument("hwid")
    p.set_defaults(func=cmd_catalog)

    args = ap.parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
