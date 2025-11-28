# Tasks: Terminal Enhancements & UI Improvements

**Input**: Design documents from `/specs/003-terminal-enhancements/`  
**Prerequisites**: [plan.md](./plan.md) ✅, [spec.md](./spec.md) ✅, [research.md](./research.md) ✅, [data-model.md](./data-model.md) ✅, [contracts/](./contracts/) ✅

**Related Documents**:
- [Feature Specification](./spec.md) - Requirements (FR-001 to FR-025) and Success Criteria (SC-001 to SC-010)
- [Implementation Plan](./plan.md) - Technical context and architecture
- [Measurement Methods](./docs/measurement-methods.md) - Success criteria measurement procedures

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., [US1], [US2], [US3])
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and preparation for terminal enhancements

- [X] T001 [P] Create helper function `check_alias_conflict()` in scripts/setup-workstation.sh for detecting existing aliases (returns 0 if conflict exists, 1 if not)
- [X] T002 [P] Create helper function `check_function_conflict()` in scripts/setup-workstation.sh for detecting existing functions (returns 0 if conflict exists, 1 if not)
- [X] T003 [P] Create helper function `create_bashrc_backup()` in scripts/setup-workstation.sh for creating timestamped backups with format `~/.bashrc.backup.YYYYMMDD_HHMMSS` (FR-012). Function must abort if backup creation fails with error: `[ERROR] [terminal-enhancements] Failed to create .bashrc backup, aborting configuration changes. Ensure write permissions to home directory.`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Create main orchestration function `setup_terminal_enhancements(username)` in scripts/setup-workstation.sh with configuration marker check (marker format: `# Terminal Enhancements Configuration - Added by setup-workstation.sh`)
- [X] T005 Integrate `setup_terminal_enhancements()` call in main() function after `create_user_and_shell()` call (line ~1472) in scripts/setup-workstation.sh
- [X] T087 [P] Add tool-specific prerequisites verification in `setup_terminal_enhancements()` function in scripts/setup-workstation.sh: verify curl/wget, tar/unzip, grep/sed/awk, bash 5.2+, dpkg-query are available
- [X] T088 [P] Add Git availability detection in `setup_terminal_enhancements()` function in scripts/setup-workstation.sh: check if Git is installed before configuring Git-related features, log warning if not: `[WARN] [terminal-enhancements] Git is not installed. Git-related features will be disabled.`

**Checkpoint**: Foundation ready - main function structure in place. User story implementation can now begin.

---

## Phase 3: User Story 1 - Enhanced Terminal Prompt & Information Display (Priority: P1) 🎯 MVP

**Goal**: Install and configure Starship prompt to display user context, directory, Git status, exit codes, and Python/Node.js versions when in project directories.

**Independent Test**: After workstation setup, open a terminal and verify the prompt displays Git branch information when in a repository, shows exit codes for failed commands, and provides clear visual indicators for current directory and system context. The test delivers immediate visual feedback that enhances the development workflow.

### Implementation for User Story 1

- [X] T006 [US1] Create `install_starship()` function in scripts/setup-workstation.sh with idempotency check using `command -v starship &>/dev/null` (FR-014 verification method)
- [X] T007 [US1] Implement Starship installation via official installer script (`curl -sS https://starship.rs/install.sh | sh`) in `install_starship()` function in scripts/setup-workstation.sh with error handling: continue on failure, log error with format `[WARN] [terminal-enhancements] Failed to install starship. Continuing with remaining tools.`, return error code (FR-013, FR-022)
- [X] T008 [US1] Add Starship installation verification using `command -v starship &>/dev/null` and visual feedback with format `[INFO] [terminal-enhancements] ✓ starship installed and configured successfully` in `install_starship()` function in scripts/setup-workstation.sh (FR-014, FR-015)
- [X] T009 [US1] Create `configure_starship_prompt(username)` function in scripts/setup-workstation.sh with backup creation before modification
- [X] T010 [US1] Implement backup creation in `configure_starship_prompt()` function using `create_bashrc_backup()` in scripts/setup-workstation.sh
- [X] T011 [US1] Implement existing PS1/PROMPT_COMMAND removal in `configure_starship_prompt()` function in scripts/setup-workstation.sh
- [X] T012 [US1] Add Starship initialization (`eval "$(starship init bash)"`) to .bashrc in `configure_starship_prompt()` function in scripts/setup-workstation.sh
- [X] T013 [US1] Add configuration marker check for Starship in `configure_starship_prompt()` function in scripts/setup-workstation.sh
- [X] T014 [US1] Call `install_starship()` and `configure_starship_prompt()` from `setup_terminal_enhancements()` function in scripts/setup-workstation.sh with error handling (only configure if installation successful)
- [X] T015 [US1] Verify Starship shows Python/Node.js versions when in project directories (FR-020) - verify Starship default config includes python and nodejs modules or add explicit configuration

**Checkpoint**: At this point, User Story 1 should be fully functional. Starship prompt is installed and configured, displaying Git status, exit codes, and environment info. Users can see immediate visual feedback in their terminal.

---

## Phase 4: User Story 2 - Fast File & History Search (Priority: P1)

**Goal**: Install and configure fzf (fuzzy finder) with keyboard shortcuts (Ctrl+R for history, Ctrl+T for files) and ignore patterns for Git repositories.

**Independent Test**: After setup, verify that pressing Ctrl+R opens a fuzzy search interface for command history, and Ctrl+T opens a file finder. Test that both searches work quickly (< 100ms) and provide preview capabilities. The test delivers immediate productivity gains for daily terminal usage.

### Implementation for User Story 2

- [X] T016 [US2] Create `install_fzf()` function in scripts/setup-workstation.sh with idempotency check using `dpkg-query -W -f='${Status}' "fzf" | grep -q "install ok installed"` (FR-014 verification method)
- [X] T017 [US2] Implement fzf installation via APT (`sudo apt install -y fzf`) in `install_fzf()` function in scripts/setup-workstation.sh with error handling: continue on failure, log error with format `[WARN] [terminal-enhancements] Failed to install fzf. Continuing with remaining tools.`, return error code (FR-013, FR-022)
- [X] T018 [US2] Add fzf installation verification using `command -v fzf &>/dev/null` and visual feedback with format `[INFO] [terminal-enhancements] ✓ fzf installed and configured successfully` in `install_fzf()` function in scripts/setup-workstation.sh (FR-014, FR-015)
- [X] T019 [US2] Create `configure_fzf_key_bindings(username)` function in scripts/setup-workstation.sh with configuration marker check
- [X] T020 [US2] Add fzf key bindings (`eval "$(fzf --bash)"`) to .bashrc in `configure_fzf_key_bindings()` function in scripts/setup-workstation.sh
- [X] T021 [US2] Configure FZF_DEFAULT_OPTS environment variable in `configure_fzf_key_bindings()` function in scripts/setup-workstation.sh
- [X] T022 [US2] Configure FZF_CTRL_T_COMMAND with ignore patterns (node_modules, .git) in `configure_fzf_key_bindings()` function in scripts/setup-workstation.sh (FR-017)
- [X] T023 [US2] Call `install_fzf()` and `configure_fzf_key_bindings()` from `setup_terminal_enhancements()` function in scripts/setup-workstation.sh with error handling (only configure if installation successful)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. Users can use fuzzy search for history and files, dramatically improving navigation efficiency.

---

## Phase 5: User Story 3 - Enhanced File Viewing & Listing (Priority: P2)

**Goal**: Install and configure bat (better cat) and exa (modern ls) for syntax-highlighted file viewing and better directory listings with Git integration.

**Independent Test**: After setup, verify that viewing files shows syntax highlighting for common file types, and directory listings show file types, sizes, and permissions with color coding. Test that these enhancements work for common development file types (Python, JavaScript, Bash, Markdown, etc.). The test delivers improved readability and faster file comprehension.

### Implementation for User Story 3

- [X] T024 [P] [US3] Create `install_bat()` function in scripts/setup-workstation.sh with idempotency check using `dpkg-query -W -f='${Status}' "bat" | grep -q "install ok installed"` (FR-014 verification method)
- [X] T025 [P] [US3] Create `install_exa()` function in scripts/setup-workstation.sh with idempotency check using `command -v exa &>/dev/null` (FR-014 verification method)
- [X] T026 [US3] Implement bat installation via APT (`sudo apt install -y bat`) in `install_bat()` function in scripts/setup-workstation.sh with error handling: continue on failure, log error with format `[WARN] [terminal-enhancements] Failed to install bat. Continuing with remaining tools.`, return error code (FR-013, FR-022)
- [X] T027 [US3] Create symlink `bat → batcat` in ~/.local/bin/ in `install_bat()` function in scripts/setup-workstation.sh (Note: batcat is Debian package name, bat is symlink alias for consistency)
- [X] T028 [US3] Ensure ~/.local/bin exists and is in PATH before creating symlink in `install_bat()` function in scripts/setup-workstation.sh
- [X] T029 [US3] Add bat installation verification using `command -v batcat &>/dev/null` and symlink check, and visual feedback with format `[INFO] [terminal-enhancements] ✓ bat installed and configured successfully` in `install_bat()` function in scripts/setup-workstation.sh (FR-014, FR-015)
- [X] T030 [US3] Implement exa binary download from GitHub releases in `install_exa()` function in scripts/setup-workstation.sh with error handling: continue on failure, log error with format `[ERROR] [terminal-enhancements] Network failure during exa download. Skipping exa installation. Remaining tools will continue installation.`, return error code (FR-013, FR-022, Edge Cases: Network Failures)
- [X] T031 [US3] Implement exa binary extraction and installation to /usr/local/bin/exa in `install_exa()` function in scripts/setup-workstation.sh with error handling: check disk space (abort if < 500MB free), log error with format `[ERROR] [terminal-enhancements] Disk space exhausted. Free at least 500MB and retry installation.` if space insufficient (Edge Cases: Disk Space Exhaustion)
- [X] T032 [US3] Add exa installation verification using `command -v exa &>/dev/null` and visual feedback with format `[INFO] [terminal-enhancements] ✓ exa installed and configured successfully` in `install_exa()` function in scripts/setup-workstation.sh (FR-014, FR-015)
- [X] T033 [US3] Add bat alias (`alias cat='bat'` or `alias cat='batcat'`) to .bashrc in `configure_terminal_aliases()` function in scripts/setup-workstation.sh
- [X] T034 [US3] Add exa aliases (`alias ls='exa'`, `alias ll='exa -lah'`) to .bashrc in `configure_terminal_aliases()` function in scripts/setup-workstation.sh
- [X] T035 [US3] Call `install_bat()` and `install_exa()` from `setup_terminal_enhancements()` function in scripts/setup-workstation.sh with error handling (only configure if installation successful)

**Checkpoint**: At this point, User Stories 1, 2, AND 3 should all work independently. Users can view files with syntax highlighting and use better directory listings with Git integration.

---

## Phase 6: User Story 4 - Productivity Aliases & Functions (Priority: P2)

**Goal**: Add convenient shortcuts for common Git, Docker, and system operations with conflict detection to preserve user customizations.

**Independent Test**: After setup, verify that aliases for Git operations (gst, gco, gcm, gpl, gps), Docker operations (dc, dps, dlog), and utility functions (extract, mkcd, ports) are available and functional. Test that each alias performs the expected operation correctly. The test delivers immediate time savings for routine tasks.

### Implementation for User Story 4

- [ ] T036 [US4] Create `configure_terminal_aliases(username)` function in scripts/setup-workstation.sh with configuration marker check
- [ ] T037 [US4] Implement conflict detection for Git aliases (gst, gco, gcm, gpl, gps) using `check_alias_conflict()` in `configure_terminal_aliases()` function in scripts/setup-workstation.sh
- [ ] T038 [US4] Add Git aliases (gst, gco, gcm, gpl, gps) to .bashrc with conflict detection in `configure_terminal_aliases()` function in scripts/setup-workstation.sh (FR-005)
- [ ] T039 [US4] Implement conflict detection for Docker aliases (dc, dps, dlog) using `check_alias_conflict()` in `configure_terminal_aliases()` function in scripts/setup-workstation.sh
- [ ] T040 [US4] Add Docker aliases (dc, dps, dlog) to .bashrc with conflict detection in `configure_terminal_aliases()` function in scripts/setup-workstation.sh (FR-006)
- [ ] T041 [US4] Create `configure_terminal_functions(username)` function in scripts/setup-workstation.sh with configuration marker check
- [ ] T042 [US4] Implement conflict detection for utility functions (mkcd, extract, ports, weather) using `check_function_conflict()` in `configure_terminal_functions()` function in scripts/setup-workstation.sh
- [ ] T043 [US4] Add mkcd() function to .bashrc with conflict detection in `configure_terminal_functions()` function in scripts/setup-workstation.sh
- [ ] T044 [US4] Add extract() function to .bashrc with conflict detection in `configure_terminal_functions()` function in scripts/setup-workstation.sh
- [ ] T045 [US4] Add ports() function to .bashrc with conflict detection in `configure_terminal_functions()` function in scripts/setup-workstation.sh
- [ ] T046 [US4] Add weather() function with error handling for wttr.in unavailability to .bashrc in `configure_terminal_functions()` function in scripts/setup-workstation.sh with error message format: `[ERROR] [weather] Weather service unavailable. Check internet connection or try again later.` (FR-024)
- [ ] T047 [US4] Add warning logging for skipped aliases/functions due to conflicts in `configure_terminal_aliases()` and `configure_terminal_functions()` functions in scripts/setup-workstation.sh with format: `[WARN] [terminal-enhancements] Alias/function '[name]' already exists, skipping to preserve user customization.` (FR-021)
- [ ] T048 [US4] Call `configure_terminal_aliases()` and `configure_terminal_functions()` from `setup_terminal_enhancements()` function in scripts/setup-workstation.sh

**Checkpoint**: At this point, User Stories 1, 2, 3, AND 4 should all work independently. Users have convenient shortcuts for common operations, reducing keystrokes by 50% for Git operations.

---

## Phase 7: User Story 5 - Improved Command History & Completion (Priority: P3)

**Goal**: Configure Bash history to persist across sessions with timestamps, duplicate removal, and enhanced tab completion with case-insensitive menu-style selection.

**Independent Test**: After setup, verify that command history persists across sessions, includes timestamps, ignores duplicates, and has a larger size limit. Test that tab completion is case-insensitive and provides menu-style selection. The test delivers smoother command recall and completion workflows.

### Implementation for User Story 5

- [ ] T049 [US5] Create `configure_bash_enhancements(username)` function in scripts/setup-workstation.sh with configuration marker check
- [ ] T050 [US5] Add HISTSIZE=10000 environment variable to .bashrc in `configure_bash_enhancements()` function in scripts/setup-workstation.sh (FR-010)
- [ ] T089 [US5] Add history file size check and truncation logic in `configure_bash_enhancements()` function in scripts/setup-workstation.sh: if history file > 100MB, truncate to last 10,000 entries and log warning: `[WARN] [terminal-enhancements] History file exceeds 100MB, truncating to last 10,000 entries.` (Edge Cases: Large History Files)
- [ ] T051 [US5] Add HISTFILESIZE=20000 environment variable to .bashrc in `configure_bash_enhancements()` function in scripts/setup-workstation.sh
- [ ] T052 [US5] Add HISTCONTROL=ignoreboth:erasedups environment variable to .bashrc in `configure_bash_enhancements()` function in scripts/setup-workstation.sh
- [ ] T053 [US5] Add shopt -s histappend to .bashrc in `configure_bash_enhancements()` function in scripts/setup-workstation.sh
- [ ] T054 [US5] Add HISTTIMEFORMAT="%F %T " environment variable to .bashrc in `configure_bash_enhancements()` function in scripts/setup-workstation.sh (FR-008)
- [ ] T055 [US5] Add case-insensitive completion binding (bind 'set completion-ignore-case on') to .bashrc in `configure_bash_enhancements()` function in scripts/setup-workstation.sh (FR-009)
- [ ] T056 [US5] Add menu-style completion binding (bind 'set show-all-if-ambiguous on') to .bashrc in `configure_bash_enhancements()` function in scripts/setup-workstation.sh (FR-009)
- [ ] T057 [US5] Add menu completion display prefix binding (bind 'set menu-complete-display-prefix on') to .bashrc in `configure_bash_enhancements()` function in scripts/setup-workstation.sh
- [ ] T058 [US5] Call `configure_bash_enhancements()` from `setup_terminal_enhancements()` function in scripts/setup-workstation.sh

**Checkpoint**: At this point, User Stories 1-5 should all work independently. Users have improved history management and tab completion, enhancing overall terminal productivity.

---

## Phase 8: User Story 6 - Visual Terminal Enhancements (Priority: P3)

**Goal**: Install modern fonts (if desktop environment available) and document color scheme options for improved visual comfort and professional appearance.

**Independent Test**: After setup, verify that terminal fonts support programming ligatures (if desktop environment available), color schemes are applied consistently, and the overall visual appearance is modern and readable. Test that these enhancements work in both the terminal emulator and integrated terminal in IDEs. The test delivers improved visual comfort and professional appearance.

### Implementation for User Story 6

- [ ] T059 [US6] Create `configure_terminal_visuals(username)` function in scripts/setup-workstation.sh with desktop environment detection
- [ ] T060 [US6] Add desktop environment detection (check `$DISPLAY` or `$XDG_SESSION_TYPE`) in `configure_terminal_visuals()` function in scripts/setup-workstation.sh (FR-016)
- [ ] T061 [US6] Install fonts-firacode package via APT if desktop environment detected in `configure_terminal_visuals()` function in scripts/setup-workstation.sh (skip gracefully in headless, no error logged) (FR-016, Edge Cases: Font Installation in Headless)
- [ ] T062 [US6] Add graceful degradation for font installation failures in headless environments in `configure_terminal_visuals()` function in scripts/setup-workstation.sh: skip font installation if headless detected, no error logged (FR-016, Edge Cases: Font Installation in Headless)
- [ ] T063 [US6] Document color scheme options (Dracula, Nord, One Dark Pro, Solarized Dark) in quickstart.md or README.md
- [ ] T064 [US6] Verify tools (Starship, bat, exa) auto-detect terminal color capabilities in `configure_terminal_visuals()` function comments in scripts/setup-workstation.sh (FR-025)
- [ ] T065 [US6] Call `configure_terminal_visuals()` from `setup_terminal_enhancements()` function in scripts/setup-workstation.sh

**Checkpoint**: At this point, all user stories should be complete. Visual enhancements improve long-term comfort, and all features work in both desktop and headless environments.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Error handling, verification, documentation, and integration improvements

- [ ] T066 [P] Verify error handling implementation in all install functions (T007, T017, T026, T030-T031) - ensure continue on failure pattern is correctly implemented with error format: `[WARN] [terminal-enhancements] Failed to install [tool-name]. Continuing with remaining tools.` (FR-022)
- [ ] T067 [P] Verify tool verification before configuration is implemented in `setup_terminal_enhancements()` function - ensure verification uses FR-014 methods: `command -v [tool] &>/dev/null` for binaries, `dpkg-query -W -f='${Status}' "[package]" | grep -q "install ok installed"` for APT packages, and only successfully installed tools are configured (FR-014)
- [ ] T068 [P] Verify visual feedback (success messages) are present in all install/configure functions (T008, T018, T029, T032) - ensure format: `[INFO] [terminal-enhancements] ✓ [tool-name] installed and configured successfully` (FR-015)
- [ ] T069 [P] Verify all functions handle installation failures gracefully without breaking existing terminal functionality - test failure scenarios including network failures, permission errors, disk space exhaustion (FR-013, Edge Cases)
- [ ] T070 [P] Verify idempotency of all installation and configuration functions (safe to run multiple times) in scripts/setup-workstation.sh - test concurrent execution scenario: check configuration marker exists, subsequent runs are idempotent and safe (FR-018, Edge Cases: Concurrent Script Executions)
- [ ] T071 [P] Document all added aliases and functions in quickstart.md with usage examples and add inline comments in .bashrc above each alias/function group (FR-019: documentation format and location)
- [ ] T072 [P] Add configuration marker `# Terminal Enhancements Configuration - Added by setup-workstation.sh` to .bashrc after all configurations are applied in `setup_terminal_enhancements()` function in scripts/setup-workstation.sh (used for idempotency and concurrent execution detection)
- [ ] T073 [P] Verify .bashrc file ownership and permissions are set correctly after modifications in all configure functions in scripts/setup-workstation.sh (permissions: 600 for backup files per spec.md Non-Functional Requirements)
- [ ] T074 [P] Test terminal startup time increase is < 100ms compared to baseline in scripts/setup-workstation.sh (SC-009)
- [ ] T075 [P] Update verify_installation() function to check for terminal enhancement tools in scripts/setup-workstation.sh
- [ ] T076 [P] Run quickstart.md validation to ensure all documented features are implemented
- [ ] T077 [P] Add integration test for terminal enhancements in tests/integration/test_terminal_enhancements.bats
- [ ] T090 [P] Add edge case handling tests: backup failures, permission errors, network failures, disk space exhaustion, concurrent executions, Git not installed, large history files in tests/integration/test_terminal_enhancements.bats
- [ ] T091 [P] Add rollback procedure test: verify backup restoration works correctly, verify configuration marker removal works, verify tool uninstallation procedures in tests/integration/test_terminal_enhancements.bats
- [ ] T092 [P] Add non-functional requirements verification: test resource usage (disk space ~50MB, memory < 10MB), test performance (startup time < 100ms increase), test scalability (history files up to 100MB, directories with 10,000 files) in tests/integration/test_terminal_enhancements.bats
- [ ] T078 [P] [SC-001] Add verification task: Test Git branch information displays in prompt within 1 second when in a repository
- [ ] T079 [P] [SC-002] Add performance verification task: Test command history search responds in < 100ms using fzf
- [ ] T080 [P] [SC-003] Add performance verification task: Test file search responds in < 200ms for directories with up to 10,000 files
- [ ] T081 [P] [SC-004] Add verification task: Test syntax highlighting works for at least 10 common file types (Python, JavaScript, Bash, Markdown, JSON, YAML, XML, HTML, CSS, SQL)
- [ ] T082 [P] [SC-005] Add measurement task: Verify Git operations using aliases require 50% fewer keystrokes compared to full commands
- [ ] T083 [P] [SC-006] Add verification task: Test command history persists across at least 10 terminal sessions without data loss
- [ ] T084 [P] [SC-007] Add performance verification task: Test tab completion provides suggestions within 50ms for commands with up to 100 possible completions
- [ ] T085 [P] [SC-008] Add measurement methodology task: Document test matrix for 95% install success rate (20 fresh Debian 13 installations, 19/20 must succeed)
- [ ] T086 [P] [SC-010] Add verification task: Test all new aliases and functions are accessible immediately after workstation setup without manual configuration
- [ ] T093 [P] Add rollback procedure documentation task: Document rollback procedures in quickstart.md or README.md per spec.md Rollback Procedures section (4 steps: restore .bashrc, remove Starship, uninstall tools, remove configuration marker)
- [ ] T094 [P] Add error message format verification: Verify all error messages match spec.md formats (installation failures, backup failures, permission errors, network failures, disk space, Git not installed, large history files, conflicts) in scripts/setup-workstation.sh

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
  - T004 must complete before T005 (integration)
  - T087 and T088 can run in parallel (prerequisites verification)
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - User stories can proceed sequentially in priority order (P1 → P2 → P3)
  - Some tasks within stories can run in parallel (marked [P])
  - All user stories require T087 (prerequisites) and T088 (Git detection) to be complete
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories (can run in parallel with US1)
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - No dependencies on other stories (can run in parallel with US1/US2)
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - No dependencies on other stories (can run in parallel with US1/US2/US3)
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - No dependencies on other stories (can run in parallel with others)
- **User Story 6 (P3)**: Can start after Foundational (Phase 2) - No dependencies on other stories (can run in parallel with others)

### Within Each User Story

- Installation functions before configuration functions
- Tool verification before .bashrc configuration
- Backup creation before .bashrc modifications
- Conflict detection before adding aliases/functions
- Configuration marker check before adding configurations

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T001, T002, T003)
- Foundational tasks: T004 must complete before T005; T087 and T088 can run in parallel after T004
- Once Foundational phase completes, user stories can start in parallel (if team capacity allows)
- Within User Story 3: T024 and T025 can run in parallel (bat and exa installation)
- Within User Story 4: T036-T040 (aliases) and T041-T046 (functions) can be worked on in parallel
- All Polish phase tasks marked [P] can run in parallel (T066-T094)

---

## Parallel Example: User Story 3

```bash
# Launch bat and exa installation in parallel:
Task: "Create install_bat() function in scripts/setup-workstation.sh"
Task: "Create install_exa() function in scripts/setup-workstation.sh"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only)

1. Complete Phase 1: Setup (helper functions)
2. Complete Phase 2: Foundational (main orchestration)
3. Complete Phase 3: User Story 1 (Starship prompt)
4. Complete Phase 4: User Story 2 (fzf search)
5. **STOP and VALIDATE**: Test User Stories 1 & 2 independently
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (Starship) → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 (fzf) → Test independently → Deploy/Demo
4. Add User Story 3 (bat/exa) → Test independently → Deploy/Demo
5. Add User Story 4 (aliases/functions) → Test independently → Deploy/Demo
6. Add User Story 5 (history/completion) → Test independently → Deploy/Demo
7. Add User Story 6 (visual) → Test independently → Deploy/Demo
8. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Starship)
   - Developer B: User Story 2 (fzf)
3. After P1 stories complete:
   - Developer A: User Story 3 (bat/exa)
   - Developer B: User Story 4 (aliases/functions)
4. After P2 stories complete:
   - Developer A: User Story 5 (history/completion)
   - Developer B: User Story 6 (visual)
5. All developers: Polish phase

---

## Notes

- [P] tasks = different files or independent operations, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- All installation functions must be idempotent (check before installing)
- All configuration functions must create backups before modifying .bashrc
- Conflict detection must preserve user customizations (skip with warning)
- Verify tools are installed before configuring in .bashrc
- Continue installing remaining tools even if one fails (partial success)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: modifying same file simultaneously, breaking idempotency, skipping error handling

---

## Task Summary

- **Total Tasks**: 94
- **Setup Phase**: 3 tasks
- **Foundational Phase**: 4 tasks (added T087, T088)
- **User Story 1 (P1)**: 10 tasks
- **User Story 2 (P1)**: 8 tasks
- **User Story 3 (P2)**: 12 tasks
- **User Story 4 (P2)**: 13 tasks
- **User Story 5 (P3)**: 11 tasks (added T089 for large history files)
- **User Story 6 (P3)**: 7 tasks
- **Polish Phase**: 26 tasks (added T090-T094 for edge cases, rollback, NFR verification, error message format verification)

**MVP Scope**: Phases 1-4 (Setup, Foundational, US1, US2) = 25 tasks
