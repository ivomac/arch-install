
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

rm -rf "$XDG_DATA_HOME"
rm -rf "$BIN"
mkdir -p "$BIN"
mkdir -p "$DOTDIR"
rm -f "$RESTOW"
touch "$RESTOW"

## FUNCTIONS

function dotclone {
	nodot=$(echo "$1" | sed -e 's/^dot-//')
	echo "Cloning $1 as $nodot"
	git clone -q --recurse-submodules "$SSH/$1.git" "$DOTDIR/$nodot"
	cd "$DOTDIR/$nodot"
	git init -q
}

function dotstow {
	mkdir -p "$2"
	nodot=$(echo "$1" | sed -e 's/^dot-//')
	echo "Stowing $nodot to $2"
	dir="$DOTDIR${3:+/}$3"
	stow --no-folding --target="$2" --dir="$dir" "$nodot"
	echo "stow --restow --no-folding --target=\"$2\" --dir=\"$dir\" \"$nodot\"" >> "$RESTOW"
}

function dotclonestow {
	dotclone "$1"
	dotstow $@
}

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

## CLEANUP

echo "Deleting config folders"

sudo rm -rf "$XDG_DATA_HOME"
sudo rm -rf "$XDG_CONFIG_HOME"
sudo rm -rf "$DOTDIR"

rm -f "$HOME/.bash*"

mkdir -p "$DOTDIR"

## CLONE REPOS

dotclonestow dot-git "$XDG_CONFIG_HOME/git"

dotclonestow dot-zsh "$XDG_CONFIG_HOME/zsh"

dotclonestow dot-tui "$XDG_CONFIG_HOME"

dotclonestow dot-gui "$XDG_CONFIG_HOME"

dotclonestow dot-kde "$XDG_CONFIG_HOME"

dotclonestow dot-python "$XDG_CONFIG_HOME"

dotclonestow dot-nvim "$XDG_CONFIG_HOME/nvim"

dotclonestow dot-systemd "$XDG_CONFIG_HOME/systemd/user"

dotclonestow dot-msmtp "$XDG_CONFIG_HOME/msmtp"

dotclonestow bin "$BIN"
dotclonestow bin-secrets "$BIN"

dotclonestow dot-desktop "$XDG_DATA_HOME/applications"

dotclonestow dot-okular "$XDG_DATA_HOME/kxmlgui5/okular"

dotclone dot-firefox-css

## ZSH CONFIG

mkdir -p "$XDG_CONFIG_HOME/zsh/cache"
mkdir -p "$XDG_CONFIG_HOME/zsh/env"

sudo chsh -s /usr/bin/zsh "$USER"

## KDE CONFIG

echo "Setting up kde config"

chmod 444 "$DOTDIR/kde/kdedefaults/kdeglobals"
chmod 444 "$DOTDIR/kde/kdedefaults/ksplashrc"
chmod 444 "$DOTDIR/kde/kglobalshortcutsrc"

## PLASMA CONFIG

echo "Setting up plasma config"

dotclone "dot-plasma"
dotstow "$ROOTED_HOST" "$XDG_CONFIG_HOME" "plasma"

chmod 444 "$DOTDIR/plasma/$ROOTED_HOST/*"

## PLASMA CONFIG

echo "Setting up plasma system monitor page"

dotclone "dot-plasma-monitor"
dotstow "$ROOTED_HOST" "$XDG_DATA_HOME/plasma-systemmonitor" "plasma-monitor"

## ENV CONFIG

echo "Setting up env config"

dotclone "dot-env" "env"
dotclone "dot-env-secrets" "env-secrets"

# public env
dotstow env "$XDG_CONFIG_HOME/zsh/env"
dotstow env "$XDG_CONFIG_HOME/plasma-workspace/env"

# general secret env
dotstow ALL "$XDG_CONFIG_HOME/zsh/env" "env-secrets"
dotstow ALL "$XDG_CONFIG_HOME/plasma-workspace/env" "env-secrets"

# host-specific secret env
dotstow "$ROOTED_HOST" "$XDG_CONFIG_HOME/zsh/env" "env-secrets"
dotstow "$ROOTED_HOST" "$XDG_CONFIG_HOME/plasma-workspace/env" "env-secrets"

## PASSWORD STORE

echo "Setting up password store"

git clone -q "$SSH/pass.git" "$PASSWORD_STORE_DIR"

## INIT THEME FILES

echo "Setting up base dark theme"
$BIN/theme-switch gruvbox_dark

## SET SYNCTHING CONFIG

echo "Setting up syncthing config"
mkdir -p "$HOME/.local/state/syncthing"
cat "$CONFIG_DIR/syncthing.xml" > "$HOME/.local/state/syncthing/config.xml"

## FINAL STEPS

chmod +x "$RESTOW"
rm -f "$SSH_ASKPASS"

## USER SERVICES

echo "Setting up user services"

systemctl --user enable foot-server.service
systemctl --user enable git-maintenance@weekly.timer
systemctl --user enable profile-cleaner.service
systemctl --user enable ssh-agent.service
systemctl --user enable syncthing.service

