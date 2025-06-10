
echo "Installing paru"
zsh "$HOME/.local/bin/paru-install"
echo "Installing AUR packages"
paru -S --noconfirm --needed - < "$PKGS/aur.txt" 
echo "Installing Yazi plugins"
ya pkg upgrade
echo "Installing font"
git clone git@github.com:ivomac/Firosevka.git && makepkg -si -D ./Firosevka && rm -rf Firosevka

