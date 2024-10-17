
echo "Disabling indexing"
balooctl6 suspend
balooctl6 disable
balooctl6 purge

echo "Adding gpg key"
bash "$SCRIPTS_DIR/gpg.sh"

echo "Setting bar clock"
bash "$SCRIPTS_DIR/set-clock.sh"

echo "Setting up jupyter server"
bash "$SCRIPTS_DIR/jupyter.sh"

echo "Installing PassFF host app"
curl -sSL https://codeberg.org/PassFF/passff-host/releases/download/latest/install_host_app.sh | bash -s -- firefox

echo "Setting up base dark theme"
$HOME/.local/bin/theme-switch gruvbox_dark
