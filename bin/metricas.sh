#!/bin/sh
# metricas.sh - o que o lead precisa saber, derivado do git (sem instrumentacao).
#
# Uso: sh bin/metricas.sh [dias]     (padrao 7)
#
# Responde: quem trabalhou, quanto, quando comecou/parou, quanto tempo levou do
# claim ao close por tarefa, e quantos commits nao tem autoria declarada.
set -u
R=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
cd "$R" || exit 2
D=${1:-7}
B=$(git branch --show-current 2>/dev/null)

echo "== commits por agente (ultimos $D dias, branch $B) =="
git log --since="$D.days" --format='%an%x09%(trailers:key=Agent-Name,valueonly)%x09%aI' 2>/dev/null |
awk -F'\t' 'NF>=3 {
  a = ($2 != "" ? $2 : $1); gsub(/[ \t]+$/, "", a)
  c[a]++
  if (!(a in ini) || $3 < ini[a]) ini[a] = $3
  if (!(a in fim) || $3 > fim[a]) fim[a] = $3
  if ($2 == "") sem[a]++
}
END {
  if (!length(c)) { print "  (sem commits no periodo)"; exit }
  printf "%-20s %6s %8s %8s %10s\n", "AGENTE", "COMMITS", "INICIO", "FIM", "SEM-TRAILER"
  for (a in c)
    printf "%-20s %6d %8s %8s %10d\n", a, c[a], substr(ini[a],12,8), substr(fim[a],12,8), sem[a]+0
}' | sort -k2 -rn

echo
echo "== tempo do claim ao close por tarefa (horas) =="
if [ -d events ]; then
  python3 - "$R" <<'PY'
import json, glob, os, sys, datetime
ini, dur = {}, {}
for p in glob.glob(os.path.join(sys.argv[1], "events", "*.jsonl")):
    for l in open(p, encoding="utf-8", errors="replace"):
        try: e = json.loads(l)
        except Exception: continue
        t = e.get("ts")
        try: d = datetime.datetime.strptime(t, "%Y-%m-%dT%H:%M:%SZ")
        except Exception: continue
        if e.get("tipo") == "claim": ini[e["id"]] = d
        elif e.get("tipo") == "close" and e["id"] in ini:
            dur[e["id"]] = (d - ini[e["id"]]).total_seconds() / 3600
if not dur:
    print("  (nenhuma tarefa fechada com claim registrado)")
else:
    for k in sorted(dur, key=lambda x: dur[x]):
        print("  %-6s %6.1f h" % (k, dur[k]))
    print("  media %.1f h · mediana %.1f h" % (
        sum(dur.values()) / len(dur),
        sorted(dur.values())[len(dur) // 2]))
PY
else
  echo "  (sem events/: projeto usa o protocolo antigo)"
fi

echo
echo "== reaberturas (retrabalho) =="
if [ -d events ]; then
  cat events/*.jsonl 2>/dev/null | grep -c '"tipo": *"release"' | sed 's/^/  releases: /'
fi

echo
echo "== saude do protocolo =="
if [ -f .work/protocolo-lint.sh ]; then
  sh .work/protocolo-lint.sh --range "origin/main..HEAD" 2>&1 | tail -3
elif [ -f protocolo-lint.sh ]; then
  sh protocolo-lint.sh --range "origin/main..HEAD" 2>&1 | tail -3
else
  echo "  (protocolo-lint.sh ausente)"
fi
