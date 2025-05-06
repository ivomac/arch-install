
## ENVIRONMENT VARIABLES

SSH="git@github.com:ivomac"

DOTDIR="$HOME/Projects/00.00-dotfiles"
XDG_DATA_HOME="$HOME/.local/share"
XDG_CONFIG_HOME="$HOME/.config"
GNUPGHOME="$XDG_CONFIG_HOME/gnupg"
PASSWORD_STORE_DIR="$XDG_CONFIG_HOME/password-store"

BIN="$HOME/.local/bin"

RESTOW="$HOME/.local/bin/restow"

ROOTED_HOST=$(cat /etc/hostname)

export SSH_ASKPASS="$HOME/ssh_askpass.sh"
export SSH_ASKPASS_REQUIRE="force" 

## CLEANUP

echo "Deleting config folders"

rm -f "$HOME/.bash*"

for dir in "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$DOTDIR" "$BIN"; do
	sudo rm -rf "$dir"
	mkdir -p "$XDG_DATA_HOME"
done

## SSH SETUP

if [ -d "$HOME/.ssh" ]; then
	echo "Found .ssh directory"
else
	echo "No .ssh directory found, exiting"
	exit 1
fi

read -s -p "one-time ssh-key unlock: " SSH_PASS
export SSH_PASS

echo "#!/usr/bin/bash
echo \"$SSH_PASS\"
" > "$SSH_ASKPASS"
chmod +x "$SSH_ASKPASS"

echo -e "\nSetting up ssh permissions"

sudo chown -R $USER:$USER ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/authorized_keys  ~/.ssh/*.pub

## GPG CONFIG

echo "Setting up GPG"

mkdir -p "$GNUPGHOME"

chmod 700 "$GNUPGHOME"

git clone -q "git@github.com:ivomac/GPG.git" "$HOME/GPG"

cp "$HOME/GPG/gpg-agent.conf" "$GNUPGHOME/"

gpg --import "$HOME/GPG/pass.key"
gpg --edit-key "Ivo Aguiar Maceira" trust quit
rm -rf "$HOME/GPG"

## CLONE REPOS

function dotclone {
	git clone -q --recurse-submodules "$SSH/$1.git" "$DOTDIR/$1"
	cd "$DOTDIR/$1"
	source ./restow
	git init -q
}

dotclone "secret-dots"
dotclone "dots"

## ZSH CONFIG

mkdir -p "$XDG_CONFIG_HOME/zsh/cache"

sudo chsh -s /usr/bin/zsh "$USER"

## PASSWORD STORE

echo "Setting up password store"

git clone -q "$SSH/pass.git" "$PASSWORD_STORE_DIR"

## THEME SETUP

echo "Setting up base dark theme"
$BIN/theme-switch gruvbox_dark

## SET SYNCTHING CONFIG

echo "Setting up syncthing config"
mkdir -p "$HOME/.local/state/syncthing"
cat "$CONFIG_DIR/syncthing.xml" > "$HOME/.local/state/syncthing/config.xml"

## SETUP RESTOW

echo """
#!/usr/bin/env zsh

cd $DOTDIR/dots
source ./restow

cd $DOTDIR/secret-dots
source ./restow

""" > "$RESTOW"
chmod +x "$RESTOW"

## USER SERVICES

echo "Setting up user services"

systemctl --user enable blueman-applet.service
systemctl --user enable blueman.service
systemctl --user enable foot-server.service
systemctl --user enable gammastep-indicator.service
systemctl --user enable git-maintenance@weekly.timer
systemctl --user enable lavalauncher.service
systemctl --user enable mpd-mpris.service
systemctl --user enable mpd.service
systemctl --user enable mpris-proxy.service
systemctl --user enable pipewire-pulse.service
systemctl --user enable pipewire-pulse.socket
systemctl --user enable pipewire.service
systemctl --user enable pipewire.socket
systemctl --user enable profile-cleaner.service
systemctl --user enable qbittorrent.service
systemctl --user enable ssh-agent.service
systemctl --user enable swaync.service
systemctl --user enable swww-daemon.service
systemctl --user enable syncthing.service
systemctl --user enable waybar.service
systemctl --user enable wireplumber.service
systemctl --user enable wvkbd.service
systemctl --user enable xwayland-satellite.service

## FINAL STEPS

rm -f "$SSH_ASKPASS"

