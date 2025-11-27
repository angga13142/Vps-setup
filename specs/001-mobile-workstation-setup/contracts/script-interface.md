# Script Interface Contract

**Date**: 2025-01-27  
**Feature**: Mobile-Ready Coding Workstation Installation Script

## Script Entry Point

### Execution

```bash
./setup-workstation.sh
```

**Requirements**:
- Must be run with root/sudo privileges
- Must be executed on Debian 13 (Trixie)
- Requires network connectivity

**Exit Codes**:
- `0`: Success
- `1`: Error (invalid OS, user cancellation, installation failure)
- `2`: Invalid input

---

## Function Signatures

### `get_user_inputs()`

**Purpose**: Collect user inputs interactively

**Inputs**: None (interactive prompts)

**Outputs**:
- `CUSTOM_USER` (string): Username (default: 'coder')
- `CUSTOM_PASS` (string): Password (hidden input)
- `CUSTOM_HOSTNAME` (string): System hostname

**Side Effects**:
- Displays welcome banner
- Prompts user for inputs
- Validates inputs
- Asks for confirmation

**Returns**: `0` on success, `1` on cancellation

---

### `system_prep()`

**Purpose**: Prepare system (hostname, package updates, essential tools)

**Inputs**:
- `CUSTOM_HOSTNAME` (string): Hostname to set

**Outputs**: None

**Side Effects**:
- Sets system hostname via `hostnamectl`
- Updates APT repositories
- Installs: `curl`, `git`, `htop`, `vim`, `build-essential`

**Returns**: `0` on success, `1` on error

**Idempotency**: Checks hostname and package existence before acting

---

### `setup_desktop_mobile()`

**Purpose**: Install and configure XFCE4 and XRDP with mobile optimization

**Inputs**:
- `CUSTOM_USER` (string): Username for XFCE configuration

**Outputs**: None

**Side Effects**:
- Installs `xfce4` desktop environment
- Installs `xrdp` remote desktop server
- Enables and starts XRDP service
- Configures XFCE for mobile:
  - Font size: 12-13pt
  - Icon size: 48px
  - Panel size: 48px

**Returns**: `0` on success, `1` on error

**Idempotency**: Checks package installation and service status before acting

**Note**: XFCE configuration must run as target user (not root)

---

### `create_user_and_shell()`

**Purpose**: Create user account and configure shell environment

**Inputs**:
- `CUSTOM_USER` (string): Username
- `CUSTOM_PASS` (string): Password

**Outputs**: None

**Side Effects**:
- Creates user account if not exists
- Sets user password
- Creates `/home/$CUSTOM_USER/.bashrc` with:
  - Custom PS1 prompt (colors, Git branch detection)
  - Aliases: `ll`, `update`, `docker-clean`
  - Git branch parsing function

**Returns**: `0` on success, `1` on error

**Idempotency**: Checks user existence before creation, file existence before writing

---

### `setup_dev_stack()`

**Purpose**: Install development tools (Docker, browsers, Node.js, Python)

**Inputs**:
- `CUSTOM_USER` (string): Username for user-specific installations

**Outputs**: None

**Side Effects**:
- Configures Docker APT repository
- Installs Docker and Docker Compose
- Adds user to docker group
- Installs Firefox ESR and Chromium
- Installs NVM (Node Version Manager)
- Installs Node.js LTS via NVM
- Verifies Python 3 availability

**Returns**: `0` on success, `1` on error

**Idempotency**: Checks package/service existence before installation

**Note**: NVM installation runs as target user (not root)

---

### `finalize()`

**Purpose**: Cleanup and display summary

**Inputs**:
- `CUSTOM_USER` (string): Username
- `CUSTOM_HOSTNAME` (string): Hostname

**Outputs**: None (displays to stdout)

**Side Effects**:
- Cleans APT cache
- Displays summary box with:
  - Server IP address
  - Username
  - "Reboot Required" message

**Returns**: `0` on success

---

## Helper Functions

### `parse_git_branch()`

**Purpose**: Extract current Git branch name

**Inputs**: None (uses current directory context)

**Outputs**: Branch name string (e.g., "(main)") or empty string

**Usage**: Called from PS1 prompt

---

### `check_debian_version()`

**Purpose**: Validate Debian 13 (Trixie) compatibility

**Inputs**: None

**Outputs**: None

**Side Effects**: Exits script if not Debian 13

**Returns**: `0` if Debian 13, exits with `1` otherwise

---

## Color Variables

Script defines color variables for output:

```bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color
```

---

## Error Handling Contract

All functions:
- Use `set -e` for automatic error exit
- Check prerequisites before actions
- Provide clear error messages
- Return appropriate exit codes

---

## Idempotency Contract

All functions:
- Check existence before creation/modification
- Safe to call multiple times
- No duplicate installations/configurations
- No side effects on repeated execution

