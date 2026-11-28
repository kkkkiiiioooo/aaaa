import asyncio
import json
import os

import aiohttp
from aiohttp import web

BIDI = os.environ.get('BIDI_WS', 'ws://127.0.0.1:9222/session')
HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 800, 480

KEYS = {
    'Enter': '\ue007', 'Backspace': '\ue003', 'Tab': '\ue004', 'Escape': '\ue00c',
    'ArrowLeft': '\ue012', 'ArrowUp': '\ue013', 'ArrowRight': '\ue014', 'ArrowDown': '\ue015',
    'Delete': '\ue017', 'Home': '\ue011', 'End': '\ue010', 'PageUp': '\ue00e', 'PageDown': '\ue00f',
    'Shift': '\ue008', 'Control': '\ue009', 'Alt': '\ue00a',
}


class Bidi:
    def __init__(self, ws):
        self.ws = ws
        self.n = 0
        self.pending = {}

    async def reader(self):
        async for m in self.ws:
            if m.type != aiohttp.WSMsgType.TEXT:
                continue
            d = json.loads(m.data)
            f = self.pending.pop(d.get('id'), None)
            if f is None or f.done():
                continue
            if d.get('type') == 'error':
                f.set_exception(RuntimeError(d.get('message') or d.get('error')))
            else:
                f.set_result(d.get('result'))

    async def call(self, method, params=None):
        self.n += 1
        i = self.n
        f = asyncio.get_running_loop().create_future()
        self.pending[i] = f
        await self.ws.send_json({'id': i, 'method': method, 'params': params or {}})
        return await asyncio.wait_for(f, 20)


async def index(request):
    return web.FileResponse(os.path.join(HERE, 'index.html'))


async def gestos(request):
    return web.FileResponse(os.path.join(HERE, '..', 'comum', 'gestos.js'))


async def frames(app):
    b, ctx = app['b'], app['ctx']
    mime = 'image/jpeg'
    while True:
        if app['clients']:
            try:
                params = {'context': ctx, 'origin': 'viewport'}
                if mime == 'image/jpeg':
                    params['format'] = {'type': 'image/jpeg', 'quality': 0.5}
                try:
                    r = await b.call('browsingContext.captureScreenshot', params)
                except RuntimeError:
                    if mime == 'image/jpeg':
                        mime = 'image/png'
                        continue
                    raise
                msg = json.dumps({'m': mime, 'd': r['data'], 'w': W if app['vp'] else None, 'h': H if app['vp'] else None})
                for c in list(app['clients']):
                    await c.send_str(msg)
            except Exception:
                pass
        await asyncio.sleep(0.4)


async def perform(app, sources):
    await app['b'].call('input.performActions', {'context': app['ctx'], 'actions': sources})


async def handle(app, e):
    b, ctx = app['b'], app['ctx']
    if e['t'] == 'url':
        await b.call('browsingContext.navigate', {'context': ctx, 'url': e['url'], 'wait': 'none'})
    elif e['t'] == 'mouse':
        down = e['type'] == 'mousePressed'
        acts = [
            {'type': 'pointerMove', 'x': int(e['x']), 'y': int(e['y'])},
            {'type': 'pointerDown' if down else 'pointerUp', 'button': 0},
        ]
        await perform(app, [{'type': 'pointer', 'id': 'm', 'parameters': {'pointerType': 'mouse'}, 'actions': acts}])
    elif e['t'] == 'key':
        k = KEYS.get(e['key'], e['key'] if len(e['key']) == 1 else None)
        if k:
            t = 'keyDown' if e['type'] == 'keyDown' else 'keyUp'
            await perform(app, [{'type': 'key', 'id': 'k', 'actions': [{'type': t, 'value': k}]}])
    elif e['t'] == 'wheel':
        acts = [{'type': 'scroll', 'x': int(e['x']), 'y': int(e['y']), 'deltaX': int(e['dx']), 'deltaY': int(e['dy'])}]
        await perform(app, [{'type': 'wheel', 'id': 'w', 'actions': acts}])
    elif e['t'] == 'click':
        bt = 2 if e.get('button') == 'right' else 0
        acts = [
            {'type': 'pointerMove', 'x': int(e['x']), 'y': int(e['y'])},
            {'type': 'pointerDown', 'button': bt},
            {'type': 'pointerUp', 'button': bt},
        ]
        await perform(app, [{'type': 'pointer', 'id': 'm', 'parameters': {'pointerType': 'mouse'}, 'actions': acts}])


async def ws_handler(request):
    app = request.app
    ws = web.WebSocketResponse()
    await ws.prepare(request)
    app['clients'].add(ws)
    try:
        async for m in ws:
            if m.type != aiohttp.WSMsgType.TEXT:
                continue
            try:
                await handle(app, json.loads(m.data))
            except Exception:
                pass
    finally:
        app['clients'].discard(ws)
    return ws


async def startup(app):
    s = aiohttp.ClientSession()
    ws = await s.ws_connect(BIDI, max_msg_size=0)
    b = Bidi(ws)
    app['s'] = s
    app['b'] = b
    app['reader'] = asyncio.create_task(b.reader())
    await b.call('session.new', {'capabilities': {}})
    tree = await b.call('browsingContext.getTree', {})
    app['ctx'] = tree['contexts'][0]['context']
    app['vp'] = False
    try:
        await b.call('browsingContext.setViewport', {'context': app['ctx'], 'viewport': {'width': W, 'height': H}})
        app['vp'] = True
    except Exception:
        pass
    app['clients'] = set()
    app['frames'] = asyncio.create_task(frames(app))


async def cleanup(app):
    app['frames'].cancel()
    app['reader'].cancel()
    await app['s'].close()


app = web.Application()
app.add_routes([web.get('/', index), web.get('/gestos.js', gestos), web.get('/ws', ws_handler)])
app.on_startup.append(startup)
app.on_cleanup.append(cleanup)

if __name__ == '__main__':
    web.run_app(app, host='0.0.0.0', port=8080)
