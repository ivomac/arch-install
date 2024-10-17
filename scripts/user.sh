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

trap 'rm -f "$SSH_ASKPASS"' EXIT

## AUTOLOGIN

sudo tee /etc/greetd/config.toml > /dev/null << EOF
[terminal]
vt = 1

[default_session]
command = 'tuigreet --cmd niri-session'
user = 'greeter'

[initial_session]
command = 'niri-session'
user = '$USER'
EOF

## SSH SETUP

key_files=($HOME/.ssh/id_*(N))
if (( ${#key_files} > 0 )); then
  echo "Found existing SSH keys"
elif [[ -z "${SSH_REPO_API_KEY:-}" ]]; then
  echo "No SSH keys found and no SSH_REPO_API_KEY provided."
  echo "Copy SSH keys to ~/.ssh or pass token: ./install.sh user <token>"
  exit 1
else
  rm -rf "$HOME/.ssh"
  git clone "https://${SSH_REPO_API_KEY}@github.com/ivomac/ssh.git" "$HOME/.ssh"
  rm -rf "$HOME/.ssh/.git"
  unset SSH_REPO_API_KEY
  key_files=($HOME/.ssh/id_*(N))
  if (( ${#key_files} == 0 )); then
    echo "Error: clone succeeded but no SSH private keys found"
    exit 1
  fi
fi

echo "one-time ssh-key unlock:"
read -r -s SSH_PASS
export SSH_PASS

echo "#!/usr/bin/bash
echo \"$SSH_PASS\"
" >| "$SSH_ASKPASS"
chmod +x "$SSH_ASKPASS"

printf '\nSetting up ssh permissions\n'

sudo chown -R "$USER:$USER" ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*(N)
for f in ~/.ssh/authorized_keys(N) ~/.ssh/*.pub(N); do chmod 644 "$f"; done

unset SSH_PASS

## CLEANUP

echo "Deleting config folders"

rm -f "$HOME"/.bash*

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

gpg --import "$HOME/GPG/pass.key"
gpg --edit-key "Ivo Aguiar Maceira" trust quit

gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

rm -rf "$HOME/GPG"

## CLONE REPOS

git clone -q --recurse-submodules "$SSH/secret-dots.git" "$DOTDIR/secret-dots"
git clone -q --recurse-submodules "$SSH/dots.git" "$DOTDIR/dots"

## SETUP RESTOW

cat >| "$RESTOW" << 'EOF'
#!/usr/bin/env zsh

cd $DOTDIR/secret-dots
source ./restow

cd $DOTDIR/dots
source ./restow
EOF
chmod +x "$RESTOW"

"$RESTOW"

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

if "$SCRIPTS/services.sh" --user pull; then
  echo "User services enabled"
else
  echo "WARNING: --user pull failed (chroot has no DBus)"
  echo "Run './install.sh graphical' after reboot to enable user services"
fi

## FINAL STEPS

rm -f "$SSH_ASKPASS"
