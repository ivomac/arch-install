echo "Installing font"
git clone git@github.com:ivomac/Firosevka.git "$HOME/Firosevka"
makepkg -si -D "$HOME/Firosevka"
rm -rf "$HOME/Firosevka"

echo "Setting up rust"
rustup default nightly

zsh "$HOME/.local/bin/aur-helper-install -f paru"

echo "Installing AUR packages"
paru -S --noconfirm --needed --asexplicit - < "$PKGS/aur.txt"

echo "Installing Yazi plugins"
ya pkg upgrade

