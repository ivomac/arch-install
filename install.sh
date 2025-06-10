
SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
ROOT_DIR="$(dirname "$SCRIPT")"

export SCRIPT
export ROOT_DIR

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
    [[ -d "/mnt/home/$2" ]] || {
      echo "Input should be a user. \$2:$2"
      exit 1
    }

		mv "$ROOT_DIR" "/mnt/home/$2/arch-install"
		;;
	root)
    [[ -d "/home/$2" ]] || {
      echo "Input should be a user. \$2:$2"
      exit 1
    }

		echo "Owning home directory"
		chown -R "$2:$2" "/home/$2"
		echo "Uninstalling packages"
		pacman -Rs --noconfirm - < "$TXT_DIR/uninstall.txt"
		bash "$SCRIPTS_DIR/root-pacman.sh"
		echo "Installing packages"
		pacman -Syu --noconfirm --needed - < "$TXT_DIR/pacman.txt"
		bash "$SCRIPTS_DIR/root.sh" "$2"
		;;
	user)
    [[ -d "/home/$2" ]] || {
      echo "Input should be a user. \$2:$2"
      exit 1
    }

		bash "$SCRIPTS_DIR/user.sh" "$2"
		echo "Installing paru"
		"$HOME/.local/bin/paru-install"
		echo "Installing AUR packages"
		paru -S --noconfirm --needed - < "$TXT_DIR/aur.txt" 
		echo "Installing Yazi plugins"
		ya pack -u
		echo "Installing font"
		git clone git@github.com:ivomac/Firosevka.git && makepkg -si -D ./Firosevka && rm -rf Firosevka
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

