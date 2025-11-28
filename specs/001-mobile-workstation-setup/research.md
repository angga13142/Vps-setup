# Research: Mobile-Ready Coding Workstation Installation Script

**Date**: 2025-01-27  
**Feature**: Mobile-Ready Coding Workstation Installation Script  
**Purpose**: Document research findings and technology decisions for implementation

## Bash Scripting Best Practices

### Decision: Use `set -euo pipefail` for Error Safety

**Rationale**:
- `set -e`: Exit immediately if a command exits with non-zero status
- `set -u`: Treat unset variables as errors
- `set -o pipefail`: Pipeline failures cause script to fail

**Source**: Introduction to Bash Scripting (bobbyiliev/introduction-to-bash-scripting)

**Implementation**:
```bash
set -e          # Exit on error (constitution requirement)
set -u          # Exit on undefined variable
set -o pipefail # Exit on pipe failure
```

**Alternatives Considered**:
- `set -e` alone: Insufficient - doesn't catch undefined variables or pipe failures
- Manual error checking: Too verbose and error-prone

---

### Decision: Modular Function Structure

**Rationale**:
- Improves readability and maintainability
- Enables independent testing of components
- Aligns with constitution's modularity principle

**Source**: Multiple best practice guides (dev.to, medium.com, cycle.io)

**Implementation Pattern**:
```bash
function_name() {
    local var1="$1"
    # Function logic with error handling
    # Idempotency checks before actions
}
```

**Alternatives Considered**:
- Monolithic script: Violates modularity principle
- Separate script files: Over-engineered for this use case

---

### Decision: Idempotency Checks Before Actions

**Rationale**:
- Script must be safely re-runnable (constitution requirement)
- Prevents duplicate installations and configuration conflicts
- Uses existence checks: `command -v`, `dpkg -l`, file existence tests

**Source**: Debian packaging best practices, automation good practices

**Implementation Pattern**:
```bash
if ! command -v package_name &> /dev/null; then
    # Install package
fi

if [ ! -f "/path/to/config" ]; then
    # Create configuration
fi
```

**Alternatives Considered**:
- Always install/configure: Violates idempotency
- Skip all if any exists: Too restrictive

---

### Decision: Interactive Input with Silent Password

**Rationale**:
- No hardcoded credentials (constitution requirement)
- Security best practice
- Uses `read -s` for password input

**Source**: Bash scripting best practices

**Implementation**:
```bash
read -p "Username [default]: " CUSTOM_USER
CUSTOM_USER=${CUSTOM_USER:-default}

read -sp "Password: " CUSTOM_PASS
echo  # Newline after hidden input
```

**Alternatives Considered**:
- Command-line arguments: Less secure, exposes credentials
- Environment variables: Still visible in process list

---

## Docker Installation on Debian

### Decision: Use Official Docker APT Repository

**Rationale**:
- Ensures latest stable version
- Official support and security updates
- Standard Debian package management

**Source**: Docker official documentation (/docker/docs)

**Implementation Steps**:
1. Install prerequisites: `ca-certificates`, `curl`
2. Create keyring directory: `/etc/apt/keyrings`
3. Add Docker GPG key
4. Add Docker repository to `/etc/apt/sources.list.d/docker.sources`
5. Install: `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`

**Alternatives Considered**:
- Snap package: Less control, potential compatibility issues
- Manual binary installation: More complex, harder to maintain

---

### Decision: Add User to Docker Group

**Rationale**:
- Allows non-root Docker usage
- Security best practice (avoid running Docker as root)
- Requires user logout/login or `newgrp docker` to take effect

**Implementation**:
```bash
usermod -aG docker "$CUSTOM_USER"
```

**Alternatives Considered**:
- Docker rootless mode: More complex setup
- Always use sudo: Less convenient for users

---

## NVM (Node Version Manager) Installation

### Decision: Install NVM via Official Install Script

**Rationale**:
- User-space installation (constitution clean architecture principle)
- Allows multiple Node.js versions
- Official installation method

**Source**: NVM official repository (/nvm-sh/nvm)

**Implementation**:
```bash
# Download and install
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Add to user's .bashrc
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

**Install Node.js LTS**:
```bash
nvm install --lts
nvm use --default --lts
```

**Alternatives Considered**:
- System-wide Node.js via apt: Violates clean architecture (root filesystem pollution)
- Manual Node.js installation: More complex, harder to manage versions

---

## XFCE Configuration

### Decision: Use `xfconf-query` for Programmatic Configuration

**Rationale**:
- Command-line tool for XFCE settings
- Can be run as target user to set user-specific preferences
- Required for mobile optimization (font size, icon size, panel size)

**Implementation**:
```bash
# Set font size (12pt)
xfconf-query -c xsettings -p /Gtk/FontName -s "Sans 12"

# Set desktop icon size (48)
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -t string -s ""

# Set panel size (48px)
xfconf-query -c xfce4-panel -p /panels/panel-1/size -t int -s 48
```

**Note**: Must run as the target user (not root) for user-specific settings.

**Alternatives Considered**:
- Manual GUI configuration: Not automatable
- Direct config file editing: Fragile, format-dependent

---

## XRDP Installation

### Decision: Install XRDP from Debian Repositories

**Rationale**:
- Standard Debian package
- Well-maintained and tested
- Simple installation via apt

**Implementation**:
```bash
apt install xrdp
systemctl enable xrdp
systemctl start xrdp
```

**Configuration**:
- Default configuration works for basic RDP access
- User authentication via system users
- Port 3389 (standard RDP port)

**Alternatives Considered**:
- Custom XRDP build: Unnecessary complexity
- Alternative RDP servers: Less standard, compatibility issues

---

## Git Branch Detection in PS1

### Decision: Use `parse_git_branch()` Function

**Rationale**:
- Standard pattern for Git-aware prompts
- Efficient (only runs `git` command when in repo)
- Displays branch name in prompt

**Implementation**:
```bash
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

PS1='\[\033[01;32m\][\u@\h]\[\033[00m\] \[\033[01;34m\][\w]\[\033[00m\] \[\033[01;33m\]$(parse_git_branch)\[\033[00m\] \$ '
```

**Color Codes**:
- `\033[01;32m` - Neon green (bold)
- `\033[01;34m` - Blue (bold)
- `\033[01;33m` - Yellow (bold)
- `\033[00m` - Reset

**Alternatives Considered**:
- `__git_ps1` from git-prompt.sh: Requires additional file
- Simple branch check: Less efficient, more complex

---

## Hostname Management

### Decision: Use `hostnamectl` for Hostname Setting

**Rationale**:
- Modern systemd tool
- Updates both `/etc/hostname` and systemd hostname
- Immediate effect without reboot

**Implementation**:
```bash
hostnamectl set-hostname "$CUSTOM_HOSTNAME"
```

**Alternatives Considered**:
- Direct `/etc/hostname` editing: Doesn't update systemd
- `hostname` command: Deprecated, less reliable

---

## Summary of Technology Choices

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Script Language | Bash 5.2+ | Native, no dependencies |
| Error Handling | `set -euo pipefail` | Best practice, constitution requirement |
| Docker Installation | Official APT repo | Standard, maintained |
| Node.js Management | NVM | User-space, clean architecture |
| Desktop Environment | XFCE4 | Lightweight, mobile-friendly |
| Remote Desktop | XRDP | Standard, Debian package |
| Configuration Tool | xfconf-query | Programmatic XFCE config |
| Hostname Tool | hostnamectl | Modern, systemd-native |

All decisions align with constitution principles and Debian 13 (Trixie) compatibility requirements.
