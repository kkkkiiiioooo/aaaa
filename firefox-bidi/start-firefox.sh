#!/bin/sh
apk add firefox-esr py3-aiohttp
cd "$(dirname "$0")"
mkdir -p /tmp/ff-profile
MOZ_HEADLESS=1 MOZ_DISABLE_CONTENT_SANDBOX=1 MOZ_DISABLE_GMP_SANDBOX=1 \
  firefox-esr -profile /tmp/ff-profile --no-remote --remote-debugging-port=9222 about:blank &
sleep 5
exec python3 server.py
