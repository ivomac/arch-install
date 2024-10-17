
export SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
export ROOT_DIR="$(dirname "$SCRIPT")"
export SCRIPTS_DIR="$ROOT_DIR/scripts"
export CONFIG_DIR="$ROOT_DIR/config"
export TXT_DIR="$ROOT_DIR/txt"

case $1 in
	noipv6)
		sysctl -w net.ipv6.conf.all.disable_ipv6=1
		sysctl -w net.ipv6.conf.default.disable_ipv6=1
		sysctl -w net.ipv6.conf.lo.disable_ipv6=1
		;;
	nvme)
		python "$SCRIPTS_DIR/nvme.py"
		;;
	base)
		archinstall --config "$CONFIG_DIR/archinstall.json"
		;;
	relocate)
		mv "$ROOT_DIR" "/mnt/archinstall/home/$2/arch-install"
		chown -R "$2:$2" "/mnt/archinstall/home/$2/arch-install"
		;;
	uninstall)
		echo "Uninstalling packages"
		cat "$TXT_DIR/uninstall.txt" | pacman -Rs --noconfirm -
		;;
	pkgs)
		echo "Installing packages"
		cat "$TXT_DIR/pacman.txt" | pacman -Syu --noconfirm --needed -
		;;
	post-root)
		bash "$SCRIPTS_DIR/post-root.sh"
		;;
	post-noipv6)
		bash "$SCRIPTS_DIR/post-noipv6.sh"
		;;
	post-user)
		bash "$SCRIPTS_DIR/post-user.sh"
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
		bash "$SCRIPTS_DIR/post-reboot.sh"
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

