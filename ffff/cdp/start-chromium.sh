#!/bin/sh
apk add chromium nodejs npm
cd "$(dirname "$0")"
npm install
chromium --headless --no-sandbox --disable-gpu --remote-debugging-port=9222 about:blank &
sleep 3
exec node server.js
