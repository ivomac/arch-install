
## ENVIRONMENT VARIABLES

export SSH="git@github.com:ivomac"

export DOTDIR="$HOME/Projects/00.00-dotfiles"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export PASSWORD_STORE_DIR="$XDG_CONFIG_HOME/password-store"

export BIN="$HOME/.local/bin"

export RESTOW="$HOME/.local/bin/restow"

export SSH_ASKPASS="$HOME/ssh_askpass.sh"
export SSH_ASKPASS_REQUIRE="force" 

export GNUPGHOME="$XDG_CONFIG_HOME/gnupg"

## AUTOLOGIN

sudo echo """
[terminal]
vt = 1

[default_session]
command = 'tuigreet --cmd niri-session'
user = 'greeter'

[initial_session]
command = 'niri-session'
user = '$USER'
""" | sudo tee /etc/greetd/config.toml > /dev/null

## SSH SETUP

if [ -d "$HOME/.ssh" ]; then
  echo "Found .ssh directory"
else
  echo "No .ssh directory found, exiting"
  exit 1
fi

echo "one-time ssh-key unlock:" 
read -r -s SSH_PASS
export SSH_PASS

echo "#!/usr/bin/bash
echo \"$SSH_PASS\"
" >| "$SSH_ASKPASS"
chmod +x "$SSH_ASKPASS"

echo -e "\nSetting up ssh permissions"

sudo chown -R "$USER:$USER" ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/authorized_keys  ~/.ssh/*.pub

## CLEANUP

echo "Deleting config folders"

rm -f $HOME/.bash*

for dir in "$HOME/GPG" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$DOTDIR" "$BIN"; do
  sudo rm -rf "$dir"
  mkdir -p "$dir"
done

## GPG CONFIG

echo "Setting up GPG"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

git clone -q "git@github.com:ivomac/GPG.git" "$HOME/GPG"

cp "$HOME/GPG/gpg-agent.conf" "$GNUPGHOME/"
chmod 600 "$GNUPGHOME/gpg-agent.conf"

gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

## CLONE REPOS

git clone -q --recurse-submodules "$SSH/secret-dots.git" "$DOTDIR/secret-dots"
git clone -q --recurse-submodules "$SSH/dots.git" "$DOTDIR/dots"

## SETUP RESTOW

echo """
#!/usr/bin/env zsh

cd $DOTDIR/secret-dots
source ./restow

cd $DOTDIR/dots
source ./restow

""" >| "$RESTOW"
chmod +x "$RESTOW"

"$RESTOW"

git -C "$DOTDIR/secret-dots" init -q
git -C "$DOTDIR/dots" init -q

## ZSH CONFIG

mkdir -p "$XDG_CONFIG_HOME/zsh/cache"

sudo chsh -s /usr/bin/zsh "$USER"

## PASSWORD STORE

echo "Setting up password store"

git clone -q "$SSH/pass.git" "$PASSWORD_STORE_DIR"

## SET SYNCTHING CONFIG

echo "Setting up syncthing config"
mkdir -p "$HOME/.local/state/syncthing"
cat "$CONFIG/syncthing.xml" >| "$HOME/.local/state/syncthing/config.xml"

## MPD CONFIG

echo "Setting up mpd folders"
mkdir -p "$HOME/.cache/mpd"
mkdir -p "$HOME/.config/mpd/playlists"

mkdir -p "$HOME/Media"

## USER SERVICES

echo "Setting up user services"

systemctl --user enable git-maintenance@weekly.timer
systemctl --user enable bucket.timer
systemctl --user enable systemd-tmpfiles-clean.timer

systemctl --user enable foot-server.socket
systemctl --user enable pipewire.socket
systemctl --user enable pipewire-pulse.socket
systemctl --user enable mpd.socket

systemctl --user enable ulauncher-wayland.service
systemctl --user enable gammastep-indicator.service
systemctl --user enable lavalauncher.service
systemctl --user enable mpd-mpris.service
systemctl --user enable mpris-proxy.service
systemctl --user enable profile-cleaner.service
systemctl --user enable qbittorrent.service
systemctl --user enable ssh-agent.service
systemctl --user enable swaync.service
systemctl --user enable swayosd.service
systemctl --user enable swww-daemon.service
systemctl --user enable syncthing.service
systemctl --user enable waybar.service
systemctl --user enable wireplumber.service
systemctl --user enable wvkbd.service
systemctl --user enable xwayland-satellite.service

## FINAL STEPS

rm -f "$SSH_ASKPASS"

