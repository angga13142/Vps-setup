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

**Bypassing hooks** (emergency only - FR-042):

Pre-commit hooks can be bypassed using the `--no-verify` flag, but this should only be used in genuine emergencies. When bypassing hooks, you **MUST** include `[SKIP HOOKS]` in your commit message to document the justification.

**Format**: `[SKIP HOOKS] <justification>`

**Example**:
```bash
git commit --no-verify -m "fix: Emergency security patch [SKIP HOOKS] Critical vulnerability fix, hooks will be verified in follow-up commit"
```

**Requirements**:
- ⚠️ **Warning**: Only bypass hooks in genuine emergencies
- **MUST** include `[SKIP HOOKS]` in commit message
- **MUST** provide justification for bypass
- All code must pass quality checks before merging to main/master
- Follow-up commits must pass all hooks normally

**Recovery Procedure** (FR-021):
1. Developer receives error message with file:line:column and SC code
2. Developer fixes issues in code
3. Developer re-runs `pre-commit run --all-files` to verify fixes
4. Developer commits again (hook will re-run automatically)
5. If bypass needed: Use `git commit --no-verify` with `[SKIP HOOKS]` and documented justification in commit message

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

## CI/CD Workflow

The project uses GitHub Actions for continuous integration and continuous deployment (CI/CD). The workflow automatically runs on every push and pull request.

### Workflow Overview

**Location**: `.github/workflows/ci.yml`

**Jobs**:
1. **Lint Job** (`lint`):
   - Installs ShellCheck
   - Runs ShellCheck recursively on all `.sh` files in the repository
   - Excludes `.git/` and `tests/helpers/` directories
   - Must pass with zero errors
   - Timeout: 5 minutes

2. **Test Job** (`test`):
   - Depends on lint job (runs only if lint passes)
   - Installs bats and dependencies
   - Downloads bats helper libraries (bats-support, bats-assert)
   - Runs test suite from `tests/` directory
   - Properly detects actual test failures vs expected skips
   - Uploads test results as artifacts
   - Timeout: 10 minutes

**Trigger Events**:
- Push to `master`, `main`, or branches matching `*-development-improvements`
- Pull requests to `master` or `main`
- Manual trigger via `workflow_dispatch`

**Status Checks**:
- Both `lint` and `test` jobs are required for merge
- Configured in GitHub repository settings → Branches → Branch protection rules
- PRs cannot be merged until all checks pass

### Local CI Simulation

```bash
# Simulate CI environment
docker run --rm -v "$PWD:/workspace" -w /workspace \
  debian:13 \
  bash -c "apt update && apt install -y shellcheck bats && \
           find . -name '*.sh' -type f -not -path './.git/*' -not -path './tests/helpers/*' -exec shellcheck {} \; && \
           bats tests/"
```

### Check CI Status

- **View workflow runs**: GitHub → Actions tab
- **Check specific run**: Click on workflow run
- **View logs**: Expand job steps to see detailed output
- **Download artifacts**: Available in workflow run page (test results, logs)
- **PR status**: Check PR page for status check indicators (✅ or ❌)

### Understanding CI/CD Results

**Success Indicators**:
- ✅ Green checkmark: All checks passed
- All jobs completed successfully
- PR can be merged (if other requirements met)

**Failure Indicators**:
- ❌ Red X: One or more checks failed
- Review error messages in Actions tab
- Fix issues and push updates
- PR cannot be merged until all checks pass

**In Progress**:
- ⏳ Yellow circle: Checks are running
- Wait for completion before merging

### Troubleshooting CI/CD Failures

**Lint Job Fails**:
```bash
# Run ShellCheck locally to see errors
find . -name "*.sh" -type f -not -path "./.git/*" -not -path "./tests/helpers/*" -exec shellcheck {} \;

# Fix errors and commit
git add scripts/
git commit -m "fix: Resolve ShellCheck errors"
git push
```

**Test Job Fails**:
```bash
# Run tests locally (requires sudo for most tests)
sudo bats tests/

# Fix failing tests and commit
git add tests/
git commit -m "fix: Fix failing tests"
git push
```

**Workflow Not Running**:
- Check if workflow file exists: `.github/workflows/ci.yml`
- Verify branch name matches trigger patterns
- Check GitHub Actions is enabled for repository
- Review workflow syntax in Actions tab

### Manual CI/CD Setup Tasks

Some CI/CD tasks require GitHub UI interaction or CLI commands. See [docs/cicd-setup-guide.md](docs/cicd-setup-guide.md) for detailed step-by-step instructions on:

- **T064**: Configuring required status checks in GitHub repository settings (using `gh` CLI or UI)
- **T065**: Testing CI/CD workflow by pushing code
- **T066**: Testing CI/CD workflow by creating PR
- **T067**: Testing merge blocking with intentional failures

## Questions?

If you have questions or need help, please:
- Open an issue on GitHub
- Check existing documentation
- Review existing code for examples

Thank you for contributing! 🎉
