// ui.js: renderização do chat. Blocos JSON ficam abertos (<details open>) por padrão.
(() => {
  const $ = s => document.querySelector(s), c = $('#chat');
  const down = () => { c.scrollTop = c.scrollHeight; };
  const add = (cls, t) => {
    const d = document.createElement('div');
    d.className = cls; if (t != null) d.textContent = t;
    c.appendChild(d); down(); return d;
  };
  App.ui = {
    $,
    bubble: (role = 'assistant') => add('msg ' + role, ''),
    text: (el, t) => { el.innerHTML = App.md(t); down(); },
    note: t => add('note', t),
    clear: () => { c.innerHTML = ''; },
    raw(title, o) {
      const d = document.createElement('details'); d.open = true;
      const s = document.createElement('summary'); s.textContent = title;
      const p = document.createElement('pre'); p.textContent = JSON.stringify(o, null, 2);
      d.append(s, p); c.appendChild(d); down();
    },
    render(msgs) {
      this.clear();
      msgs.forEach(m => {
        if (m.role === 'tool') return this.raw('Resultado da ferramenta', { tool_call_id: m.tool_call_id, content: m.content });
        this.text(this.bubble(m.role), m.content || '');
        (m.tool_calls || []).forEach(t => this.raw('tool_call ' + t.function.name, t));
      });
    }
  };
})();
