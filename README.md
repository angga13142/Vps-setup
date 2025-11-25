# VPS Remote Dev Bootstrap

**Modular Edition v2.1** - Automated provisioning of a complete remote development workstation on Debian 13 (Trixie/Bookworm) VPS.

Transform a fresh VPS into a production-ready development environment with GUI desktop, development tools, monitoring, and security features - all in one command.

---

## 🚀 Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/angga13142/Vps-setup/master/setup.sh | sudo bash
```

### With Custom Settings

```bash
curl -fsSL https://raw.githubusercontent.com/angga13142/Vps-setup/master/setup.sh | \
sudo DEV_USER="angga" \
     DEV_USER_PASSWORD="SecurePass123!" \
     CUSTOM_HOSTNAME="my-dev-server" \
     TIMEZONE="Asia/Jakarta" \
     bash
```

---

## ✨ Features

### 🖥️ **Desktop Environment**
- **XFCE4** - Lightweight desktop environment
- **XRDP** - Remote Desktop Protocol (port 3389)
- **XFCE RDP Optimization** - Optimized for remote workspace (no screen lock, no suspend, performance mode)
- **Auto-start configuration** - Desktop ready on first login

### 💻 **Development Stack**
- **Docker** - Docker Engine, CLI, Compose, Buildx
- **Node.js** - Latest LTS via NVM (with yarn, pnpm, TypeScript, ts-node)
- **Python** - Python 3 with pip and venv
- **Git** - Pre-configured with useful aliases

### 📝 **Code Editors**
- **VS Code** - From official Microsoft repository
- **Cursor AI Editor** - Multiple installation methods (official installer, Snap, AppImage)

### 🐚 **Shell & Terminal**
- **Zsh** - Default shell with Oh My Zsh
- **Nerd Fonts** - Hack font for better terminal experience
- **Fancy Prompts** - Colorful, informative prompts with Git branch info
- **Starship Prompt** - Optional modern prompt (Rust-based)

### 🔒 **Security & Hardening**
- **UFW Firewall** - Configured with SSH (22) and XRDP (3389)
- **Fail2Ban** - Protection for SSH and XRDP
- **User Management** - Auto-remove other users (security cleanup)
- **Root Password Sync** - Root password = user password for convenience
- **SSH Key Setup** - Automatic ED25519 key generation

### 🛠️ **System Optimization**
- **4GB Swap** - Auto-configured with optimal swappiness (10)
- **System Limits** - inotify limits for VS Code/Webpack
- **Hostname Customization** - Clean, memorable hostnames
- **Timezone Configuration** - Customizable timezone

### 📊 **Monitoring & Health**
- **Health Check** - Comprehensive system status monitoring
- **Performance Monitoring** - Real-time resource tracking
- **Automated Alerts** - Configurable thresholds (CPU, RAM, Disk)
- **Daily Reports** - Performance reports generated automatically

### 🔄 **Maintenance & Recovery**
- **Auto-Backup** - All config files backed up before modification
- **Rollback System** - Restore from backups interactively
- **Idempotent** - Safe to run multiple times
- **Progress Tracking** - Know exactly where installation is

### 👨‍💻 **Developer Tools**
- **Git Configuration** - User name, email, useful aliases
- **SSH Keys** - Auto-generated with GitHub/GitLab config
- **GPG Keys** - Optional signed commits setup
- **Shell Aliases** - 40+ shortcuts (git, docker, system)
- **Dev Utilities** - tree, jq, ag, tmux, ripgrep, ncdu

---

## 📋 Installation Options

### Full Installation (Default)

```bash
sudo ./setup.sh
```

Installs all components: System, User, Desktop, Docker, Node.js, Python, VS Code, Cursor, Shell.

### Selective Installation

```bash
# Skip desktop (headless server)
sudo ./setup.sh --skip-desktop

# Skip specific components
sudo ./setup.sh --skip-cursor --skip-vscode --skip-docker

# Keep other users (don't auto-remove)
sudo ./setup.sh --keep-other-users
```

---

## 🎯 Available Commands

### Health & Monitoring

```bash
# Full health check
sudo ./setup.sh --check

# Quick stats
./setup.sh --stats

# Setup performance monitoring
sudo ./setup.sh --monitor

# Real-time resource monitor
sudo ./setup.sh --realtime

# Generate performance report
./setup.sh --report
```

### Maintenance

```bash
# Restore from backup (interactive)
sudo ./setup.sh --rollback

# List available backups
sudo ./setup.sh --list-backups

# Cleanup old backups
sudo ./setup.sh --cleanup-backups
```

### Developer Tools

```bash
# Setup Git, SSH keys, aliases
sudo GIT_USER_NAME="John Doe" \
     GIT_USER_EMAIL="john@example.com" \
     ./setup.sh --devtools
```

### Customization

```bash
# Change hostname (interactive)
sudo ./setup.sh --hostname

# Install with custom hostname
sudo CUSTOM_HOSTNAME="my-server" ./setup.sh

# Install with Starship prompt
sudo INSTALL_STARSHIP=true ./setup.sh
```

---

## ⚙️ Configuration Variables

### User Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `DEV_USER` | `developer` | Non-root development user |
| `DEV_USER_PASSWORD` | `DevPass123!` | Password for DEV_USER (also used for root) |
| `TIMEZONE` | `Asia/Jakarta` | System timezone |

### System Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CUSTOM_HOSTNAME` | (auto-generated) | Custom hostname (e.g., `my-dev-server`) |
| `INSTALL_STARSHIP` | `false` | Install Starship prompt |
| `REMOVE_OTHER_USERS` | `true` | Remove other users except root & DEV_USER |

### Developer Tools

| Variable | Default | Description |
|----------|---------|-------------|
| `GIT_USER_NAME` | (empty) | Git user name (for devtools) |
| `GIT_USER_EMAIL` | (empty) | Git user email (for devtools) |

### Installation Options

Set to `true` or `false` to enable/disable components:

- `INSTALL_SYSTEM` (default: `true`)
- `INSTALL_USER` (default: `true`)
- `INSTALL_DESKTOP` (default: `true`)
- `INSTALL_DOCKER` (default: `true`)
- `INSTALL_NODEJS` (default: `true`)
- `INSTALL_PYTHON` (default: `true`)
- `INSTALL_VSCODE` (default: `true`)
- `INSTALL_CURSOR` (default: `true`)
- `INSTALL_SHELL` (default: `true`)

---

## 📖 Usage Examples

### Basic Installation

```bash
# Default installation
sudo ./setup.sh
```

### Custom User & Hostname

```bash
sudo DEV_USER="angga" \
     DEV_USER_PASSWORD="MySecurePass123!" \
     CUSTOM_HOSTNAME="raccoon-dev" \
     ./setup.sh
```

### Headless Server (No Desktop)

```bash
sudo ./setup.sh --skip-desktop
```

### Development Tools Only

```bash
sudo GIT_USER_NAME="Angga" \
     GIT_USER_EMAIL="angga@example.com" \
     ./setup.sh --devtools
```

### With Monitoring

```bash
# Install everything + monitoring
sudo ./setup.sh && sudo ./setup.sh --monitor
```

### Health Check

```bash
# Check system status
sudo ./setup.sh --check
```

---

## 🏗️ Architecture

This project uses a **modular architecture** for better maintainability:

```
project/
├── setup.sh              # Main orchestrator
├── config.sh             # Centralized configuration
├── lib/                  # Shared libraries
│   ├── logging.sh        # Logging functions
│   ├── helpers.sh       # Utility functions
│   ├── validators.sh     # Pre-flight checks
│   └── verification.sh   # Post-install verification
└── modules/              # Installation modules
    ├── system.sh         # System preparation
    ├── user.sh           # User management
    ├── desktop.sh        # XFCE & XRDP
    ├── docker.sh         # Docker
    ├── nodejs.sh         # Node.js/NVM
    ├── python.sh         # Python stack
    ├── vscode.sh         # VS Code
    ├── cursor.sh         # Cursor IDE
    ├── shell.sh          # Zsh/Oh My Zsh
    ├── healthcheck.sh    # Health monitoring
    ├── rollback.sh       # Backup/restore
    ├── devtools.sh       # Developer tools
    ├── monitoring.sh     # Performance monitoring
    └── hostname.sh       # Hostname customization
```

**Benefits:**
- ✅ Easy to maintain and extend
- ✅ Test individual modules
- ✅ Selective installation
- ✅ Better code organization

---

## 📚 Documentation

- **[MODULAR.md](MODULAR.md)** - Architecture guide & module development
- **[FEATURES.md](FEATURES.md)** - Advanced features documentation
- **[HOSTNAME.md](HOSTNAME.md)** - Hostname & terminal customization guide

---

## 🔧 Post-Installation

### 1. Reboot Server

```bash
sudo reboot
```

### 2. Connect via RDP

- **Server**: `your-server-ip:3389`
- **User**: `developer` (or your `DEV_USER`)
- **Password**: (your `DEV_USER_PASSWORD`)

### 3. Access Tools

**Cursor:**
- Menu: Applications > Development > Cursor
- Terminal: `cursor`

**VS Code:**
- Menu: Applications > Development > VS Code
- Terminal: `code`

**Node.js:**
```bash
source ~/.nvm/nvm.sh
node --version
npm --version
```

**Docker:**
```bash
docker --version
docker run hello-world
```

### 4. Monitoring Commands

```bash
vps-stats      # Quick system stats
vps-report     # Full performance report
vps-monitor    # Run resource check
```

---

## 🎨 Terminal Customization

### Default Prompt

Colorful prompt with:
- Timestamp
- Username (green) @ Hostname (blue)
- Current directory (yellow)
- Git branch (cyan, if in repo)

### Starship Prompt (Optional)

Modern, highly customizable prompt:

```bash
sudo INSTALL_STARSHIP=true ./setup.sh
```

---

## 🔒 Security Features

### Auto-Remove Other Users

By default, script removes all regular users except:
- `root`
- Your `DEV_USER`

This cleans up default users from cloud images for better security.

**Disable:**
```bash
sudo ./setup.sh --keep-other-users
```

### Firewall

UFW configured with:
- SSH (port 22)
- XRDP (port 3389)

### Fail2Ban

Protection for:
- SSH brute force attacks
- XRDP attacks

---

## 🐛 Troubleshooting

### Check Installation Status

```bash
sudo ./setup.sh --check
```

### View Logs

```bash
# Latest log file
ls -lt /var/log/vps-bootstrap-*.log | head -1

# View log
tail -f /var/log/vps-bootstrap-*.log
```

### Rollback Changes

```bash
sudo ./setup.sh --rollback
```

### Re-run Installation

Script is **idempotent** - safe to run multiple times:

```bash
sudo ./setup.sh  # Will skip already installed components
```

---

## 📊 System Requirements

- **OS**: Debian 12 (Bookworm) or 13 (Trixie)
- **RAM**: Minimum 1GB (2GB+ recommended)
- **Disk**: Minimum 10GB free space
- **Network**: Internet connection required
- **Access**: Root or sudo access

---

## 🎯 What Gets Installed

### System Packages
- curl, wget, git, htop, ufw, unzip
- build-essential, apt-transport-https
- ca-certificates, gnupg, lsb-release
- fail2ban, libfuse2/libfuse2t64

### Desktop
- xfce4, xfce4-goodies, xorg
- dbus-x11, x11-xserver-utils
- xrdp

### Development
- Docker CE (latest stable)
- Node.js LTS via NVM
- Python 3 + pip + venv
- VS Code
- Cursor IDE

### Shell
- zsh
- Oh My Zsh
- Nerd Fonts (Hack)
- Optional: Starship prompt

---

## 🔗 Links

- **Repository**: https://github.com/angga13142/Vps-setup
- **Raw Script**: https://raw.githubusercontent.com/angga13142/Vps-setup/master/setup.sh
- **Issues**: https://github.com/angga13142/Vps-setup/issues

---

## 📝 License

This project is open source. Feel free to use, modify, and distribute.

---

## 🤝 Contributing

Contributions welcome! Please feel free to submit a Pull Request.

---

**Made with ❤️ for developers who want a complete remote dev environment in minutes!**
