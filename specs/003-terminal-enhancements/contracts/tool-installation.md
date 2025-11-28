# Tool Installation Contract

**Feature**: Terminal Enhancements & UI Improvements  
**Date**: 2025-11-28

## Overview

This contract defines the installation and verification requirements for terminal enhancement tools (Starship, fzf, bat, exa).

## Installation Contracts

### 1. Starship Installation

**Tool**: Starship prompt  
**Installation Method**: Official installer script  
**Binary Location**: `~/.local/bin/starship` or system PATH

**Pre-Installation Checks**:
- Verify `curl` or `wget` is available
- Check if `starship` command already exists: `command -v starship &>/dev/null`
- If exists → Skip installation, return success

**Installation Steps**:
1. Download installer: `curl -sS https://starship.rs/install.sh`
2. Execute installer: `sh` (pipes installer output)
3. Installer handles: binary download, PATH configuration, permissions

**Post-Installation Verification**:
- Verify binary exists: `command -v starship &>/dev/null`
- Verify binary is executable: `test -x "$(command -v starship)"`
- Test initialization: `starship init bash` (should output configuration)

**Success Criteria**:
- `starship --version` returns version number
- `starship init bash` outputs valid Bash configuration
- Binary is in user's PATH

**Failure Handling**:
- Log error with context and recovery steps
- Return error code (don't abort entire process)
- Don't configure in .bashrc if installation failed

---

### 2. fzf Installation

**Tool**: fzf (fuzzy finder)  
**Installation Method**: APT package  
**Package Name**: `fzf`

**Pre-Installation Checks**:
- Verify `apt` package manager is available
- Check package status: `dpkg-query -W -f='${Status}' fzf 2>/dev/null | grep -q "install ok installed"`
- If installed → Skip installation, return success

**Installation Steps**:
1. Update package list: `sudo apt update`
2. Install package: `sudo apt install -y fzf`
3. Verify installation: `dpkg-query -W -f='${Status}' fzf`

**Post-Installation Verification**:
- Verify command exists: `command -v fzf &>/dev/null`
- Verify package status: `dpkg-query -W -f='${Status}' fzf | grep -q "install ok installed"`
- Test basic functionality: `echo "test" | fzf` (should work)

**Success Criteria**:
- `fzf --version` returns version number
- Package status shows "install ok installed"
- Command is available in PATH

**Failure Handling**:
- Log error with context and recovery steps
- Return error code (don't abort entire process)
- Don't configure in .bashrc if installation failed

---

### 3. bat Installation

**Tool**: bat (better cat)  
**Installation Method**: APT package  
**Package Name**: `bat`  
**Binary Name**: `batcat` (Debian-specific)

**Pre-Installation Checks**:
- Verify `apt` package manager is available
- Check package status: `dpkg-query -W -f='${Status}' bat 2>/dev/null | grep -q "install ok installed"`
- If installed → Skip installation, return success

**Installation Steps**:
1. Update package list: `sudo apt update`
2. Install package: `sudo apt install -y bat`
3. Verify installation: `dpkg-query -W -f='${Status}' bat`

**Post-Installation Steps** (Symlink Creation):
1. Ensure `~/.local/bin` exists: `mkdir -p ~/.local/bin`
2. Create symlink: `ln -s /usr/bin/batcat ~/.local/bin/bat`
3. Verify `~/.local/bin` is in PATH (standard in Debian)

**Post-Installation Verification**:
- Verify `batcat` exists: `command -v batcat &>/dev/null`
- Verify symlink exists: `test -L ~/.local/bin/bat`
- Verify `bat` works: `command -v bat &>/dev/null` (after symlink)
- Test functionality: `batcat --version`

**Success Criteria**:
- `batcat --version` returns version number
- Symlink `bat → batcat` exists and works
- Both `batcat` and `bat` commands available

**Failure Handling**:
- If package install fails → Log error, return error code
- If symlink fails → Log warning, continue (user can use `batcat` directly)
- Don't configure alias if installation failed

---

### 4. exa Installation

**Tool**: exa (modern ls)  
**Installation Method**: GitHub binary release  
**Binary Location**: `/usr/local/bin/exa`

**Pre-Installation Checks**:
- Verify `wget` or `curl` is available
- Verify `unzip` is available
- Check if `exa` command already exists: `command -v exa &>/dev/null`
- If exists → Skip installation, return success

**Installation Steps**:
1. Determine architecture: `uname -m` (should be `x86_64` for Debian 13)
2. Download latest release: `wget https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-musl.zip`
3. Extract binary: `unzip exa-linux-x86_64-musl.zip`
4. Install binary: `sudo mv bin/exa /usr/local/bin/exa`
5. Set permissions: `sudo chmod +x /usr/local/bin/exa`
6. Cleanup: Remove downloaded zip and extracted files

**Post-Installation Verification**:
- Verify binary exists: `command -v exa &>/dev/null`
- Verify binary is executable: `test -x /usr/local/bin/exa`
- Test functionality: `exa --version`

**Success Criteria**:
- `exa --version` returns version number
- Binary is executable and in PATH
- Command works for basic operations

**Failure Handling**:
- If download fails → Log error, return error code
- If extraction fails → Log error, return error code
- If installation fails → Log error, return error code
- Don't configure aliases if installation failed

**Alternative**: If binary installation fails, document manual installation steps for user

---

## Verification Contracts

### Tool Verification Pattern

All tools must be verified after installation using this pattern:

```bash
verify_tool_installation(tool_name, binary_path)
```

**Inputs**:
- `tool_name` (string): Name of tool for logging
- `binary_path` (string, optional): Expected path to binary

**Verification Steps**:
1. Check command existence: `command -v "$tool_name" &>/dev/null`
2. If binary_path provided, verify path matches
3. Test version command: `$tool_name --version` (if supported)
4. Test basic functionality (tool-specific)

**Returns**:
- `0` - Tool verified and working
- `1` - Tool verification failed

**Usage**:
```bash
if verify_tool_installation "starship"; then
    log "INFO" "✓ Starship verified"
else
    log "ERROR" "Starship verification failed"
    return 1
fi
```

---

## Configuration Contracts

### Configuration Prerequisites

Before configuring any tool in .bashrc:
1. Tool must be successfully installed (verified)
2. Backup of .bashrc must be created
3. Configuration marker must be checked (idempotency)

### Configuration Pattern

```bash
configure_tool_in_bashrc(tool_name, username, configuration_block)
```

**Inputs**:
- `tool_name` (string): Name of tool
- `username` (string): Username for .bashrc path
- `configuration_block` (string): Configuration to add

**Steps**:
1. Verify tool is installed
2. Check for configuration marker
3. If marker exists → Skip (already configured)
4. If no marker → Add configuration block
5. Add configuration marker
6. Set file ownership and permissions

**Returns**:
- `0` - Configuration successful or already configured
- `1` - Configuration failed

---

## Error Recovery Contracts

### Installation Failure Recovery

When a tool installation fails:
1. Log error with full context
2. Log recovery steps for user
3. Continue with remaining tools (don't abort)
4. Don't configure failed tool in .bashrc
5. At end, provide summary of successes and failures

### Configuration Failure Recovery

When configuration fails:
1. Attempt to restore from backup
2. Log error with full context
3. Log recovery steps for user
4. Return error code
5. Don't leave .bashrc in broken state

---

## Performance Contracts

### Installation Time Limits

- Starship: < 30 seconds (download + install)
- fzf: < 10 seconds (APT install)
- bat: < 10 seconds (APT install)
- exa: < 60 seconds (download + extract + install)
- Total: < 2 minutes for all tools

### Configuration Time Limits

- Backup creation: < 1 second
- Configuration addition: < 2 seconds
- File permission setting: < 1 second
- Total configuration: < 5 seconds

---

## Idempotency Contracts

All installation and configuration operations must be idempotent:

1. **Installation Idempotency**:
   - Check if tool exists before installing
   - Skip installation if already present
   - Return success if already installed

2. **Configuration Idempotency**:
   - Check for configuration marker
   - Skip configuration if marker exists
   - Safe to run multiple times

3. **Verification**:
   - Re-running script produces same result
   - No duplicate installations
   - No duplicate configurations

---

## Testing Contracts

Each tool installation must be testable:

1. **Installation Test**: Verify tool installs correctly
2. **Verification Test**: Verify tool works after installation
3. **Idempotency Test**: Verify re-run doesn't duplicate
4. **Failure Test**: Verify graceful handling of failures
5. **Configuration Test**: Verify tool is configured in .bashrc

**Test Requirements**:
- All tests must pass before considering tool "ready"
- Tests must run in isolated environment
- Tests must clean up after execution
