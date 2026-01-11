#!/bin/bash

# Simple VPN toggler for a NetworkManager connection (e.g., WireGuard).
# - `up`   : If VPN is already active -> exit. Otherwise bring it up.
# - `down` : If VPN is already inactive -> exit. Otherwise bring it down.
#
# It prefers running without sudo. If the current user is not allowed to control
# the connection, it can (optionally) assign the connection to the current user
# by setting `connection.permissions` (requires sudo one time). If you decline,
# it will use sudo for the current action and future actions.

set -u

# ===== Configuration =====
VPN_CONNECTION="<nmcli vpn connection name>"

CURRENT_USER="$(whoami)"
SUDO_CMD=""   # Will be set to "sudo" if needed.

# Check whether the configured connection exists.
connection_exists() {
  nmcli -t -f NAME connection show 2>/dev/null | grep -q "^${VPN_CONNECTION}$"
}

# Check whether the VPN connection is currently active.
# Returns 0 (true) if active, 1 (false) if not.
is_vpn_active() {
  nmcli -t -f NAME connection show --active | grep -q "^${VPN_CONNECTION}$"
}

# Ensure we can run nmcli up/down without sudo.
# If not possible, prompt the user:
# - Yes: assign the connection to the current user (one-time sudo).
# - No : fall back to using sudo for the action.
ensure_permissions() {
  # If already root, no need to do anything.
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    SUDO_CMD=""
    return 0
  fi

  # Read current connection permissions (may be empty or "user:...").
  PERMS="$(nmcli -t -f connection.permissions connection show "$VPN_CONNECTION" 2>/dev/null || true)"

  # If the current user is already allowed, proceed without sudo.
  if [[ "$PERMS" == *"user:${CURRENT_USER}"* ]]; then
    SUDO_CMD=""
    return 0
  fi

  # Otherwise, ask whether to assign the connection to the current user.
  echo "The connection '${VPN_CONNECTION}' is not currently assigned to user '${CURRENT_USER}'."
  read -r -p "Assign it to '${CURRENT_USER}' so it can be controlled without sudo? (y/n) " answer

  if [[ "$answer" =~ ^[yY]$ ]]; then
    echo "Updating connection permissions (requires sudo once)..."
    if sudo nmcli connection modify "$VPN_CONNECTION" connection.permissions "user:${CURRENT_USER}"; then
      echo "Done. Next runs should work without sudo."
      SUDO_CMD=""
      return 0
    else
      echo "Failed to update permissions. Falling back to sudo."
      SUDO_CMD="sudo"
      return 0
    fi
  fi

  echo "OK. Falling back to sudo for this action."
  SUDO_CMD="sudo"
  return 0
}

# ===== Main =====
case "${1:-}" in
  up)
    if ! connection_exists; then
      echo "Error: connection '${VPN_CONNECTION}' not found."
      exit 2
    fi

    if is_vpn_active; then
      echo "VPN is already up. Nothing to do."
      exit 0
    fi

    ensure_permissions
    echo "Bringing VPN up..."
    $SUDO_CMD nmcli connection up "$VPN_CONNECTION"
    ;;
  down)
    if ! connection_exists; then
      echo "Error: connection '${VPN_CONNECTION}' not found."
      exit 2
    fi

    if ! is_vpn_active; then
      echo "VPN is already down. Nothing to do."
      exit 0
    fi

    ensure_permissions
    echo "Bringing VPN down..."
    $SUDO_CMD nmcli connection down "$VPN_CONNECTION"
    ;;
  *)
    echo "Usage: $0 {up|down}"
    exit 1
    ;;
esac
