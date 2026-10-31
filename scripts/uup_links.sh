#!/bin/sh
# uup_links.sh — gera a lista de LINKS DIRETOS OFICIAIS (dominios Microsoft) via API do uupdump.
# Nao baixa nada: só resolve os links, para qualquer agente/máquina baixar de onde quiser.
#
# Uso:
#   sh scripts/uup_links.sh                       # usa ID/EDICAO/IDIOMA padrao (Home 1809 en-us)
#   sh scripts/uup_links.sh --search 1809         # procura builds pelo termo
#   UUP_EDITION=professional sh scripts/uup_links.sh
#   sh scripts/uup_links.sh <UUID> <edition> <lang>
#
# Variaveis de ambiente (todas opcionais):
#   UUP_ID       UUID do build (ex.: 814acacb-6203-4083-b0f0-21746910e3a9 = Win10 1809 amd64)
#   UUP_EDITION  core(Home) | professional | education | enterprise | coren ...
#   UUP_LANG     en-us | pt-br | es-es ...
#   UUP_RING     retail (padrao) | wif | dev
#   UUP_OUT      diretorio de saida (padrao .work/uup)
#
# ATENCAO: a API tem rate limit por IP. Chame poucas vezes e reuse o .tsv gerado.
set -u
API=https://api.uupdump.net
UUP_ID="${UUP_ID:-814acacb-6203-4083-b0f0-21746910e3a9}"   # Feature update Win10 1809 (17763.9376) amd64
UUP_EDITION="${UUP_EDITION:-core}"                          # core = Home
UUP_LANG="${UUP_LANG:-en-us}"
UUP_RING="${UUP_RING:-retail}"
UUP_OUT="${UUP_OUT:-.work/uup}"
say(){ printf '[uup_links] %s\n' "$*"; }

case "${1:-}" in
  --search|-s)
    termo="${2:?uso: --search TERMO}"
    say "procurando builds: $termo"
    curl -s --max-time 30 "$API/listid.php?search=$termo" | python3 -c '
import sys,json
d=json.load(sys.stdin); b=d.get("response",{}).get("builds",{})
for k,v in sorted(b.items(), key=lambda x:-int(x[0]))[:12]:
    print("  %-10s %-58s %s %s"%(v.get("uuid","")[:36], v.get("title","")[:58], v.get("build",""), v.get("arch","")))'
    exit 0;;
esac

[ -n "${1:-}" ] && UUP_ID="$1"
[ -n "${2:-}" ] && UUP_EDITION="$2"
[ -n "${3:-}" ] && UUP_LANG="$3"

mkdir -p "$UUP_OUT"
json="$UUP_OUT/${UUP_ID}_${UUP_EDITION}_${UUP_LANG}.json"
tsv="$UUP_OUT/${UUP_ID}_${UUP_EDITION}_${UUP_LANG}.tsv"

if [ ! -s "$json" ]; then
  say "consultando API: id=$UUP_ID edition=$UUP_EDITION lang=$UUP_LANG ring=$UUP_RING"
  curl -s --max-time 60 "$API/get.php?id=$UUP_ID&lang=$UUP_LANG&edition=$UUP_EDITION&ring=$UUP_RING" -o "$json"
fi

python3 - "$json" "$tsv" <<'EOF'
import json,sys,os
jp,tp=sys.argv[1],sys.argv[2]
d=json.load(open(jp)); r=d.get('response',d)
if 'files' not in r:
    print('[uup_links] ERRO:', r.get('error','desconhecido')); sys.exit(1)
files=r['files']; tot=0
with open(tp,'w') as f:
    f.write("# url\tnome\ttamanho\tsha1\n")
    for fn,info in files.items():
        tot+=int(info.get('size',0))
        f.write("%s\t%s\t%s\t%s\n"%(info.get('url',''),fn,info.get('size',0),info.get('sha1','')))
print("[uup_links] build=%s arquivos=%d total=%.2f GB"%(r.get('build'),len(files),tot/1024**3))
print("[uup_links] lista: %s"%tp)
EOF

# imprime tambem os links diretos (pronto para copiar/uso por outro agente)
[ -s "$tsv" ] && say "links diretos (oficiais Microsoft):" && grep -v '^#' "$tsv" | cut -f1 | sed 's/^/  /'
