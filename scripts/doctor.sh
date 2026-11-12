#!/bin/sh
# doctor.sh - diz o que ESTE ambiente consegue executar.
#
# Uso: sh scripts/doctor.sh            (saida humana, padrao)
#      sh scripts/doctor.sh --env       (KEY=VALUE, parseable com . ou source)
#      sh scripts/doctor.sh --json      (JSON one-liner)
#      sh scripts/doctor.sh --cache     (usa cache de 5 min em .work/doctor-cache.env)
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
MODE=${1:-human}
[ "$MODE" = "--env" ]   && MODE=env
[ "$MODE" = "--json" ]  && MODE=json
[ "$MODE" = "--cache" ] && MODE=cache

CACHE_F="$R/.work/doctor-cache.env"
if [ "$MODE" = cache ] && [ -f "$CACHE_F" ]; then
  age=$(( $(date +%s) - $(date -r "$CACHE_F" +%s 2>/dev/null || echo 0) ))
  [ "$age" -lt 300 ] && { cat "$CACHE_F"; exit 0; }
fi

SILENT=0
{ [ "$MODE" = env ] || [ "$MODE" = json ] || [ "$MODE" = cache ]; } && SILENT=1

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); [ "$SILENT" = 0 ] && printf '  [ok    ] %s\n' "$*"; }
no(){ FAIL=$((FAIL+1)); [ "$SILENT" = 0 ] && printf '  [FALTA ] %s\n' "$*"; }
inf(){ [ "$SILENT" = 0 ] && printf '           %s\n' "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }
hdr(){ [ "$SILENT" = 0 ] && echo "$*"; }

MEM=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}')
DISK=$(df -m "$R" 2>/dev/null | awk 'NR==2{print $4}')
KVM=nao; [ -w /dev/kvm ] && KVM=sim

hdr "== niveis de teste (do mais barato ao mais fiel) =="

hdr "T0 - inspecao/injecao offline de WIM (wimlib)"
T0=nao
if have wimlib-imagex; then ok "wimlib-imagex presente: da para abrir e alterar o Winre.wim"; T0=sim
else no "wimlib-imagex ausente: rode sh scripts/ambiente.sh"; fi

hdr "T1 - suite QEMU Linux ja escrita (a que termina em SUITE: PASS)"
T1=nao
if have qemu-system-x86_64 && have qemu-img && have busybox && have unsquashfs; then
  ok "qemu + qemu-img + busybox + unsquashfs: suite executavel"
  if [ "$KVM" = sim ]; then ok "/dev/kvm acessivel (acelerado)"
  else no "sem /dev/kvm: usara TCG (emulacao pura, mais lento)"; fi
  T1=sim
else no "ferramenta de VM ausente: rode sh scripts/ambiente.sh"; fi

hdr "T2 - PAN simulado (network namespaces + veth)"
T2=nao
if have unshare && have ip; then
  if unshare -Un true 2>/dev/null; then ok "netns+veth liberado: suite PAN executavel"; T2=sim
  else no "unshare existe, mas o kernel negou namespace (container sem CAP_NET_ADMIN)"; fi
else no "iproute2/unshare ausentes"; fi

hdr "T3 - boot real de WinRE/WinPE (precisa ISO + recursos)"
T3=nao
if [ "${MEM:-0}" -ge 3072 ] && [ "${DISK:-0}" -ge 12288 ] && have qemu-system-x86_64; then
  ok "recursos minimos OK (mem ${MEM}MB, disco ${DISK}MB livres)"
  inf "falta: imagem (sh scripts/obter_imagem.sh --wim; ISO: sh scripts/montar_iso_winre.sh)"
  inf "sem /dev/kvm: PE do Windows MUITO lento em TCG — 2o plano, timeout alto"
  T3=parcial
else
  no "sem condicoes (qemu+mem>=3072MB+disco>=12288MB) mem=${MEM:-?} disco=${DISK:-?}"
fi

hdr "T4 - driver WiFi em runtime / erro 10 do adaptador real"
hdr "  [fora  ] exige hardware do dono: nenhum sandbox reproduz. Limite do metodo."

EXEC=""
[ "$T0" = sim ]     && EXEC="$EXEC T0"
[ "$T1" = sim ]     && EXEC="$EXEC T1"
[ "$T2" = sim ]     && EXEC="$EXEC T2"
[ "$T3" != nao ]    && EXEC="$EXEC T3:$T3"

if [ "$SILENT" = 0 ]; then
  echo "== sentenca =="
  printf 'mem=%sMB disco_livre=%sMB kvm=%s ok=%s falta=%s\n' "${MEM:-?}" "${DISK:-?}" "$KVM" "$PASS" "$FAIL"
  if [ -z "$EXEC" ]; then
    echo "NAO HA como testar nada aqui ainda. Rode sh scripts/ambiente.sh e repita o doctor."
    exit 1
  fi
  echo "EXECUTAVEL AGORA:$EXEC"
  echo "Proximo passo util: sh scripts/tests/run-tests.sh    (T1+T2)"
fi

ENV_LINE="T0=$T0 T1=$T1 T2=$T2 T3=$T3 MEM=${MEM:-?} DISK=${DISK:-?} KVM=$KVM EXEC=${EXEC# }"

case "$MODE" in
  env|cache)
    printf '%s\n' "$ENV_LINE"
    mkdir -p "$(dirname "$CACHE_F")"
    printf '%s\n' "$ENV_LINE" > "$CACHE_F"
    ;;
  json)
    printf '{"T0":"%s","T1":"%s","T2":"%s","T3":"%s","MEM":"%s","DISK":"%s","KVM":"%s","EXEC":"%s"}\n' \
      "$T0" "$T1" "$T2" "$T3" "${MEM:-?}" "${DISK:-?}" "$KVM" "${EXEC# }"
    ;;
esac

[ -n "$EXEC" ] || exit 1
exit 0
