# Test Interface Contract

**Feature**: Development Improvements & Quality Assurance  
**Date**: 2025-01-27

## Test Function Signatures

### Unit Test Structure

```bash
#!/usr/bin/env bats

# Load helper libraries
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Setup function (optional)
setup() {
    # Test setup code
    # Runs before each test
}

# Teardown function (optional)
teardown() {
    # Test cleanup code
    # Runs after each test
}

# Test case
@test "descriptive test name" {
    # Test implementation
    run function_under_test "arg1" "arg2"
    assert_success
    assert_output "expected output"
}
```

### Test Function Requirements

**Inputs**:
- Test name: Descriptive string in `@test "name"` format
- Test body: Bash commands with assertions

**Outputs**:
- TAP (Test Anything Protocol) format output
- Exit code: 0 on success, non-zero on failure

**Side Effects**:
- May create temporary files/directories (cleaned in teardown)
- May modify environment variables (restored in teardown)
- Must not modify production files

**Idempotency**: Tests must be re-runnable without side effects

---

## Assertion Functions

### Success/Failure Assertions

```bash
# Assert command succeeded (exit code 0)
assert_success

# Assert command failed (non-zero exit code)
assert_failure [expected_exit_code]

# Assert exit code matches
assert_equal "$status" 0
```

### Output Assertions

```bash
# Assert exact output match
assert_output "expected output"

# Assert output contains substring
assert_output --partial "substring"

# Assert output matches regex
assert_output --regexp "pattern"

# Assert output is empty
assert_output ""

# Assert output does not contain
refute_output --partial "unwanted"
```

### File Assertions

```bash
# Assert file exists
assert_file_exists "path/to/file"

# Assert file does not exist
refute_file_exists "path/to/file"

# Assert file contains content
assert_file_contains "path/to/file" "content"
```

---

## Test Organization

### Test File Naming

- Format: `test_<function_or_feature>.bats`
- Location: `tests/unit/` or `tests/integration/`
- Example: `test_user_creation.bats`

### Test Tagging

```bash
# Tag all tests in file
# bats file_tags=unit,fast

# Tag specific test
# bats test_tags=integration,slow
@test "test name" {
    # ...
}
```

### Test Filtering

```bash
# Run tests with specific tags
bats --filter-tags unit tests/

# Exclude tags
bats --filter-tags '!slow' tests/

# Multiple tag filters (OR logic)
bats --filter-tags unit --filter-tags integration tests/
```

---

## Test Coverage Requirements

### Critical Functions (80% coverage required)

- `create_user()` - User account creation
- `setup_docker_repository()` - Docker repository configuration
- `install_docker()` - Docker installation
- `configure_xfce_mobile()` - XFCE mobile optimization
- `configure_shell()` - Shell configuration
- `get_user_inputs()` - User input collection
- `system_prep()` - System preparation
- `finalize()` - Installation finalization

### Test Types Required

1. **Unit Tests**: Test individual functions in isolation
2. **Integration Tests**: Test script execution end-to-end
3. **Idempotency Tests**: Verify functions can run multiple times safely
4. **Error Handling Tests**: Verify error messages and recovery

---

## Test Execution Contract

### Local Execution

```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/unit/test_user_creation.bats

# Run with verbose output
bats --verbose tests/

# Run with TAP output
bats --tap tests/
```

### CI/CD Execution

```yaml
# GitHub Actions step
- name: Run tests
  run: bats tests/
```

### Expected Behavior

- Tests must complete in < 5 minutes
- All tests must pass before merge
- Test output must be clear and actionable
- Failed tests must provide debugging information

---

## Test Data Management

### Test Fixtures

- Location: `tests/fixtures/`
- Format: Sample files, mock data
- Usage: Loaded in setup(), cleaned in teardown()

### Temporary Files

- Created in: `/tmp/` or test-specific directory
- Naming: Include test name for uniqueness
- Cleanup: Always removed in teardown()

### Environment Isolation

- Each test runs in isolated environment
- Environment variables restored after test
- No shared state between tests

---

## Test Documentation Requirements

### Test Case Documentation

Each test must include:
- Purpose: What is being tested
- Preconditions: Required setup
- Expected behavior: What should happen
- Assertions: What is verified

### Example

```bash
@test "create_user creates user with valid input" {
    # Purpose: Verify user creation with valid username and password
    # Preconditions: None (function is self-contained)
    # Expected: User is created, password is set
    # Assertions: User exists, can login
    
    run create_user "testuser" "testpass123"
    assert_success
    assert_output --partial "User created"
    
    # Verify user exists
    id testuser
    assert_success
}
```

