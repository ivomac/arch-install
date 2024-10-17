echo "Setting up rust"
rustup default nightly

zsh "$HOME/.local/bin/aur-helper-install" -f yay

echo "Installing AUR packages"
yay -S --noconfirm --needed --asexplicit - < "$PKGS/aur.txt"

echo "Installing Yazi plugins"
ya pkg upgrade
