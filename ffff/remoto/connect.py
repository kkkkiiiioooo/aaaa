import asyncio
import json
import os

import aiohttp


async def main():
    async with aiohttp.ClientSession() as s:
        async with s.ws_connect(os.environ['WS_ENDPOINT'], max_msg_size=0) as ws:
            n = 0

            async def call(method, params=None, session=None):
                nonlocal n
                n += 1
                msg = {'id': n, 'method': method, 'params': params or {}}
                if session:
                    msg['sessionId'] = session
                await ws.send_json(msg)
                async for m in ws:
                    if m.type != aiohttp.WSMsgType.TEXT:
                        continue
                    d = json.loads(m.data)
                    if d.get('id') == n:
                        if 'error' in d:
                            raise RuntimeError(d['error'])
                        return d.get('result')

            t = await call('Target.createTarget', {'url': 'https://example.com'})
            a = await call('Target.attachToTarget', {'targetId': t['targetId'], 'flatten': True})
            await asyncio.sleep(3)
            r = await call('Runtime.evaluate', {'expression': 'document.title'}, a['sessionId'])
            print(r['result']['value'])


asyncio.run(main())
