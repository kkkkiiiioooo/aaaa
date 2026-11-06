# Teste: webtop Kasm no túnel do Codespaces

Imagem: [linuxserver/webtop, tag ubuntu-xfce-kasm](https://github.com/linuxserver/docker-webtop/tree/ubuntu-xfce-kasm)
Base: [docker-baseimage-kasmvnc](https://github.com/linuxserver/docker-baseimage-kasmvnc) (Dockerfile linha 3: `FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntunoble`)

Fonte das portas: README da branch, linhas 229-230 e 264-265: `-p 3000:3000` (Web Desktop GUI) e `-p 3001:3001` (HTTPS).
Fonte do shm: README linha 274: "Minimum of 1gb required for modern web browsers to operate".

## 1. Subir (rode no terminal do Codespace)

```bash
docker run -d --name wk -p 3000:3000 --shm-size=1g lscr.io/linuxserver/webtop:ubuntu-xfce-kasm
```

Formas curtas: `-d` segundo plano, `-p` porta. Para trocar o nome use `--name`.

## 2. Abrir a porta 3000 no túnel

```bash
gh cs ports visibility 3000:public -c NOME
```

Use a 3000 (http), não a 3001. Hipótese minha, não confirmada em fonte: o túnel do Codespaces já faz o HTTPS, e a 3001 tem certificado autoassinado, o que pode quebrar o túnel.

Alternativa sem comando: aba PORTS do Codespace, clique direito na 3000, Port Visibility, Public.

## 3. Abrir na TV

URL: aba PORTS, copie o endereço `https://NOME-3000.app.github.dev`.

## 4. Ver se o WebSocket conecta

No Codespace:

```bash
curl -si -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: x" localhost:3000/websockify | head -1
```

Esperado: `101` ou `400`. Se for `502`, o erro está dentro do container.
Logs: `docker logs wk`

## 5. Resultado (preencher)

- Carregou a página na TV: ?
- Conectou o desktop: ?
- Mensagem de erro: ?

## Se falhar, na ordem

1. Selkies: `docker run -d -p 3000:3000 -p 3001:3001 --shm-size=1g lscr.io/linuxserver/webtop`
2. Windows: `docker run -it --rm -p 8006:8006 --device=/dev/kvm --cap-add NET_ADMIN -e VERSION=11 dockurr/windows`
3. Cloudflare Tunnel: `cloudflared tunnel --url http://localhost:3000`
4. ngrok: `ngrok http 3000`
5. Tailscale Funnel: `tailscale funnel 3000`

Limpar: `docker rm -f wk`
