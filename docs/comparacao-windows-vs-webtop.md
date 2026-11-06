# Comparação: dockur/windows vs linuxserver/webtop (Kasm e Selkies)

Repositórios lidos (clones em /home/claude, branch padrão, `--depth 1`):

- [dockur/windows](https://github.com/dockur/windows)
- [qemus/qemu](https://github.com/qemus/qemu) (imagem base `qemux/qemu`, onde ficam nginx e noVNC do Windows)
- [linuxserver/docker-webtop](https://github.com/linuxserver/docker-webtop) (branch `ubuntu-xfce-kasm` e `master`)
- [linuxserver/docker-baseimage-kasmvnc](https://github.com/linuxserver/docker-baseimage-kasmvnc) (clonei o `master`, que é Alpine 3.21; o webtop Kasm usa a tag `ubuntunoble`, que não li)
- [linuxserver/docker-baseimage-selkies](https://github.com/linuxserver/docker-baseimage-selkies)

## 1. Tabela comparativa

| Item | dockur/windows (qemus/qemu) | webtop Kasm | webtop Selkies (master) |
|---|---|---|---|
| Base | `scratch`, copia `qemux/qemu:7.50` (windows/Dockerfile linha 6); qemu em `debian:trixie-slim` | `FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntunoble` (wk/Dockerfile linha 3) | `FROM ghcr.io/linuxserver/baseimage-selkies:alpine324` |
| Porta web | `EXPOSE 3389 8006` (windows/Dockerfile linha 65) | `EXPOSE 3000` no webtop (linha 49); base: `EXPOSE 3000 3001` (linha 396) | nginx `listen 3000` e `listen 3001 ssl` (default.conf linhas 4 e 66) |
| Cliente no navegador | noVNC `VERSION_VNC="1.7.0"` do repositório oficial novnc/noVNC (qemu/Dockerfile linha 10) | fork do noVNC da Kasm, commit `KASMWEB_RELEASE` (base Dockerfile linhas 5 e 13), compilado com `node:12-buster` (linha 3) | cliente Selkies próprio |
| Quem serve o WebSocket | o próprio QEMU: `-display vnc=:port,websocket=unix:${WSS_SOCKET}` (qemu/src/display.sh linhas 61 e 968) | KasmVNC (Xvnc), em TCP 127.0.0.1:6900 e 6901 | processo do Selkies em 127.0.0.1:CWS (default.conf linha 40) |
| Ligação nginx para o WebSocket | **socket unix**: `proxy_pass http://unix:/run/shm/vnc-ws.sock:/` | **TCP**: `proxy_pass http://127.0.0.1:6901` (default.conf linha 46) | **TCP**: `proxy_pass http://127.0.0.1:CWS` |
| Quantidade de WebSockets | 3: `/websockify`, `/status`, `/audio` (nginx.conf) | 1 principal: `/websockify` | `/api` e outros |
| Cabeçalho `Host` repassado | **não** | sim: `proxy_set_header Host $host;` | sim: `proxy_set_header Host $host;` |
| `X-Forwarded-Proto/For`, `X-Real-IP` | **não** | sim | não vi na seção lida |
| `Cookie ""` | não | sim | não vi |
| Cabeçalhos CORS e COOP/COEP/CORP | **não** | sim (`Access-Control-*`, `Cross-Origin-*`) | não vi |
| `proxy_buffering off`, timeout 3600s | sim | sim | não conferi |
| URL do WebSocket no cliente | `wss://host/pasta/websockify` montada em qemu/web/js/script.js linhas 105-115 | relativo, feito pelo noVNC da Kasm | relativo |
| Página de entrada | página própria que faz XHR e um WebSocket de teste em `/websockify` antes de abrir o noVNC (script.js linhas 105-116) | abre o cliente direto | abre o cliente direto |

## 2. Diferenças que mais chamam atenção (lidas nos arquivos)

1. O Windows liga nginx e QEMU por **socket unix**, e o webtop liga por **TCP** em 127.0.0.1.
2. O nginx do Windows **não manda `Host` nem `X-Forwarded-*`**. O do webtop manda.
3. O Windows abre **três** WebSockets (`/websockify`, `/status`, `/audio`) e a página de entrada testa o WebSocket antes de redirecionar. Se o teste falha, o usuário vê o erro de conexão sem nem chegar no noVNC.
4. O noVNC do Windows é a versão 1.7.0 atual. O do webtop Kasm é um fork antigo.
5. O webtop devolve cabeçalhos CORS e `Cross-Origin-*`. O Windows não devolve nenhum.

## 3. Hipóteses (nenhuma confirmada em fonte)

- **H1:** o QEMU, sozinho atrás do nginx sem `Host`, pode recusar o handshake vindo do túnel. Teste: adicionar `proxy_set_header Host $host;` e `X-Forwarded-Proto $scheme;` no `location /websockify`.
- **H2:** o noVNC 1.7.0 pode usar recursos que o Chrome 108 da TV não tem. Teste: abrir o console do navegador na TV (ou Chrome 108 no PC) e ler o primeiro erro de JavaScript.
- **H3:** o túnel do Codespaces pode tratar mal vários WebSockets simultâneos ou o upgrade em porta pública/privada. Teste: `curl -si -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: x" https://NOME-8006.app.github.dev/websockify | head -1`, comparando com o mesmo teste na 3000 do webtop.

## 4. Comandos curtos

```bash
# clonar (-q silencioso, --depth 1 só o último commit)
git clone -q --depth 1 https://github.com/dockur/windows
git clone -q --depth 1 https://github.com/qemus/qemu
git clone -q --depth 1 -b ubuntu-xfce-kasm https://github.com/linuxserver/docker-webtop
git clone -q --depth 1 https://github.com/linuxserver/docker-baseimage-kasmvnc

# comparar os nginx lado a lado
diff -y -W 200 qemu/web/conf/nginx.conf docker-baseimage-kasmvnc/root/defaults/default.conf | less
```

## 5. Limites desta análise

- Não executei nenhum container (sem Docker no ambiente) nem testei o túnel.
- Li o `master` do baseimage-kasmvnc (Alpine 3.21), não a tag `ubuntunoble` usada pelo webtop Kasm.
- Não li o código do cliente Selkies nem a lista de requisitos de navegador do noVNC 1.7.0.
