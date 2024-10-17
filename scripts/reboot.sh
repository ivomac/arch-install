## DISABLE INDEXING

echo "Disabling indexing"
balooctl6 suspend
balooctl6 disable
balooctl6 purge

## GPG SETUP

echo "Setting up GPG key"

mkdir -p "$GNUPGHOME"

chmod 700 "$GNUPGHOME"

git clone "git@github.com:ivomac/GPG.git" "$HOME/GPG"

cp "$HOME/GPG/gpg-agent.conf" "$GNUPGHOME/"

gpg --import "$HOME/GPG/pass.key"
gpg --edit-key "Ivo Aguiar Maceira" trust quit
rm -rf "$HOME/GPG"

## JUPYTER SETUP

echo "Setting up jupyter server"

python -m jupyter_server.auth password $(pass show localhost:8888/jupyter)
systemctl --user enable jupyter_server.service

## PASSFF SETUP

echo "Installing PassFF host app"

curl -sSL https://codeberg.org/PassFF/passff-host/releases/download/latest/install_host_app.sh | bash -s -- firefox

echo "Setting up base dark theme"
$HOME/.local/bin/theme-switch gruvbox_dark
