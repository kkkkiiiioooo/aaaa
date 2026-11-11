// storage.js: persistência local (localStorage), contador de uso e limpeza total.
window.App = {};
App.store = {
  p: 'htmlai:',
  get(k, d) {
    try { const v = localStorage.getItem(this.p + k); return v ? JSON.parse(v) : d; } catch (e) { return d; }
  },
  set(k, v) {
    try { localStorage.setItem(this.p + k, JSON.stringify(v)); return true; }
    catch (e) { alert('Armazenamento cheio. Apague conversas ou use "Limpar todos os dados".'); return false; }
  },
  bytes() {
    let n = 0;
    for (const k of Object.keys(localStorage)) if (k.startsWith(this.p)) n += (k.length + localStorage.getItem(k).length) * 2;
    return n;
  },
  clear() {
    Object.keys(localStorage).filter(k => k.startsWith(this.p)).forEach(k => localStorage.removeItem(k));
  }
};
