
RESTOW="$HOME/.local/bin/restow"

## BLUETOOTH SETUP

echo "Pair bluetooth devices (scan on -> devices -> trust XX:... -> connect XX:XX...)"
sleep 2s
bluetoothctl

## QBITTORRENT SETUP

echo "Setting up qBitTorrent config"
read -p "Enter the root directory for torrents: " TORRENTROOT
mkdir -p "$XDG_CONFIG_HOME/qBittorrent"
cat "$CONFIG_DIR/qBittorrent.conf" | sed -e "s:TORRENTROOT:$TORRENTROOT:g" -e "s:HOME:$HOME:g" > "$XDG_CONFIG_HOME/qBittorrent/qBittorrent.conf"

## FSTAB SETUP

echo "Add drives to fstab if needed"
sleep 2s
lsblk -f | nvim -c "split" -c "bn" -o - -- /etc/fstab
sudo systemctl daemon-reload
sudo mount -m -a

## FIREFOX LOGIN SETUP

echo "Login to firefox, google, github, tailscale..."
sleep 2s

firefox --new-tab "accounts.firefox.com/?context=fx_desktop_v3&entrypoint=fxa_app_menu&action=email&service=sync" &> /dev/null & disown
firefox --new-tab "accounts.google.com/v3/signin/identifier?flowName=GlifWebSignIn" &> /dev/null & disown
firefox --new-tab "github.com/login" &> /dev/null & disown

read -p "Press any key to continue..."

echo "Login to copilot"
sleep 2s
firefox --new-tab "github.com/login/device" &> /dev/null & disown
nvim -c 'Copilot auth'

echo "Login to gist"
firefox --new-tab "github.com/login/device" &> /dev/null & disown
gist --login

echo "Login to tailscale"
sudo tailscale up

# make sure firefox is closed
while pgrep -x firefox > /dev/null; do
	echo "Close firefox to continue..."
	sleep 1s
done

## FIREFOX SETUP

echo "Removing unnused firefox profile..."
rm -rf ~/.mozilla/firefox/*.default
rm -rf ~/.mozilla/firefox/*.default-backup

dir=$(ls -d ~/.mozilla/firefox/*.default-release)

echo "Changing about:config options..."

echo '
user_pref("browser.urlbar.update2.engineAliasRefresh", true);
user_pref("svg.context-properties.content.enabled", true);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
' > "$dir/user.js"

echo "Stowing CSS in firefox profile..."
mkdir -p "$dir/chrome"
stow --no-folding --target="$dir/chrome" --dir="$HOME/Projects/00-dotfiles" "firefox-css"
echo "stow --restow --no-folding --target=\"$dir/chrome\" --dir=\"$HOME/Projects/00-dotfiles\" \"firefox-css\"" >> "$RESTOW"

firefox --new-tab localhost:8384 &> /dev/null & disown

