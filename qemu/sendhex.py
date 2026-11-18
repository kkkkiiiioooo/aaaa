#!/usr/bin/env python3
# sendhex.py - type a hex string into the guest via QEMU monitor `sendkey`,
# simulating the touch-screen virtual keyboard. The hex is sent in short lines
# (Linux canonical mode caps a line at 4096 chars), terminated by an "end" line.
# Inbound channel = typed text only; no network, no host share.
#
# Flow control: after each line the guest prints "ACK <n>" on the serial port.
# We wait for that ACK before typing the next line (lock-step), so the guest never
# falls behind and drops keystrokes. Fixed pacing alone dropped bytes under TCG.
import socket, sys, time
mon, hexfile = sys.argv[1], sys.argv[2]
chunk = int(sys.argv[3]) if len(sys.argv) > 3 else 256
seriallog = sys.argv[4] if len(sys.argv) > 4 else None
hexstr = open(hexfile).read().strip()
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(mon); s.settimeout(2)
time.sleep(0.2)
try: s.recv(65536)
except Exception: pass
def send(cmd):
    s.sendall((cmd + "\n").encode()); time.sleep(0.02)
    try: s.recv(65536)
    except Exception: pass
def type_line(text):
    for ch in text: send("sendkey " + ch)
    send("sendkey ret")
def wait_ack(n, timeout=60):
    if not seriallog:
        time.sleep(0.05); return True
    pat = ("ACK %d" % n).encode()
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            if pat in open(seriallog, "rb").read(): return True
        except FileNotFoundError: pass
        time.sleep(0.05)
    return False
n = 0
for i in range(0, len(hexstr), chunk):
    n += 1
    type_line(hexstr[i:i+chunk])
    if not wait_ack(n):
        print("sendhex: TIMEOUT waiting for ACK %d (guest fell behind)" % n); sys.exit(2)
type_line("end")
s.close()
print("sendhex: typed %d hex chars in %d lines + end via simulated keyboard (ACK flow control)" % (len(hexstr), n))
