#!/usr/bin/env zsh

setopt errexit nounset pipefail no_nomatch err_return noclobber

ROOT="${0:A:h}"

SCRIPTS="$ROOT/scripts"
CONFIG="$ROOT/config"
PKGS="$ROOT/pkgs"

case ${1} in
  nvme)
    python "$SCRIPTS/nvme.py"
    ;;
  base)
    archinstall --config "$CONFIG/archinstall.json"
    ;;
  relocate)
    userhomes=(/mnt/home/*)
    [[ -n "${userhomes[1]}" ]]
    for HOME in "${userhomes[@]}"; do
      echo "HOME=$HOME: copying to ~/arch-install"
      cp -R "$ROOT" "${HOME}/arch-install"
    done
    ;;
  root)
    userhomes=(/home/*)
    [[ -n "${userhomes[1]}" ]]
    for HOME in "${userhomes[@]}"; do
      USER="${HOME:A:t}"
      echo "HOME=$HOME: Owning home directory"
      chown -R "$USER:$USER" "/home/$USER"
      source "$SCRIPTS/pacman.sh"
      source "$SCRIPTS/root.sh"
    done
    ;;
  user)
    [[ -n "$USER" ]]
    sudo usermod -a -G video "$USER"
    source "$SCRIPTS/user.sh"
    source "$SCRIPTS/aur.sh"
    ;;
  graphical)
    [[ -n "$USER" ]]
    source "$SCRIPTS/graphical.sh"
    cat "$ROOT/TODO.md"
    ;;
  *)
    cat "$ROOT/README.md"
    ;;
esac

