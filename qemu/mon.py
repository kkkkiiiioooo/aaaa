#!/usr/bin/env python3
# mon.py - send one HMP command to a QEMU monitor unix socket and print the reply.
# Used only to capture framebuffer screendumps and VM status as boot evidence.
import socket, sys, time
path, cmd = sys.argv[1], sys.argv[2]
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(path); s.settimeout(5)
time.sleep(0.2)
try: s.recv(65536)
except Exception: pass
s.sendall((cmd + "\n").encode())
time.sleep(0.6)
data = b""
try:
    while True:
        c = s.recv(65536)
        if not c: break
        data += c
except socket.timeout:
    pass
sys.stdout.write(data.decode(errors="replace"))
s.close()
