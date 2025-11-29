# Data Model: Terminal Enhancements & UI Improvements

**Feature**: Terminal Enhancements & UI Improvements  
**Date**: 2025-11-28

## Overview

This feature enhances the terminal environment through tool installations and shell configuration. The data model represents the state and configuration of terminal enhancements.

## Entities

### 1. Terminal Configuration

**Purpose**: Represents the complete shell environment setup including prompt, aliases, functions, and history settings.

**Attributes**:
- `bashrc_path` (string): Path to user's .bashrc file (e.g., `/home/username/.bashrc`)
- `backup_path` (string): Path to backup file (e.g., `/home/username/.bashrc.backup.20251128_120000`)
- `configuration_marker` (string): Unique marker to identify our custom configuration (e.g., `"# Terminal Enhancements Configuration"`)
- `prompt_type` (enum): Type of prompt configured (`"starship"`, `"custom"`, `"default"`)
- `history_size` (integer): Maximum number of commands in history (default: 10000)
- `history_file_size` (integer): Maximum size of history file (default: 20000)
- `history_control` (string): History control options (e.g., `"ignoreboth:erasedups"`)
- `history_timestamp_format` (string): Format for history timestamps (e.g., `"%F %T "`)
- `completion_case_insensitive` (boolean): Whether completion is case-insensitive (default: true)
- `completion_menu_style` (boolean): Whether menu-style completion is enabled (default: true)

**State Transitions**:
1. **Empty** → **Backed Up**: When backup is created before modification
2. **Backed Up** → **Configured**: When configuration is successfully applied
3. **Configured** → **Verified**: When configuration is verified to work

**Validation Rules**:
- `bashrc_path` must be writable by the user
- `backup_path` must be in the same directory as `bashrc_path`
- `history_size` must be >= 1000 and <= 100000
- `history_file_size` must be >= history_size

**Relationships**:
- Contains multiple `AliasDefinition` entities
- Contains multiple `FunctionDefinition` entities
- References `ToolInstallation` entities for verification

---

### 2. Tool Installation

**Purpose**: Represents the installation state and verification status of terminal enhancement tools.

**Attributes**:
- `tool_name` (string): Name of the tool (e.g., `"starship"`, `"fzf"`, `"bat"`, `"exa"`)
- `installation_method` (enum): How tool is installed (`"apt"`, `"binary"`, `"script"`)
- `binary_path` (string): Full path to tool binary (e.g., `"/usr/local/bin/starship"`)
- `version` (string): Installed version (optional, e.g., `"1.0.0"`)
- `installation_status` (enum): Current status (`"not_installed"`, `"installing"`, `"installed"`, `"failed"`)
- `verification_status` (enum): Verification result (`"not_verified"`, `"verified"`, `"failed"`)
- `configured_in_bashrc` (boolean): Whether tool is configured in .bashrc (default: false)
- `configuration_marker` (string): Marker used in .bashrc to identify tool configuration

**State Transitions**:
1. **not_installed** → **installing**: When installation begins
2. **installing** → **installed**: When installation succeeds
3. **installing** → **failed**: When installation fails
4. **installed** → **verified**: When tool is verified to work
5. **verified** → **configured_in_bashrc**: When configuration is added to .bashrc

**Validation Rules**:
- `tool_name` must be one of: `"starship"`, `"fzf"`, `"bat"`, `"exa"`
- `binary_path` must be in system PATH or user's local bin
- `installation_status` must be set before `verification_status`
- `configured_in_bashrc` can only be true if `verification_status` is `"verified"`

**Relationships**:
- Referenced by `TerminalConfiguration` for verification
- May have dependencies on other `ToolInstallation` entities (e.g., Git for Starship Git module)

---

### 3. Alias Definition

**Purpose**: Represents a shell alias that provides a shortcut for common commands.

**Attributes**:
- `alias_name` (string): Name of the alias (e.g., `"gst"`, `"ll"`, `"dc"`)
- `alias_command` (string): Command the alias executes (e.g., `"git status"`, `"ls -alFh --color=auto"`)
- `category` (enum): Category of alias (`"git"`, `"docker"`, `"system"`, `"utility"`)
- `conflict_status` (enum): Whether alias conflicts with existing definition (`"none"`, `"exists"`, `"skipped"`)
- `configured` (boolean): Whether alias is added to .bashrc (default: false)

**State Transitions**:
1. **not_configured** → **checking_conflict**: When conflict detection begins
2. **checking_conflict** → **no_conflict**: When no conflict detected
3. **checking_conflict** → **conflict_exists**: When conflict detected
4. **no_conflict** → **configured**: When alias is successfully added
5. **conflict_exists** → **skipped**: When alias is skipped due to conflict

**Validation Rules**:
- `alias_name` must be a valid Bash identifier
- `alias_command` must be a valid shell command
- `configured` can only be true if `conflict_status` is `"none"`

**Relationships**:
- Belongs to `TerminalConfiguration`
- May conflict with user's existing aliases

---

### 4. Function Definition

**Purpose**: Represents a shell function that provides enhanced functionality.

**Attributes**:
- `function_name` (string): Name of the function (e.g., `"mkcd"`, `"extract"`, `"ports"`)
- `function_body` (string): Complete function definition (multi-line)
- `category` (enum): Category of function (`"file_management"`, `"system"`, `"utility"`, `"external_service"`)
- `conflict_status` (enum): Whether function conflicts with existing definition (`"none"`, `"exists"`, `"skipped"`)
- `configured` (boolean): Whether function is added to .bashrc (default: false)
- `external_dependency` (string, optional): External service dependency (e.g., `"wttr.in"` for weather function)

**State Transitions**:
1. **not_configured** → **checking_conflict**: When conflict detection begins
2. **checking_conflict** → **no_conflict**: When no conflict detected
3. **checking_conflict** → **conflict_exists**: When conflict detected
4. **no_conflict** → **configured**: When function is successfully added
5. **conflict_exists** → **skipped**: When function is skipped due to conflict

**Validation Rules**:
- `function_name` must be a valid Bash identifier
- `function_body` must be valid Bash function syntax
- `configured` can only be true if `conflict_status` is `"none"`

**Relationships**:
- Belongs to `TerminalConfiguration`
- May conflict with user's existing functions
- May depend on external services (e.g., weather function)

---

### 5. Backup Record

**Purpose**: Tracks backup files created before modifications to ensure recovery capability.

**Attributes**:
- `backup_path` (string): Full path to backup file
- `original_path` (string): Path to original file (e.g., `.bashrc`)
- `backup_timestamp` (datetime): When backup was created (format: `YYYYMMDD_HHMMSS`)
- `backup_size` (integer): Size of backup file in bytes
- `backup_reason` (string): Reason for backup (e.g., `"Before terminal enhancements configuration"`)

**State Transitions**:
1. **created** → **verified**: When backup is verified to exist and be readable
2. **verified** → **used**: When backup is used for restoration (optional)

**Validation Rules**:
- `backup_path` must be in same directory as `original_path`
- `backup_timestamp` must be valid datetime format
- Backup file must be readable

**Relationships**:
- Created before modifying `TerminalConfiguration`
- Can be used to restore `TerminalConfiguration` to previous state

---

## Data Flow

### Installation Flow

```
1. User runs setup script
2. Script checks existing .bashrc configuration
3. If configuration marker exists → Skip (idempotent)
4. If no marker → Create backup
5. For each tool:
   a. Check if tool installed
   b. If not → Install tool
   c. Verify installation
   d. If verified → Configure in .bashrc
6. Add aliases/functions (with conflict detection)
7. Add history/completion enhancements
8. Add configuration marker
9. Verify final configuration
```

### Conflict Resolution Flow

```
1. For each alias/function to add:
   a. Check if exists using `type` command
   b. If exists → Log warning, skip
   c. If not exists → Add to .bashrc
2. Continue with remaining aliases/functions
3. Log summary of skipped items
```

### Error Recovery Flow

```
1. Tool installation fails
2. Log error with context
3. Continue with next tool (don't abort)
4. Skip configuration for failed tool
5. At end, log summary of successes and failures
6. User can manually retry failed installations
```

## Constraints

### Installation Constraints

- Tools must be installable without breaking existing functionality
- Installation must be idempotent (safe to re-run)
- Failed installations must not prevent other tools from installing

### Configuration Constraints

- .bashrc modifications must preserve existing user customizations
- Configuration must be additive (append, don't replace)
- Configuration marker must be unique and detectable

### Performance Constraints

- Terminal startup time increase: < 100ms (SC-009)
- Tool installation time: < 2 minutes total
- Configuration application: < 5 seconds

### Compatibility Constraints

- Must work on Debian 13 (Trixie) amd64
- Must work in both desktop and headless environments
- Must gracefully degrade when tools unavailable
- Must handle terminal environments without color support

## Relationships Summary

```
TerminalConfiguration
├── contains → AliasDefinition (multiple)
├── contains → FunctionDefinition (multiple)
├── references → ToolInstallation (multiple, for verification)
└── has → BackupRecord (one, created before modification)

ToolInstallation
└── verified_by → TerminalConfiguration (when configured)

AliasDefinition
└── belongs_to → TerminalConfiguration

FunctionDefinition
└── belongs_to → TerminalConfiguration
└── may_depend_on → ExternalService (optional, e.g., wttr.in)

BackupRecord
└── protects → TerminalConfiguration
```
