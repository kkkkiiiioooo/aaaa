#!/bin/bash
# jwm.sh - troca o openbox por JWM (~0,5 MB) com barra, menu "Menu" e lista de apps automatica.
# Roda DENTRO do container, depois do kasmweb.sh (ou do setup.sh). Idempotente.
# Uso: bash /workspaces/windows/.devcontainer/jwm.sh
export DEBIAN_FRONTEND=noninteractive
K=:1

# 1) pacotes minimos (jwm + terminal xterm)
command -v jwm >/dev/null && command -v xterm >/dev/null || {
  apt-get update -qq
  apt-get install -y -qq --no-install-recommends jwm xterm
}

# 2) gerador do menu: le /usr/share/applications/*.desktop e imprime XML do JWM
cat > /usr/local/bin/jwm-apps <<'EOF'
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
chmod +x /usr/local/bin/jwm-apps

# 3) configuracao: barra embaixo, botao Menu, relogio; o viewer do Windows fica maximizado sem borda
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

# 4) troca de WM: para openbox/jwm antigos, reinicia o viewer SEM -FullScreen (para a barra aparecer)
pkill -x openbox 2>/dev/null
pkill -x jwm 2>/dev/null
pkill -f 'while :; do' 2>/dev/null     # laco antigo do viewer (setup.sh/kasmweb.sh)
pkill -f xtigervncviewer 2>/dev/null
sleep 1
DISPLAY=$K nohup jwm >/tmp/jwm.log 2>&1 &
sleep 1
nohup bash -c "while :; do
  DISPLAY=$K xtigervncviewer localhost:5900 -SecurityTypes None -Shared
  sleep 3
done" >/tmp/viewer.log 2>&1 &

sleep 2
pgrep -x jwm >/dev/null && echo "JWM rodando em $K (menu: botao Menu ou clique no fundo). Logs: /tmp/jwm.log /tmp/viewer.log" \
  || { echo "JWM falhou:"; cat /tmp/jwm.log; exit 1; }
