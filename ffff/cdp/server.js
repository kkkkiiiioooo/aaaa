const CDP = require('chrome-remote-interface');
const WebSocket = require('ws');
const http = require('http');
const fs = require('fs');

(async () => {
  const client = await CDP({ port: 9222 });
  const { Page, Input } = client;
  await Page.enable();

  const server = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'text/html');
    res.end(fs.readFileSync(__dirname + '/index.html'));
  });
  const wss = new WebSocket.Server({ server });

  wss.on('connection', (ws) => {
    Page.screencastFrame(async ({ data, sessionId }) => {
      if (ws.readyState === 1) ws.send(data);
      await Page.screencastFrameAck({ sessionId });
    });
    Page.startScreencast({ format: 'jpeg', quality: 50, maxWidth: 800, maxHeight: 480 });

    ws.on('message', (m) => {
      const e = JSON.parse(m);
      if (e.t === 'url') Page.navigate({ url: e.url });
      if (e.t === 'mouse') Input.dispatchMouseEvent({ type: e.type, x: e.x, y: e.y, button: 'left', clickCount: 1 });
      if (e.t === 'key') Input.dispatchKeyEvent({ type: e.type, key: e.key, text: e.type === 'keyDown' && e.key.length === 1 ? e.key : undefined });
    });
    ws.on('close', () => Page.stopScreencast());
  });
  server.listen(8080);
})();
