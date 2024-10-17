
## ENVIRONMENT VARIABLES

REPO="git@github.com:ivomac"
URL="https://ivomac.github.io/arch"

DOTDIR="$HOME/Projects/00-dotfiles"
XDG_DATA_HOME="$HOME/.local/share"
XDG_CONFIG_HOME="$HOME/.config"
GNUPGHOME="$XDG_CONFIG_HOME/gnupg"
PASSWORD_STORE_DIR="$XDG_CONFIG_HOME/password-store"

BIN="$HOME/.local/bin"

RESTOW="$HOME/.local/bin/restow"

ROOTED_HOST=$(cat /etc/hostname)

export SSH_ASKPASS="$HOME/ssh_askpass.sh"
export SSH_ASKPASS_REQUIRE="force" 

mkdir -p "$BIN"
rm -f "$RESTOW"
touch "$RESTOW"

## FUNCTIONS

function dotstow {
	mkdir -p "$2"
	stow --no-folding --target="$2" --dir="${3:-$DOTDIR}" "$1"
	echo "Stowed $1 to $2"
	echo "stow --restow --no-folding --target=\"$2\" --dir=\"${3:-$DOTDIR}\" \"$1\"" >> "$RESTOW"
}

function dotclone {
	echo "Cloning $1 repo"
	target=$(echo "$1" | sed 's/^dot-//')
	git clone -q --recurse-submodules "$REPO/$1.git" "$DOTDIR/$target"
	if [[ -n "$2" ]]; then
		dotstow "$target" "$2"
	fi
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

dotclone dot-git "$XDG_CONFIG_HOME/git"

dotclone dot-zsh "$XDG_CONFIG_HOME/zsh"

dotclone dot-tui "$XDG_CONFIG_HOME"

dotclone dot-gui "$XDG_CONFIG_HOME"

dotclone dot-kde "$XDG_CONFIG_HOME"

dotclone dot-python "$XDG_CONFIG_HOME"

dotclone dot-nvim "$XDG_CONFIG_HOME/nvim"

dotclone dot-systemd "$XDG_CONFIG_HOME/systemd/user"

dotclone dot-msmtp "$XDG_CONFIG_HOME/msmtp"

dotclone bin "$BIN"
dotclone bin-secrets "$BIN"

dotclone dot-desktop "$XDG_DATA_HOME/applications"

dotclone dot-okular "$XDG_DATA_HOME/kxmlgui5/okular"

dotclone dot-firefox-css

## GIT CONFIG

cd "$DOTDIR/git"
git init

## ZSH CONFIG

mkdir -p "$XDG_CONFIG_HOME/zsh/cache"
mkdir -p "$XDG_CONFIG_HOME/zsh/env"

sudo chsh -s /usr/bin/zsh "$USER"

## ENV CONFIG

echo "Setting up env config"

git clone -q "$REPO/dot-env.git" "$DOTDIR/env"
git clone -q "$REPO/dot-env-secrets.git" "$DOTDIR/env-secrets"

# public env
dotstow env "$XDG_CONFIG_HOME/zsh/env"
dotstow env "$XDG_CONFIG_HOME/plasma-workspace/env"

# general secret env
dotstow ALL "$XDG_CONFIG_HOME/zsh/env" "$DOTDIR/env-secrets"
dotstow ALL "$XDG_CONFIG_HOME/plasma-workspace/env" "$DOTDIR/env-secrets"

# host-specific secret env
dotstow $ROOTED_HOST "$XDG_CONFIG_HOME/zsh/env" "$DOTDIR/env-secrets"
dotstow $ROOTED_HOST "$XDG_CONFIG_HOME/plasma-workspace/env" "$DOTDIR/env-secrets"

## PASSWORD STORE

echo "Setting up password store"

git clone -q "$REPO/pass.git" "$PASSWORD_STORE_DIR"

## INIT THEME FILES

echo "Setting up base dark theme"
$BIN/theme-switch gruvbox_dark

## SET SYNCTHING CONFIG

echo "Setting up syncthing config"
mkdir -p "$HOME/.local/state/syncthing"
cat "$CONFIG_DIR/syncthing.xml" > "$HOME/.local/state/syncthing/config.xml"

## SETUP MPV

echo "Setting up mpv config (uosc)"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tomasklaen/uosc/HEAD/installers/unix.sh)"
curl "https://raw.githubusercontent.com/po5/thumbfast/refs/heads/master/thumbfast.lua" > "$XDG_CONFIG_HOME/mpv/scripts/thumbfast.lua"

## FINAL STEPS

chmod +x "$RESTOW"
rm -f "$SSH_ASKPASS"

## USER SERVICES

echo "Setting up user services"

systemctl --user enable foot-server.service
systemctl --user enable git-maintenance@weekly.timer
systemctl --user enable psd.service
systemctl --user enable ssh-agent.service
systemctl --user enable syncthing.service

