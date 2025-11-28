# Contributing Guidelines

Thank you for your interest in contributing to the Mobile-Ready Coding Workstation Setup Script project!

## Development Workflow

### Developer Workflow Requirements (FR-034)

The standard developer workflow follows this sequence:

1. **Install tools** → Install required development tools (ShellCheck, bats-core, pre-commit)
2. **Write code** → Make your changes following coding standards
3. **Lint** → Run ShellCheck to verify code quality
4. **Test** → Run test suite to verify functionality
5. **Commit** → Commit changes (pre-commit hooks run automatically)

**Example workflow**:
```bash
# 1. Install tools (one-time setup)
sudo apt install shellcheck bats
pipx install pre-commit
pre-commit install

# 2. Write code
vim scripts/setup-workstation.sh

# 3. Lint
shellcheck scripts/setup-workstation.sh

# 4. Test
sudo bats tests/

# 5. Commit (hooks run automatically)
git add scripts/setup-workstation.sh
git commit -m "feat: Add new feature"
```

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

### Test Coverage Requirements (FR-019)

**Critical Functions** (explicit list requiring 80% test coverage):

The following 15 functions are considered critical and must have test coverage:

1. `create_user()` - User account creation
2. `setup_docker_repository()` - Docker repository configuration
3. `install_docker()` - Docker installation
4. `configure_xfce_mobile()` - XFCE mobile optimization
5. `configure_shell()` - Shell configuration
6. `get_user_inputs()` - User input collection
7. `system_prep()` - System preparation
8. `finalize()` - Installation finalization
9. `setup_desktop_mobile()` - Desktop environment setup
10. `setup_dev_stack()` - Development stack setup
11. `install_nvm_nodejs()` - NVM and Node.js installation
12. `verify_python()` - Python verification
13. `verify_installation()` - Installation verification
14. `log()` - Structured logging function
15. `check_debian_version()` - Debian version validation

**Coverage Target**: At least 80% of these critical functions must have test coverage (12 out of 15 functions minimum).

### Test Coverage Calculation (FR-035, SC-002)

**Measurement Method**:

Test coverage is calculated using the following formula:

```
Coverage % = (tested critical functions / total critical functions) × 100%
```

**Calculation Steps**:
1. List all 15 critical functions from the list above
2. Identify which functions have test cases in `tests/unit/` or `tests/integration/`
3. Count tested functions (functions with at least one test case)
4. Calculate: `(tested functions / 15) × 100%`
5. Target: ≥80% (at least 12 functions must have tests)

**Manual Calculation Example**:
```bash
# Count test files that cover critical functions
# Each test file should test one or more critical functions
# Review test files to verify which functions are covered

# Example: If 12 out of 15 functions have tests
# Coverage = (12 / 15) × 100% = 80% ✓
```

**Tools**:
- Manual review of test files
- Automated tools like `bats-coverage` (if available)
- CI/CD pipeline can track coverage over time

### Test Coverage Boundary Conditions (FR-023, FR-024)

**Zero Test Coverage Scenario** (new projects):
- Acceptable for initial project setup
- Must achieve 80% coverage before first production release
- Document coverage gap in README with timeline for test addition
- Example: "Current test coverage: 0%. Target: 80% before v1.0.0 release."

**100% Test Coverage Scenario** (maximum coverage):
- Ideal but not required
- Focus on critical functions first (80% minimum)
- Additional coverage is optional but encouraged
- Do not sacrifice code quality for 100% coverage
- Balance between coverage and test maintainability

**Coverage Strategy**:
1. **Phase 1**: Cover all 15 critical functions (100% of critical functions)
2. **Phase 2**: Add tests for edge cases and error handling
3. **Phase 3**: Add integration tests for end-to-end scenarios
4. **Phase 4**: Optional coverage for helper functions

### Public Functions Documentation Requirements (FR-020)

**Public Functions** (explicit list requiring complete documentation):

All functions defined in `scripts/setup-workstation.sh` that are:
- Called from `main()` function (entry points)
- Exported or intended for external use
- Documented with function header comments

**Complete list** (matches Critical Functions list, plus helper functions):

1. `create_user()` - User account creation
2. `setup_docker_repository()` - Docker repository configuration
3. `install_docker()` - Docker installation
4. `configure_xfce_mobile()` - XFCE mobile optimization
5. `configure_shell()` - Shell configuration
6. `get_user_inputs()` - User input collection
7. `system_prep()` - System preparation
8. `finalize()` - Installation finalization
9. `setup_desktop_mobile()` - Desktop environment setup
10. `setup_dev_stack()` - Development stack setup
11. `install_nvm_nodejs()` - NVM and Node.js installation
12. `verify_python()` - Python verification
13. `verify_installation()` - Installation verification
14. `log()` - Structured logging function
15. `check_debian_version()` - Debian version validation

**Documentation Requirements**:
Each public function must have documentation block with:
- **Purpose**: What the function does
- **Inputs**: Parameters and their types/constraints
- **Outputs**: Return values and side effects
- **Idempotency**: Whether function is safe to run multiple times
- **Error Handling**: How errors are handled and reported

**Example**:
```bash
# Function: create_user
# Purpose: Creates a new user account with specified username and password
# Inputs:
#   - username: String, valid username format
#   - password: String, non-empty password
# Outputs:
#   - Returns 0 on success, non-zero on failure
#   - Side effects: Creates user account, sets password, creates home directory
# Idempotency: Yes - checks if user exists before creation
# Error Handling: Logs errors with context, returns error code
```

### Documentation Update Process (FR-033)

**Update Frequency**:
- **On each PR**: Review documentation for accuracy when code changes
- **Major updates**: Quarterly review of all documentation for completeness and accuracy

**Update Triggers**:
- New features added → Update README Features section
- Function changes → Update function documentation
- New error scenarios → Update troubleshooting guide
- Workflow changes → Update CONTRIBUTING.md
- Version releases → Update CHANGELOG.md

**Review Checklist**:
- [ ] README.md reflects current functionality
- [ ] Function documentation matches implementation
- [ ] Troubleshooting guide covers new issues
- [ ] CONTRIBUTING.md reflects current workflow
- [ ] CHANGELOG.md updated with changes
- [ ] All links are valid and working

**Process**:
1. Update documentation as part of feature development
2. Include documentation changes in same PR as code changes
3. Review documentation during PR review
4. Quarterly comprehensive review of all documentation
5. Archive outdated documentation in `docs/archive/` if needed

### Test Suite Stability Requirements (FR-031)

**Stability Target**: 95% pass rate over 10 consecutive runs

**Definition**: Test suite stability measures the consistency of test results across multiple runs. A stable test suite should pass consistently, with only rare flaky failures.

**Measurement**:
- Run test suite 10 times consecutively: `for i in {1..10}; do sudo bats tests/; done`
- Count successful runs (all tests pass)
- Calculate: `(successful runs / 10) × 100%`
- Target: ≥95% (at least 9 out of 10 runs must pass)

**Acceptable Flaky Test Tolerance**:
- Up to 5% failure rate is acceptable (allows for rare environment issues)
- Flaky tests should be identified and fixed
- Tests that consistently fail should be investigated and fixed

**Improving Stability**:
- Use proper test isolation (setup/teardown)
- Avoid race conditions in tests
- Mock external dependencies
- Use deterministic test data
- Avoid time-dependent assertions
- Clean up test artifacts properly

**Monitoring**:
- Track test pass rate in CI/CD over time
- Identify patterns in flaky test failures
- Document known flaky tests with skip conditions if needed

### Pre-commit Hook Reliability Requirements (FR-032)

**Reliability Target**: 99% success rate

**Definition**: Pre-commit hook reliability measures how often hooks execute successfully. A reliable hook should work consistently, with only rare failures due to environment issues.

**Measurement**:
- Track pre-commit hook execution over time
- Count successful hook runs (hooks complete without errors)
- Count total hook runs (including failures)
- Calculate: `(successful runs / total runs) × 100%`
- Target: ≥99% (allows for rare environment issues)

**Acceptable Failure Tolerance**:
- Up to 1% failure rate is acceptable (allows for rare environment issues)
- Failures should be investigated and fixed
- Environment-specific issues should be documented

**Common Failure Causes**:
- Network issues (downloading hook dependencies)
- Permission issues (file system access)
- Environment configuration issues (missing tools)
- Hook timeout (very rare)

**Improving Reliability**:
- Cache hook dependencies locally
- Use stable hook versions
- Document hook requirements clearly
- Provide fallback mechanisms
- Test hooks in CI/CD environment

**Monitoring**:
- Track hook success rate over time
- Review hook failures in CI/CD logs
- Document known issues and workarounds

### Test Performance Limits (FR-026)

**Large Test Suites** (>100 tests):
- **Execution time limit**: <10 minutes (2x normal limit of 5 minutes)
- **Strategy**: Use test tags to run subsets during development
- **Full suite**: Runs in CI/CD only
- **Development**: Run specific test files or tagged subsets

**Running Test Subsets**:
```bash
# Run only unit tests (faster during development)
bats tests/unit/

# Run only integration tests
bats tests/integration/

# Run specific test file
bats tests/unit/test_user_creation.bats

# Full suite (run in CI/CD)
bats tests/
```

**Performance Optimization**:
- Use test tags to categorize tests (unit, integration, slow)
- Skip slow tests during development: `bats --filter-tags '!slow' tests/`
- Run full suite only before commits or in CI/CD
- Monitor test execution time in CI/CD logs

**If Tests Exceed Limits**:
- Review test structure for optimization opportunities
- Consider splitting large test files
- Use test fixtures and helpers to reduce duplication
- Document performance impact in plan.md

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

### Recovery Procedures for Failed CI/CD Checks (FR-022)

**CI/CD Check Failure Recovery Process**:

When CI/CD checks fail, follow this recovery procedure:

1. **Receive Notification**: Developer receives notification of failed CI checks via GitHub PR status (red X indicator)

2. **Review Error Messages**:
   - Click on the failed check in PR status
   - Review error messages in CI logs (GitHub Actions tab)
   - Identify which job failed (lint or test)
   - Note specific error details and file locations

3. **Fix Issues Locally**:
   - Pull latest changes: `git pull origin <branch-name>`
   - Fix issues based on error messages
   - For lint failures: Run `shellcheck scripts/*.sh` locally
   - For test failures: Run `sudo bats tests/` locally

4. **Verify Fixes Locally**:
   ```bash
   # Run pre-commit hooks to verify linting
   pre-commit run --all-files

   # Run test suite to verify tests pass
   sudo bats tests/

   # Ensure all checks pass locally before pushing
   ```

5. **Push Fixes**:
   ```bash
   git add .
   git commit -m "fix: Resolve CI/CD check failures"
   git push origin <branch-name>
   ```

6. **CI/CD Re-runs Automatically**: GitHub Actions automatically re-runs on new push

7. **Repeat if Needed**: If checks still fail, repeat steps 2-6 until all checks pass

**Common Failure Scenarios**:

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

### Rollback Procedures for Deployment Failures (Recovery Flows)

**If deployment fails** (e.g., code merged but causes issues in production):

1. **Identify Failed Deployment Step**:
   - Review deployment logs
   - Identify which step failed (installation, configuration, service start)
   - Note error messages and context

2. **Revert Code Changes**:
   ```bash
   # Option 1: Revert specific commit (recommended for single bad commit)
   git revert <commit-hash>
   git push origin main

   # Option 2: Reset to previous working state (use with caution)
   git reset --hard <previous-commit-hash>
   git push --force origin main  # ⚠️ Only if necessary, coordinate with team
   ```

3. **Verify Reverted Code Passes All Checks**:
   - CI/CD will automatically run on revert commit
   - Verify all checks pass (lint, test)
   - Confirm code is in working state

4. **Document Failure Reason**:
   - Create GitHub Issue documenting:
     - What failed
     - Why it failed
     - Steps to reproduce (if applicable)
     - Proposed fix
   - Link issue to reverted commit

5. **Re-deploy After Fixes**:
   - Implement fixes in new branch
   - Test thoroughly locally
   - Create PR with fixes
   - Ensure all CI/CD checks pass
   - Merge after review

**Prevention**:
- Always test changes locally before pushing
- Run full test suite before committing
- Review CI/CD logs before merging
- Use feature branches for all changes
- Test in staging environment if available

### Manual CI/CD Setup Tasks

Some CI/CD tasks require GitHub UI interaction or CLI commands. See [docs/cicd-setup-guide.md](docs/cicd-setup-guide.md) for detailed step-by-step instructions on:

- **T064**: Configuring required status checks in GitHub repository settings (using `gh` CLI or UI)
- **T065**: Testing CI/CD workflow by pushing code
- **T066**: Testing CI/CD workflow by creating PR
- **T067**: Testing merge blocking with intentional failures

## Measurement Methods (FR-035)

For detailed measurement methods for all success criteria (SC-001 through SC-010), see [docs/measurement-methods.md](docs/measurement-methods.md).

This document defines how each success criterion is measured and validated, including:
- SC-001: ShellCheck linting pass rate
- SC-002: Test coverage calculation
- SC-003: Function documentation coverage
- SC-004: First-attempt success rate
- SC-005: CI/CD pipeline success rate
- SC-006: Merge blocking rate
- SC-007: Error message context coverage
- SC-008: Logging operation coverage
- SC-009: Troubleshooting guide resolution rate
- SC-010: Code review time reduction

All measurement methods are objective and verifiable.

## Questions?

If you have questions or need help, please:
- Open an issue on GitHub
- Check existing documentation
- Review existing code for examples

Thank you for contributing! 🎉
