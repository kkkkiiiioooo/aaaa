// api.js: Pollinations (compatível com OpenAI) + parser SSE reaproveitado pelo mcp.js.
App.api = {
  base: 'https://text.pollinations.ai',
  async models() {
    const r = await fetch(this.base + '/models');
    return r.json();
  },
  // Gera o payload de cada evento SSE ("data: ...").
  async *sse(res) {
    const rd = res.body.getReader(), dec = new TextDecoder();
    let buf = '';
    for (;;) {
      const { done, value } = await rd.read();
      if (done) break;
      buf += dec.decode(value, { stream: true }).replace(/\r\n/g, '\n');
      let i;
      while ((i = buf.indexOf('\n\n')) >= 0) {
        const ev = buf.slice(0, i); buf = buf.slice(i + 2);
        const data = ev.split('\n').filter(l => l.startsWith('data:')).map(l => l.slice(5).trim()).join('\n');
        if (data) yield data;
      }
    }
  },
  async chat(body, signal, onDelta) {
    const r = await fetch(this.base + '/openai', {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body), signal
    });
    if (!r.ok) throw new Error('HTTP ' + r.status + ' ' + (await r.text()).slice(0, 300));
    if (!body.stream) return (await r.json()).choices[0].message;
    const m = { role: 'assistant', content: '', tool_calls: [] };
    for await (const d of this.sse(r)) {
      if (d === '[DONE]') break;
      let j; try { j = JSON.parse(d); } catch (e) { continue; }
      const x = j.choices && j.choices[0] && j.choices[0].delta;
      if (!x) continue;
      if (x.content) { m.content += x.content; onDelta && onDelta(m.content); }
      for (const t of x.tool_calls || []) {
        const k = t.index || 0;
        const c = m.tool_calls[k] || (m.tool_calls[k] = { id: '', type: 'function', function: { name: '', arguments: '' } });
        if (t.id) c.id = t.id;
        if (t.function) { c.function.name += t.function.name || ''; c.function.arguments += t.function.arguments || ''; }
      }
    }
    m.tool_calls = m.tool_calls.filter(Boolean);
    if (!m.tool_calls.length) delete m.tool_calls;
    return m;
  }
};
