#!/usr/bin/env zsh

setopt errexit nounset pipefail no_nomatch err_return noclobber

ROOT="${0:A:h}"

SCRIPTS="$ROOT/scripts"
CONFIG="$ROOT/config"
PKGS="$ROOT/pkgs"

if [[ ! -v 1 ]]; then
  cat "$ROOT/README.md"
  exit 1
fi

case ${1} in
  nvme)
    python "$SCRIPTS/nvme.py"
    ;;
  base)
    [[ -n "${2:-}" ]] || {
      echo "Usage: ./install.sh base <username>"
      exit 1
    }
    export BASE_USER="$2"
    source "$SCRIPTS/base.sh"
    ;;
  root)
    [[ -n "${2:-}" ]] || {
      echo "Usage: ./install.sh root <hostname>"
      exit 1
    }
    export HOSTNAME="$2"
    source "$SCRIPTS/root.sh"
    ;;
  user)
    [[ -n "${USER:-}" ]] || {
      echo "Error: USER not set"
      exit 1
    }
    [[ -n "${2:-}" ]] && export SSH_REPO_API_KEY="$2"
    source "$SCRIPTS/user.sh"
    source "$SCRIPTS/aur.sh"
    zsh
    ;;
  graphical)
    [[ -n "${USER:-}" ]] || {
      echo "Error: USER not set"
      exit 1
    }
    source "$SCRIPTS/graphical.sh"
    cat "$ROOT/TODO.md"
    ;;
  *)
    echo "Unknown subcommand: $1"
    echo "Valid: nvme base root user graphical"
    exit 1
    ;;
esac
