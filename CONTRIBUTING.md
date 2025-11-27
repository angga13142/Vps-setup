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

### Writing Tests

Tests are written using bats-core. See `tests/` directory for examples.

**Test structure**:
```bash
#!/usr/bin/env bats

load 'tests/helpers/bats-support/load'
load 'tests/helpers/bats-assert/load'

@test "function_name handles valid input" {
    run function_name "valid_input"
    assert_success
    assert_output "expected_output"
}
```

## Pull Request Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Follow coding standards
   - Add tests for new functionality
   - Update documentation as needed

3. **Run quality checks**:
   ```bash
   # Run linting
   shellcheck scripts/*.sh

   # Run tests
   bats tests/

   # Run pre-commit hooks
   pre-commit run --all-files
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: Add new feature"
   ```
   Pre-commit hooks will run automatically.

5. **Push and create PR**:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **CI/CD checks**: GitHub Actions will automatically run linting and tests on your PR.

7. **Code review**: Wait for review and address any feedback.

8. **Merge**: Once approved and all checks pass, your PR will be merged.

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
