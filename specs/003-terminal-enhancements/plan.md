# Implementation Plan: Terminal Enhancements & UI Improvements

**Branch**: `003-terminal-enhancements` | **Date**: 2025-11-28 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/003-terminal-enhancements/spec.md`

**Related Documents**:
- [Feature Specification](./spec.md) - Requirements and user scenarios (FR-001 to FR-025, SC-001 to SC-010)
- [Research Findings](./research.md) - Installation methods and best practices
- [Data Model](./data-model.md) - Entity definitions
- [Task Breakdown](./tasks.md) - Implementation tasks (T001-T086)
- [Measurement Methods](./docs/measurement-methods.md) - Success criteria measurement procedures
- [Contracts](./contracts/) - Function signatures and tool installation contracts

## Summary

Enhancement of the workstation setup script to install and configure modern terminal tools (Starship prompt, fzf, bat, exa), enhanced aliases and functions, improved Bash history and completion, and visual terminal enhancements. The implementation follows Bash scripting best practices for idempotency, error handling, and user experience, ensuring all enhancements work seamlessly in both desktop and headless/server environments.

## Technical Context

**Language/Version**: Bash 5.2+ (Debian 13 default)  
**Primary Dependencies**:
- **Starship**: Binary installation via official installer script (`curl -sS https://starship.rs/install.sh | sh`) - single binary, no dependencies
- **fzf**: Available in Debian 13 APT (`apt install fzf`) or via GitHub binary
- **bat**: Available in Debian 13 APT (`apt install bat`) - installs as `batcat`, requires symlink `ln -s /usr/bin/batcat ~/.local/bin/bat`
- **exa**: Binary installation from GitHub releases (Rust-based, no system dependencies)
- **Git**: Already installed (dependency from workstation setup)
- **curl/wget**: Already installed (dependency from workstation setup) - required for downloading tool binaries

**Tool-Specific Prerequisites** (explicitly required per spec.md):
- `curl` or `wget` for downloading tool binaries (Starship, exa) - already in workstation setup
- `tar` or `unzip` for extracting tool binaries (standard Debian packages)
- `grep`, `sed`, `awk` for configuration processing (standard Debian packages)
- `bash` 5.2+ (default for Debian 13)
- `dpkg-query` for verifying APT package installations (fzf, bat)

**Storage**: File-based configuration:
- Shell configuration: `~/.bashrc` (user home directory)
- Starship configuration: `~/.config/starship.toml` (optional, user-configurable)
- Backup files: `~/.bashrc.backup.YYYYMMDD_HHMMSS` (timestamped backups)
- Tool binaries: System PATH locations (`/usr/local/bin/`, `~/.local/bin/`)

**Testing**:
- Integration tests: bats-core for end-to-end script execution
- Idempotency tests: Verify safe re-runs
- Functional tests: Verify tools are installed and configured correctly
- Test coverage: Critical installation and configuration functions
- Measurement tests: See `docs/measurement-methods.md` for success criteria measurement methods

**Target Platform**: Debian 13 (Trixie) - 64-bit amd64 architecture  
**Project Type**: Shell environment enhancement (additive to existing setup script)  
**Performance Goals**:
- Tool installation completes in < 2 minutes total
- Terminal startup time increases by < 100ms (SC-009)
- Fuzzy search responds in < 100ms (SC-002)
- File search responds in < 200ms for 10,000 files (SC-003)
- Tab completion provides suggestions in < 50ms (SC-007)

**Constraints**:
- Must be idempotent (safe to run multiple times)
- Must preserve existing user customizations in .bashrc
- Must handle installation failures gracefully (continue with remaining tools)
- Must work in both desktop (XFCE4) and headless/server environments
- Must not break existing terminal functionality if tools fail to install
- All tools must be installable without conflicting with system packages
- Must create backups before modifying .bashrc (format: `~/.bashrc.backup.YYYYMMDD_HHMMSS`)
- Must detect and skip conflicting aliases/functions with warning messages
- Must verify tool installations before configuring in .bashrc (FR-014)
- Must handle edge cases: backup failures, permission errors, network failures, disk space exhaustion, concurrent executions
- Must support rollback procedures (see spec.md Rollback Procedures section)

**Scale/Scope**:
- Single script enhancement (`scripts/setup-workstation.sh`)
- 4 core tools (Starship, fzf, bat, exa)
- ~15 aliases and functions
- Bash history and completion enhancements
- Visual enhancements (fonts, colors) - desktop only

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

✅ **Idempotency & Safety**:
- All installation functions check if tools are already installed before installing
- .bashrc modifications check for existing configuration markers before adding
- Backups created before any .bashrc modifications
- Installation failures don't break existing terminal functionality
- Uses `set -e` for error safety (inherited from parent script)
- All functions verify tool availability before configuring in .bashrc

✅ **Interactive UX**:
- Clear logging messages for installation progress
- Warning messages for skipped conflicts
- Error messages with recovery suggestions
- Visual feedback when tools are successfully installed

✅ **Aesthetic Excellence**:
- Starship prompt provides enhanced visual prompt with colors and Git awareness
- bat provides syntax highlighting for file viewing
- exa provides better directory listings with colors and icons
- All enhancements improve terminal aesthetics significantly

✅ **Mobile-First Optimization**:
- Font installation only in desktop environments (graceful degradation)
- Color schemes work in all environments (auto-detection)
- Not applicable for terminal-only enhancements (GUI enhancements are optional)

✅ **Clean Architecture**:
- Tools installed via official binaries or APT (no system pollution)
- User-specific configuration in home directory
- No system-wide modifications beyond tool binaries in standard locations
- Version managers not applicable (these are standalone tools)

✅ **Modularity**:
- Separate functions for each tool installation: `install_starship()`, `install_fzf()`, `install_bat()`, `install_exa()`
- Separate function for alias/function configuration: `configure_terminal_aliases()`
- Separate function for history/completion enhancements: `configure_bash_enhancements()`
- Separate function for visual enhancements: `configure_terminal_visuals()`
- Main orchestration function: `setup_terminal_enhancements()`

✅ **Target Platform**:
- All tools verified for Debian 13 (Trixie) compatibility
- fzf and bat available in APT repositories
- Starship and exa available as binaries (architecture-specific)
- Installation methods tested for Debian 13

**No violations** - All terminal enhancements align with constitution principles.

## Project Structure

### Documentation (this feature)

```text
specs/003-terminal-enhancements/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── docs/
│   └── measurement-methods.md  # Measurement methods for all success criteria
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── script-interface.md  # Function contracts for terminal enhancement functions
│   └── tool-installation.md # Installation and configuration contracts
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
scripts/
└── setup-workstation.sh  # Enhanced with terminal enhancement functions

tests/
├── integration/
│   └── test_terminal_enhancements.bats  # Integration tests for terminal enhancements
└── unit/
    └── test_terminal_config.bats  # Unit tests for configuration functions
```

**Structure Decision**: This is an enhancement to the existing single-script project structure. New functions are added to `scripts/setup-workstation.sh`, and new tests are added to the existing `tests/` directory structure. No new source directories are needed.

## Complexity Tracking

> **No violations** - All enhancements comply with constitution principles.

## Phase 0: Research & Best Practices

### Research Areas

1. **Starship Installation & Configuration**
   - Official installation method for Linux
   - Bash initialization best practices
   - Configuration file location and format
   - Performance optimization
   - Idempotency patterns

2. **fzf Installation & Key Bindings**
   - APT vs GitHub binary installation
   - Bash key binding configuration
   - Integration with existing history
   - Performance considerations
   - Ignore patterns configuration

3. **bat Installation & Configuration**
   - Debian package name (`bat` vs `batcat`)
   - Symlink creation for consistency
   - Alias configuration
   - Syntax highlighting support

4. **exa Installation**
   - Binary installation from GitHub releases
   - Architecture detection (amd64)
   - PATH configuration
   - Alternative if binary unavailable

5. **Bash Script Idempotency Patterns**
   - Checking tool installation status
   - Detecting existing aliases/functions
   - Backup creation patterns
   - Configuration marker detection

6. **Error Handling & Graceful Degradation**
   - Partial installation success patterns
   - Tool availability verification
   - Terminal capability detection
   - Fallback strategies

## Phase 1: Design & Contracts

### Data Model

See `data-model.md` for detailed entity definitions:
- **Terminal Configuration**: Shell environment state
- **Tool Installation**: Installation state and verification
- **Alias/Function Registry**: Conflict detection and management

### Contracts

See `contracts/` directory for:
- **script-interface.md**: Function signatures and contracts
- **tool-installation.md**: Installation and verification contracts

### Quick Start

See `quickstart.md` for user-facing quick start guide.

## Implementation Strategy

### Installation Order (Priority-based)

1. **Phase 1: Core Tools (P1)**
   - Starship prompt (highest visibility impact)
   - fzf (fundamental productivity tool)

2. **Phase 2: File Tools (P2)**
   - bat (file viewing enhancement)
   - exa (directory listing enhancement)

3. **Phase 3: Shell Enhancements (P2-P3)**
   - Aliases and functions
   - History improvements
   - Completion enhancements

4. **Phase 4: Visual Polish (P3)**
   - Font installation (desktop only)
   - Color scheme documentation

### Idempotency Strategy

1. **Tool Installation**:
   - Check if binary exists in PATH before installing using `command -v [tool] &>/dev/null`
   - Check package status for APT-installed tools using `dpkg-query -W -f='${Status}' "[package]" | grep -q "install ok installed"`
   - Skip installation if already present

2. **Configuration**:
   - Check for configuration marker in .bashrc: `# Terminal Enhancements Configuration - Added by setup-workstation.sh`
   - Create backup before modifications (format: `~/.bashrc.backup.YYYYMMDD_HHMMSS`)
   - Verify tool availability before configuring (FR-014 verification method)
   - Skip conflicting aliases/functions with warning (FR-021)

3. **Verification** (FR-014):
   - Verify each tool after installation using:
     - Binary check: `command -v [tool] &>/dev/null` for binary tools
     - Package check: `dpkg-query -W -f='${Status}' "[package]" | grep -q "install ok installed"` for APT-installed tools
   - Only configure tools that are successfully installed
   - Log warnings for failed installations with format: `[WARN] [terminal-enhancements] Failed to install [tool-name]. Continuing with remaining tools.`
   - Provide visual feedback for successful installations: `[INFO] [terminal-enhancements] ✓ [tool-name] installed and configured successfully` (FR-015)

### Error Handling Strategy

1. **Installation Failures** (FR-013, FR-022):
   - Continue with remaining tools (partial success)
   - Log clear error messages with format: `[WARN] [terminal-enhancements] Failed to install [tool-name]. Continuing with remaining tools.`
   - Don't configure failed tools in .bashrc
   - Partial success delivers value (if 3 out of 4 tools install, configure the 3 successful tools)

2. **Configuration Failures**:
   - Restore from backup if configuration fails
   - Log detailed error context with recovery suggestions
   - Don't break existing terminal functionality
   - **Backup failures**: Abort .bashrc modifications if backup creation fails. Error format: `[ERROR] [terminal-enhancements] Failed to create .bashrc backup, aborting configuration changes. Ensure write permissions to home directory.`

3. **Conflict Resolution** (FR-021):
   - Detect existing aliases/functions before adding
   - Skip conflicts with warning message format: `[WARN] [terminal-enhancements] Alias/function '[name]' already exists, skipping to preserve user customization.`
   - Preserve user customizations

4. **Edge Case Handling** (per spec.md Edge Cases):
   - **Permission errors**: Log error with recovery suggestion. Format: `[ERROR] [terminal-enhancements] Permission denied during [operation]. Ensure user has write permissions to [location]. Recovery: Check file permissions and user account privileges.`
   - **Network failures**: Continue with remaining tools. Format: `[ERROR] [terminal-enhancements] Network failure during [tool] download. Skipping [tool] installation. Remaining tools will continue installation.`
   - **Disk space exhaustion**: Abort installation. Format: `[ERROR] [terminal-enhancements] Disk space exhausted. Free at least 500MB and retry installation. Required space: ~50MB for tool binaries, ~30MB for downloads.`
   - **Concurrent executions**: Use file locking or check configuration marker. If marker exists, subsequent runs are idempotent and safe.
   - **Git not installed**: Detect Git availability before configuring Git features. Log warning: `[WARN] [terminal-enhancements] Git is not installed. Git-related features will be disabled.`
   - **Large history files**: Truncate to last 10,000 entries if > 100MB. Warning: `[WARN] [terminal-enhancements] History file exceeds 100MB, truncating to last 10,000 entries.`
   - **Font installation in headless**: Skip gracefully (no error logged). Only attempt in desktop environments (detected via `$DISPLAY` or `$XDG_SESSION_TYPE`).

### Integration Points

- **Existing Script**: `scripts/setup-workstation.sh`
- **Integration Function**: `setup_terminal_enhancements(username)` - main orchestration function
- **Call Site**: After `create_user_and_shell()` at line ~1472, before final verification
- **Dependencies**:
  - Git must be installed (already in workstation setup)
  - Tool-specific prerequisites: curl/wget, tar/unzip, grep/sed/awk, bash 5.2+, dpkg-query
  - User account must have write permissions to home directory

### Rollback Procedures

If configuration fails or user wants to revert terminal enhancements (per spec.md Rollback Procedures):

1. **Restore .bashrc from backup**: `cp ~/.bashrc.backup.YYYYMMDD_HHMMSS ~/.bashrc && source ~/.bashrc`
2. **Manual removal of Starship**: Remove `eval "$(starship init bash)"` line from .bashrc
3. **Uninstall tools** (optional): Remove binaries from `~/.local/bin/` or `/usr/local/bin/`
4. **Remove configuration marker**: Remove section starting with `# Terminal Enhancements Configuration - Added by setup-workstation.sh`

Backup files are preserved for 30 days or until disk space is needed.

### Non-Functional Requirements

Per spec.md Non-Functional Requirements section:

- **Security**: Tools are user-space only, no elevated privileges. All installations use official sources.
- **Accessibility**: Works with screen readers via standard terminal output. Color features auto-detect and degrade gracefully.
- **Resource Usage**: ~50MB disk space, < 10MB memory, ~30MB network download, < 100ms startup time increase
- **Scalability**: History files up to 100MB, directories with 10,000 files, 100 completions within 50ms
- **Performance**: Installation < 2 minutes, search < 100-200ms, completion < 50ms
- **Reliability**: 95% install success rate (SC-008), idempotent operations, graceful failure handling
- **Maintainability**: Modular function design, clear error messages, comprehensive logging, documentation

## Next Steps

1. Complete Phase 0 research (generate `research.md`)
2. Complete Phase 1 design (generate `data-model.md`, `contracts/`, `quickstart.md`)
3. Update agent context
4. Proceed to `/speckit.tasks` for task breakdown
