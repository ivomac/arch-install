#!/usr/bin/env zsh

setopt errexit nounset pipefail no_nomatch err_return

PKGS="${0:A:h:h}/pkgs"

PACMAN_LIST="$PKGS/pacman.txt"
AUR_LIST="$PKGS/aur.txt"

if [[ "$1" == "push" ]]; then

  pacman -Qeqn | sort > "$PACMAN_LIST"
  echo "Updated pacman packages list"

  pacman -Qeqm | sort > "$AUR_LIST"
  echo "Updated AUR packages list"

elif [[ "$1" == "pull" ]]; then

  sudo pacman -S --noconfirm --needed --asexplicit - < "$PACMAN_LIST"

  yay -S --noconfirm --needed --asexplicit --aur - < "$AUR_LIST"

  pac_to_remove=$(pacman -Qeqn | grep -vFxf "$PACMAN_LIST" || true)
  aur_to_remove=$(yay -Qeqm | grep -vFxf "$AUR_LIST" || true)

  if [[ -n "$pac_to_remove" ]]; then
    sudo pacman -Rs ${=pac_to_remove}
  fi

  if [[ -n "$aur_to_remove" ]]; then
    yay -Rs ${=aur_to_remove}
  fi

else
  echo "Usage: $0 {push|pull}"
  exit 1
fi
