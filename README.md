# VPS Remote Dev Bootstrap

Automates provisioning of a fresh Debian 13 (Trixie/Bookworm) VPS into a lightweight remote development workstation with XFCE, XRDP, Docker, Node/Python stacks, VS Code, Cursor AppImage, hardened SSH/Firewall, Fail2Ban, WireGuard, Zsh + Oh My Zsh, and Nerd Fonts.

## Features
- System prep: upgrades, baseline tooling, 4 GB swap, low swappiness, firewall with UFW.
- GUI/RDP: XFCE4, XRDP auto-start, non-root `DEV_USER`.
- Dev tooling: nvm + Node.js LTS + npm/yarn/pnpm/TypeScript/ts-node, Python 3 + pip + venv, Docker Engine & Compose.
- Editors: VS Code from Microsoft repo, Cursor AppImage with desktop entry.
- Shell polish: zsh default for root/user, unattended Oh My Zsh, Hack Nerd Font.
- Security: hostname setter, SSH hardening (no root login, optional password auth), optional SSH key injection, Fail2Ban profiles for SSH/XRDP, optional WireGuard server with NAT rules.
- Browsers: Firefox ESR and Chromium for web debugging.

## Quick Start
```bash
curl -fsSL https://paste.rs/Pwzla | sudo bash
```

### Customizing
Set environment variables inline before executing (defaults in parentheses):

| Variable | Description |
| --- | --- |
| `DEV_USER` (`developer`) | Non-root desktop/SSH user |
| `DEV_USER_PASSWORD` (`DevPass123!`) | Password for `DEV_USER` |
| `DEV_USER_SSH_KEY` (empty) | Public key appended to `~DEV_USER/.ssh/authorized_keys` |
| `SERVER_HOSTNAME` (`dev-workstation`) | Hostname applied via `hostnamectl` |
| `ALLOW_PASSWORD_AUTH` (`false`) | Set `true` to keep SSH password auth enabled |
| `ENABLE_WIREGUARD` (`true`) | Toggle WireGuard installation |
| `WG_INTERFACE_ADDRESS` (`10.8.0.1/24`) | wg0 interface CIDR |
| `WG_PORT` (`51820`) | WireGuard UDP port |
| `WG_PUBLIC_INTERFACE` (`eth0`) | Outbound NIC for NAT masquerade |

Example:
```bash
curl -fsSL https://paste.rs/Pwzla | \
  SERVER_HOSTNAME=dev-vps \
  DEV_USER=alice \
  DEV_USER_PASSWORD='S3cur3!' \
  DEV_USER_SSH_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
  ENABLE_WIREGUARD=false \
  sudo bash
```

## Post-Install Checklist
1. Reboot the server to ensure XRDP, Docker, and WireGuard start cleanly.
2. Connect via RDP to `server-ip:3389` using the `DEV_USER` credentials.
3. (Optional) Add WireGuard peers to `/etc/wireguard/wg0.conf` and restart `wg-quick@wg0`.
4. Verify Docker with `docker run hello-world` and Node with `nvm use default && node -v`.

## Development
The main script lives in `setup.sh`. Edit and test locally, then redeploy by re-running the hosted command or copying the file to your VPS.

