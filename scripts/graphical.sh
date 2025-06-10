
## FIREFOX SETUP

echo "Removing unnused firefox profile..."
rm -rf ~/.mozilla/firefox/*.default
rm -rf ~/.mozilla/firefox/*.default-backup

## THEME

echo "Setting up base theme"
"$HOME/.local/bin/theme-switch" gruvbox_light_soft

## JUPYTER SETUP

echo "Setting up jupyter server"

python -m jupyter_server.auth password "$(pass show localhost:8888/jupyter)"
systemctl --user enable jupyter-server.service

## PASSFF SETUP

echo "Installing PassFF host app"

curl -sSL https://codeberg.org/PassFF/passff-host/releases/download/latest/install_host_app.sh \
  | bash -s -- firefox

## BLUETOOTH SETUP

echo "Pair bluetooth devices (scan on -> devices -> trust XX:... -> connect XX:XX...)"
sleep 2s
bluetoothctl

## QBITTORRENT SETUP

echo "Setting up qBitTorrent config"
read -r -p "Enter the root directory for torrents (/Torrents/ will be appended): " TORRENTROOT
mkdir -p "$XDG_CONFIG_HOME/qBittorrent"
sed -e "s:TORRENTROOT:$TORRENTROOT:g" -e "s:HOME:$HOME:g" \
  < "$CONFIG/qBittorrent.conf" \
  >| "$XDG_CONFIG_HOME/qBittorrent/qBittorrent.conf"

## FSTAB SETUP

echo "Add drives to fstab if needed"
sleep 2s
lsblk -f | nvim -c "split" -c "bn" -o - -- /etc/fstab
sudo systemctl daemon-reload
sudo mount -m -a

## FIREFOX LOGIN SETUP

echo "Login to firefox, google, github, gist, tailscale..."
sleep 2s

firefox --new-tab "accounts.firefox.com/?context=fx_desktop_v3&entrypoint=fxa_app_menu&action=email&service=sync" &> /dev/null & disown
firefox --new-tab "accounts.google.com/v3/signin/identifier?flowName=GlifWebSignIn" &> /dev/null & disown
firefox --new-tab "github.com/login" &> /dev/null & disown
firefox --new-tab localhost:8384 &> /dev/null & disown
firefox --new-tab localhost:8888 &> /dev/null & disown
firefox --new-tab "github.com/login/device" &> /dev/null & disown

gist --login

echo "Login to tailscale"
sudo tailscale up

echo "Detect sensors"
sensors-detect

## POWER PROFILE

echo "Set up power profiles?"

powerprofilesctl list-actions
