#!/usr/bin/env python3
"""inf_dependencias.py — lista os arquivos que um INF de driver exige em disco.

Por que existe: um INF de rede referencia firmware e co-instaladores em
[SourceDisksFiles] (e o .sys em [ServiceInstall]/[CopyFiles]). Se esses arquivos
nao estao junto do INF (ou no pacote do DriverStore), o `drvload` falha com
0x80070002 (ERROR_FILE_NOT_FOUND): o INF "existe", o driver nao instala.

Medido em 2026-11-07 no WinRE 1809: os 6 drivers da E2 injetados so com
.inf/.sys/.cat/.dll falhavam no PE com 0x80070002; so o mrvlpcie8897.inf, que ja
veio na imagem com o pacote completo no DriverStore, carregava. As listas que
faltavam eram .dat, .bin, .msc, .txt (firmware).

Uso: python3 scripts/inf_dependencias.py <arquivo.inf> [outro.inf ...]
Saida: uma linha por arquivo exigido (nome do arquivo, sem caminho), sem repetir.
Exit: 0 sempre (a lista pode ser vazia: INF sem referencia de arquivo).
"""
import pathlib
import re
import sys


def texto_inf(caminho):
    raw = pathlib.Path(caminho).read_bytes()
    if raw[:2] == b"\xff\xfe":
        return raw.decode("utf-16-le", "ignore")
    if raw[:2] == b"\xfe\xff":
        return raw.decode("utf-16-be", "ignore")
    return raw.decode("latin-1", "ignore")


def dependencias(caminho):
    txt = texto_inf(caminho)
    refs = set()
    secao = ""
    for linha in txt.splitlines():
        s = linha.strip()
        if s.startswith("[") and s.endswith("]"):
            secao = s[1:-1].strip().lower()
            continue
        if not s or s.startswith(";"):
            continue
        # o nome da secao pode ter sufixo: [SourceDisksFiles.amd64], [CopyFiles.NT]
        base = secao.split(".")[0]
        if base == "sourcedisksfiles":
            # "Nome.sys = 1,,"  ->  nome do arquivo
            if "=" in s:
                nome = s.split("=", 1)[0].strip()
                if nome:
                    refs.add(nome)
        elif base == "copyfiles":
            # "Nome.sys" ou "Nome.sys,Destino"
            nome = s.split(",", 1)[0].strip()
            if nome and not nome.startswith("%"):
                refs.add(nome)
        elif ".files" in secao:
            # secao de arquivos referenciada por CopyFiles= (ex.: [BCM43XX_NT64.files.NTamd64])
            # formato: "nome.sys,,,6"
            nome = s.split(",", 1)[0].strip()
            if nome and not nome.startswith("%"):
                refs.add(nome)
        elif base == "serviceinstall":
            m = re.search(r"servicebinary\s*=\s*(.+)$", s, re.I)
            if m:
                nome = m.group(1).split(",")[0].strip().split("\\")[-1]
                if nome and not nome.startswith("%"):
                    refs.add(nome)
    return refs


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    todos = set()
    for p in sys.argv[1:]:
        try:
            todos |= dependencias(p)
        except Exception as e:  # noqa: BLE001
            print("erro lendo %s: %s" % (p, e), file=sys.stderr)
    for nome in sorted(todos, key=str.lower):
        print(nome)
    return 0


if __name__ == "__main__":
    sys.exit(main())
