
export SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
export ROOT_DIR="$(dirname "$SCRIPT")"
export SCRIPTS_DIR="$ROOT_DIR/scripts"
export CONFIG_DIR="$ROOT_DIR/config"
export TXT_DIR="$ROOT_DIR/txt"

case $1 in
	nvme)
		python "$SCRIPTS_DIR/nvme.py"
		;;
	base)
		archinstall --config "$CONFIG_DIR/archinstall.json"
		;;
	relocate)
		mv "$ROOT_DIR" "/mnt/home/$2/arch-install"
		;;
	root)
		echo "Owning home directory"
		chown -R "$2:$2" "/home/$2"
		echo "Uninstalling packages"
		cat "$TXT_DIR/uninstall.txt" | pacman -Rs --noconfirm -
		bash "$SCRIPTS_DIR/root-pacman.sh"
		echo "Installing packages"
		cat "$TXT_DIR/pacman.txt" | pacman -Syu --noconfirm --needed -
		bash "$SCRIPTS_DIR/root.sh"
		echo "Installing font"
		git clone git@github.com:ivomac/Firosevka.git && makepkg -si -D ./Firosevka && rm -rf Firosevka
		;;
	user)
		bash "$SCRIPTS_DIR/user.sh"
		echo "Installing paru"
		$HOME/.local/bin/paru-install
		echo "Installing AUR packages"
		cat "$TXT_DIR/aur.txt" | paru -S --noconfirm --needed -
		;;
	graphical)
		bash "$SCRIPTS_DIR/reboot.sh"
		;;
	manual)
		bash "$SCRIPTS_DIR/manual.sh"
		;;
	todo)
		cat "$ROOT_DIR/TODO.md"
		;;
	*)
		cat "$ROOT_DIR/README.md"
		;;
esac

