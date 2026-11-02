#!/bin/sh
# in-vm-fdisk-pan.sh — ITEM 1 (fdisk real) + ITEM 2 (PAN via netns/veth).
#
# Roda DENTRO do guest QEMU (initramfs Alpine + busybox). Nada e mock:
# disco virtual real (/dev/sda), namespaces de rede e pares veth reais.
#
# ITEM 1 espelha o runbook: cria a tabela de particoes do jeito que o diskpart
# criaria (C: formatada + particao de recuperacao com o Winre.wim) e prova que
# formatar C: NAO apaga a particao de recuperacao.
#
# ITEM 2 espelha o PAN (R4): o "celular" compartilha a conexao com o "PC" por um
# link ponto-a-ponto (veth) dentro de network namespaces.
#   - o PC obtem IP no link PAN
#   - o PC alcanca o servico que roda no "celular"
#   - o PC alcanca a rede externa passando pelo "celular" (ip_forward)
#   - teste negativo: sem o link do celular o acesso falha
#
# Saida: linhas [PASS]/[FAIL] e "RESULTADO:" (aparece no log serial).
set -u
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin
export PATH

DISK="${DISK:-/dev/sda}"
PASS=0
FAIL=0

ok(){ echo "[PASS] $*"; PASS=$((PASS+1)); }
no(){ echo "[FAIL] $*"; FAIL=$((FAIL+1)); }
inf(){ echo "[INFO] $*"; }
sec(){ echo ""; echo "===== $* ====="; }

# ---------------------------------------------------------------- ITEM 1
item1_fdisk(){
  sec "ITEM 1 - fdisk real em $DISK"
  [ -b "$DISK" ] || { no "ITEM1: $DISK ausente no guest"; return 1; }
  ok "ITEM1: device $DISK presente"

  base=$(basename "$DISK")
  total=$(cat "/sys/block/$base/size" 2>/dev/null)
  [ -n "$total" ] || total=$(blockdev --getsz "$DISK" 2>/dev/null)
  [ -n "$total" ] && [ "$total" -ge 8192 ] || { no "ITEM1: tamanho ilegivel (total=$total)"; return 1; }
  ok "ITEM1: $DISK tem $total setores"

  # layout alvo: C: (sistema, formatada) + recuperacao (Winre.wim)
  c_start=2048
  c_size=$(( total / 2 - 2048 ))
  c_end=$(( c_start + c_size - 1 ))
  rec_start=$(( c_end + 1 ))
  rec_end=$(( total - 1 ))
  [ "$rec_end" -gt "$rec_start" ] || { no "ITEM1: disco pequeno demais para 2 particoes"; return 1; }
  inf "ITEM1: layout -> C: [$c_start..$c_end] | recuperacao [$rec_start..$rec_end]"

  p1="${base}1"; p2="${base}2"
  cmds=/tmp/fdisk.cmds
  # o busybox fdisk pede: tipo (p=primaria) -> numero -> primeiro setor -> ultimo setor
  { echo n; echo p; echo 1; echo "$c_start"; echo "$c_end"
    echo n; echo p; echo 2; echo "$rec_start"; echo "$rec_end"
    echo w; echo q; } > "$cmds"
  inf "ITEM1: comandos do fdisk:"; sed 's/^/    | /' "$cmds"

  fdisk -u "$DISK" < "$cmds" > /tmp/fdisk.out 2>&1
  inf "ITEM1: transcript do fdisk:"; sed 's/^/    | /' /tmp/fdisk.out

  st1=$(cat "/sys/block/$base/$p1/start" 2>/dev/null); sz1=$(cat "/sys/block/$base/$p1/size" 2>/dev/null)
  st2=$(cat "/sys/block/$base/$p2/start" 2>/dev/null); sz2=$(cat "/sys/block/$base/$p2/size" 2>/dev/null)
  inf "ITEM1: sysfs -> $p1 start=$st1 size=$sz1 | $p2 start=$st2 size=$sz2"

  good=1
  [ "$st1" = "$c_start" ]  || { no "ITEM1: $p1 comeca em '$st1' (esperado $c_start)"; good=0; }
  [ "$sz1" = "$c_size" ]   || { no "ITEM1: $p1 tem $sz1 setores (esperado $c_size)"; good=0; }
  [ "$st2" = "$rec_start" ] || { no "ITEM1: $p2 comeca em '$st2' (esperado $rec_start)"; good=0; }
  [ -n "$sz2" ]            || { no "ITEM1: $p2 sem tamanho em sysfs"; good=0; }
  [ "$good" = 1 ] && ok "ITEM1: tabela gravada com o layout esperado"

  inf "ITEM1: fdisk -l $DISK"
  fdisk -l "$DISK" 2>&1 | sed 's/^/    | /'
  if fdisk -l "$DISK" 2>&1 | grep -q "$p1" && fdisk -l "$DISK" 2>&1 | grep -q "$p2"; then
    ok "ITEM1: fdisk -l lista $p1 e $p2 (tabela persistida no disco)"
  else
    no "ITEM1: fdisk -l nao lista as particoes criadas"
  fi
  inf "ITEM1: /proc/partitions"; sed 's/^/    | /' /proc/partitions
  if grep -q "$p1" /proc/partitions && grep -q "$p2" /proc/partitions; then
    ok "ITEM1: $p1 e $p2 aparecem em /proc/partitions"
  else
    no "ITEM1: particoes ausentes em /proc/partitions"
  fi

  # ---- assinatura na particao de recuperacao (simula o Winre.wim) ----
  set -- $(awk -v p="$p2" '$4==p {print $1" "$2}' /proc/partitions)
  [ -b "/dev/$p2" ] || mknod "/dev/$p2" b "${1:-8}" "${2:-1}" 2>/dev/null
  { printf 'WINRE_WIM_SIGNATURE_4.4MMII1\n'; dd if=/dev/zero bs=1 count=486 2>/dev/null; } > /tmp/winre.sig
  dd if=/tmp/winre.sig of="/dev/$p2" bs=512 count=1 conv=notrunc 2>/dev/null
  before=$(dd if="/dev/$p2" bs=512 count=1 2>/dev/null | md5sum | cut -d' ' -f1)
  inf "ITEM1: md5 do setor 0 da recuperacao ANTES do wipe = $before"
  case "$(dd if="/dev/$p2" bs=512 count=1 2>/dev/null | tr -d '\000')" in
    *WINRE_WIM_SIGNATURE*) ok "ITEM1: assinatura do Winre.wim presente na particao de recuperacao";;
    *) no "ITEM1: assinatura do Winre.wim NAO encontrada na particao de recuperacao";;
  esac

  # ---- wipe do inicio da particao C: (equivale a formatar C:) ----
  set -- $(awk -v p="$p1" '$4==p {print $1" "$2}' /proc/partitions)
  [ -b "/dev/$p1" ] || mknod "/dev/$p1" b "${1:-8}" "${2:-1}" 2>/dev/null
  inf "ITEM1: wipe do inicio de $p1 (16 MiB de zeros)"
  dd if=/dev/zero of="/dev/$p1" bs=1M count=16 conv=notrunc 2>&1 | sed 's/^/    | /'
  nz=$(dd if="/dev/$p1" bs=512 count=32 2>/dev/null | tr -d '\000' | wc -c)
  if [ "$nz" -eq 0 ]; then
    ok "ITEM1: inicio de $p1 zerado (32 setores, 0 bytes nao-nulos) = C: formatada"
  else
    no "ITEM1: inicio de $p1 ainda tem $nz bytes nao-nulos"
  fi

  after=$(dd if="/dev/$p2" bs=512 count=1 2>/dev/null | md5sum | cut -d' ' -f1)
  inf "ITEM1: md5 do setor 0 da recuperacao DEPOIS do wipe = $after"
  if [ -n "$before" ] && [ "$before" = "$after" ]; then
    ok "ITEM1: particao de recuperacao INTACTA apos formatar C: (md5 identico antes/depois)"
  else
    no "ITEM1: particao de recuperacao CORROMPIDA (antes=$before depois=$after)"
  fi
  st1b=$(cat "/sys/block/$base/$p1/start" 2>/dev/null)
  st2b=$(cat "/sys/block/$base/$p2/start" 2>/dev/null)
  if [ "$st1b" = "$c_start" ] && [ "$st2b" = "$rec_start" ]; then
    ok "ITEM1: tabela de particoes intacta apos o wipe de C:"
  else
    no "ITEM1: tabela de particoes alterada pelo wipe ($st1b/$st2b)"
  fi
  return 0
}

# ---------------------------------------------------------------- ITEM 2
item2_pan(){
  sec "ITEM 2 - PAN simulado (network namespace + veth)"

  # 2.1 modulo veth
  ko=$(find /lib/modules -name 'veth.ko*' 2>/dev/null | head -n1)
  if [ -n "$ko" ]; then
    insmod "$ko" 2>/tmp/insmod.err || modprobe veth 2>/tmp/modprobe.err
    [ -d /sys/module/veth ] && ok "ITEM2: modulo veth carregado ($ko)" \
      || { no "ITEM2: modulo veth nao carregou: $(cat /tmp/insmod.err /tmp/modprobe.err 2>/dev/null)"; return 1; }
  else
    no "ITEM2: veth.ko nao esta no initramfs"
    return 1
  fi

  # 2.2 'ip' completo (o busybox ip nao faz 'ip link add type veth')
  IPBIN=""
  for c in /sbin/ip.full /usr/sbin/ip.full /sbin/ip /usr/sbin/ip; do
    [ -x "$c" ] && { IPBIN="$c"; break; }
  done
  inf "ITEM2: ip = ${IPBIN:-<nenhum>}"
  [ -n "$IPBIN" ] || { no "ITEM2: nenhum binario ip no guest"; return 1; }

  if $IPBIN link add __probe_a type veth peer name __probe_b >/tmp/vprobe.err 2>&1; then
    $IPBIN link del __probe_a >/dev/null 2>&1
    ok "ITEM2: '$IPBIN link add ... type veth' suportado"
  else
    no "ITEM2: 'link add type veth' NAO suportado: $(cat /tmp/vprobe.err)"
    return 1
  fi

  # 2.3 namespaces: 'celular' (gateway do PC) e 'srv' (internet)
  rm -f /tmp/cel.pid /tmp/srv.pid
  unshare -n sh -c 'echo $$ > /tmp/cel.pid; exec sleep 600' >/dev/null 2>&1 &
  unshare -n sh -c 'echo $$ > /tmp/srv.pid; exec sleep 600' >/dev/null 2>&1 &
  sleep 1
  CEL_PID=$(cat /tmp/cel.pid 2>/dev/null); SRV_PID=$(cat /tmp/srv.pid 2>/dev/null)
  [ -n "$CEL_PID" ] && [ -n "$SRV_PID" ] \
    && ok "ITEM2: namespaces criados (celular=$CEL_PID srv=$SRV_PID)" \
    || { no "ITEM2: unshare -n nao criou os namespaces"; return 1; }

  # 2.4 pares veth: pan-pc<->pan-cel (link PAN) e wan-cel<->wan-srv (uplink)
  $IPBIN link add pan-pc type veth peer name pan-cel || { no "ITEM2: falha ao criar par veth do PAN"; return 1; }
  $IPBIN link add wan-cel type veth peer name wan-srv || { no "ITEM2: falha ao criar par veth WAN"; return 1; }
  ok "ITEM2: pares veth criados (pan-pc<->pan-cel, wan-cel<->wan-srv)"

  $IPBIN link set dev pan-cel netns "$CEL_PID" || { no "ITEM2: pan-cel nao moveu para o ns celular"; return 1; }
  $IPBIN link set dev wan-cel netns "$CEL_PID" || { no "ITEM2: wan-cel nao moveu para o ns celular"; return 1; }
  $IPBIN link set dev wan-srv netns "$SRV_PID" || { no "ITEM2: wan-srv nao moveu para o ns srv"; return 1; }
  ok "ITEM2: pontas movidas para os namespaces"

  # 2.5 enderecos e rota: celular compartilha a conexao (10.8/24 no PAN, 10.9/24 uplink)
  $IPBIN addr add 10.8.0.2/24 dev pan-pc; $IPBIN link set pan-pc up
  nsenter -t "$CEL_PID" -n $IPBIN addr add 10.8.0.1/24 dev pan-cel
  nsenter -t "$CEL_PID" -n $IPBIN link set pan-cel up
  nsenter -t "$CEL_PID" -n $IPBIN addr add 10.9.0.1/24 dev wan-cel
  nsenter -t "$CEL_PID" -n $IPBIN link set wan-cel up
  nsenter -t "$CEL_PID" -n $IPBIN link set lo up
  nsenter -t "$CEL_PID" -n sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward' 2>/dev/null
  nsenter -t "$SRV_PID" -n $IPBIN addr add 10.9.0.2/24 dev wan-srv
  nsenter -t "$SRV_PID" -n $IPBIN link set wan-srv up
  nsenter -t "$SRV_PID" -n $IPBIN link set lo up
  # rota de RETORNO: o srv precisa saber responder para a rede do PAN (10.8/24)
  # via o celular. Sem isso o pacote sai mas a resposta nao volta (nao ha SNAT aqui).
  nsenter -t "$SRV_PID" -n $IPBIN route add 10.8.0.0/24 via 10.9.0.1 dev wan-srv 2>/dev/null
  $IPBIN route add 10.9.0.0/24 via 10.8.0.1 dev pan-pc 2>/dev/null
  fwd=$(nsenter -t "$CEL_PID" -n cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)
  inf "ITEM2: ip_forward no ns celular = ${fwd:-<leitura falhou>}"
  inf "ITEM2: rota do srv: $(nsenter -t "$SRV_PID" -n $IPBIN route list 2>/dev/null | tr '\n' ' ')"
  ok "ITEM2: enderecos e rota configurados (PC 10.8.0.2/24 -> celular 10.8.0.1 -> srv 10.9.0.2)"

  # 2.6 servicos
  mkdir -p /www
  printf 'PAN-OK: celular compartilhando conexao com o PC\n' > /www/index.html
  printf 'UPSTREAM-OK: servidor do lado internet\n'                > /www/upstream.html
  chmod 0644 /www/index.html /www/upstream.html
  nsenter -t "$CEL_PID" -n busybox httpd -f -p 8080 -h /www >/tmp/httpd-cel.log 2>&1 &
  nsenter -t "$SRV_PID" -n busybox httpd -f -p 80   -h /www >/tmp/httpd-srv.log 2>&1 &
  sleep 1

  # cliente HTTP: o wget do busybox segfaulta neste initramfs, entao usa nc (TCP cru)
  http_get(){ # http_get <host> <port> <path>
    printf 'GET %s HTTP/1.0\r\nHost: %s\r\n\r\n' "$3" "$1" | nc "$1" "$2" 2>/dev/null
  }

  inf "ITEM2: addr do lado PC:"; $IPBIN addr show dev pan-pc 2>&1 | sed 's/^/    | /'
  $IPBIN addr show dev pan-pc 2>&1 | grep -q '10\.8\.0\.2/24' \
    && ok "ITEM2: PC tem IP 10.8.0.2/24 no link PAN" \
    || no "ITEM2: PC sem IP no link PAN"

  out=$(http_get 10.8.0.1 8080 /index.html)
  echo "$out" | grep -q 'PAN-OK' \
    && { ok "ITEM2: PC acessou o servico do celular atraves do link PAN (R4)"; inf "ITEM2: resposta: $(echo "$out" | tr -d '\r')"; } \
    || no "ITEM2: PC nao alcanca o servico do celular: [$(echo "$out" | tr -d '\r')]"

  ping -c 2 -W 2 10.8.0.1 >/dev/null 2>&1 \
    && ok "ITEM2: ICMP PC->celular ok" \
    || no "ITEM2: ICMP PC->celular falhou"

  out2=$(http_get 10.9.0.2 80 /upstream.html)
  echo "$out2" | grep -q 'UPSTREAM-OK' \
    && ok "ITEM2: PC alcanou a rede externa via o celular (ip_forward) - R1" \
    || no "ITEM2: PC nao alcanca 10.9.0.2 via o celular: [$(echo "$out2" | tr -d '\r')]"

  # 2.7 NEGATIVO: sem o link do celular o acesso falha
  nsenter -t "$CEL_PID" -n $IPBIN link set pan-cel down
  sleep 1
  if http_get 10.8.0.1 8080 /index.html | grep -q 'PAN-OK'; then
    no "ITEM2 (negativo): acesso ainda funcionou sem o link do celular"
  else
    ok "ITEM2 (negativo): acesso falhou como esperado sem o link do celular"
  fi
  nsenter -t "$CEL_PID" -n $IPBIN link set pan-cel up
  sleep 1
  http_get 10.8.0.1 8080 /index.html | grep -q 'PAN-OK' \
    && ok "ITEM2: link restaurado e o acesso voltou" \
    || no "ITEM2: link nao foi restaurado"
  return 0
}

# ---------------------------------------------------------------- main
echo "########## 4.4mmii1 - ITEM 1 (fdisk real) + ITEM 2 (PAN/veth) ##########"
inf "kernel: $(uname -r) | busybox: $(busybox 2>/dev/null | head -n1)"
item1_fdisk
item2_pan
sec "RESUMO"
echo "RESULTADO: PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "RESULTADO: OK - fdisk real (particao de recuperacao sobrevive ao format de C:) e PAN (netns+veth) passaram"
else
  echo "RESULTADO: FALHA - $FAIL teste(s) falharam"
fi
[ "$FAIL" -eq 0 ]
