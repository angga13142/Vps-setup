# Tasks: Mobile-Ready Coding Workstation Installation Script

**Input**: Design documents from `/specs/001-mobile-workstation-setup/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are OPTIONAL - not requested in feature specification, so no test tasks included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: Script at `scripts/setup-workstation.sh` at repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic script structure

- [x] T001 Create scripts directory structure at scripts/ in repository root
- [x] T002 [P] Initialize setup-workstation.sh with shebang `#!/usr/bin/env bash` in scripts/setup-workstation.sh
- [x] T003 [P] Add error handling setup (`set -euo pipefail`) at top of scripts/setup-workstation.sh
- [x] T004 [P] Define color variables (GREEN, RED, YELLOW, NC) in scripts/setup-workstation.sh
- [x] T005 [P] Add script header comments (name, description, author, date) in scripts/setup-workstation.sh

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Implement check_debian_version() function to validate Debian 13 (Trixie) in scripts/setup-workstation.sh
- [x] T007 Add main script entry point that calls check_debian_version() first in scripts/setup-workstation.sh
- [x] T008 Add root/sudo privilege check at script start in scripts/setup-workstation.sh

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Interactive System Initialization (Priority: P1) 🎯 MVP

**Goal**: Set up a new Debian 13 server with a custom user account and hostname through an interactive process that collects user preferences safely and immediately applies the hostname configuration.

**Independent Test**: Run the script on a fresh Debian 13 system, verify it prompts for username (with default), password (hidden input), and hostname, shows a confirmation prompt, and successfully sets the hostname using `hostnamectl`. The test delivers a properly configured base system with a new user account.

### Implementation for User Story 1

- [ ] T009 [US1] Implement welcome banner display with ASCII art in get_user_inputs() function in scripts/setup-workstation.sh
- [ ] T010 [US1] Implement username prompt with default value 'coder' in get_user_inputs() function in scripts/setup-workstation.sh
- [ ] T011 [US1] Implement password prompt with hidden input (read -s) in get_user_inputs() function in scripts/setup-workstation.sh
- [ ] T012 [US1] Implement hostname prompt in get_user_inputs() function in scripts/setup-workstation.sh
- [ ] T013 [US1] Add input validation (non-empty password, valid hostname format) in get_user_inputs() function in scripts/setup-workstation.sh
- [ ] T014 [US1] Implement confirmation prompt before proceeding in get_user_inputs() function in scripts/setup-workstation.sh
- [ ] T015 [US1] Implement system_prep() function with hostname setting via hostnamectl in scripts/setup-workstation.sh
- [ ] T016 [US1] Add idempotency check for hostname (check current hostname before setting) in system_prep() function in scripts/setup-workstation.sh
- [ ] T017 [US1] Implement APT repository update in system_prep() function in scripts/setup-workstation.sh
- [ ] T018 [US1] Add installation of essential packages (curl, git, htop, vim, build-essential) with idempotency checks in system_prep() function in scripts/setup-workstation.sh
- [ ] T019 [US1] Implement create_user_and_shell() function stub with user creation logic in scripts/setup-workstation.sh
- [ ] T020 [US1] Add idempotency check for user existence before creation in create_user_and_shell() function in scripts/setup-workstation.sh
- [ ] T021 [US1] Implement useradd command with password setting in create_user_and_shell() function in scripts/setup-workstation.sh
- [ ] T022 [US1] Update main script entry point to call get_user_inputs(), system_prep(), and create_user_and_shell() in sequence in scripts/setup-workstation.sh

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently. The script can collect user input, set hostname, update packages, and create a user account.

---

## Phase 4: User Story 2 - Enhanced Terminal Experience (Priority: P2)

**Goal**: Provide a professional, visually appealing terminal environment that provides immediate context about current location, Git repository status, and system information, with helpful aliases for common operations.

**Independent Test**: Log in as the created user and verify that the `.bashrc` contains a custom PS1 prompt with the specified format and colors, Git branch detection works in repository directories, and all specified aliases (`ll`, `update`, `docker-clean`) are available and functional. The test delivers an immediately usable, professional terminal environment.

### Implementation for User Story 2

- [ ] T023 [US2] Implement parse_git_branch() helper function for Git branch detection in scripts/setup-workstation.sh
- [ ] T024 [US2] Add custom PS1 prompt with format `[User@Hostname] [CurrentDir] [GitBranch] $` in create_user_and_shell() function in scripts/setup-workstation.sh
- [ ] T025 [US2] Add color codes (neon green for user/host, blue for directory, yellow for Git branch) to PS1 prompt in create_user_and_shell() function in scripts/setup-workstation.sh
- [ ] T026 [US2] Integrate parse_git_branch() function call into PS1 prompt in create_user_and_shell() function in scripts/setup-workstation.sh
- [ ] T027 [US2] Add alias `ll` that executes `ls -alFh --color=auto` to .bashrc generation in create_user_and_shell() function in scripts/setup-workstation.sh
- [ ] T028 [US2] Add alias `update` that executes `sudo apt update && sudo apt upgrade -y` to .bashrc generation in create_user_and_shell() function in scripts/setup-workstation.sh
- [ ] T029 [US2] Add alias `docker-clean` that removes unused Docker containers and images to .bashrc generation in create_user_and_shell() function in scripts/setup-workstation.sh
- [ ] T030 [US2] Implement .bashrc file generation logic that writes to /home/$CUSTOM_USER/.bashrc in create_user_and_shell() function in scripts/setup-workstation.sh
- [ ] T031 [US2] Add idempotency check for .bashrc existence before writing in create_user_and_shell() function in scripts/setup-workstation.sh
- [ ] T032 [US2] Ensure .bashrc is owned by the created user with correct permissions in create_user_and_shell() function in scripts/setup-workstation.sh

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. The user account has a fully configured terminal with Git awareness and helpful aliases.

---

## Phase 5: User Story 3 - Mobile-Optimized Desktop Environment (Priority: P2)

**Goal**: Install and configure a desktop environment accessible remotely from a mobile device via RDP, with large, touch-friendly UI elements (fonts, icons, panels) that are readable and usable on mobile screens.

**Independent Test**: Install XFCE4 and XRDP, connect via RDP from a mobile device, and verify that fonts are 12-13pt, desktop icons are size 48, and the panel/taskbar is 48px high. The test delivers a mobile-accessible desktop environment that is immediately usable for remote development work.

### Implementation for User Story 3

- [ ] T033 [US3] Implement setup_desktop_mobile() function stub in scripts/setup-workstation.sh
- [ ] T034 [US3] Add idempotency check for xfce4 package before installation in setup_desktop_mobile() function in scripts/setup-workstation.sh
- [ ] T035 [US3] Implement XFCE4 desktop environment installation via apt in setup_desktop_mobile() function in scripts/setup-workstation.sh
- [ ] T036 [US3] Add idempotency check for xrdp package before installation in setup_desktop_mobile() function in scripts/setup-workstation.sh
- [ ] T037 [US3] Implement XRDP remote desktop server installation via apt in setup_desktop_mobile() function in scripts/setup-workstation.sh
- [ ] T038 [US3] Implement XRDP service enablement (systemctl enable xrdp) in setup_desktop_mobile() function in scripts/setup-workstation.sh
- [ ] T039 [US3] Implement XRDP service start (systemctl start xrdp) with idempotency check in setup_desktop_mobile() function in scripts/setup-workstation.sh
- [ ] T040 [US3] Implement XFCE font size configuration (12-13pt) using xfconf-query as target user in setup_desktop_mobile() function in scripts/setup-workstation.sh
- [ ] T041 [US3] Implement XFCE desktop icon size configuration (48px) using xfconf-query as target user in setup_desktop_mobile() function in scripts/setup-workstation.sh
- [ ] T042 [US3] Implement XFCE panel size configuration (48px height) using xfconf-query as target user in setup_desktop_mobile() function in scripts/setup-workstation.sh
- [ ] T043 [US3] Add error handling for XFCE configuration (xfconf-query may fail if XFCE not running) in setup_desktop_mobile() function in scripts/setup-workstation.sh
- [ ] T044 [US3] Update main script entry point to call setup_desktop_mobile() after create_user_and_shell() in scripts/setup-workstation.sh

**Checkpoint**: At this point, User Stories 1, 2, AND 3 should all work independently. The workstation has a mobile-optimized desktop environment accessible via RDP.

---

## Phase 6: User Story 4 - Development Stack Installation (Priority: P3)

**Goal**: Install Docker, web browsers, and programming language environments (Node.js, Python) for the user account, ready for immediate use in development projects.

**Independent Test**: Verify Docker and Docker Compose are installed and the user can run Docker commands, Firefox ESR and Chromium browsers are installed and launchable, Node.js LTS is installed via NVM and accessible to the user, and Python environment is configured for the user. The test delivers a complete development environment ready for coding projects.

### Implementation for User Story 4

- [ ] T045 [US4] Implement setup_dev_stack() function stub in scripts/setup-workstation.sh
- [ ] T046 [US4] Add Docker APT repository prerequisites installation (ca-certificates, curl) in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T047 [US4] Implement Docker GPG key installation to /etc/apt/keyrings/docker.asc in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T048 [US4] Add idempotency check for Docker repository before adding in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T049 [US4] Implement Docker APT repository configuration in /etc/apt/sources.list.d/docker.sources in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T050 [US4] Implement APT update after Docker repository addition in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T051 [US4] Add idempotency checks for Docker packages before installation in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T052 [US4] Implement Docker and Docker Compose installation (docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin) in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T053 [US4] Add user to docker group with idempotency check in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T054 [US4] Add idempotency checks for browsers before installation in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T055 [US4] Implement Firefox ESR browser installation via apt in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T056 [US4] Implement Chromium browser installation via apt in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T057 [US4] Implement NVM installation script download and execution as target user in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T058 [US4] Add NVM configuration to user's .bashrc (export NVM_DIR, source nvm.sh) in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T059 [US4] Implement Node.js LTS installation via NVM as target user in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T060 [US4] Set Node.js LTS as default version via NVM as target user in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T061 [US4] Add Python 3 availability verification in setup_dev_stack() function in scripts/setup-workstation.sh
- [ ] T062 [US4] Update main script entry point to call setup_dev_stack() after setup_desktop_mobile() in scripts/setup-workstation.sh

**Checkpoint**: All user stories should now be independently functional. The workstation has a complete development stack ready for coding.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Finalization, cleanup, and improvements that affect the entire script

- [ ] T063 Implement finalize() function with APT cache cleanup in scripts/setup-workstation.sh
- [ ] T064 Add IP address detection logic (hostname -I or ip command) in finalize() function in scripts/setup-workstation.sh
- [ ] T065 Implement summary box display with IP address, username, and "Reboot Required" message in finalize() function in scripts/setup-workstation.sh
- [ ] T066 Update main script entry point to call finalize() at the end in scripts/setup-workstation.sh
- [ ] T067 [P] Add comprehensive error messages throughout all functions in scripts/setup-workstation.sh
- [ ] T068 [P] Add logging/output messages for each major step in scripts/setup-workstation.sh
- [ ] T069 Verify all functions have proper idempotency checks in scripts/setup-workstation.sh
- [ ] T070 Add script execution permissions check and guidance message in scripts/setup-workstation.sh
- [ ] T071 Test script on fresh Debian 13 installation following quickstart.md validation steps
- [ ] T072 Verify script can be safely re-run (idempotency test) on already-configured system

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed sequentially in priority order (P1 → P2 → P3)
  - User Story 2 and 3 can potentially be worked on in parallel after User Story 1
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on User Story 1 (needs user account to exist) - Can be implemented after US1 user creation
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Independent of other stories, but benefits from user account existing
- **User Story 4 (P3)**: Depends on User Story 1 (needs user account) - Can be implemented after US1 user creation

### Within Each User Story

- Core function implementation before integration
- Idempotency checks before actions
- Error handling throughout
- Story complete before moving to next priority

### Parallel Opportunities

- Setup tasks T002-T005 can run in parallel (different sections of same file, but can be worked on simultaneously)
- User Story 3 and User Story 2 can be worked on in parallel after User Story 1 completes (different functions)
- Polish tasks T067-T068 can run in parallel (different functions)

---

## Parallel Example: User Story 1

```bash
# Sequential execution required for US1:
# T009 → T010 → T011 → T012 → T013 → T014 (get_user_inputs function)
# T015 → T016 → T017 → T018 (system_prep function)
# T019 → T020 → T021 (create_user_and_shell function)
# T022 (main script integration)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

**MVP delivers**: Interactive system initialization with user account creation and hostname configuration.

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo (Enhanced terminal)
4. Add User Story 3 → Test independently → Deploy/Demo (Mobile desktop)
5. Add User Story 4 → Test independently → Deploy/Demo (Complete dev stack)
6. Each story adds value without breaking previous stories

### Sequential Implementation Strategy

Since this is a single script with function dependencies:

1. Complete Setup + Foundational together
2. Implement User Story 1 functions in order
3. Implement User Story 2 functions (depends on user account from US1)
4. Implement User Story 3 functions (can be parallel with US2 after US1)
5. Implement User Story 4 functions (depends on user account from US1)
6. Complete Polish phase

---

## Notes

- [P] tasks = different sections/functions, can be worked on simultaneously
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- All functions must include idempotency checks
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Script must be executable: `chmod +x scripts/setup-workstation.sh`
- Test on fresh Debian 13 (Trixie) installation
- Verify script can be safely re-run (idempotency)

