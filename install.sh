
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
		mv "$ROOT_DIR" "/mnt/archinstall/home/$2/arch-install"
		;;
	own)
		chown -R "$2:$2" "/home/$2/arch-install"
		;;
	uninstall)
		echo "Uninstalling packages"
		cat "$TXT_DIR/uninstall.txt" | pacman -Rs --noconfirm -
		;;
	pkgs)
		echo "Installing packages"
		cat "$TXT_DIR/pacman.txt" | pacman -Syu --noconfirm --needed -
		;;
	root)
		bash "$SCRIPTS_DIR/root.sh"
		;;
	user)
		bash "$SCRIPTS_DIR/user.sh"
		;;
	yay)
		echo "Installing yay"
		$HOME/.local/bin/yay-install
		;;
	aur)
		echo "Installing AUR packages"
		cat "$TXT_DIR/aur.txt" | yay -S --noconfirm --needed -
		;;
	post-reboot)
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

