#!/bin/sh
# doctor.sh - diz o que ESTE ambiente consegue executar, antes de voce gastar a rodada.
#
# Por que isto existe: o AGENTS.md manda preparar o ambiente com `sh setup.sh`, mas o
# setup.sh instalava so curl/wget/git/unzip/xz - nada de qemu nem wimlib. O agente lia
# "[setup] pronto", ia rodar um teste e falhava 3 passos depois. Dava para saber no
# passo 1. Este script mede em vez de supor e aponta o nivel atingivel.
#
# Uso: sh scripts/doctor.sh      (exit 0 = ha pelo menos um nivel executavel)
set -u
PASS=0; FAIL=0
ok(){ printf '  [ok    ] %s\n' "$*"; PASS=$((PASS+1)); }
no(){ printf '  [FALTA ] %s\n' "$*"; FAIL=$((FAIL+1)); }
have(){ command -v "$1" >/dev/null 2>&1; }

MEM=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}')
DISK=$(df -m . 2>/dev/null | awk 'NR==2{print $4}')
KVM=nao; [ -w /dev/kvm ] && KVM=sim

echo "== niveis de teste (do mais barato ao mais fiel) =="

echo "T0 - inspecao/injecao offline de WIM (wimlib)"
if have wimlib-imagex; then ok "wimlib-imagex presente: da para abrir e alterar o Winre.wim"; T0=sim
else no "wimlib-imagex ausente: rode sh scripts/ambiente.sh"; T0=nao; fi

echo "T1 - suite QEMU Linux ja escrita (a que termina em SUITE: PASS)"
if have qemu-system-x86_64 && have qemu-img && have busybox && have unsquashfs; then
  ok "qemu + qemu-img + busybox + unsquashfs: suite executavel"
  if [ "$KVM" = sim ]; then ok "/dev/kvm acessivel (acelerado)"; else no "sem /dev/kvm: usara TCG (emulacao pura, mais lento)"; fi
  T1=sim
else no "ferramenta de VM ausente: rode sh scripts/ambiente.sh"; T1=nao; fi

echo "T2 - PAN simulado (network namespaces + veth)"
if have unshare && have ip; then
  if unshare -Un true 2>/dev/null; then ok "netns+veth liberado: suite PAN executavel"; T2=sim
  else no "unshare existe, mas o kernel negou namespace (container sem CAP_NET_ADMIN)"; T2=nao; fi
else no "iproute2/unshare ausentes"; T2=nao; fi

echo "T3 - boot real de WinRE/WinPE (precisa ISO + recursos)"
T3=nao
if [ "${MEM:-0}" -ge 3072 ] && [ "${DISK:-0}" -ge 12288 ] && have qemu-system-x86_64; then
  ok "recursos minimos OK (mem ${MEM}MB, disco ${DISK}MB livres)"
  echo "         falta ainda: ISO do 1809 (uup_links.sh + baixar_uup.sh + converter_iso.sh)"
  echo "         sem /dev/kvm o PE do Windows e MUITO lento em TCG: rode em 2o plano, timeout alto"
  T3=parcial
else
  no "sem condicoes agora (qemu=preciso, mem>=3072MB, disco>=12288MB) - mem=${MEM:-?} disco=${DISK:-?}"
fi

echo "T4 - driver WiFi em runtime / erro 10 do adaptador real"
echo "  [fora  ] exige o hardware do dono: nenhum sandbox reproduce. Limite do metodo, nao do agente."

echo "== sentenca =="
printf 'mem=%sMB disco_livre=%sMB kvm=%s ok=%s falta=%s\n' "${MEM:-?}" "${DISK:-?}" "$KVM" "$PASS" "$FAIL"
EXEC=""
[ "$T0" = sim ] && EXEC="$EXEC T0"
[ "$T1" = sim ] && EXEC="$EXEC T1"
[ "$T2" = sim ] && EXEC="$EXEC T2"
[ "$T3" != nao ] && EXEC="$EXEC T3:$T3"
if [ -z "$EXEC" ]; then
  echo "NAO HA como testar nada aqui ainda. Rode sh scripts/ambiente.sh e repita o doctor."
  exit 1
fi
echo "EXECUTAVEL AGORA:$EXEC"
echo "Proximo passo util: sh scripts/tests/run-tests.sh    (T1+T2)"
exit 0
