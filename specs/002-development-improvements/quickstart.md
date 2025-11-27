# Quick Start: Development Improvements

**Feature**: Development Improvements & Quality Assurance  
**Date**: 2025-01-27

## Developer Setup

### Prerequisites

- Debian 13 (Trixie) or compatible Linux distribution
- Git installed
- Python 3.11+ (for pre-commit)
- Root or sudo access (for installing tools)

### Installation Steps

1. **Install Development Tools**:
   ```bash
   sudo apt update
   sudo apt install -y shellcheck bats python3-pip
   ```

2. **Install Pre-commit Framework**:
   ```bash
   pip3 install --user pre-commit
   # Or system-wide: sudo pip3 install pre-commit
   ```

3. **Install Pre-commit Hooks**:
   ```bash
   cd /path/to/project
   pre-commit install
   ```

4. **Verify Installation**:
   ```bash
   shellcheck --version
   bats --version
   pre-commit --version
   ```

## Running Tests Locally

### Run All Tests

```bash
# From project root
bats tests/
```

### Run Specific Test File

```bash
bats tests/unit/test_user_creation.bats
```

### Run Tests with Tags

```bash
# Run only unit tests
bats --filter-tags unit tests/

# Run only integration tests
bats --filter-tags integration tests/

# Exclude slow tests
bats --filter-tags '!slow' tests/
```

### Run Tests with Verbose Output

```bash
bats --verbose tests/
```

## Running Linting

### Lint All Scripts

```bash
shellcheck scripts/*.sh
```

### Lint Specific Script

```bash
shellcheck scripts/setup-workstation.sh
```

### Lint with Specific Severity

```bash
# Only show errors and warnings
shellcheck --severity=warning scripts/*.sh

# Show all issues including style
shellcheck --severity=style scripts/*.sh
```

### Lint via Pre-commit

```bash
# Run pre-commit hooks manually
pre-commit run --all-files

# Run specific hook
pre-commit run shellcheck --all-files
```

## Contributing Workflow

### 1. Before Making Changes

```bash
# Ensure pre-commit hooks are installed
pre-commit install

# Pull latest changes
git pull origin main
```

### 2. Make Changes

- Edit code in your preferred editor
- Follow coding standards (enforced by ShellCheck)
- Write tests for new functionality

### 3. Test Your Changes

```bash
# Run linting
shellcheck scripts/*.sh

# Run tests
bats tests/

# Run pre-commit hooks
pre-commit run --all-files
```

### 4. Commit Changes

```bash
# Pre-commit hooks will run automatically
git add .
git commit -m "feat: add new feature"

# If hooks fail, fix issues and commit again
# To bypass (not recommended): git commit --no-verify
```

### 5. Push and Create PR

```bash
git push origin feature-branch
# Create PR on GitHub
# CI/CD will run automatically
```

## CI/CD Workflow

### Local CI Simulation

```bash
# Simulate CI environment
docker run --rm -v "$PWD:/workspace" -w /workspace \
  debian:13 \
  bash -c "apt update && apt install -y shellcheck bats && \
           shellcheck scripts/*.sh && bats tests/"
```

### Check CI Status

- View workflow runs: GitHub → Actions tab
- Check specific run: Click on workflow run
- View logs: Expand job steps
- Download artifacts: Available in workflow run page

## Troubleshooting

### Pre-commit Hooks Not Running

```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install

# Verify hooks are installed
ls -la .git/hooks/pre-commit
```

### Tests Failing Locally But Pass in CI

- Check environment differences (OS, versions)
- Ensure all dependencies are installed
- Run tests in clean environment (Docker)

### ShellCheck Errors

- Read error message for specific issue
- Check ShellCheck wiki for SC code explanations
- Use `# shellcheck disable=SC####` for intentional violations (with comment)

### Bats Tests Not Found

- Ensure test files have `.bats` extension
- Check file permissions (must be executable)
- Verify bats is installed: `which bats`

## Next Steps

1. Read `CONTRIBUTING.md` for detailed guidelines
2. Review existing tests in `tests/` directory
3. Check `README.md` for project overview
4. Join team discussions for questions

## Resources

- ShellCheck: https://github.com/koalaman/shellcheck
- Bats-core: https://github.com/bats-core/bats-core
- Pre-commit: https://pre-commit.com/
- GitHub Actions: https://docs.github.com/en/actions

