# Mobile-Ready Coding Workstation Setup Script

A comprehensive Bash installation script for setting up a mobile-ready coding workstation on Debian 13 (Trixie). This script automates the installation and configuration of essential development tools, desktop environment, and remote access capabilities.

## Overview

This script transforms a fresh Debian 13 installation into a fully configured development workstation optimized for mobile access via RDP. It handles everything from system preparation to development stack installation, ensuring a consistent and professional setup every time.

### Key Features

- **Interactive Setup**: User-friendly prompts for username, password, and hostname configuration
- **Mobile-First Desktop**: XFCE4 desktop environment optimized for mobile devices with large fonts and icons
- **Remote Access**: XRDP server for remote desktop connections
- **Development Stack**: Docker, Node.js (via NVM), Python, and essential development tools
- **Beautiful Terminal**: Custom PS1 prompt with Git branch detection and color coding
- **Idempotent**: Safe to run multiple times without causing duplicate installations
- **Error Handling**: Comprehensive error checking and user-friendly error messages

## Prerequisites

- **Operating System**: Debian 13 (Trixie) - 64-bit amd64
- **Access**: Root or sudo privileges
- **Network**: Internet connection for package downloads
- **Storage**: At least 10GB free disk space

## Installation

### Quick Start

Run the script directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/angga13142/Vps-setup/master/scripts/setup-workstation.sh | sudo bash
```

Or download and run locally:

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/angga13142/Vps-setup/master/scripts/setup-workstation.sh -o setup-workstation.sh

# Make it executable
chmod +x setup-workstation.sh

# Run with sudo
sudo ./setup-workstation.sh
```

### Installation Steps

1. **Download the script** (if not using curl pipe method)
2. **Make it executable**: `chmod +x setup-workstation.sh`
3. **Run with sudo**: `sudo ./setup-workstation.sh`
4. **Follow the prompts**:
   - Enter username (default: `coder`)
   - Enter password (input is hidden)
   - Enter hostname (e.g., `my-vps`)
   - Confirm to proceed
5. **Wait for completion** (typically 5-15 minutes depending on network speed)
6. **Reboot the system** when prompted

## Usage

### Basic Usage

```bash
sudo ./setup-workstation.sh
```

The script will:
1. Verify Debian 13 compatibility
2. Check root privileges
3. Display welcome banner
4. Prompt for user credentials and hostname
5. Install and configure all components
6. Display connection information

### What Gets Installed

#### System Tools
- `curl` - Command-line tool for transferring data
- `git` - Version control system
- `htop` - Interactive process viewer
- `vim` - Text editor
- `build-essential` - Essential build tools

#### Desktop Environment
- **XFCE4** - Lightweight desktop environment
- **XRDP** - Remote Desktop Protocol server
- Mobile-optimized settings:
  - Font size: 12pt
  - Desktop icon size: 48px
  - Panel size: 48px

#### Development Stack
- **Docker** - Container platform (Engine + Compose)
- **Node.js LTS** - JavaScript runtime (via NVM)
- **Python** - Python interpreter (system default)
- **Firefox ESR** - Web browser
- **Chromium** - Web browser

#### Shell Configuration
- Custom PS1 prompt: `[User@Hostname] [CurrentDir] [GitBranch] $`
- Git branch detection function
- Useful aliases:
  - `ll` - Detailed file listing
  - `update` - System update command
  - `docker-clean` - Clean Docker resources

## Features

### Interactive Initialization
- Clear welcome banner with ASCII art
- Interactive prompts for username, password, and hostname
- Input validation and confirmation
- Immediate hostname configuration

### Terminal & Shell Aesthetics
- **Custom PS1 Prompt**: Color-coded prompt with user, hostname, directory, and Git branch
  - Neon green for user/hostname
  - Blue for current directory
  - Yellow for Git branch
- **Git Integration**: Automatic branch detection and display
- **Aliases**: Pre-configured useful commands

### Desktop & Mobile Optimization
- **XFCE4 Desktop**: Lightweight and responsive
- **Mobile-Friendly Settings**:
  - Large fonts (12pt) for readability
  - Large icons (48px) for touch-friendly interface
  - Large panel (48px) for easy navigation
- **Remote Access**: XRDP server for remote desktop connections

### Core Development Stack
- **Docker**: Full Docker Engine and Docker Compose installation
- **Node.js**: Latest LTS version via NVM (user-space installation)
- **Python**: System Python environment verification
- **Browsers**: Firefox ESR and Chromium for web development

### Idempotency
All installation and configuration steps are idempotent:
- Packages are checked before installation
- Users are checked before creation
- Configurations are checked before applying
- Safe to run multiple times

## Remote Access

After installation and reboot, connect via RDP:

1. **Find your server IP**: Displayed at the end of installation
2. **Use an RDP client**:
   - Windows: Built-in Remote Desktop Connection
   - macOS: Microsoft Remote Desktop or similar
   - Linux: `remmina` or `rdesktop`
   - Mobile: Microsoft Remote Desktop app
3. **Connect**: Use the displayed IP address and port 3389
4. **Login**: Use the username and password you configured

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for comprehensive troubleshooting guide with common issues and solutions.

**Quick fixes for common issues**:
- **"CUSTOM_PASS: unbound variable"**: Fixed in v1.0.0 - update to latest version
- **"Malformed stanza" Docker error**: Fixed in v1.0.0 - uses correct DEB822 format
- **Password input loop**: Fixed in v1.0.0 - uses `/dev/tty` redirection for piped execution
- **XFCE configuration not applying**: Autostart script fallback mechanism handles this automatically

For detailed troubleshooting steps, error messages, and solutions, see the [Troubleshooting Guide](docs/troubleshooting.md).

## Development

### Running Tests

```bash
# Run all tests (requires sudo for most tests)
sudo bats tests/

# Run specific test file
sudo bats tests/unit/test_user_creation.bats

# Run tests by tag
bats --filter-tags unit tests/
```

### Linting

```bash
# Lint all scripts
shellcheck scripts/*.sh

# Lint specific script
shellcheck scripts/setup-workstation.sh
```

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

## Documentation

- **README.md** (this file): Project overview and quick start
- **CONTRIBUTING.md**: Development workflow and contribution guidelines
- **docs/troubleshooting.md**: Common issues and solutions
- **CHANGELOG.md**: Version history and changes

## Function Documentation

All public functions in `scripts/setup-workstation.sh` are documented with:
- Purpose and description
- Input parameters
- Return values
- Side effects
- Idempotency notes

See function comments in the script for detailed documentation.

## License

This project is open source. See repository for license details.

## Support

- **Issues**: Open an issue on GitHub
- **Documentation**: Check [docs/troubleshooting.md](docs/troubleshooting.md)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)

## Acknowledgments

Built with best practices for DevOps automation, following principles of:
- Idempotency & Safety
- Interactive UX
- Aesthetic Excellence
- Mobile-First Optimization
- Clean Architecture
- Modularity

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-27  
**Target Platform**: Debian 13 (Trixie)
