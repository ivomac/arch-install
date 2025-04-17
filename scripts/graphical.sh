## JUPYTER SETUP

echo "Setting up jupyter server"

python -m jupyter_server.auth password $(pass show localhost:8888/jupyter)
systemctl --user enable jupyter_server.service

## PASSFF SETUP

echo "Installing PassFF host app"

curl -sSL https://codeberg.org/PassFF/passff-host/releases/download/latest/install_host_app.sh | bash -s -- firefox

echo "Setting up base dark theme"
$HOME/.local/bin/theme-switch gruvbox_dark
