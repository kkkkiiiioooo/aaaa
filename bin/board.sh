#!/bin/sh
# board.sh - gera BOARD.md e PROGRESS.md a partir de events/*.jsonl.
#
# Estado deixa de ser arquivo editado a mao (que conflita) e passa a ser evento
# append-only em arquivo privado de cada agente (que nunca conflita). Este script
# e a unica coisa que escreve nas visoes; rode-o antes de commitar a visao.
#
# Uso: sh bin/board.sh          # regenera e mostra o quadro
#      sh bin/board.sh --check  # nao escreve; falha se a visao estiver defasada
set -u
R=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
cd "$R" || exit 2
mkdir -p events

python3 - "$R" "${1:-}" <<'PY'
import json, os, sys, glob, datetime

root, modo = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "")
evs = []
for p in sorted(glob.glob(os.path.join(root, "events", "*.jsonl"))):
    for n, linha in enumerate(open(p, encoding="utf-8", errors="replace"), 1):
        linha = linha.strip()
        if not linha:
            continue
        try:
            e = json.loads(linha)
        except Exception:
            print("evento ilegivel: %s:%d" % (os.path.basename(p), n), file=sys.stderr)
            continue
        if not {"ts", "ag", "tipo", "id"} <= set(e):
            continue
        evs.append(e)
evs.sort(key=lambda e: (e["ts"], e["ag"]))

ordem = {"claim": 0, "note": 1, "close": 2, "release": 2}
estado, dono, quando, nota = {}, {}, {}, {}
for e in evs:
    i = e["id"]
    if e["tipo"] == "claim":
        estado[i], dono[i], quando[i] = "tomada", e["ag"], e["ts"]
    elif e["tipo"] == "note":
        nota[i] = e["texto"]
    elif e["tipo"] == "close":
        estado[i], quando[i], nota[i] = "concluida", e["ts"], e.get("texto", "")
        dono.setdefault(i, e["ag"])
    elif e["tipo"] == "release":
        estado[i], quando[i] = "aberta", e["ts"]

def fmt(ts):
    try:
        return datetime.datetime.strptime(ts, "%Y-%m-%dT%H:%M:%SZ").strftime("%Y-%m-%d %H:%M")
    except Exception:
        return ts[:16].replace("T", " ")

b = ["# BOARD.md — gerado por bin/board.sh (nao edite a mao)", "",
     "Estados: aberta -> tomada -> concluida | bloqueada",
     "Reivindicar: `sh bin/reivindicar.sh <ID>` · Fechar: `sh bin/liberar.sh <ID> feita \"<evidencia>\"`", "",
     "| ID | Estado | Agente | Atualizada em | Nota |",
     "| --- | --- | --- | --- | --- |"]
for i in sorted(estado):
    n = (nota.get(i) or "").replace("|", "/")[:70]
    b.append("| %s | %s | %s | %s | %s |" % (i, estado[i], dono.get(i, "—"), fmt(quando.get(i, "")), n))
if not estado:
    b.append("| — | aberta | — | — | nenhuma tarefa registrada |")

p = ["# PROGRESS.md — gerado por bin/board.sh (nao edite a mao)", "",
     "Fonte: `events/<agente>.jsonl` (append-only, um arquivo por agente).", ""]
for e in evs:
    p.append("## %s — %s" % (fmt(e["ts"]), e["ag"]))
    p.append("%s %s: %s" % (e["tipo"], e["id"], e.get("texto", "")))
    p.append("")

novo_b, novo_p = "\n".join(b) + "\n", "\n".join(p) + "\n"
if modo == "--check":
    ok = True
    for nome, novo in (("BOARD.md", novo_b), ("PROGRESS.md", novo_p)):
        atual = open(os.path.join(root, nome), encoding="utf-8").read() if os.path.exists(os.path.join(root, nome)) else ""
        if atual != novo:
            print("DESATUALIZADO: %s (rode sh bin/board.sh)" % nome)
            ok = False
    sys.exit(0 if ok else 1)

for nome, novo in (("BOARD.md", novo_b), ("PROGRESS.md", novo_p)):
    abrir = os.path.join(root, nome)
    if not os.path.exists(abrir) or open(abrir, encoding="utf-8").read() != novo:
        open(abrir, "w", encoding="utf-8").write(novo)
        print("atualizado: %s" % nome)
print(novo_b)
PY
