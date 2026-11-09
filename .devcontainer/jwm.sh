#!/bin/bash
# jwm.sh - troca o openbox por JWM com barra, menu e lista de apps automatica. Portatil e idempotente.
# Roda depois do kasmweb.sh (le o display em /tmp/kasm.env). Funciona como root ou com sudo.
export DEBIAN_FRONTEND=noninteractive
R=; [ "$(id -u)" = 0 ] || { command -v sudo >/dev/null && R=sudo || { echo "precisa de root ou sudo"; exit 1; }; }
[ -f /tmp/kasm.env ] && . /tmp/kasm.env
K=${K:-:1}
[ -e /tmp/.X11-unix/X${K#:} ] || { echo "display $K nao existe: rode kasmweb.sh antes"; exit 1; }

# 1) pacotes minimos
command -v jwm >/dev/null && command -v xterm >/dev/null || {
  $R apt-get update -qq
  $R apt-get install -y -qq --no-install-recommends jwm xterm || { echo "falha apt jwm"; exit 1; }
}

# 2) gerador do menu a partir dos .desktop
$R tee /usr/local/bin/jwm-apps >/dev/null <<'EOF'
#!/bin/sh
echo '<JWM>'
for f in /usr/share/applications/*.desktop; do
  [ -f "$f" ] && awk '
    /^\[/ { s = ($0 == "[Desktop Entry]") }
    s && /^Name=/ && !n { n = substr($0, 6) }
    s && /^Exec=/ && !e { e = substr($0, 6); gsub(/ ?%[a-zA-Z]/, "", e) }
    s && /^(NoDisplay|Hidden)=true/ { h = 1 }
    END { if (n != "" && e != "" && !h) print n "|" e }' "$f"
done | sort -f -t'|' -k1,1 | awk -F'|' '{
  n = $1; e = $2
  gsub(/&/, "\\&amp;", n); gsub(/</, "\\&lt;", n); gsub(/>/, "\\&gt;", n)
  gsub(/&/, "\\&amp;", e); gsub(/</, "\\&lt;", e); gsub(/>/, "\\&gt;", e)
  print "<Program label=\"" n "\">" e "</Program>"
}'
echo '</JWM>'
EOF
$R chmod +x /usr/local/bin/jwm-apps

# 3) configuracao
cat > ~/.jwmrc <<'EOF'
<?xml version="1.0"?>
<JWM>
  <RootMenu onroot="12">
    <Include>exec:/usr/local/bin/jwm-apps</Include>
    <Separator/>
    <Program label="Terminal">xterm</Program>
    <Restart label="Reiniciar JWM"/>
  </RootMenu>
  <Group><Class>.*[Vv][Nn][Cc].*</Class><Option>maximized</Option><Option>noborder</Option><Option>notitle</Option></Group>
  <Group><Name>.*[Vv][Nn][Cc].*</Name><Option>maximized</Option><Option>noborder</Option><Option>notitle</Option></Group>
  <Tray x="0" y="-1" height="26" autohide="off">
    <TrayButton label="Menu">root:1</TrayButton>
    <Spacer width="2"/>
    <TaskList maxwidth="220"/>
    <Dock/>
    <Clock format="%H:%M"/>
  </Tray>
  <TrayStyle><Background>#333333</Background><Foreground>#FFFFFF</Foreground></TrayStyle>
  <MenuStyle><Background>#333333</Background><Foreground>#FFFFFF</Foreground>
    <Active><Background>#0077CC</Background><Foreground>#FFFFFF</Foreground></Active></MenuStyle>
  <TaskListStyle><Background>#333333</Background><Foreground>#FFFFFF</Foreground>
    <Active><Background>#0077CC</Background><Foreground>#FFFFFF</Foreground></Active></TaskListStyle>
</JWM>
EOF

# 4) troca de WM e viewer SEM -FullScreen (a barra aparece); mata so o que e nosso
pkill -x openbox 2>/dev/null
pkill -x jwm 2>/dev/null
pkill -f viewer-loop.sh 2>/dev/null
pkill -x xtigervncviewer 2>/dev/null
sleep 1
DISPLAY=$K nohup setsid jwm >/tmp/jwm.log 2>&1 &
sleep 1
cat > /tmp/viewer-loop.sh <<EOF
#!/bin/bash
while :; do
  DISPLAY=$K xtigervncviewer ${VNC:-localhost:5900} -SecurityTypes None -Shared
  sleep 3
done
EOF
chmod +x /tmp/viewer-loop.sh
nohup setsid /tmp/viewer-loop.sh >/tmp/viewer.log 2>&1 &

sleep 2
pgrep -x jwm >/dev/null && echo "JWM rodando em $K (menu: botao Menu ou clique no fundo). Logs: /tmp/jwm.log /tmp/viewer.log" \
  || { echo "JWM falhou:"; cat /tmp/jwm.log; exit 1; }
