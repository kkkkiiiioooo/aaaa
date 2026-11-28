#!/bin/sh
apk add chromium py3-aiohttp
cd "$(dirname "$0")"
chromium --headless --no-sandbox --disable-gpu --remote-debugging-port=9222 about:blank &
sleep 3
exec python3 server.py
