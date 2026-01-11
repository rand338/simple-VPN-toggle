## README.md 

```markdown
# nmcli-vpn-toggle

Small Bash helper to toggle a NetworkManager VPN connection (e.g., WireGuard) via `nmcli`. 

## Features

- `./vpn up` exits cleanly if the VPN is already active (no unnecessary prompts). 
- `./vpn down` exits cleanly if the VPN is already inactive. 
- Tries to operate **without sudo** when possible. 
- If the current user is not allowed to control the connection, the script can optionally set `connection.permissions` to `user:$USER` (requires sudo once). 
- If you decline that change, the script will fall back to sudo for the current action (and will ask again next time). 

## Requirements

- Linux with NetworkManager
- `nmcli` available
- A configured NetworkManager VPN connection name (example: `<vpn connection name>`) 

## Installation

1. Save the script as `vpn` (or any name you prefer).
2. Make it executable:
```

```bash
   chmod +x vpn
```

3. (Optional) Move it into your PATH:

```bash
sudo mv vpn /usr/local/bin/vpn
```

## Configuration

Edit the script and set the connection name:

```bash
VPN_CONNECTION="<vpn connection name>"
```

The name must match exactly what `nmcli connection show` reports.

## Usage

```bash
./vpn up
./vpn down
```

### Examples

Bring the VPN up:

```bash
./vpn up
```

Bring the VPN down:

```bash
./vpn down
```

## Notes on permissions
NetworkManager connections are often system-wide and require admin privileges to activate/deactivate.
This script can convert the connection to a user-owned connection by setting `connection.permissions` to the current user (prompted on demand).
