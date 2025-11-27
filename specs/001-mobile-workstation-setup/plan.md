# Implementation Plan: Mobile-Ready Coding Workstation Installation Script

**Branch**: `001-mobile-workstation-setup` | **Date**: 2025-01-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-mobile-workstation-setup/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

A comprehensive, idempotent Bash installation script that automates the setup of a mobile-ready coding workstation on Debian 13 (Trixie). The script follows DevOps best practices with modular functions, interactive user input, enhanced terminal aesthetics, mobile-optimized desktop environment, and a complete development stack. The implementation uses proven patterns for error handling, idempotency checks, and user environment configuration.

## Technical Context

**Language/Version**: Bash 5.2+ (Debian 13 default)  
**Primary Dependencies**: 
- System packages: `curl`, `git`, `htop`, `vim`, `build-essential`, `xfce4`, `xrdp`, `docker-ce`, `docker-compose-plugin`, `firefox-esr`, `chromium`
- User-space tools: NVM (Node Version Manager) for Node.js LTS, Python 3 (system default)
- Configuration tools: `xfconf-query` for XFCE settings, `hostnamectl` for hostname management

**Storage**: File-based configuration:
- User home directory: `/home/$CUSTOM_USER/.bashrc` (shell configuration)
- System configuration: `/etc/hostname` (hostname), `/etc/apt/sources.list.d/` (Docker repository)
- XFCE user settings: `~/.config/xfce4/` (desktop configuration)

**Testing**: Manual testing on fresh Debian 13 installations; validation through acceptance scenarios from spec

**Target Platform**: Debian 13 (Trixie) - 64-bit amd64 architecture  
**Project Type**: Single standalone installation script (bash automation)  
**Performance Goals**: Complete installation in under 15 minutes on standard VPS hardware  
**Constraints**: 
- Must be idempotent (safe to re-run)
- Requires root/sudo privileges for system-level changes
- Network connectivity required for package downloads
- Minimum 2GB RAM, 10GB disk space recommended

**Scale/Scope**: Single-server installation script targeting one user account per execution

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

✅ **Idempotency & Safety**: 
- Script uses `set -e` for error safety
- All functions check for existing packages/configurations before acting
- Idempotency verified through existence checks (e.g., `command -v`, `dpkg -l`, file existence)

✅ **Interactive UX**: 
- No hardcoded credentials
- Interactive prompts for Username, Password, Hostname at script start
- Password input uses `read -s` for silent input

✅ **Aesthetic Excellence**: 
- Custom PS1 prompt with colors (neon green, blue, yellow)
- Git branch detection via `parse_git_branch()` function
- Structured prompt format: `[User@Hostname] [CurrentDir] [GitBranch] $`

✅ **Mobile-First Optimization**: 
- XFCE font size set to 12-13pt via `xfconf-query`
- Desktop icon size set to 48
- Panel size set to 48px height

✅ **Clean Architecture**: 
- Docker used for containerized services
- NVM used for Node.js (user-space version manager)
- Python uses system installation (Debian 13 default)

✅ **Modularity**: 
- Code organized into distinct functions:
  - `get_user_inputs()` - Interactive input collection
  - `system_prep()` - System preparation and hostname
  - `setup_desktop_mobile()` - XFCE and XRDP installation
  - `create_user_and_shell()` - User creation and shell configuration
  - `setup_dev_stack()` - Docker, browsers, Node.js, Python
  - `finalize()` - Cleanup and summary output

✅ **Target Platform**: 
- Debian 13 (Trixie) compatibility verified
- OS version check at script start
- Package names validated for Debian 13 repositories

**No violations detected** - All constitution principles are satisfied.

## Project Structure

### Documentation (this feature)

```text
specs/001-mobile-workstation-setup/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
scripts/
└── setup-workstation.sh  # Main installation script
```

**Structure Decision**: Single standalone Bash script at repository root under `scripts/` directory. This follows the constitution's modularity principle by organizing the script into distinct functions while keeping it as a single executable file for simplicity and portability.

## Complexity Tracking

> **No violations** - All constitution principles are satisfied without requiring complexity justification.
