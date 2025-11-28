# Changelog

All notable changes to the Mobile-Ready Coding Workstation Setup Script will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-27

### Added
- Initial release of Mobile-Ready Coding Workstation Setup Script
- Interactive user input collection (username, password, hostname)
- System preparation (hostname setting, essential package installation)
- User account creation with password configuration
- XFCE4 desktop environment installation and mobile optimization
- XRDP server installation and configuration for remote access
- Docker Engine and Docker Compose installation
- NVM and Node.js LTS installation
- Python environment verification
- Firefox ESR and Chromium browser installation
- Custom shell configuration (PS1 prompt, Git branch detection, aliases)
- Idempotent installation and configuration (safe to run multiple times)
- Comprehensive error handling and validation
- Installation summary with connection information

### Features
- **Interactive Setup**: User-friendly prompts with validation
- **Mobile-First Desktop**: XFCE4 optimized for mobile devices (12pt fonts, 48px icons/panel)
- **Remote Access**: XRDP server for remote desktop connections
- **Development Stack**: Docker, Node.js, Python, and essential tools
- **Beautiful Terminal**: Custom PS1 prompt with color coding and Git integration
- **Idempotency**: All operations are safe to run multiple times

### Fixed
- Fixed "CUSTOM_PASS: unbound variable" error by initializing variables before use
- Fixed "Malformed stanza" Docker repository error by implementing correct DEB822 format
- Fixed password input loop when script is piped (curl ... | bash) by using /dev/tty redirection
- Fixed hostname input issues in piped execution
- Fixed Docker GPG key management by removing old keys before adding new ones
- Fixed XFCE configuration fallback mechanism for when XFCE session is not running

### Security
- Password input is hidden (silent mode)
- Input validation for username and hostname
- Root privilege checks before system modifications
- GPG key verification for Docker repository

### Documentation
- Comprehensive README.md with installation instructions and usage examples
- CONTRIBUTING.md with development workflow and coding standards
- Troubleshooting guide (docs/troubleshooting.md) with common issues and solutions
- Function documentation in script comments
- CHANGELOG.md for version history

### Testing
- Unit tests for user creation, Docker setup, XFCE configuration, shell configuration
- Integration tests for idempotency and full installation flow
- Test suite using bats-core framework
- 29 test cases covering critical functionality

### Development Infrastructure
- ShellCheck linting configuration (.shellcheckrc)
- Pre-commit hooks for code quality (ShellCheck, formatting)
- GitHub Actions CI/CD workflow (linting and testing)
- Test helpers (bats-support, bats-assert)

---

## [Unreleased]

### Planned
- Support for additional Linux distributions
- Additional desktop environment options
- Enhanced logging and error reporting
- Performance optimizations
- Extended test coverage

---

## Version History

- **1.0.0** (2025-01-27): Initial release with core functionality

---

**Format Notes**:
- `Added` for new features
- `Changed` for changes in existing functionality
- `Deprecated` for soon-to-be removed features
- `Removed` for now removed features
- `Fixed` for any bug fixes
- `Security` for vulnerability fixes
