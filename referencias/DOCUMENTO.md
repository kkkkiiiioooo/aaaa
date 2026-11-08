# ddee — dockur/windows + KasmVNC (webtop) + desktop-lite

## Estrutura
- `windows/` → clone de [dockur/windows](https://github.com/dockur/windows) (base, `.devcontainer/` original: porta 8006, `codespaces.yml`)
- `docker-baseimage-kasmvnc/` → [linuxserver/docker-baseimage-kasmvnc](https://github.com/linuxserver/docker-baseimage-kasmvnc) (nginx + s6)
- `docker-webtop/` → [linuxserver/docker-webtop](https://github.com/linuxserver/docker-webtop)
- `features/` → [devcontainers/features](https://github.com/devcontainers/features) (desktop-lite)
- `.devcontainer/` → resultado (Dockerfile, start.sh, devcontainer.json) — **NÃO TESTADO** (sem Docker/ghcr aqui)

## Por que o KasmVNC funciona no ghcs tunnel (hipóteses, com evidência)
Fonte: [defaults/default.conf](https://github.com/linuxserver/docker-baseimage-kasmvnc/blob/master/root/defaults/default.conf), [svc-kasmvnc/run](https://github.com/linuxserver/docker-baseimage-kasmvnc/blob/master/root/etc/s6-overlay/s6-rc.d/svc-kasmvnc/run), [init-nginx/run](https://github.com/linuxserver/docker-baseimage-kasmvnc/blob/master/root/etc/s6-overlay/s6-rc.d/init-nginx/run)

| # | Evidência (trecho exato) | Efeito provável |
|---|---|---|
| 1 | `listen 3000 default_server;` (HTTP puro) | O túnel (GitHub/cloudflared) termina o TLS; backend HTTP evita erro de cert self-signed |
| 2 | `-sslOnly 0` e `-disableBasicAuth -SecurityTypes None` no Xvnc | KasmVNC nativo exige SSL+basic auth; aqui some a barreira atrás do proxy |
| 3 | `proxy_set_header Upgrade $http_upgrade; Connection "upgrade";` | Websocket passa corretamente |
| 4 | `proxy_set_header Cookie "";` | Remove cookies do túnel (evita conflito de auth) |
| 5 | `location SUBFOLDERwebsockify` → `proxy_pass http://127.0.0.1:6901` | Separa o websocket do HTTP (6900/6901) |
| 6 | `add_header 'Cross-Origin-Embedder-Policy' 'require-corp'` | Headers COOP/COEP exigidos pelo cliente web |
| 7 | `-PublicIP 127.0.0.1` | Evita o servidor anunciar IP interno |

Sem nginx + cf tunnel funcionando sugere #1/#2 (Xvnc direto em `-sslOnly 0`) e que o Host/Origin chega correto. **Confirmar rodando:** `curl -sI -H 'Upgrade: websocket' -H 'Connection: Upgrade' localhost:6901`.

## desktop-lite funciona porque
Fonte: [install.sh](https://github.com/devcontainers/features/blob/main/src/desktop-lite/install.sh): `tigervncserver ... -rfbport ${VNC_PORT} ... -localhost` + noVNC/websockify na 6080 (HTTP puro, sem cert).

## Conflito tratado
- KasmVNC e desktop-lite disputam `DISPLAY=:1` → `start.sh` usa `:2` para o lite. Validado por leitura: [install.sh linha 313](https://github.com/devcontainers/features/blob/main/src/desktop-lite/install.sh) contém `export DISPLAY="${DISPLAY:-:1}"`, então o `DISPLAY=:2` passado é respeitado. Execução real **não testada**.
- s6 precisa ser PID 1 → `exec /init`.
- A tag `ubuntu-xfce-kasm` não foi confirmada; usei `ubuntu-xfce` ([docker-webtop README](https://github.com/linuxserver/docker-webtop)). ghcr.io está bloqueado neste sandbox.

## Testar (comandos curtos)
```
cd ddee/.devcontainer && docker build -t ddee .
docker run -d --shm-size=1g -p 3000:3000 -p 6080:6080 -p 8006:8006 ddee
curl -sI localhost:3000 localhost:6080
```
Alternativas ao ghcs tunnel: `cloudflared tunnel --url http://localhost:3000` | `npx localtunnel -p 3000` | `ssh -R 80:localhost:3000 nokey@localhost.run` | `ngrok http 3000` | `tailscale funnel 3000`.
