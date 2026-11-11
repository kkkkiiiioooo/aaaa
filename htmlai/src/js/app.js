// app.js: inicialização e ligação dos módulos.
(() => {
  const { $ } = App.ui, S = App.store;
  const SYS = [
    'Você é um agente de IA proativo e autônomo que resolve tarefas do início ao fim usando ferramentas (MCP). Responda em português, de forma clara e objetiva. Trabalhe com persistência: continue agindo até a tarefa estar realmente concluída, sem parar no meio e sem pedir confirmação a cada passo.',
    'Data atual: {{data_atual}}',
    '',
    'Regras:',
    '1. Antes de agir, pense no que precisa descobrir. Se a pergunta depende de fatos atuais ou verificáveis, use as ferramentas de busca. Não responda de memória.',
    '2. Chame uma ferramenta por vez quando uma depender da outra. Chame várias juntas só se forem independentes.',
    '3. Use apenas as ferramentas listadas, com o nome exato e argumentos em JSON válido seguindo o schema. Nunca invente ferramentas ou parâmetros.',
    '4. Se uma ferramenta falhar ou voltar vazia, leia o erro, corrija os argumentos ou tente outra consulta. No máximo 2 tentativas por ferramenta, depois explique o que falhou.',
    '5. Em pesquisas, faça várias consultas com termos diferentes, compare fontes e abra as páginas para ler o conteúdo, não só os resumos.',
    '6. Não repita chamadas idênticas. Se um caminho não funcionar, mude a estratégia em vez de insistir. Pare só quando tiver informação suficiente e verificada.',
    '7. Resposta final direta, com cada afirmação importante seguida da fonte (URL completa). O que não foi confirmado deve vir marcado como "não confirmado".',
    '8. Nunca invente nem altere resultados de ferramentas.',
    '9. Seja proativo: se o pedido for ambíguo, escolha a interpretação mais razoável, diga em uma linha qual assumiu e siga em frente. Só pergunte ao usuário se for impossível avançar sem a resposta.',
    '10. Em tarefas longas, escreva antes um plano curto (3 a 6 passos), execute passo a passo, marque o que já foi feito e, no fim, confira o resultado contra o pedido original.',
    '11. Antes de uma ação irreversível (apagar, sobrescrever, enviar dados a terceiros), avise em uma linha o que vai fazer e por quê.'
  ].join('\n');
  const D = { model: 'openai-fast', sys: SYS, temperature: '', top_p: '', max_tokens: '', seed: '', steps: 50, maxres: 8000, stream: true };
  const cfg = Object.assign({}, D, S.get('cfg', {}));
  let chats = S.get('chats', []), cur = null, ctl = null;
  let servers = S.get('servers', [{ name: 'Exa', url: 'https://mcp.exa.ai/mcp', headers: {}, off: [] }]);
  const saveCfg = () => S.set('cfg', cfg);
  const saveSrv = () => S.set('servers', servers.map(({ name, url, headers, off }) => ({ name, url, headers, off })));

  const usage = () => {
    const b = S.bytes();
    $('#usage').textContent = (b / 1048576).toFixed(2) + ' MB / 5 MB' + (b > 4194304 ? ' (quase cheio)' : '');
    $('#bar').value = b / 52428.8;
  };
  const hist = () => {
    const u = $('#hist'); u.innerHTML = '';
    chats.forEach(ch => {
      const li = document.createElement('li'); if (ch === cur) li.className = 'on';
      const t = document.createElement('span'); t.textContent = ch.title || 'Novo chat';
      t.onclick = () => { cur = ch; App.ui.render(ch.messages); hist(); };
      const x = document.createElement('button'); x.textContent = '×';
      x.onclick = () => { chats = chats.filter(c => c !== ch); if (cur === ch) { cur = null; App.ui.clear(); } save(); };
      li.append(t, x); u.appendChild(li);
    });
  };
  const save = () => { S.set('chats', chats); usage(); hist(); };

  const srv = () => {
    const box = $('#servers'); box.innerHTML = '';
    servers.forEach(s => {
      const d = document.createElement('div'); d.className = 'srv';
      const h = document.createElement('div'); h.innerHTML = '<b></b> <small></small> ';
      h.firstChild.textContent = s.name;
      h.querySelector('small').textContent = s.err ? 'erro: ' + s.err : (s.tools ? s.tools.length + ' tools' : 'conectando…');
      const b = document.createElement('button'); b.textContent = 'Testar'; b.onclick = () => conn(s);
      const r = document.createElement('button'); r.textContent = '×';
      r.onclick = () => { servers = servers.filter(x => x !== s); saveSrv(); srv(); };
      h.append(b, r); d.appendChild(h);
      (s.tools || []).forEach(t => {
        const l = document.createElement('label'), k = document.createElement('input');
        k.type = 'checkbox'; k.checked = !(s.off || []).includes(t.name);
        k.onchange = () => { s.off = (s.off || []).filter(n => n !== t.name); if (!k.checked) s.off.push(t.name); saveSrv(); };
        l.append(k, t.name); l.title = t.description || ''; d.appendChild(l);
      });
      box.appendChild(d);
    });
  };
  const conn = s => {
    s.err = null; s.tools = null; s.sid = null; srv();
    App.mcp.connect(s).catch(e => { s.err = e.message; }).finally(srv);
  };

  ['sys', 'temperature', 'top_p', 'max_tokens', 'seed', 'steps', 'maxres'].forEach(k => {
    const e = $('#' + k); e.value = cfg[k]; e.oninput = () => { cfg[k] = e.value; saveCfg(); };
  });
  $('#stream').checked = cfg.stream;
  $('#stream').onchange = e => { cfg.stream = e.target.checked; saveCfg(); };
  $('#model').onchange = e => { cfg.model = e.target.value; saveCfg(); };
  App.api.models().then(m => {
    const l = (Array.isArray(m) ? m : []).map(x => x.name || x.id || x);
    if (!l.includes(cfg.model)) l.unshift(cfg.model);
    l.forEach(n => $('#model').add(new Option(n)));
    $('#model').value = cfg.model;
  }).catch(() => { $('#model').add(new Option(cfg.model)); });

  $('#send').onclick = async () => {
    const t = $('#input').value.trim();
    if (!t || ctl) return;
    $('#input').value = '';
    if (!cur) { cur = { title: t.slice(0, 40), messages: [] }; chats.unshift(cur); }
    cur.messages.push({ role: 'user', content: t });
    App.ui.text(App.ui.bubble('user'), t); save();
    ctl = new AbortController();
    try { await App.agent.run(cur, cfg, servers, App.ui, ctl.signal); }
    catch (e) { App.ui.note(e.name === 'AbortError' ? 'Parado.' : 'Erro: ' + e.message); }
    ctl = null; save();
  };
  $('#stop').onclick = () => ctl && ctl.abort();
  $('#new').onclick = () => { cur = null; App.ui.clear(); hist(); };
  $('#clear').onclick = () => { if (confirm('Apagar todos os dados salvos?')) { S.clear(); location.reload(); } };
  $('#input').onkeydown = e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); $('#send').click(); } };
  $('#madd').onclick = () => {
    let h = {};
    try { h = JSON.parse($('#mhdr').value || '{}'); } catch (e) { return alert('Headers: JSON inválido'); }
    const s = { name: $('#mname').value || 'MCP', url: $('#murl').value.trim(), headers: h, off: [] };
    if (!s.url) return;
    servers.push(s); saveSrv(); conn(s);
  };
  hist(); usage(); srv(); servers.forEach(conn);
})();
