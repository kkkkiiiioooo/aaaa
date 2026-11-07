#!/bin/sh
# boot-winre.sh — E4: dá boot na ISO do WinRE em QEMU e LÊ o log que o autorun gravou em disco.
#
# O gate da E4 não é "a ISO existe": é provar que o PE subiu SOZINHO (sem tecla), rodou
# autorun-wwii.cmd e gravou wwii.log num volume. Este script faz os três:
#   1. cria um disco de dados (MBR + FAT32) — o PE mostra como C: e o autorun copia
#      X:\wwii.log para C:\wwii.log
#   2. sobe QEMU em segundo plano (TCG, sem KVM), com monitor unix e serial em arquivo
#   3. a cada POLL s: screendump (prova visual) + leitura de C:\wwii.log PELO HOST, sem
#      montar nada (mtools lê a partição direto do .img via `partition=1` no ~/.mtoolsrc;
#      o kernel deste sandbox não tem o módulo vfat, então mount NÃO é opção)
#   4. sai sozinho quando o log traz "autorun-wwii end" ou quando estoura o TIMEOUT
#
# Uso: sh scripts/boot-winre.sh [--iso .work/iso/winre-wwii.iso] [--disk .work/vm/dados.img]
#          [--timeout 1800] [--poll 20] [--mem 4096] [--cpus 2]
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
ISO=${ISO:-$R/.work/iso/winre-wwii.iso}
DISK=${DISK:-$R/.work/vm/dados.img}
VM=$R/.work/vm
TIMEOUT=${TIMEOUT:-1800}
POLL=${POLL:-20}
MEM=${MEM:-4096}
CPUS=${CPUS:-2}
# VGA=cirrus -> o screendump sai como texto legivel (std da fonte "checkerboard" ilegivel no TCG)
VGA=${VGA:-std}
# PROVA VISUAL: com -display none o screendump do QEMU 6.2 devolve superficie invalida. Com
# DISP=vnc=127.0.0.1:N + VNC=<porta TCP> o frame real vem de scripts/vncshot.py (sem X, sem
# cliente VNC instalado). Sem VNC definido, o script segue funcionando so com screendump.
DISP=${DISP:-none}
VNC=${VNC:-}
# --- variaveis de diagnostico (2026-11-07, mavis) --------------------------------
# CPU: modelo de CPU do QEMU. O padrao antigo e qemu64; a E4 mediu BSOD com ele.
#      `-cpu max` e a alternativa (so ela destrava o boot). Medir e o que importa.
CPU=${CPU:-qemu64}
# BLOCKSTATS=1: grava `info blockstats` a cada poll (mede onde o boot travou).
BLOCKSTATS=${BLOCKSTATS:-0}
# BSOD=1: classifica cada quadro (scripts/detectar-bsod.py); ao ver a tela laranja
#         manda a seta para a direita pelo monitor, que vira a PAGINA TECNICA do
#         bugcheck (codigo hex, parametros e modulo culpado). Sem isso so temos o
#         nome do stop code, que nao identifica driver.
BSOD=${BSOD:-0}
# DEBUGCON=<arquivo>: saida do debug port do QEMU (so util com `debug on` no BCD).
DEBUGCON=${DEBUGCON:-}
while [ $# -gt 0 ]; do
  case "$1" in
    --iso) ISO="$2"; shift 2;; --disk) DISK="$2"; shift 2;;
    --timeout) TIMEOUT="$2"; shift 2;; --poll) POLL="$2"; shift 2;;
    --mem) MEM="$2"; shift 2;; --cpus) CPUS="$2"; shift 2;;
    --vga) VGA="$2"; shift 2;;
    --cpu) CPU="$2"; shift 2;;
    --blockstats) BLOCKSTATS=1; shift;;
    --bsod) BSOD=1; shift;;
    --debugcon) DEBUGCON="$2"; shift 2;;
    *) echo "opcao desconhecida: $1"; exit 2;;
  esac
done
case "$ISO" in /*) : ;; *) ISO="$R/$ISO";; esac
case "$DISK" in /*) : ;; *) DISK="$R/$DISK";; esac
say(){ printf '[boot] %s %s\n' "$(date -u +%H:%M:%S)" "$*"; }
die(){ say "ERRO: $*"; exit 1; }

command -v qemu-system-x86_64 >/dev/null 2>&1 || die "falta qemu-system-x86_64 (sh scripts/ambiente.sh)"
command -v mtype >/dev/null 2>&1 || die "falta mtools (apt-get install -y mtools)"
command -v socat >/dev/null 2>&1 || die "falta socat (para o monitor do QEMU)"
[ -s "$ISO" ] || die "ISO ausente: $ISO (sh scripts/montar_iso_winre.sh)"
mkdir -p "$VM" "$(dirname "$DISK")"

# --- mtools enxergando a particao 1 do arquivo-bruto (sem loop, sem mount) ---
# `partition=1` e o jeito bonito, mas o mtools 4.0.32 deste sandbox responde
# "Big disks not supported on this architecture" para QUALQUER imagem com
# partition= (medido em 100M/512M/1G/2G/3G, 2026-11-07). O mesmo volume lido com
# `offset=` funciona. Entao: tenta partition=1 e cai para offset= (1 MB = LBA 2048,
# que e o inicio da particao que o proprio script grava no MBR).
OFFSET=1048576
MTSRC="$VM/mtoolsrc"
printf 'mtools_skip_check=1\ndrive t:\n  file="%s"\n  partition=1\n' "$DISK" > "$MTSRC"
export MTOOLSRC="$MTSRC"   # mdir/mtype/mcopy/mrm passam a ver t:/ = particao 1 do disco

# --- disco de dados: MBR + 1 particao FAT32 (>=2G para o mkfs aceite FAT32 de verdade) ---
if [ ! -s "$DISK" ]; then
  say "criando disco de dados $DISK (3G, MBR + 1 particao FAT32)"
  qemu-img create -f raw "$DISK" 3G >/dev/null || die "qemu-img create"
  # MBR escrito em python e FAT32 por mformat com offset: nao depende de fdisk, losetup nem mkfs.vfat
  python3 - "$DISK" <<'PY' || die "mbr"
import struct,sys,os
p=sys.argv[1];n=os.path.getsize(p)//512
e=b'\x00\x20\x21\x00\x0c\xfe\xff\xff'+struct.pack('<II',2048,n-2048)
open(p,'r+b').write(b'\x00'*446+e+b'\x00'*48+b'\x55\xaa')
PY
  mformat -i "$DISK@@1048576" -F -v WWIIDS ::  >/dev/null 2>&1 || die "mformat"
fi
mdir t:/ >/dev/null 2>&1 || {
  say "mtools recusou partition=1; usando offset=$OFFSET"
  printf 'mtools_skip_check=1\ndrive t:\n  file="%s"\n  offset=%s\n' "$DISK" "$OFFSET" > "$MTSRC"
  export MTOOLSRC="$MTSRC"
}
mdir t:/ >/dev/null 2>&1 || die "sem FAT na particao 1 de $DISK (recrie o disco)"
# --- o log do run ANTERIOR nao pode sobrar ---------------------------------------
# Medido em 2026-11-07: o mtools 4.0.32 deste sandbox NAO tem o comando `mrm`
# (o nome do mtools e `mdel`). O `mrm t:/wwii.log` falhava em silencio (rc=127,
# stderr jogado para /dev/null) e o wwii.log VELHO continuava no disco: o gate
# da E4 passava com log de um boot anterior (falso positivo de 202 s).
# Agora: apaga, CONFIRMA que sumiu e, alem disso, o log lido tem que ter data
# posterior ao inicio deste run (o PE escreve %DATE% %TIME% em UTC).
apaga_log(){
  mdel t:/wwii.log >/dev/null 2>&1 || mrm t:/wwii.log >/dev/null 2>&1
  if mtype t:/wwii.log >/dev/null 2>&1; then
    echo "[boot] ERRO: o wwii.log antigo NAO foi apagado (mtools mdel falhou?)." >&2
    echo "[boot]       Sem isto o gate da E4 le log de outro boot: falso positivo." >&2
    return 1
  fi
  return 0
}
apaga_log || die "nao consegui apagar o wwii.log antigo - gate seria falso positivo"
printf 'host gravou isto ANTES do boot (%s)\n' "$(date -u +%FT%TZ)" > "$VM/marca-host.txt"
mcopy "$VM/marca-host.txt" t:/host_marker.txt >/dev/null 2>&1 && say "host_marker.txt gravado no disco"

# --- QEMU ---
# Firmware: UEFI (OVMF) por padrao. Motivo, medido em 2026-11-04: o Winre.wim 1809 traz
# bootmgr.efi, mas NAO traz o bootmgr de BIOS (PCAT) — com SeaBIOS o etfsboot roda e para em
# "CDBOOT: Couldn't find BOOTMGR". BIOS so funciona com BOOTMGR_PCAT apontando para o arquivo
# (midia de instalacao/ADK). Para o teste do autorun isso e irrelevante: o que se quer provar
# e que o PE sobe sem tecla e grava log, e o mesmo winpeshl.ini vale para os dois firmwares.
MON="$VM/monitor.sock"; PIDF="$VM/qemu.pid"; SERIAL="$VM/serial.log"; LOG="$VM/qemu.log"
rm -f "$MON" "$SERIAL" "$LOG"
[ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null
FWMODE=${FWMODE:-bios}
FW=""
if [ "$FWMODE" = uefi ]; then
  CODE=${OVMF_CODE:-/usr/share/OVMF/OVMF_CODE_4M.fd}
  VARS_T=/usr/share/OVMF/OVMF_VARS_4M.fd
  VARS="$VM/ovmf-vars.fd"
  [ -s "$CODE" ] || die "sem OVMF_CODE em $CODE (apt-get install -y ovmf) ou use FWMODE=bios"
  cp -f "$VARS_T" "$VARS"
  FW="-drive if=pflash,format=raw,readonly=on,file=$CODE -drive if=pflash,format=raw,file=$VARS"
fi
say "subendo QEMU TCG ($FWMODE) mem=${MEM}MB cpus=${CPUS} timeout=${TIMEOUT}s"
# DISK_BOOT=<img> troca o CD por um disco de boot (ESP com \EFI\BOOT\BOOTX64.EFI): foi o unico
# caminho que o OVMF aceitou sem tecla e sem opcao de boot inventada (ver montar_disco_winre.sh).
# IMPORTANTE: o disco de dados vai SEMPRE preso, inclusive no boot por CD. No teste de
# 2026-11-04 ele so era ligado quando DISK_BOOT estava definido, entao o autorun gravava o
# log num disco que o host nao enxergava e o gate de E4 nunca podia ser verificado.
# DISKAT=hda por decisao do lead (PLANO DO LIDER D6): repetir uma vez com -hda e nao
# depender do disco, porque o log tambem sai por COM1 (-serial file:, lido abaixo).
DISKAT=${DISKAT:-hda}
MEDIA="-boot order=d -cdrom $ISO -$DISKAT $DISK"
[ -n "${DISK_BOOT:-}" ] && MEDIA="-boot order=c -hda $DISK_BOOT -hdb $DISK"
DBGCON=""
[ -n "$DEBUGCON" ] && DBGCON="-debugcon file:$DEBUGCON"
setsid sh -c "exec qemu-system-x86_64 \
  -name wwii-e4 -pidfile $PIDF \
  -m $MEM -smp $CPUS -cpu $CPU \
  $FW \
  $MEDIA \
  -netdev user,id=n0,dhcpstart=10.0.2.15 -device e1000,netdev=n0,mac=52:54:00:00:04:04 \
  -display "$DISP" -vga "$VGA" \
  -serial file:$SERIAL \
  $DBGCON \
  -monitor unix:$MON,server,nowait" > "$LOG" 2>&1 < /dev/null &
sleep 8
QP=$(cat "$PIDF" 2>/dev/null || pgrep -f 'wwii-e4' | head -1)
[ -n "$QP" ] || { tail -20 "$LOG"; die "qemu nao subiu"; }
say "qemu pid=$QP"

mon(){ printf '%s\n' "$1" | socat - UNIX-CONNECT:"$MON" 2>/dev/null; }
shot(){ # shot <rotulo> -> arquivo .ppm (QEMU 6.x so grava PPM)
  rm -f "$VM/shot-$1.ppm"
  mon "screendump $VM/shot-$1.ppm" >/dev/null 2>&1
  [ -s "$VM/shot-$1.ppm" ]
}
readlog(){ # readlog <rotulo> -> .work/vm/wwii-<rotulo>.log
  rm -f "$VM/wwii-$1.log"
  mtype t:/wwii.log > "$VM/wwii-$1.log" 2>/dev/null || return 1
  [ -s "$VM/wwii-$1.log" ] || return 1
  # o log tem que ser DESTE run: o PE escreve %DATE% %TIME% na 2a linha (UTC no sandbox)
  python3 - "$VM/wwii-$1.log" "$START_ISO" <<'PY' || return 1
import re, sys, datetime
log = open(sys.argv[1], errors="replace").read()
ref = datetime.datetime.strptime(sys.argv[2], "%Y-%m-%dT%H:%M:%SZ").replace(
    tzinfo=datetime.timezone.utc)
m = re.search(r"(\d{2}/\d{2}/\d{4})\s+(\d{2}:\d{2}:\d{2})", log)
if not m:
    print("[boot]   log sem data/hora reconhecivel: descartado", file=sys.stderr)
    sys.exit(1)
try:
    dt = datetime.datetime.strptime(m.group(1) + " " + m.group(2),
                                   "%m/%d/%Y %H:%M:%S").replace(
        tzinfo=datetime.timezone.utc)
except ValueError:
    sys.exit(1)
if dt < ref - datetime.timedelta(seconds=60):
    print("[boot]   log de run ANTERIOR (%s < %s): descartado" % (dt, ref), file=sys.stderr)
    sys.exit(1)
print("[boot]   log deste run: %s" % dt, file=sys.stderr)
PY
}
serialmarca(){ # canal alternativo (D6): o autorun despeja o log em COM1 e o QEMU grava em SERIAL
  [ -s "$SERIAL" ] && grep -aq 'autorun-wwii' "$SERIAL"
}

START=$(date +%s); START_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ); N=0; FOUND=0; BSODSTATE=""; BSODVISTO=0
while :; do
  EL=$(( $(date +%s) - START ))
  [ "$EL" -gt "$TIMEOUT" ] && { say "timeout de ${TIMEOUT}s atingido"; break; }
  kill -0 "$QP" 2>/dev/null || { say "qemu encerrou sozinho em ${EL}s"; break; }
  N=$((N+1)); T=$(printf '%03d' "$N")
  shot "$T" && say "${EL}s: tela capturada (shot-$T.ppm)"
  if [ -n "$VNC" ]; then
    python3 "$R/scripts/vncshot.py" --porta "$VNC" --saida "$VM/tela-$T.ppm" >/dev/null 2>&1 \
      && python3 "$R/scripts/ppm2png.py" "$VM/tela-$T.ppm" "$VM/tela-$T.png" >/dev/null 2>&1 \
      && say "${EL}s: tela VNC -> tela-$T.png"
  fi
  # --- diagnostico do bugcheck e do travamento ---------------------------------
  # blockstats: onde o convidado parou de ler/escrever (mede, nao supoe).
  [ "$BLOCKSTATS" = 1 ] && { mon "info blockstats" >> "$VM/blockstats.log" 2>/dev/null; }
  # bugcheck: a tela laranja do Win10 1809 so mostra o NOME do stop code. A seta para
  # a direita vira a pagina tecnica, que traz codigo hex, parametros e modulo culpado.
  if [ "$BSOD" = 1 ]; then
    FRAME=""
    [ -s "$VM/tela-$T.ppm" ] && FRAME="$VM/tela-$T.ppm"
    [ -z "$FRAME" ] && [ -s "$VM/shot-$T.ppm" ] && FRAME="$VM/shot-$T.ppm"
    if [ -n "$FRAME" ]; then
      ST=$(python3 "$R/scripts/detectar-bsod.py" "$FRAME" 2>/dev/null)
      [ "$ST" != "$BSODSTATE" ] && { say "${EL}s: estado da tela = ${ST}"; BSODSTATE="$ST"; }
      if [ "$ST" = bsod ] && [ "$BSODVISTO" = 0 ]; then
        BSODVISTO=1
        say "${EL}s: *** BUGCHECK DETECTADO *** -> mandando seta para a direita (pagina tecnica)"
        mon "sendkey right" >/dev/null 2>&1; sleep 3
        mon "sendkey right" >/dev/null 2>&1; sleep 2
        if [ -n "$VNC" ]; then
          python3 "$R/scripts/vncshot.py" --porta "$VNC" --saida "$VM/tecnico-$T.ppm" >/dev/null 2>&1 \
            && python3 "$R/scripts/ppm2png.py" "$VM/tecnico-$T.ppm" "$VM/tecnico-$T.png" >/dev/null 2>&1 \
            && say "${EL}s: pagina tecnica -> tecnico-$T.png"
        fi
      fi
    fi
  fi
  if readlog "$T"; then
    FOUND=1
    say "${EL}s: wwii.log LIDO DO DISCO ($(wc -l < "$VM/wwii-$T.log") linhas)"
    grep -q 'autorun-wwii end' "$VM/wwii-$T.log" && { say "${EL}s: autorun concluido"; break; }
  fi
  if serialmarca; then
    FOUND=1
    cp -f "$SERIAL" "$VM/serial-$T.log" 2>/dev/null
    say "${EL}s: AUTORUN VISTO NO SERIAL ($(wc -l < "$VM/serial-$T.log") linhas)"
    grep -aq 'autorun-wwii end' "$SERIAL" && { say "${EL}s: autorun concluido (serial)"; break; }
  fi
  sleep "$POLL"
done

mon "system_power" >/dev/null 2>&1
kill -TERM "$QP" 2>/dev/null; sleep 3; kill -KILL "$QP" 2>/dev/null
sleep 1
readlog final && say "LOG FINAL: .work/vm/wwii-final.log" || say "sem wwii.log no disco"
mdir t:/ 2>/dev/null | sed 's/^/[boot] disco: /'
say "evidencia: $VM (shot-*.ppm, serial.log, wwii-*.log, qemu.log)"
[ "$FOUND" = 1 ] || exit 1
exit 0
