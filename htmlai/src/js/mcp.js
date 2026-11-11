// mcp.js: cliente MCP, transporte Streamable HTTP (resposta JSON ou SSE) + Mcp-Session-Id.
App.mcp = {
  async rpc(s, method, params, notify) {
    const h = Object.assign({ 'Content-Type': 'application/json', Accept: 'application/json, text/event-stream' }, s.headers || {});
    if (s.sid) h['Mcp-Session-Id'] = s.sid;
    const body = { jsonrpc: '2.0', method, params };
    if (!notify) body.id = Date.now() + Math.random();
    const r = await fetch(s.url, { method: 'POST', headers: h, body: JSON.stringify(body) });
    const sid = r.headers.get('Mcp-Session-Id');
    if (sid) s.sid = sid;
    if (!r.ok) throw new Error('HTTP ' + r.status);
    if (notify) return null;
    let j;
    if ((r.headers.get('content-type') || '').includes('text/event-stream')) {
      for await (const d of App.api.sse(r)) {
        try { const x = JSON.parse(d); if (x.id === body.id) { j = x; break; } } catch (e) { /* ignora */ }
      }
    } else j = await r.json();
    if (!j) throw new Error('sem resposta JSON-RPC');
    if (j.error) throw new Error(JSON.stringify(j.error));
    return j.result;
  },
  async connect(s) {
    await this.rpc(s, 'initialize', { protocolVersion: '2025-03-26', capabilities: {}, clientInfo: { name: 'htmlai', version: '0.1.0' } });
    await this.rpc(s, 'notifications/initialized', {}, true);
    s.tools = (await this.rpc(s, 'tools/list', {})).tools || [];
    return s.tools;
  },
  call(s, name, args) { return this.rpc(s, 'tools/call', { name, arguments: args }); }
};
