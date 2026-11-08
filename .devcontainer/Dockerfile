FROM ghcr.io/linuxserver/webtop:ubuntu-xfce

USER root
ENV DEBIAN_FRONTEND=noninteractive \
    _REMOTE_USER=abc \
    _REMOTE_USER_HOME=/config \
    VERSION=latest NOVNCVERSION=1.6.0 PASSWORD=noPassword \
    WEBPORT=6080 VNCPORT=5901 \
    VNC_DISPLAY=:1

# desktop-lite (Xtigervnc + noVNC) tirado do repo oficial de features
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates sudo \
 && curl -fsSL https://raw.githubusercontent.com/devcontainers/features/main/src/desktop-lite/install.sh | bash \
 && rm -rf /var/lib/apt/lists/*

COPY start.sh /usr/local/bin/ddee-start.sh
RUN chmod +x /usr/local/bin/ddee-start.sh

# KasmVNC: 3000 http / 3001 https | noVNC: 6080 | TigerVNC: 5901 | Windows (dockur): 8006
EXPOSE 3000 3001 6080 5901 8006
ENTRYPOINT ["/usr/local/bin/ddee-start.sh"]
