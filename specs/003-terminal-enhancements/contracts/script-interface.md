# Script Interface Contract: Terminal Enhancements

**Feature**: Terminal Enhancements & UI Improvements  
**Date**: 2025-11-28

## Overview

This contract defines the function signatures, inputs, outputs, side effects, and error handling for terminal enhancement functions to be added to `scripts/setup-workstation.sh`.

## Functions

### 1. `setup_terminal_enhancements()`

**Purpose**: Main orchestration function for installing and configuring all terminal enhancements.

**Signature**:
```bash
setup_terminal_enhancements(username)
```

**Inputs**:
- `username` (string, required): Username for which to configure terminal enhancements

**Outputs**: None (uses structured logging via `log()` function)

**Side Effects**:
- Installs Starship, fzf, bat, exa tools
- Modifies user's `.bashrc` file
- Creates backup of `.bashrc` before modifications
- Adds aliases, functions, and configuration to `.bashrc`
- Sets file ownership and permissions

**Returns**:
- `0` - Success (all tools installed and configured, or already configured)
- `1` - Error (critical failure preventing configuration)

**Idempotency**: Yes
- Checks for configuration marker in `.bashrc`: `# Terminal Enhancements Configuration - Added by setup-workstation.sh`
- Skips installation if tools already installed
- Safe to run multiple times

**Dependencies**:
- `log()` function (from parent script)
- `install_starship()`, `install_fzf()`, `install_bat()`, `install_exa()`
- `configure_terminal_aliases()`, `configure_bash_enhancements()`

**Example**:
```bash
setup_terminal_enhancements "coder"
```

---

### 2. `install_starship()`

**Purpose**: Install Starship prompt tool.

**Signature**:
```bash
install_starship()
```

**Inputs**: None

**Outputs**: None (uses structured logging)

**Side Effects**:
- Downloads and installs Starship binary
- Adds Starship to system PATH
- May modify system-wide or user-specific PATH configuration

**Returns**:
- `0` - Success (Starship installed or already installed)
- `1` - Error (installation failed)

**Idempotency**: Yes
- Checks if `starship` command exists in PATH before installing
- Skips installation if already present

**Dependencies**:
- `curl` or `wget` (for downloading installer)
- Internet connectivity
- Write permissions for installation directory

**Verification**:
- After installation, verifies: `command -v starship &>/dev/null`

**Example**:
```bash
if install_starship; then
    log "INFO" "Starship installed successfully"
fi
```

---

### 3. `install_fzf()`

**Purpose**: Install fzf (fuzzy finder) tool.

**Signature**:
```bash
install_fzf()
```

**Inputs**: None

**Outputs**: None (uses structured logging)

**Side Effects**:
- Installs fzf package via APT
- Makes fzf available in system PATH

**Returns**:
- `0` - Success (fzf installed or already installed)
- `1` - Error (installation failed)

**Idempotency**: Yes
- Checks package status: `dpkg-query -W -f='${Status}' fzf`
- Skips installation if package already installed

**Dependencies**:
- `apt` package manager
- Internet connectivity
- Root/sudo privileges

**Verification**:
- After installation, verifies: `command -v fzf &>/dev/null` or package status

**Example**:
```bash
if install_fzf; then
    log "INFO" "fzf installed successfully"
fi
```

---

### 4. `install_bat()`

**Purpose**: Install bat (better cat) tool and create symlink.

**Signature**:
```bash
install_bat()
```

**Inputs**: None

**Outputs**: None (uses structured logging)

**Side Effects**:
- Installs bat package via APT (installs as `batcat`)
- Creates symlink `bat → batcat` in `~/.local/bin/`
- Ensures `~/.local/bin` is in PATH

**Returns**:
- `0` - Success (bat installed and symlink created, or already installed)
- `1` - Error (installation or symlink creation failed)

**Idempotency**: Yes
- Checks package status: `dpkg-query -W -f='${Status}' bat`
- Checks if symlink exists before creating
- Skips if already installed and configured

**Dependencies**:
- `apt` package manager
- `~/.local/bin` directory (created if needed)
- Write permissions for user's home directory

**Verification**:
- After installation, verifies: `command -v batcat &>/dev/null`
- After symlink, verifies: `command -v bat &>/dev/null` (or symlink exists)

**Example**:
```bash
if install_bat; then
    log "INFO" "bat installed and symlink created"
fi
```

---

### 5. `install_exa()`

**Purpose**: Install exa (modern ls) tool from GitHub releases.

**Signature**:
```bash
install_exa()
```

**Inputs**: None

**Outputs**: None (uses structured logging)

**Side Effects**:
- Downloads exa binary from GitHub releases
- Installs binary to `/usr/local/bin/exa`
- Makes exa available in system PATH

**Returns**:
- `0` - Success (exa installed or already installed)
- `1` - Error (download or installation failed)

**Idempotency**: Yes
- Checks if `exa` command exists in PATH before installing
- Skips installation if already present

**Dependencies**:
- `wget` or `curl` (for downloading)
- `unzip` (for extracting binary)
- Internet connectivity
- Root/sudo privileges (for `/usr/local/bin/`)

**Verification**:
- After installation, verifies: `command -v exa &>/dev/null`

**Example**:
```bash
if install_exa; then
    log "INFO" "exa installed successfully"
fi
```

---

### 6. `configure_terminal_aliases(username)`

**Purpose**: Add Git, Docker, and utility aliases to user's .bashrc with conflict detection.

**Signature**:
```bash
configure_terminal_aliases(username)
```

**Inputs**:
- `username` (string, required): Username for which to configure aliases

**Outputs**: None (uses structured logging)

**Side Effects**:
- Checks for existing aliases before adding
- Adds non-conflicting aliases to `.bashrc`
- Logs warnings for skipped conflicts

**Returns**:
- `0` - Success (aliases configured or already configured)
- `1` - Error (configuration failed)

**Idempotency**: Yes
- Checks for configuration marker: `# Terminal Enhancements Configuration - Added by setup-workstation.sh`
- Checks each alias for conflicts before adding
- Safe to run multiple times

**Dependencies**:
- User's `.bashrc` file must exist or be creatable
- Write permissions for user's home directory

**Aliases Added** (if no conflicts):
- Git: `gst`, `gco`, `gcm`, `gpl`, `gps`
- Docker: `dc`, `dps`, `dlog`
- System: `ports`, `ll` (if not exists)
- Utility: `update`, `docker-clean` (if not exists)

**Example**:
```bash
configure_terminal_aliases "coder"
```

---

### 7. `configure_terminal_functions(username)`

**Purpose**: Add utility functions to user's .bashrc with conflict detection.

**Signature**:
```bash
configure_terminal_functions(username)
```

**Inputs**:
- `username` (string, required): Username for which to configure functions

**Outputs**: None (uses structured logging)

**Side Effects**:
- Checks for existing functions before adding
- Adds non-conflicting functions to `.bashrc`
- Logs warnings for skipped conflicts

**Returns**:
- `0` - Success (functions configured or already configured)
- `1` - Error (configuration failed)

**Idempotency**: Yes
- Checks for configuration marker: `# Terminal Enhancements Configuration - Added by setup-workstation.sh`
- Checks each function for conflicts before adding
- Safe to run multiple times

**Dependencies**:
- User's `.bashrc` file must exist or be creatable
- Write permissions for user's home directory

**Functions Added** (if no conflicts):
- `mkcd()` - Create and enter directory
- `extract()` - Extract archives
- `ports()` - Show listening ports
- `weather()` - Weather info (with error handling for wttr.in)

**Example**:
```bash
configure_terminal_functions "coder"
```

---

### 8. `configure_bash_enhancements(username)`

**Purpose**: Configure Bash history and completion improvements.

**Signature**:
```bash
configure_bash_enhancements(username)
```

**Inputs**:
- `username` (string, required): Username for which to configure enhancements

**Outputs**: None (uses structured logging)

**Side Effects**:
- Modifies `.bashrc` with history and completion settings
- Sets environment variables (HISTSIZE, HISTFILESIZE, etc.)
- Configures readline bindings

**Returns**:
- `0` - Success (enhancements configured or already configured)
- `1` - Error (configuration failed)

**Idempotency**: Yes
- Checks for configuration marker: `# Terminal Enhancements Configuration - Added by setup-workstation.sh`
- Safe to run multiple times

**Dependencies**:
- User's `.bashrc` file must exist or be creatable
- Write permissions for user's home directory

**Configuration Added**:
- History size: 10000 commands
- History file size: 20000 commands
- History control: ignore duplicates, timestamps
- Completion: case-insensitive, menu-style

**Example**:
```bash
configure_bash_enhancements "coder"
```

---

### 9. `configure_starship_prompt(username)`

**Purpose**: Configure Starship prompt in user's .bashrc, replacing existing prompt if present.

**Signature**:
```bash
configure_starship_prompt(username)
```

**Inputs**:
- `username` (string, required): Username for which to configure Starship

**Outputs**: None (uses structured logging)

**Side Effects**:
- Creates backup of `.bashrc` before modification
- Removes existing PS1/PROMPT_COMMAND configurations
- Adds Starship initialization to `.bashrc`
- Sets file ownership and permissions

**Returns**:
- `0` - Success (Starship configured or already configured)
- `1` - Error (configuration failed)

**Idempotency**: Yes
- Checks if Starship initialization already exists
- Checks if Starship command is available before configuring
- Safe to run multiple times

**Dependencies**:
- `install_starship()` must succeed first
- User's `.bashrc` file must exist or be creatable
- Write permissions for user's home directory

**Configuration**:
- Adds: `eval "$(starship init bash)"` to `.bashrc`
- Removes existing PS1/PROMPT_COMMAND (after backup)

**Example**:
```bash
if command -v starship &>/dev/null; then
    configure_starship_prompt "coder"
fi
```

---

### 10. `configure_fzf_key_bindings(username)`

**Purpose**: Configure fzf key bindings in user's .bashrc.

**Signature**:
```bash
configure_fzf_key_bindings(username)
```

**Inputs**:
- `username` (string, required): Username for which to configure fzf

**Outputs**: None (uses structured logging)

**Side Effects**:
- Adds fzf key bindings to `.bashrc`
- Configures fzf options (FZF_DEFAULT_OPTS, FZF_CTRL_T_COMMAND)
- Sets file ownership and permissions

**Returns**:
- `0` - Success (fzf configured or already configured)
- `1` - Error (configuration failed)

**Idempotency**: Yes
- Checks if fzf key bindings already configured
- Checks if fzf command is available before configuring
- Safe to run multiple times

**Dependencies**:
- `install_fzf()` must succeed first
- User's `.bashrc` file must exist or be creatable
- Write permissions for user's home directory

**Configuration**:
- Adds: `eval "$(fzf --bash)"` or sources `~/.fzf.bash`
- Sets: `FZF_DEFAULT_OPTS`, `FZF_CTRL_T_COMMAND` (with ignore patterns)

**Example**:
```bash
if command -v fzf &>/dev/null; then
    configure_fzf_key_bindings "coder"
fi
```

---

### 11. `check_alias_conflict(alias_name)`

**Purpose**: Check if an alias already exists (for conflict detection).

**Signature**:
```bash
check_alias_conflict(alias_name)
```

**Inputs**:
- `alias_name` (string, required): Name of alias to check

**Outputs**:
- Returns `0` if alias exists (conflict)
- Returns `1` if alias doesn't exist (no conflict)

**Side Effects**: None

**Returns**:
- `0` - Conflict exists (alias already defined)
- `1` - No conflict (alias not defined)

**Implementation**:
```bash
type "$alias_name" &>/dev/null
```

**Example**:
```bash
if check_alias_conflict "gst"; then
    log "WARNING" "Alias 'gst' already exists, skipping"
fi
```

---

### 12. `check_function_conflict(function_name)`

**Purpose**: Check if a function already exists (for conflict detection).

**Signature**:
```bash
check_function_conflict(function_name)
```

**Inputs**:
- `function_name` (string, required): Name of function to check

**Outputs**:
- Returns `0` if function exists (conflict)
- Returns `1` if function doesn't exist (no conflict)

**Side Effects**: None

**Returns**:
- `0` - Conflict exists (function already defined)
- `1` - No conflict (function not defined)

**Implementation**:
```bash
type "$function_name" &>/dev/null
```

**Example**:
```bash
if check_function_conflict "mkcd"; then
    log "WARNING" "Function 'mkcd' already exists, skipping"
fi
```

---

### 13. `create_bashrc_backup(bashrc_path)`

**Purpose**: Create a timestamped backup of .bashrc before modifications.

**Signature**:
```bash
create_bashrc_backup(bashrc_path)
```

**Inputs**:
- `bashrc_path` (string, required): Path to .bashrc file

**Outputs**:
- Backup path (string) on success, empty string on failure

**Side Effects**:
- Creates backup file with timestamp
- Preserves original file permissions

**Returns**:
- `0` - Success (backup created)
- `1` - Error (backup failed)

**Backup Format**:
- Filename: `{bashrc_path}.backup.YYYYMMDD_HHMMSS`
- Example: `/home/coder/.bashrc.backup.20251128_120000`

**Example**:
```bash
backup_path=$(create_bashrc_backup "/home/coder/.bashrc")
if [ -n "$backup_path" ]; then
    log "INFO" "Backup created: $backup_path"
fi
```

---

## Error Handling

All functions must:
1. Use `log()` function for structured logging
2. Return appropriate exit codes (0 = success, 1 = error)
3. Provide recovery suggestions in error messages
4. Not abort entire process on single failure (where applicable)

**Error Message Format**:
```
Context: Function name and operation attempted
Recovery: Specific steps user can take to resolve
```

**Example Error**:
```bash
log "ERROR" "Failed to install Starship. Context: Function install_starship() attempted to download Starship installer but curl failed. Recovery: Check internet connectivity, verify curl is installed, or install Starship manually: curl -sS https://starship.rs/install.sh | sh"
```

## Integration Points

### Call Site in Main Script

```bash
# In setup-workstation.sh, after user creation:
if [ "$ENABLE_TERMINAL_ENHANCEMENTS" = "true" ]; then
    setup_terminal_enhancements "$CUSTOM_USER"
fi
```

### Dependencies on Existing Functions

- Uses `log()` function from parent script
- May use `verify_installation()` for final verification
- Integrates with existing `configure_shell()` or replaces it

## Testing Contracts

Each function must be testable with:
- Unit tests: Verify function behavior in isolation
- Integration tests: Verify end-to-end installation and configuration
- Idempotency tests: Verify safe re-runs

**Test Requirements**:
- All functions must be idempotent
- All functions must handle missing dependencies gracefully
- All functions must provide clear error messages
