
echo "Setting up pacman"
sed -i \
  -e 's/#Color/Color/' \
  -e 's/.*ParallelDownloads.*/ParallelDownloads = 10/' \
  -e '/^#\[multilib\]/,/^#Include/ s/^#//' \
  /etc/pacman.conf
echo "Installing packages"
pacman -Syu --noconfirm --needed - < "$PKGS/pacman.txt"
