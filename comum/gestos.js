function instalarGestos(el, enviar, mapear) {
  var LIM = 8, LONGO = 500, PASSO = 40;
  var st = null, timer = null, vy = 0, raf = null;
  var acc = { dx: 0, dy: 0, p: null }, ultimo = 0;

  function soltar() {
    var sx = Math.round(acc.dx), sy = Math.round(acc.dy);
    if (acc.p && (sx || sy)) {
      enviar({ t: 'wheel', x: acc.p.x, y: acc.p.y, dx: sx, dy: sy });
      acc.dx -= sx;
      acc.dy -= sy;
    }
    ultimo = performance.now();
  }

  function empurrar(dx, dy, p) {
    acc.dx += dx;
    acc.dy += dy;
    acc.p = p;
    if (performance.now() - ultimo >= PASSO) soltar();
  }

  function parar() {
    if (raf) cancelAnimationFrame(raf);
    raf = null;
  }

  el.addEventListener('touchstart', function (e) {
    e.preventDefault();
    var rodando = !!raf;
    parar();
    clearTimeout(timer);
    if (e.touches.length !== 1) { st = null; return; }
    var t = e.touches[0];
    st = { x0: t.clientX, y0: t.clientY, x: t.clientX, y: t.clientY, mov: false, longo: false, parou: rodando, tm: performance.now() };
    vy = 0;
    timer = setTimeout(function () {
      if (st && !st.mov && !st.parou) {
        st.longo = true;
        var p = mapear({ clientX: st.x0, clientY: st.y0 });
        enviar({ t: 'click', x: p.x, y: p.y, button: 'right' });
      }
    }, LONGO);
  }, { passive: false });

  el.addEventListener('touchmove', function (e) {
    e.preventDefault();
    if (!st || e.touches.length !== 1 || st.longo) return;
    var t = e.touches[0];
    if (!st.mov && Math.hypot(t.clientX - st.x0, t.clientY - st.y0) < LIM) return;
    st.mov = true;
    clearTimeout(timer);
    var agora = performance.now();
    var dt = Math.max(agora - st.tm, 1);
    var dx = st.x - t.clientX, dy = st.y - t.clientY;
    vy = 0.8 * vy + 0.2 * (dy / dt);
    st.tm = agora;
    st.x = t.clientX;
    st.y = t.clientY;
    var p = mapear(t);
    empurrar(dx * p.k, dy * p.k, p);
  }, { passive: false });

  function fim(e, cancelado) {
    e.preventDefault();
    clearTimeout(timer);
    if (!st) return;
    var s = st;
    st = null;
    if (!s.mov && !s.longo && !s.parou && !cancelado) {
      var p0 = mapear({ clientX: s.x0, clientY: s.y0 });
      enviar({ t: 'click', x: p0.x, y: p0.y, button: 'left' });
      return;
    }
    if (!s.mov || cancelado) return;
    soltar();
    var v = vy;
    var ult = performance.now();
    var p = mapear(e.changedTouches[0]);
    if (Math.abs(v) < 0.05) return;
    function passo(agora) {
      var dt = Math.max(agora - ult, 0);
      ult = agora;
      empurrar(0, v * dt * p.k, p);
      v *= Math.pow(0.95, dt / 16);
      if (Math.abs(v) > 0.02) raf = requestAnimationFrame(passo);
      else { raf = null; soltar(); }
    }
    raf = requestAnimationFrame(passo);
  }

  el.addEventListener('touchend', function (e) { fim(e, false); }, { passive: false });
  el.addEventListener('touchcancel', function (e) { fim(e, true); }, { passive: false });
}
