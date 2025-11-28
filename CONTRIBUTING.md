# Contributing Guidelines

Thank you for your interest in contributing to the Mobile-Ready Coding Workstation Setup Script project!

## Development Workflow

### Prerequisites

Before contributing, ensure you have the following tools installed:

- **ShellCheck**: Bash script linting tool
  ```bash
  sudo apt install shellcheck
  ```

- **bats-core**: Bash testing framework
  ```bash
  sudo apt install bats
  ```

- **pre-commit**: Pre-commit hooks framework
  ```bash
  pipx install pre-commit
  ```

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/angga13142/Vps-setup.git
   cd Vps-setup
   ```

2. Install pre-commit hooks:
   ```bash
   pre-commit install
   ```

3. Verify setup:
   ```bash
   pre-commit run --all-files
   ```

## Code Quality Standards

### ShellCheck Linting

All Bash scripts must pass ShellCheck linting with zero errors. The project uses ShellCheck with error-level severity.

**Configuration**: `.shellcheckrc` in the repository root

**Run linting manually**:
```bash
shellcheck scripts/*.sh
```

**Pre-commit hook**: Automatically runs ShellCheck on all `.sh` files before commits. Commits with ShellCheck errors will be blocked.

**Common ShellCheck issues and fixes**:

- **SC2162**: Use `read -r` instead of `read` to prevent backslash mangling
- **SC2034**: Unused variables - either use them or add `# shellcheck disable=SC2034` with rationale
- **SC2155**: Declare and assign separately - assign first, then declare readonly
- **SC1091**: External file sourcing - add `# shellcheck disable=SC1091` with explanation if intentional

**Example**:
```bash
# Good
read -rp "Enter value: " value

# Bad (SC2162 warning)
read -p "Enter value: " value
```

### Pre-commit Hooks

The project uses pre-commit hooks to ensure code quality:

- **ShellCheck**: Lints all `.sh` files with error severity
- **trailing-whitespace**: Removes trailing whitespace
- **end-of-file-fixer**: Ensures files end with newline
- **check-yaml**: Validates YAML files
- **check-added-large-files**: Prevents committing large files
- **check-merge-conflict**: Detects merge conflict markers
- **check-case-conflict**: Detects case-only filename conflicts

**Bypassing hooks** (emergency only):
```bash
git commit --no-verify -m "Emergency fix"
```
⚠️ **Warning**: Only bypass hooks in genuine emergencies. All code must pass quality checks before merging.

## Testing

### Running Tests

Run the full test suite:
```bash
bats tests/
```

Run specific test files:
```bash
bats tests/unit/test_user_creation.bats
```

Run tests by tag:
```bash
# Run only unit tests
bats --filter-tags unit tests/

# Run only integration tests
bats --filter-tags integration tests/

# Exclude slow tests
bats --filter-tags '!slow' tests/
```

### Test Structure

The test suite is organized into:
- **Unit tests** (`tests/unit/`): Test individual functions in isolation
  - `test_user_creation.bats` - User creation and validation
  - `test_docker_setup.bats` - Docker repository and installation
  - `test_xfce_config.bats` - XFCE mobile optimization
  - `test_shell_config.bats` - Shell configuration and PS1 prompt

- **Integration tests** (`tests/integration/`): Test script execution end-to-end
  - `test_idempotency.bats` - Verify functions can run multiple times safely
  - `test_full_installation.bats` - End-to-end script execution

### Writing Tests

Tests are written using bats-core. See `tests/` directory for examples.

**Test structure**:
```bash
#!/usr/bin/env bats

# bats file_tags=unit

load 'tests/helpers/bats-support/load'
load 'tests/helpers/bats-assert/load'

setup() {
    # Test setup code
}

teardown() {
    # Test cleanup code
}

@test "function_name handles valid input" {
    # Purpose: What is being tested
    # Preconditions: Required setup
    # Expected: What should happen
    # Assertions: What is verified

    run function_name "valid_input"
    assert_success
    assert_output "expected_output"
}
```

**Important Notes**:
- Most tests require root privileges - run with `sudo bats tests/`
- Tests that require root are marked with `skip "Requires root privileges"`
- Use `setup()` and `teardown()` for test isolation
- Always clean up test data in `teardown()`

## Pull Request Process

### 1. Create a Feature Branch

```bash
# Create and switch to feature branch
git checkout -b feature/your-feature-name

# Or use the main/master branch name based on your repository
git checkout -b feature/your-feature-name origin/master
```

**Branch Naming**:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `test/` - Test additions or improvements
- `refactor/` - Code refactoring

### 2. Make Your Changes

- Follow coding standards (enforced by ShellCheck)
- Add tests for new functionality
- Update documentation as needed
- Ensure all changes are idempotent (safe to run multiple times)

### 3. Test Your Changes

**Before committing, always run quality checks**:

```bash
# Run linting
shellcheck scripts/*.sh

# Run tests (requires sudo for most tests)
sudo bats tests/

# Run specific test file
sudo bats tests/unit/test_user_creation.bats

# Run pre-commit hooks manually
pre-commit run --all-files
```

**Ensure**:
- ✅ All ShellCheck checks pass (zero errors)
- ✅ All tests pass (or appropriately skipped)
- ✅ Pre-commit hooks pass
- ✅ Script runs successfully on Debian 13

### 4. Commit Your Changes

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: Add new feature"
```

**Pre-commit hooks will run automatically**. If hooks fail:
- Fix the issues
- Stage fixes: `git add .`
- Commit again: `git commit -m "feat: Add new feature"`

**⚠️ Warning**: Only bypass hooks (`--no-verify`) in genuine emergencies.

### 5. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/your-feature-name
```

Then:
1. Go to GitHub repository
2. Click "New Pull Request"
3. Select your branch
4. Fill out PR description:
   - What changes were made
   - Why the changes were needed
   - How to test the changes
   - Related issues (if any)

### 6. CI/CD Checks

GitHub Actions will automatically:
- Run ShellCheck linting on all `.sh` files
- Run test suite with bats
- Report results in PR status checks

**All checks must pass** before PR can be merged.

### 7. Code Review

- Wait for maintainer review
- Address feedback promptly
- Make requested changes
- Push updates to the same branch (PR updates automatically)

### 8. Merge

Once approved and all checks pass:
- Maintainer will merge the PR
- Your branch will be merged into main/master
- You can delete your feature branch

**Merge Requirements**:
- ✅ At least one approval from maintainer
- ✅ All CI/CD checks passing
- ✅ No merge conflicts
- ✅ Up to date with base branch

## Commit Message Guidelines

Follow conventional commit format:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `test:` Test additions or changes
- `refactor:` Code refactoring
- `chore:` Maintenance tasks

**Example**:
```
feat: Add Docker installation verification

- Verify Docker installation after setup
- Add error handling for Docker service
- Update documentation with verification steps
```

## Questions?

If you have questions or need help, please:
- Open an issue on GitHub
- Check existing documentation
- Review existing code for examples

Thank you for contributing! 🎉
