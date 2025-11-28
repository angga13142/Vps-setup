# Feature Specification: Terminal Enhancements & UI Improvements

**Feature Branch**: `003-terminal-enhancements`  
**Created**: 2025-11-28  
**Status**: Draft  
**Input**: User description: "Terminal Enhancements & UI Improvements: Add modern terminal tools (Starship, fzf, bat, exa), enhanced aliases, bash improvements, and visual enhancements to workstation setup script"

**Related Documents**:
- [Implementation Plan](./plan.md) - Technical implementation details and architecture
- [Research Findings](./research.md) - Best practices and installation methods
- [Data Model](./data-model.md) - Entity definitions and relationships
- [Task Breakdown](./tasks.md) - Actionable implementation tasks
- [Measurement Methods](./docs/measurement-methods.md) - Success criteria measurement procedures
- [Contracts](./contracts/) - Function and tool installation contracts
- [Quick Start Guide](./quickstart.md) - User-facing documentation

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enhanced Terminal Prompt & Information Display (Priority: P1)

As a developer using the workstation, I want a modern, informative terminal prompt that shows me relevant context (Git status, current directory, exit codes, environment info) so that I can work more efficiently without constantly running commands to check status.

**Why this priority**: The prompt is the most visible and frequently used part of the terminal experience. An informative prompt immediately improves productivity by reducing the need for manual status checks.

**Independent Test**: After workstation setup, open a terminal and verify the prompt displays Git branch information when in a repository, shows exit codes for failed commands, and provides clear visual indicators for current directory and system context. The test delivers immediate visual feedback that enhances the development workflow.

**Acceptance Scenarios**:

1. **Given** a fresh workstation installation, **When** a user opens a terminal, **Then** the prompt displays user@hostname, current directory, and Git branch (if in a repository) with color coding
2. **Given** a user is in a Git repository, **When** they run commands, **Then** the prompt shows the current branch name and indicates if there are uncommitted changes
3. **Given** a user runs a command that fails, **When** the command exits with non-zero status, **Then** the prompt clearly indicates the failure with visual feedback
4. **Given** a user is working with Python or Node.js projects, **When** they navigate to project directories, **Then** the prompt shows the active version of Python or Node.js if applicable

---

### User Story 2 - Fast File & History Search (Priority: P1)

As a developer, I want to quickly search through command history and find files using fuzzy search so that I can navigate and recall commands faster without typing full paths or scrolling through long history.

**Why this priority**: File and history search are fundamental operations performed dozens of times per day. Fast, intuitive search dramatically reduces time spent on routine navigation tasks.

**Independent Test**: After setup, verify that pressing Ctrl+R opens a fuzzy search interface for command history, and Ctrl+T opens a file finder. Test that both searches work quickly (< 100ms) and provide preview capabilities. The test delivers immediate productivity gains for daily terminal usage.

**Acceptance Scenarios**:

1. **Given** a user has command history, **When** they press Ctrl+R, **Then** a fuzzy search interface appears allowing them to search and select from previous commands
2. **Given** a user wants to find a file, **When** they press Ctrl+T, **Then** a file finder appears with fuzzy search and file preview
3. **Given** a user searches for commands or files, **When** they type partial matches, **Then** relevant results are displayed instantly with highlighting
4. **Given** a user is in a Git repository, **When** they use file search, **Then** Git-ignored files are excluded from results by default

---

### User Story 3 - Enhanced File Viewing & Listing (Priority: P2)

As a developer, I want syntax-highlighted file viewing and better directory listings so that I can read code and navigate filesystems more effectively with visual cues.

**Why this priority**: File viewing and listing are daily operations. Syntax highlighting and better visual organization reduce cognitive load and help developers understand code structure faster.

**Independent Test**: After setup, verify that viewing files shows syntax highlighting for common file types, and directory listings show file types, sizes, and permissions with color coding. Test that these enhancements work for common development file types (Python, JavaScript, Bash, Markdown, etc.). The test delivers improved readability and faster file comprehension.

**Acceptance Scenarios**:

1. **Given** a user views a code file, **When** they use the file viewing command, **Then** syntax highlighting is applied based on file type
2. **Given** a user lists directory contents, **When** they use the listing command, **Then** files are displayed with color coding, icons, and clear organization
3. **Given** a user is in a Git repository, **When** they list files, **Then** Git status indicators show which files are modified, staged, or untracked
4. **Given** a user views a large file, **When** they use the file viewer, **Then** the output is paginated with line numbers and navigation controls

---

### User Story 4 - Productivity Aliases & Functions (Priority: P2)

As a developer, I want convenient shortcuts for common Git, Docker, and system operations so that I can perform frequent tasks with fewer keystrokes and less typing.

**Why this priority**: Developers repeat many commands daily. Short, memorable aliases reduce typing errors and speed up common workflows, especially for Git and Docker operations.

**Independent Test**: After setup, verify that aliases for Git operations (gst, gco, gcm, gpl, gps), Docker operations (dc, dps, dlog), and utility functions (extract, mkcd, ports) are available and functional. Test that each alias performs the expected operation correctly. The test delivers immediate time savings for routine tasks.

**Acceptance Scenarios**:

1. **Given** a user is in a Git repository, **When** they type `gst`, **Then** Git status is displayed
2. **Given** a user wants to create and enter a directory, **When** they use the `mkcd` function, **Then** the directory is created and they are moved into it
3. **Given** a user has an archive file, **When** they use the `extract` function, **Then** the archive is extracted based on file type automatically
4. **Given** a user wants to check listening ports, **When** they type `ports`, **Then** a list of listening ports with processes is displayed

---

### User Story 5 - Improved Command History & Completion (Priority: P3)

As a developer, I want better command history management and tab completion so that I can recall and complete commands more efficiently without retyping or searching.

**Why this priority**: History and completion improvements provide incremental productivity gains. While less immediately visible than the prompt, they significantly improve the overall terminal experience over time.

**Independent Test**: After setup, verify that command history persists across sessions, includes timestamps, ignores duplicates, and has a larger size limit. Test that tab completion is case-insensitive and provides menu-style selection. The test delivers smoother command recall and completion workflows.

**Acceptance Scenarios**:

1. **Given** a user runs commands in a terminal session, **When** they close and reopen the terminal, **Then** previous command history is available
2. **Given** a user types a partial command, **When** they press Tab, **Then** case-insensitive completion suggestions appear
3. **Given** a user runs the same command multiple times, **When** they search history, **Then** duplicates are consolidated
4. **Given** a user wants to see when a command was run, **When** they view history with timestamps, **Then** each command shows the date and time it was executed

---

### User Story 6 - Visual Terminal Enhancements (Priority: P3)

As a developer, I want an aesthetically pleasing terminal with modern fonts and color schemes so that I can work comfortably for extended periods with reduced eye strain.

**Why this priority**: Visual enhancements improve long-term comfort and satisfaction. While not critical for functionality, they contribute to overall user experience and can reduce fatigue during long coding sessions.

**Independent Test**: After setup, verify that terminal fonts support programming ligatures (if desktop environment available), color schemes are applied consistently, and the overall visual appearance is modern and readable. Test that these enhancements work in both the terminal emulator and integrated terminal in IDEs. The test delivers improved visual comfort and professional appearance.

**Acceptance Scenarios**:

1. **Given** a desktop environment is available, **When** a user opens a terminal, **Then** modern fonts with ligature support are used if configured
2. **Given** terminal color schemes are configured, **When** a user views code or command output, **Then** colors are consistent and readable
3. **Given** a user works in low-light conditions, **When** they use the terminal, **Then** dark color schemes are available to reduce eye strain
4. **Given** a user prefers light themes, **When** they configure the terminal, **Then** light color schemes are available as an option

---

### Edge Cases

- **Tool Installation Failures**: What happens when a tool (Starship, fzf, bat, exa) fails to install or is unavailable? → System continues installing remaining tools and only configures successfully installed tools in .bashrc, logging warnings for failed installations. Error message format: `[WARN] [terminal-enhancements] Failed to install [tool-name]. Continuing with remaining tools.`

- **Alias/Function Conflicts**: How does the system handle conflicts with existing aliases or functions in user's .bashrc? → System skips conflicting aliases/functions and logs a warning, preserving user's existing customizations. Warning message format: `[WARN] [terminal-enhancements] Alias/function '[name]' already exists, skipping to preserve user customization.`

- **Existing Prompt Configurations**: What happens if the user already has custom prompt configurations? → System replaces existing PS1/PROMPT_COMMAND with Starship after creating backup, allowing restoration if needed. Restoration procedure: Users can restore previous prompt by copying backup file (`~/.bashrc.backup.YYYYMMDD_HHMMSS`) to `~/.bashrc` or manually removing Starship initialization and restoring PS1/PROMPT_COMMAND from backup.

- **Terminal Color Support**: How does the system handle terminal environments that don't support colors or advanced features? → Tools automatically detect terminal capabilities and disable color features gracefully, ensuring functionality works in all environments. Detection method: Tools check `$TERM` environment variable and ANSI escape sequence support.

- **Git Not Installed**: What happens when Git is not installed but Git-related prompt features are enabled? → System detects Git availability before configuring Git-related features. If Git is not installed, Starship prompt will not display Git status (graceful degradation), and Git aliases will not be added. System logs a warning message: `[WARN] [terminal-enhancements] Git is not installed. Git-related features will be disabled.`

- **Large History Files**: How does the system handle very large command history files? → System configures history size limit (HISTSIZE=10000) to prevent excessive memory usage. History files larger than 100MB are truncated to last 10,000 entries with a warning logged: `[WARN] [terminal-enhancements] History file exceeds 100MB, truncating to last 10,000 entries.`

- **Font Installation in Headless**: What happens if font installation fails in headless/server environments? → System skips font installation gracefully in headless environments. Font installation is only attempted in desktop environments (detected via `$DISPLAY` or `$XDG_SESSION_TYPE`). No error is logged for skipped font installation in headless environments.

- **.bashrc Backup Failures**: What happens if .bashrc backup creation fails? → System logs an error and aborts .bashrc modifications to prevent data loss. Error message format: `[ERROR] [terminal-enhancements] Failed to create .bashrc backup, aborting configuration changes. Ensure write permissions to home directory.`

- **Permission Errors**: What happens if permission errors occur during installation? → System logs an error with recovery suggestion. Error message format: `[ERROR] [terminal-enhancements] Permission denied during [operation]. Ensure user has write permissions to [location]. Recovery: Check file permissions and user account privileges.`

- **Network Failures**: What happens if network connectivity fails during tool downloads? → System logs an error and continues with remaining tools that don't require network. Error message format: `[ERROR] [terminal-enhancements] Network failure during [tool] download. Skipping [tool] installation. Remaining tools will continue installation.`

- **Disk Space Exhaustion**: What happens if disk space is exhausted during installation? → System logs an error and aborts installation. Error message format: `[ERROR] [terminal-enhancements] Disk space exhausted. Free at least 500MB and retry installation. Required space: ~50MB for tool binaries, ~30MB for downloads.`

- **Concurrent Script Executions**: What happens if the script is run concurrently? → System uses file locking mechanism (if available) or checks for existing configuration marker. If configuration marker exists, subsequent runs are idempotent and safe. Configuration marker format: `# Terminal Enhancements Configuration - Added by setup-workstation.sh`

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST install and configure Starship prompt to display user context, directory, Git status, and exit codes. Installation method: Official installer script (`curl -sS https://starship.rs/install.sh | sh`). Configuration: Add `eval "$(starship init bash)"` to .bashrc after creating backup.

- **FR-002**: System MUST install fzf and configure keyboard shortcuts (Ctrl+R for history, Ctrl+T for files). Installation method: APT (`apt install fzf`) or GitHub binary. Key bindings: `bind -x '"\C-r": fzf-history-widget'` and `bind -x '"\C-t": fzf-file-widget'`.

- **FR-003**: System MUST install bat (or batcat) and configure it as an enhanced file viewer with syntax highlighting. Installation method: APT (`apt install bat`) - installs as `batcat`, requires symlink `ln -s /usr/bin/batcat ~/.local/bin/bat`. Enhanced features: Syntax highlighting for 10+ file types (Python, JavaScript, Bash, Markdown, JSON, YAML, XML, HTML, CSS, SQL), line numbers, Git integration, paging support.

- **FR-004**: System MUST install exa and provide it as an enhanced directory listing tool with Git integration. Installation method: Binary from GitHub releases. Enhanced features: Color-coded file types, icons, Git status indicators (modified, staged, untracked), tree view, detailed file information.

- **FR-005**: System MUST add Git aliases (gst, gco, gcm, gpl, gps) that work in any Git repository. Aliases: `gst` (git status), `gco` (git checkout), `gcm` (git commit -m), `gpl` (git pull), `gps` (git push). These aliases work in any Git repository where Git is installed and the directory is a Git repository (detected by presence of `.git` directory). The aliases support all standard Git operations: status checking, branch operations, commits, and remote operations (pull/push).

- **FR-006**: System MUST add Docker aliases (dc, dps, dlog) for specified container operations. Aliases: `dc` (docker-compose), `dps` (docker ps), `dlog` (docker logs). These aliases provide shortcuts for common Docker container management operations.
- **FR-007**: System MUST add utility functions (mkcd, extract, ports, weather) that are available in all terminal sessions. Function categories: Directory management (mkcd), archive extraction (extract), system monitoring (ports), external service integration (weather). These functions persist across terminal sessions via .bashrc configuration.
- **FR-024**: System MUST implement weather function to display clear error message when external service (wttr.in) is unavailable, rather than failing silently or hanging. Error message format: `[ERROR] [weather] Weather service unavailable. Check internet connection or try again later.`
- **FR-008**: System MUST configure command history to persist across sessions with timestamps and duplicate removal
- **FR-009**: System MUST enhance tab completion to be case-insensitive with menu-style selection
- **FR-010**: System MUST configure history size to accommodate at least 10,000 commands
- **FR-011**: System MUST preserve existing user customizations in .bashrc when adding new configurations
- **FR-021**: System MUST skip installation of aliases or functions that conflict with existing user-defined aliases/functions and log a warning message. Warning message format: `[WARN] [terminal-enhancements] Alias/function '[name]' already exists, skipping to preserve user customization.`
- **FR-012**: System MUST create backups of .bashrc before making modifications
- **FR-023**: System MUST replace existing PS1/PROMPT_COMMAND configurations with Starship prompt after creating backup, allowing users to restore previous prompt if needed. Restoration procedure: Users can restore previous prompt by copying backup file (`~/.bashrc.backup.YYYYMMDD_HHMMSS`) to `~/.bashrc` or manually removing Starship initialization and restoring PS1/PROMPT_COMMAND from backup.
- **FR-013**: System MUST handle installation failures gracefully without breaking existing terminal functionality
- **FR-022**: System MUST continue installing remaining tools even if one or more tools fail to install, ensuring partial success delivers value. Success criteria: Partial success is quantified by SC-008 (95% install success rate). If 3 out of 4 tools install successfully, the system delivers value by configuring the 3 successful tools.
- **FR-014**: System MUST verify tool installations before configuring them in .bashrc. Verification method: Check if tool binary exists in PATH using `command -v [tool] &>/dev/null` or verify package installation status for APT-installed tools using `dpkg-query -W -f='${Status}' "[package]" | grep -q "install ok installed"`.

- **FR-015**: System MUST provide clear visual feedback when tools are successfully installed and configured. Feedback format: `[INFO] [terminal-enhancements] ✓ [tool-name] installed and configured successfully`. Visual indicators: Checkmark (✓) for success, clear status messages with tool names.

- **FR-016**: System MUST support both desktop and headless/server environments appropriately. Behavior differences: Desktop environments enable font installation and visual enhancements (detected via `$DISPLAY` or `$XDG_SESSION_TYPE`); headless environments skip font installation and rely on terminal auto-detection for color support. All core functionality works in both environments.
- **FR-025**: System MUST ensure tools automatically detect terminal color capabilities and disable color features gracefully when terminal doesn't support colors or ANSI escape sequences
- **FR-017**: System MUST configure fzf to exclude common ignore patterns (node_modules, .git) from file search
- **FR-018**: System MUST ensure all aliases and functions are idempotent (safe to run multiple times)
- **FR-019**: System MUST document all added aliases and functions for user reference. Documentation format: Comments in .bashrc above each alias/function group, and a reference section in `quickstart.md` with usage examples. Documentation location: Inline comments in .bashrc and `specs/003-terminal-enhancements/quickstart.md`.

- **FR-020**: System MUST configure Starship prompt to show Python/Node.js versions when in project directories. Detection criteria: Starship automatically detects project directories by presence of version files (e.g., `package.json`, `requirements.txt`, `pyproject.toml`, `.python-version`, `.node-version`). Starship's built-in Python and Node.js modules handle this detection automatically.

### Key Entities *(include if feature involves data)*

- **Terminal Configuration**: Represents the shell environment setup including prompt, aliases, functions, and history settings. Key attributes: prompt format, alias definitions, function definitions, history size and behavior, completion settings.
- **Tool Installation**: Represents the installation state of terminal enhancement tools. Key attributes: tool name, installation method, version, configuration status, availability in PATH.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can see Git branch information in the prompt within 1 second of opening a terminal in a repository
- **SC-002**: Users can search and select from command history in under 100ms using fuzzy search
- **SC-003**: Users can find files using fuzzy search in under 200ms for directories with up to 10,000 files
- **SC-004**: Users can view code files with syntax highlighting for at least 10 common file types (Python, JavaScript, Bash, Markdown, JSON, YAML, XML, HTML, CSS, SQL)
- **SC-005**: Users can perform common Git operations using aliases with 50% fewer keystrokes compared to full commands
- **SC-006**: Command history persists across at least 10 terminal sessions without data loss
- **SC-007**: Tab completion provides suggestions within 50ms for commands with up to 100 possible completions
- **SC-008**: All terminal enhancements install successfully on 95% of fresh Debian 13 installations
- **SC-009**: Terminal startup time increases by less than 100ms compared to baseline configuration
- **SC-010**: Users can access all new aliases and functions immediately after workstation setup without manual configuration

## Assumptions

- Users are working in a Bash shell environment (default for Debian)
- Git is installed and available (already part of workstation setup)
- Users have internet access for downloading tools during installation
- Desktop environment (XFCE4) is available for font and visual enhancements, but features degrade gracefully in headless environments
- Users may have existing .bashrc customizations that should be preserved
- All tools are available in Debian 13 repositories or can be installed via official binaries
- Terminal emulator supports color output and basic ANSI escape sequences
- Users are familiar with basic terminal usage and Git operations

## Dependencies

- Existing workstation setup script (`setup-workstation.sh`) must be functional
- Git must be installed (already included in workstation setup)
- Internet connectivity required for tool downloads during installation
- Package manager (apt) must be functional and have access to repositories
- User account must have write permissions to home directory for .bashrc modifications
- **Tool-specific prerequisites** (explicitly required):
  - `curl` or `wget` for downloading tool binaries (Starship, exa) - already in workstation setup
  - `tar` or `unzip` for extracting tool binaries (standard Debian packages)
  - `grep`, `sed`, `awk` for configuration processing (standard Debian packages)
  - `bash` 5.2+ (default for Debian 13)
  - `dpkg-query` for verifying APT package installations (fzf, bat)

## Clarifications

### Session 2025-11-28

- Q: When a user already has an alias/function with the same name (e.g., `gst`, `mkcd`), what should the system do? → A: Skip conflicting aliases/functions and log a warning (preserve user's customizations)
- Q: If one tool fails to install (e.g., Starship fails but fzf succeeds), should the system continue installing remaining tools or abort? → A: Continue installing remaining tools (partial success is acceptable)
- Q: If a user already has a custom PS1 prompt configured in .bashrc, should Starship replace it, coexist with it, or skip installation? → A: Replace existing prompt with Starship after creating backup (user can restore if needed)
- Q: If the weather function cannot reach wttr.in (service down, no internet, firewall), what should happen when a user calls it? → A: Display clear error message indicating service unavailable
- Q: When a terminal doesn't support colors or ANSI escape sequences, should tools disable color features automatically or fail gracefully? → A: Automatically detect and disable color features (tools handle gracefully)

## Rollback Procedures

If configuration fails or user wants to revert terminal enhancements:

1. **Restore .bashrc from backup**:
   ```bash
   cp ~/.bashrc.backup.YYYYMMDD_HHMMSS ~/.bashrc
   source ~/.bashrc
   ```

2. **Manual removal of Starship**:
   - Remove line containing `eval "$(starship init bash)"` from .bashrc
   - Restore previous PS1/PROMPT_COMMAND from backup if needed

3. **Uninstall tools** (optional):
   - Starship: `rm ~/.local/bin/starship` or `rm /usr/local/bin/starship`
   - fzf: `apt remove fzf` (if installed via APT)
   - bat: `apt remove bat` (if installed via APT)
   - exa: `rm ~/.local/bin/exa` or `rm /usr/local/bin/exa`

4. **Remove aliases and functions**:
   - Remove configuration marker section from .bashrc: `# Terminal Enhancements Configuration - Added by setup-workstation.sh`
   - Remove all alias and function definitions added by the script

**Note**: Backup files are preserved for 30 days or until disk space is needed. Users can restore from any backup file using the timestamp in the filename.

## Non-Functional Requirements

### Security
- No security requirements beyond standard workstation setup (tools are user-space only, no elevated privileges required)
- All tool installations use official sources (Starship official installer, Debian APT repositories, GitHub official releases)
- No network services exposed by terminal enhancements
- User-specific configuration files have standard permissions (600 for .bashrc backups)

### Accessibility
- Terminal enhancements work with screen readers via standard terminal output
- Color features auto-detect terminal capabilities and degrade gracefully
- No additional accessibility requirements beyond standard terminal accessibility
- All tools support standard terminal interfaces (no GUI dependencies)

### Resource Usage
- **Disk Space**: ~50MB for all tool binaries (Starship ~15MB, fzf ~5MB, bat ~10MB, exa ~20MB)
- **Memory**: Negligible impact (< 10MB for tool processes during active use)
- **Network**: One-time download during installation (~30MB total for all tool downloads)
- **Startup Time**: Terminal startup time increases by less than 100ms (SC-009)
- **History Files**: History files up to 100MB are supported (truncated to last 10,000 entries if larger)
- **Directory Size**: System handles directories with up to 10,000 files efficiently (SC-003)

### Scalability
- History files up to 100MB are supported (truncated to last 10,000 entries if larger)
- System handles directories with up to 10,000 files efficiently for file search (SC-003)
- Tab completion handles up to 100 possible completions within 50ms (SC-007)
- Command history supports at least 10,000 commands (FR-010)

### Performance
- Tool installation completes in < 2 minutes total
- Terminal startup time increases by < 100ms (SC-009)
- Fuzzy search responds in < 100ms (SC-002)
- File search responds in < 200ms for 10,000 files (SC-003)
- Tab completion provides suggestions in < 50ms (SC-007)

### Reliability
- Installation success rate: 95% of fresh Debian 13 installations (SC-008)
- All tools must be idempotent (safe to run multiple times)
- Installation failures don't break existing terminal functionality
- Partial installation success delivers value (FR-022)

### Maintainability
- Modular function design (separate functions for each tool)
- Clear error messages with recovery suggestions
- Comprehensive logging for troubleshooting
- Documentation for all aliases and functions

## Out of Scope

- Migration from other shells (Zsh, Fish) - focuses on Bash enhancements only
- Custom terminal emulator installation - uses system default
- Advanced tool configurations beyond basic setup - users can customize further
- IDE-specific terminal configurations - handled separately in IDE proposal
- Remote terminal access setup - out of scope for this feature
- Terminal multiplexer setup (tmux, screen) - may be included in future enhancements
