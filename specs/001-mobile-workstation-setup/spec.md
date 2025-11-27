# Feature Specification: Mobile-Ready Coding Workstation Installation Script

**Feature Branch**: `001-mobile-workstation-setup`  
**Created**: 2025-01-27  
**Status**: Draft  
**Input**: User description: "I need a comprehensive Bash installation script for a \"Mobile-Ready Coding Workstation\" on Debian 13."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Interactive System Initialization (Priority: P1)

A DevOps engineer needs to set up a new Debian 13 server with a custom user account and hostname. They run the installation script and are guided through an interactive process that collects their preferences safely and immediately applies the hostname configuration.

**Why this priority**: This is the foundation of the entire setup. Without proper user creation and hostname configuration, subsequent phases cannot proceed. The interactive UX ensures security (no hardcoded credentials) and customization.

**Independent Test**: Can be fully tested by running the script on a fresh Debian 13 system, verifying that it prompts for username (with default), password (hidden input), and hostname, shows a confirmation prompt, and successfully sets the hostname using `hostnamectl`. The test delivers a properly configured base system with a new user account.

**Acceptance Scenarios**:

1. **Given** a fresh Debian 13 installation, **When** the script is executed, **Then** the screen clears and displays a welcome banner with ASCII art
2. **Given** the script is running, **When** prompted for username, **Then** it shows a default value ('coder') that can be accepted or changed
3. **Given** the script is prompting for password, **When** the user types, **Then** the input is hidden/silent (no characters displayed)
4. **Given** all inputs are collected, **When** the user confirms, **Then** the system hostname is immediately set using `hostnamectl set-hostname`
5. **Given** the user cancels or provides invalid input, **When** confirmation is declined, **Then** the script exits gracefully without making changes

---

### User Story 2 - Enhanced Terminal Experience (Priority: P2)

A developer needs a professional, visually appealing terminal environment that provides immediate context about their current location, Git repository status, and system information. The terminal should include helpful aliases for common operations.

**Why this priority**: Developer productivity depends heavily on terminal experience. A well-configured shell with Git awareness and useful aliases reduces cognitive load and speeds up daily workflows. This can be implemented independently after user creation.

**Independent Test**: Can be fully tested by logging in as the created user and verifying that the `.bashrc` contains a custom PS1 prompt with the specified format and colors, Git branch detection works in repository directories, and all specified aliases (`ll`, `update`, `docker-clean`) are available and functional. The test delivers an immediately usable, professional terminal environment.

**Acceptance Scenarios**:

1. **Given** the user account exists, **When** the script completes the terminal configuration phase, **Then** the `.bashrc` file contains a custom PS1 prompt with format `[User@Hostname] [CurrentDir] [GitBranch] $`
2. **Given** the user opens a terminal, **When** they navigate to a Git repository, **Then** the prompt automatically displays the current Git branch name in yellow
3. **Given** the terminal is configured, **When** the user types `ll`, **Then** it executes `ls -alFh --color=auto`
4. **Given** the terminal is configured, **When** the user types `update`, **Then** it executes `sudo apt update && sudo apt upgrade -y`
5. **Given** the terminal is configured, **When** the user types `docker-clean`, **Then** it removes unused Docker containers and images

---

### User Story 3 - Mobile-Optimized Desktop Environment (Priority: P2)

A developer needs to access the workstation remotely from a mobile device via RDP. The desktop environment must have large, touch-friendly UI elements (fonts, icons, panels) that are readable and usable on mobile screens.

**Why this priority**: Mobile RDP access is a core requirement. Without proper DPI scaling and large UI elements, the desktop is unusable on mobile devices. This can be implemented independently after the base system is ready.

**Independent Test**: Can be fully tested by installing XFCE4 and XRDP, connecting via RDP from a mobile device, and verifying that fonts are 12-13pt, desktop icons are size 48, and the panel/taskbar is 48px high. The test delivers a mobile-accessible desktop environment that is immediately usable for remote development work.

**Acceptance Scenarios**:

1. **Given** the base system is configured, **When** the script installs XFCE4 and XRDP, **Then** both packages are successfully installed and XRDP service is enabled
2. **Given** XFCE4 is installed, **When** the script configures mobile optimization, **Then** the XFCE configuration files are programmatically edited to set font size to 12pt or 13pt
3. **Given** XFCE4 is installed, **When** the script configures mobile optimization, **Then** desktop icon size is set to 48
4. **Given** XFCE4 is installed, **When** the script configures mobile optimization, **Then** the panel (taskbar) size is set to 48px height
5. **Given** XRDP is running, **When** a user connects from a mobile device, **Then** they can see and interact with all UI elements comfortably

---

### User Story 4 - Development Stack Installation (Priority: P3)

A developer needs Docker, web browsers, and programming language environments (Node.js, Python) installed and configured for their user account, ready for immediate use in development projects.

**Why this priority**: While essential for a coding workstation, this can be added after the core system and desktop environment are functional. The development tools enable actual coding work but are not required for the initial setup to be considered complete.

**Independent Test**: Can be fully tested by verifying Docker and Docker Compose are installed and the user can run Docker commands, Firefox ESR and Chromium browsers are installed and launchable, Node.js LTS is installed via NVM and accessible to the user, and Python environment is configured for the user. The test delivers a complete development environment ready for coding projects.

**Acceptance Scenarios**:

1. **Given** the user account exists, **When** the script installs Docker, **Then** Docker and Docker Compose are installed and the user is added to the docker group
2. **Given** the script completes browser installation, **When** the user launches Firefox ESR or Chromium, **Then** both browsers start successfully
3. **Given** the script installs Node.js via NVM, **When** the user opens a new terminal, **Then** Node.js LTS version is available and `node --version` returns the LTS version
4. **Given** the script configures Python environment, **When** the user runs `python3 --version`, **Then** Python is available and properly configured for the user

---

### Edge Cases

- What happens when the script is run on a non-Debian 13 system? The script should detect the OS version and exit with a clear error message
- How does the script handle network failures during package installation? The script should retry failed operations and provide clear error messages
- What happens if the specified username already exists? The script should detect this and either skip user creation or prompt for a different username
- How does the script handle interrupted execution? The script should be idempotent and safely resumable
- What happens if XRDP fails to start? The script should log the error and continue with other installations, but warn the user
- How does the script handle insufficient disk space? The script should check available space before large installations and fail gracefully with a clear message
- What happens if the user provides an invalid hostname? The script should validate hostname format and reject invalid entries
- How does the script handle permission errors? The script should detect if it's run without sudo and provide clear guidance

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Script MUST clear the screen and display a welcome banner with ASCII art at startup
- **FR-002**: Script MUST interactively prompt for username with a default value of 'coder' that can be accepted or modified
- **FR-003**: Script MUST interactively prompt for password with hidden/silent input (no characters displayed)
- **FR-004**: Script MUST interactively prompt for hostname (e.g., 'my-vps')
- **FR-005**: Script MUST ask for user confirmation before proceeding with any system changes
- **FR-006**: Script MUST immediately set the system hostname using `hostnamectl set-hostname` after confirmation
- **FR-007**: Script MUST configure `.bashrc` for the created user with a custom PS1 prompt
- **FR-008**: Script MUST format PS1 as `[User@Hostname] [CurrentDir] [GitBranch] $` with neon green for user/host, blue for directory, and yellow for Git branch
- **FR-009**: Script MUST implement automatic Git branch detection and display in the prompt when inside a Git repository
- **FR-010**: Script MUST create alias `ll` that executes `ls -alFh --color=auto`
- **FR-011**: Script MUST create alias `update` that executes `sudo apt update && sudo apt upgrade -y`
- **FR-012**: Script MUST create alias `docker-clean` that removes unused Docker containers and images
- **FR-013**: Script MUST install XFCE4 desktop environment
- **FR-014**: Script MUST install and configure XRDP for remote desktop access
- **FR-015**: Script MUST programmatically edit XFCE configuration to set font size to 12pt or 13pt
- **FR-016**: Script MUST programmatically edit XFCE configuration to set desktop icon size to 48
- **FR-017**: Script MUST programmatically edit XFCE configuration to set panel (taskbar) size to 48px height
- **FR-018**: Script MUST install Docker and Docker Compose
- **FR-019**: Script MUST install Firefox ESR browser
- **FR-020**: Script MUST install Chromium browser
- **FR-021**: Script MUST install Node.js LTS version using NVM for the created user
- **FR-022**: Script MUST configure Python environment for the created user
- **FR-023**: Script MUST display a summary box at completion showing IP address, username, and "Reboot Required" message
- **FR-024**: Script MUST be idempotent (safe to run multiple times) and check for existing packages/configurations before acting
- **FR-025**: Script MUST use `set -e` for error safety to fail fast on errors
- **FR-026**: Script MUST validate that it is running on Debian 13 (Trixie) before proceeding

### Key Entities *(include if feature involves data)*

- **Installation Script**: The main Bash script that orchestrates the entire workstation setup process, containing modular functions for each phase
- **User Account**: The system user account created during initialization, with custom username and password, used for all subsequent configurations
- **System Configuration**: The collection of system-wide settings including hostname, package installations, and service configurations
- **User Environment**: The per-user configurations including `.bashrc` customizations, NVM setup, and Python environment

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can complete the entire workstation setup process in under 15 minutes from script execution to completion
- **SC-002**: The script successfully installs and configures all components on a fresh Debian 13 system with 100% success rate for all phases
- **SC-003**: Users can successfully connect to the workstation via RDP from a mobile device and interact with all UI elements without zooming or straining to read
- **SC-004**: The terminal prompt provides immediate visual context (user, hostname, directory, Git branch) reducing the need for manual `pwd` and `git status` commands by 90%
- **SC-005**: The script can be safely re-run on an already-configured system without causing errors or duplicate configurations
- **SC-006**: All installed development tools (Docker, Node.js, Python, browsers) are immediately usable without additional manual configuration after script completion
- **SC-007**: The mobile-optimized desktop environment receives positive usability feedback from users accessing via mobile RDP (target: 95% of users report comfortable readability)
