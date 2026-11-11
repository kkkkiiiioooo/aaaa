// agent.js: loop agentic manual (modelo -> tool_calls -> MCP -> resultado -> modelo).
App.agent = {
  async run(chat, cfg, servers, ui, signal) {
    for (let i = 0; i < (+cfg.steps || 50); i++) {
      const tools = [], map = {};
      servers.forEach(s => (s.tools || []).forEach(t => {
        if ((s.off || []).includes(t.name)) return;
        tools.push({ type: 'function', function: { name: t.name, description: (t.description || '').slice(0, 300), parameters: t.inputSchema || { type: 'object', properties: {} } } });
        map[t.name] = s;
      }));
      const sys = (cfg.sys || '').replace('{{data_atual}}', new Date().toLocaleDateString('pt-BR'));
      const body = { model: cfg.model, messages: [{ role: 'system', content: sys }, ...chat.messages], stream: !!cfg.stream };
      ['temperature', 'top_p', 'max_tokens', 'seed'].forEach(k => { if (cfg[k] !== '' && cfg[k] != null) body[k] = +cfg[k]; });
      if (tools.length) body.tools = tools;
      ui.raw('Requisição → Pollinations', body);
      const el = ui.bubble();
      const m = await App.api.chat(body, signal, t => ui.text(el, t));
      chat.messages.push(m);
      ui.text(el, m.content || '');
      if (!m.tool_calls || !m.tool_calls.length) return;
      const seen = new Set();
      await Promise.all(m.tool_calls.map(async (c, k) => {
        c.id = c.id || 'call_' + i + '_' + k;
        let args, out;
        try { args = JSON.parse(c.function.arguments || '{}'); }
        catch (e) { out = 'Erro: argumentos JSON inválidos (' + e.message + '). Tente de novo.'; }
        const sig = c.function.name + c.function.arguments, s = map[c.function.name];
        if (!out && seen.has(sig)) out = 'Erro: chamada idêntica repetida no mesmo passo.';
        seen.add(sig);
        if (!out) {
          if (!s) out = 'Erro: ferramenta inexistente. Válidas: ' + Object.keys(map).join(', ');
          else try {
            const r = await App.mcp.call(s, c.function.name, args);
            out = (r.content || []).map(x => x.text || JSON.stringify(x)).join('\n') || JSON.stringify(r);
          } catch (e) { out = 'Erro: ' + e.message; }
        }
        const lim = +cfg.maxres || 8000, cut = out.length > lim;
        if (cut) out = out.slice(0, lim) + '\n…[truncado]';
        ui.raw('Ferramenta ' + c.function.name, { tool_call: c, arguments: args, result: out, truncado: cut });
        c._out = out;
      }));
      m.tool_calls.forEach(c => { chat.messages.push({ role: 'tool', tool_call_id: c.id, content: c._out }); delete c._out; });
    }
    ui.note('Limite de passos atingido. Envie uma mensagem para continuar.');
  }
};
