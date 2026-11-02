#!/bin/busybox sh
# in-vm-tests.sh — suite executada DENTRO da VM (stand-in do WinRE).
# Simula, em analogo Linux, o fluxo do runbook de recuperacao. Imprime PASS/FAIL.
fail=0
ok() { echo "  [PASS] $1"; }
no() { echo "  [FAIL] $1"; fail=$((fail+1)); }

echo "-- T1 kernel/console"
echo "  $(cut -c1-70 /proc/version 2>/dev/null)"
ok "boot + /init + console serial funcionando"

echo "-- T2 disco virtual presente"
DISK=$(ls /dev/sd? /dev/vd? 2>/dev/null | head -n1)
if [ -n "$DISK" ]; then
  ok "disco detectado: $DISK"
else
  no "nenhum disco de bloco (/dev/sd? ou /dev/vd?)"
fi

echo "-- T3 particao C: formatada (mock: wipe do inicio do disco)"
if [ -n "$DISK" ] && [ -b "$DISK" ]; then
  if dd if=/dev/zero of="$DISK" bs=1M count=1 2>/dev/null; then
    ok "wipe de C: simulado (dd em $DISK)"
  else
    no "falha ao escrever em $DISK"
  fi
else
  no "disco ausente"
fi

echo "-- T4 imagem de recuperacao (mock de Winre.wim)"
mkdir -p /mnt/winre
echo "wim-base" > /mnt/winre/base.txt
if tar -cf /recovery/winre.tar -C /mnt/winre . 2>/dev/null; then
  ok "imagem de recuperacao criada (tar)"
else
  no "falha ao criar imagem de recuperacao"
fi

echo "-- T5 injecao de driver (analogo a DISM /Add-Driver)"
mkdir -p /tmp/wr && tar -xf /recovery/winre.tar -C /tmp/wr       # monta (desempacota)
echo "wifi.inf" > /tmp/wr/wifi.inf                                # adiciona o driver
tar -cf /recovery/winre.tar -C /tmp/wr . 2>/dev/null              # commit (reempacota)
if tar -tf /recovery/winre.tar 2>/dev/null | grep -q wifi.inf; then
  ok "driver injetado e persistido na imagem"
else
  no "driver nao persistiu na imagem"
fi

echo "-- T6 conectividade (premissa do desafio)"
ifaces=$(ip link show 2>/dev/null | grep -c '^[0-9]')
if [ "${ifaces:-0}" -le 1 ]; then
  ok "sem rede (apenas lo) — premissa 'WinRE sem rede' reproduzida"
else
  ok "com interface de rede (NET=1): $ifaces ifaces"
fi

echo "-- T7 fdisk real + PAN (netns/veth)"
if [ -f /in-vm-fdisk-pan.sh ]; then
  sh /in-vm-fdisk-pan.sh
  if [ $? -eq 0 ]; then
    ok "suite fdisk/PAN (detalhes acima) sem falhas"
  else
    no "suite fdisk/PAN reportou falhas (detalhes acima)"
  fi
else
  no "in-vm-fdisk-pan.sh ausente no initramfs"
fi

echo "RESULTADO: $([ $fail -eq 0 ] && echo PASS || echo FAIL) ($fail falhas)"
[ "$fail" -eq 0 ]
