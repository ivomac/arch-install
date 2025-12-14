#!/usr/bin/env zsh

setopt errexit nounset pipefail no_nomatch err_return

ROOT="${0:A:h}/.."
PKGS="$ROOT/pkgs"

pacman -Qeqn | sort -h > "$PKGS/pacman.txt"
echo "Updated pacman packages list"

pacman -Qeqm | sort -h > "$PKGS/aur.txt"
echo "Updated AUR packages list"
