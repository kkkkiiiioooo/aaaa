import asyncio
import json
import os

import aiohttp
from aiohttp import web

CDP_HTTP = os.environ.get('CDP_HTTP', 'http://127.0.0.1:9222')
HERE = os.path.dirname(os.path.abspath(__file__))


async def index(request):
    return web.FileResponse(os.path.join(HERE, 'index.html'))


async def ws_handler(request):
    ws = web.WebSocketResponse()
    await ws.prepare(request)
    async with aiohttp.ClientSession() as s:
        async with s.get(CDP_HTTP + '/json') as r:
            pages = [p for p in await r.json() if p.get('type') == 'page']
        async with s.ws_connect(pages[0]['webSocketDebuggerUrl'], max_msg_size=0) as cdp:
            n = 0

            async def call(method, params=None):
                nonlocal n
                n += 1
                await cdp.send_json({'id': n, 'method': method, 'params': params or {}})

            async def from_cdp():
                async for m in cdp:
                    if m.type != aiohttp.WSMsgType.TEXT:
                        continue
                    d = json.loads(m.data)
                    if d.get('method') == 'Page.screencastFrame':
                        p = d['params']
                        await ws.send_str(p['data'])
                        await call('Page.screencastFrameAck', {'sessionId': p['sessionId']})

            await call('Page.enable')
            await call('Page.startScreencast', {'format': 'jpeg', 'quality': 50, 'maxWidth': 800, 'maxHeight': 480})
            task = asyncio.create_task(from_cdp())
            async for m in ws:
                if m.type != aiohttp.WSMsgType.TEXT:
                    continue
                e = json.loads(m.data)
                if e['t'] == 'url':
                    await call('Page.navigate', {'url': e['url']})
                elif e['t'] == 'mouse':
                    await call('Input.dispatchMouseEvent', {'type': e['type'], 'x': e['x'], 'y': e['y'], 'button': 'left', 'clickCount': 1})
                elif e['t'] == 'key':
                    k = {'type': e['type'], 'key': e['key']}
                    if e['type'] == 'keyDown' and len(e['key']) == 1:
                        k['text'] = e['key']
                    await call('Input.dispatchKeyEvent', k)
            task.cancel()
            await call('Page.stopScreencast')
    return ws


app = web.Application()
app.add_routes([web.get('/', index), web.get('/ws', ws_handler)])

if __name__ == '__main__':
    web.run_app(app, host='0.0.0.0', port=8080)
