<!--
Sync Impact Report:
Version change: N/A → 1.0.0 (Initial constitution)
Modified principles: N/A (new constitution)
Added sections: Core Principles (7 principles), Target Platform, Governance
Removed sections: N/A
Templates requiring updates:
  ✅ plan-template.md - Constitution Check section references constitution principles
  ✅ spec-template.md - No direct constitution references, but aligns with principles
  ✅ tasks-template.md - No direct constitution references, but aligns with principles
  ✅ checklist-template.md - No direct constitution references
Follow-up TODOs: None
-->

# DevOps Automation Constitution

## Core Principles

### I. Idempotency & Safety

All scripts and automation MUST be re-runnable without adverse effects. Always check if a package, configuration, or resource exists before acting upon it. Use `set -e` for error safety to ensure scripts fail fast on errors. This principle ensures that automation can be safely executed multiple times, making rollbacks and re-runs predictable and safe.

**Rationale**: Idempotent operations prevent accidental duplicate installations, configuration conflicts, and system corruption. Error safety (`set -e`) prevents scripts from continuing in an undefined state after failures.

### II. Interactive UX

Scripts MUST NOT use hardcoded credentials or sensitive information. All scripts MUST interactively prompt the user at the very beginning for required inputs such as `Username`, `Password`, and `Hostname`. This ensures security best practices and makes automation adaptable to different environments without code modifications.

**Rationale**: Hardcoded credentials are a security anti-pattern. Interactive prompting ensures credentials are never stored in version control and allows the same script to work across different environments and users.

### III. Aesthetic Excellence

The resulting terminal environment MUST be visually superior to default configurations. The default bash prompt is unacceptable. We require colors, structure, and Git awareness in the shell prompt. Terminal aesthetics directly impact developer productivity and experience.

**Rationale**: A well-designed prompt provides immediate context (current directory, Git status, user/host info) and reduces cognitive load. Visual feedback improves workflow efficiency and reduces errors.

### IV. Mobile-First Optimization

The GUI target (XFCE) is optimized for mobile device access via RDP. Large fonts (DPI scaling) and large icons are MANDATORY requirements, not optional. All GUI configurations must prioritize readability and usability on mobile screens accessed remotely.

**Rationale**: Mobile RDP usage requires significantly larger UI elements than desktop displays. Standard desktop DPI settings are unusable on mobile devices, making this a hard requirement for accessibility and usability.

### V. Clean Architecture

Do not pollute the root filesystem. Use Docker for services and containerized applications. Use Version Managers (NVM, pyenv, etc.) for programming languages rather than system-wide installations. This keeps the base system clean and allows for isolated, reproducible environments.

**Rationale**: Root filesystem pollution leads to dependency conflicts, version management nightmares, and difficult system maintenance. Containerization and version managers provide isolation, reproducibility, and easy cleanup.

### VI. Modularity

Code MUST be separated into distinct functions with clear responsibilities. Examples include `get_user_inputs`, `setup_shell_aesthetics`, `setup_docker`. Each function should have a single, well-defined purpose. This promotes maintainability, testability, and reusability.

**Rationale**: Modular code is easier to understand, test, debug, and modify. Function separation allows for independent development, testing, and reuse across different scripts and projects.

### VII. Target Platform

All automation and configurations target Debian 13 (Trixie). Package names, repository configurations, and system paths must be compatible with Debian 13. This ensures consistency and predictability across all automation efforts.

**Rationale**: Standardizing on a specific OS version eliminates compatibility issues, ensures package availability, and provides a stable foundation for all automation work.

## Target Platform

**Operating System**: Debian 13 (Trixie)

All scripts, package installations, and system configurations must be compatible with Debian 13. When referencing packages, repositories, or system paths, ensure Debian 13 compatibility is maintained.

## Development Workflow

All automation scripts must follow the core principles above. Before committing any script:

1. Verify idempotency by running the script twice
2. Confirm all credentials are interactively prompted (no hardcoded values)
3. Validate shell aesthetics are enhanced (prompt customization)
4. For GUI configurations, verify mobile-friendly DPI and icon sizes
5. Ensure services use Docker, languages use version managers
6. Confirm code is modular with distinct functions
7. Test on Debian 13 (Trixie) target platform

## Governance

This constitution supersedes all other development practices and conventions. All automation scripts, configuration management, and system setup procedures must comply with these principles.

**Amendment Procedure**: Amendments to this constitution require:
- Documentation of the rationale for change
- Impact assessment on existing automation
- Update to version number following semantic versioning:
  - **MAJOR**: Backward incompatible principle removals or redefinitions
  - **MINOR**: New principle added or materially expanded guidance
  - **PATCH**: Clarifications, wording improvements, typo fixes

**Compliance Review**: All PRs and code reviews must verify compliance with these principles. Any violations must be justified in the Complexity Tracking section of implementation plans, or the code must be refactored to comply.

**Version**: 1.0.0 | **Ratified**: 2025-01-27 | **Last Amended**: 2025-01-27
