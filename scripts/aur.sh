echo "Installing font"
git clone git@github.com:ivomac/Firosevka.git "$HOME/Firosevka"
makepkg -si -D "$HOME/Firosevka"
rm -rf "$HOME/Firosevka"

echo "Setting up rust"
rustup default nightly

echo "Installing paru"
zsh "$HOME/.local/bin/paru-install"

echo "Installing AUR packages"
paru -S --noconfirm --needed - < "$PKGS/aur.txt"

echo "Installing Yazi plugins"
ya pkg upgrade

