# Data Model: Mobile-Ready Coding Workstation Installation Script

**Date**: 2025-01-27  
**Feature**: Mobile-Ready Coding Workstation Installation Script

## Entities

### User Account

**Purpose**: Represents the system user account created during installation

**Attributes**:
- `username` (string): User login name (default: 'coder')
- `password` (string): User password (encrypted in system, plaintext during input only)
- `home_directory` (path): `/home/$username`
- `shell` (path): `/bin/bash`
- `groups` (array): ['docker'] (after Docker installation)

**Validation Rules**:
- Username must be valid Linux username (alphanumeric, underscore, hyphen)
- Password must not be empty
- Username must not already exist (or handle gracefully)

**State Transitions**:
1. **Not Exists** → **Created**: When `useradd` command succeeds
2. **Created** → **Configured**: When `.bashrc` and home directory setup complete
3. **Configured** → **Docker Enabled**: When added to docker group

---

### System Configuration

**Purpose**: System-wide settings and package installations

**Attributes**:
- `hostname` (string): System hostname (e.g., 'my-vps')
- `os_version` (string): 'Debian 13 (Trixie)' - validated at start
- `packages_installed` (array): List of installed packages
- `docker_repository_configured` (boolean): Docker APT repo setup status
- `docker_service_enabled` (boolean): Docker daemon enabled status

**Validation Rules**:
- Hostname must be valid (RFC 1123 format)
- OS version must be Debian 13 (Trixie)
- Packages must be available in repositories

**State Transitions**:
1. **Unconfigured** → **Hostname Set**: After `hostnamectl set-hostname`
2. **Hostname Set** → **Packages Installed**: After apt installations
3. **Packages Installed** → **Docker Ready**: After Docker installation and user group addition

---

### User Environment

**Purpose**: Per-user shell and development environment configuration

**Attributes**:
- `bashrc_path` (path): `/home/$username/.bashrc`
- `ps1_prompt` (string): Custom prompt format with colors
- `git_branch_function` (function): `parse_git_branch()` function definition
- `aliases` (object): 
  - `ll`: `ls -alFh --color=auto`
  - `update`: `sudo apt update && sudo apt upgrade -y`
  - `docker-clean`: Docker cleanup command
- `nvm_installed` (boolean): NVM installation status
- `node_version` (string): Installed Node.js LTS version
- `python_available` (boolean): Python 3 availability

**Validation Rules**:
- `.bashrc` must be writable by user
- NVM must be installed in user's home directory
- Node.js LTS must be installable via NVM

**State Transitions**:
1. **Empty** → **Shell Configured**: After `.bashrc` customization
2. **Shell Configured** → **NVM Installed**: After NVM installation script
3. **NVM Installed** → **Node.js Ready**: After Node.js LTS installation

---

### Desktop Environment

**Purpose**: XFCE desktop environment configuration for mobile optimization

**Attributes**:
- `desktop_environment` (string): 'xfce4'
- `remote_desktop` (string): 'xrdp'
- `font_size` (integer): 12 or 13 (points)
- `icon_size` (integer): 48 (pixels)
- `panel_size` (integer): 48 (pixels)
- `xrdp_service_enabled` (boolean): XRDP service enabled status
- `xrdp_service_running` (boolean): XRDP service running status

**Configuration Paths**:
- Font: `xfconf-query -c xsettings -p /Gtk/FontName`
- Icon size: `xfconf-query -c xfce4-desktop` (desktop properties)
- Panel size: `xfconf-query -c xfce4-panel -p /panels/panel-1/size`

**Validation Rules**:
- Font size must be 12 or 13 points
- Icon size must be 48 pixels
- Panel size must be 48 pixels
- XRDP must be accessible on port 3389

**State Transitions**:
1. **Not Installed** → **Installed**: After XFCE4 and XRDP package installation
2. **Installed** → **Configured**: After mobile optimization settings applied
3. **Configured** → **Running**: After XRDP service start

---

## Relationships

### User Account ↔ User Environment
- **One-to-One**: Each user account has exactly one user environment configuration
- **Dependency**: User environment cannot exist without user account

### User Account ↔ System Configuration
- **Many-to-One**: Multiple user accounts can exist on one system configuration
- **Dependency**: System configuration must exist before user account creation

### User Account ↔ Desktop Environment
- **One-to-Many**: One user account can have one desktop environment configuration
- **Dependency**: Desktop environment configuration applies to specific user

### System Configuration ↔ Desktop Environment
- **One-to-One**: System has one desktop environment installation
- **Dependency**: Desktop environment requires system-level packages

---

## Data Flow

1. **Input Phase**: User provides username, password, hostname
2. **System Prep**: Hostname set, packages installed
3. **User Creation**: User account created with password
4. **Environment Setup**: `.bashrc` configured, NVM installed, Node.js installed
5. **Desktop Setup**: XFCE4 and XRDP installed, mobile settings applied
6. **Finalization**: Summary displayed, cleanup performed

---

## Validation and Error Handling

All entities include existence checks before modification:
- User account: `id "$username" &>/dev/null`
- Packages: `dpkg -l | grep -q package_name`
- Files: `[ -f "$file_path" ]`
- Services: `systemctl is-enabled service_name`

This ensures idempotency and prevents duplicate operations.

