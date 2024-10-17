#!/usr/bin/env bash

set -euo pipefail

SCOPE="system"
ACTION=""

while (($#)); do
  case "$1" in
    --system) SCOPE="system" ;;
    --user) SCOPE="user" ;;
    push | pull)
      ACTION="$1"
      ;;
    *)
      echo "usage: services.sh [--system|--user] <push|pull>"
      exit 1
      ;;
  esac
  shift
done

if [[ -z "$ACTION" ]]; then
  echo "usage: services.sh [--system|--user] <push|pull>"
  exit 1
fi

PKGS="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]:-$0}")")")/pkgs"
SERVICES_FILE="$PKGS/services-${SCOPE}.txt"

SYSTEMCTL="systemctl"
[[ "$SCOPE" == "user" ]] && SYSTEMCTL="systemctl --user"

if [[ "$ACTION" == "push" ]]; then

  sorted=$($SYSTEMCTL list-unit-files --state=enabled --type=service,timer,socket --no-legend |
    awk '{print $1}' | sort)

  declare -A has_socket
  while IFS= read -r unit; do
    [[ "$unit" == *.socket ]] && has_socket["${unit%.socket}"]=1
  done <<< "$sorted"

  while IFS= read -r unit; do
    if [[ "$unit" == *.service ]] && [[ -n "${has_socket["${unit%.service}"]:-}" ]]; then
      continue
    fi
    echo "$unit"
  done <<< "$sorted" > "$SERVICES_FILE"
  echo "Updated ${SCOPE} services list ($SERVICES_FILE)"

elif [[ "$ACTION" == "pull" ]]; then

  if [[ ! -s "$SERVICES_FILE" ]]; then
    echo "error: ${SERVICES_FILE} is empty or missing — run push first"
    exit 1
  fi

  while IFS= read -r svc; do
    [[ -z "$svc" ]] && continue
    if $SYSTEMCTL is-enabled "$svc" &> /dev/null; then
      echo "[skip] $SYSTEMCTL enable $svc (already enabled)"
    else
      echo "[do  ] $SYSTEMCTL enable $svc"
      $SYSTEMCTL enable "$svc"
    fi
  done < "$SERVICES_FILE"

  extras=$(
    $SYSTEMCTL list-unit-files --state=enabled --type=service,timer,socket --no-legend |
      awk '{print $1}' | grep -vFf "$SERVICES_FILE" || true
  )

  if [[ -n "$extras" ]]; then
    while IFS= read -r svc; do
      echo "[do  ] $SYSTEMCTL disable $svc"
      $SYSTEMCTL disable "$svc"
    done <<< "$extras"
  fi

fi
