# VPS Setup Script

Automates provisioning of a lightweight Debian 13 (Trixie/Bookworm) VPS into a full remote development workstation with:

- XFCE4 desktop + XRDP for GUI access
- Node.js (nvm + LTS toolchain), Python 3, Docker & Compose
- VS Code via Microsoft repo and Cursor AppImage
- Zsh + Oh My Zsh + Nerd Font
- Security hardening: swap/UFW, SSH lockdown, Fail2Ban, optional WireGuard VPN

## Usage

```bash
curl -fsSL https://paste.rs/Pwzla | sudo \
  SERVER_HOSTNAME=dev-vps \
  DEV_USER=developer \
  DEV_USER_PASSWORD='StrongPass!' \
  DEV_USER_SSH_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
  ENABLE_WIREGUARD=true \
  bash
```

### Key Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `DEV_USER` | `developer` | Non-root desktop + SSH user |
| `DEV_USER_PASSWORD` | `DevPass123!` | Password for the user (override!) |
| `DEV_USER_SSH_KEY` | empty | Public key appended to `authorized_keys` |
| `SERVER_HOSTNAME` | `dev-workstation` | Sets system hostname |
| `ALLOW_PASSWORD_AUTH` | `false` | Permit SSH password login if `true` |
| `ENABLE_WIREGUARD` | `true` | Install and start WireGuard server |
| `WG_INTERFACE_ADDRESS` | `10.8.0.1/24` | WireGuard interface CIDR |
| `WG_PORT` | `51820` | UDP port opened in UFW |
| `WG_PUBLIC_INTERFACE` | `eth0` | Interface used for NAT masquerade |

After the script completes, reboot and connect via any RDP client to `server-ip:3389` using the `DEV_USER` credentials. For VPN clients, add peer entries to `/etc/wireguard/wg0.conf` and restart `wg-quick@wg0`.

