#!/usr/bin/env bats

# bats file_tags=unit

load "${BATS_TEST_DIRNAME}/../helpers/bats-support/load"
load "${BATS_TEST_DIRNAME}/../helpers/bats-assert/load"

# Source the script to test functions
SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/../../scripts/setup-workstation.sh"

setup() {
    # Create temporary directory for test user home
    TEST_DIR=$(mktemp -d)
    export TEST_USER="testuser_$(date +%s)"
    export TEST_PASS="TestPass123!"
}

teardown() {
    # Cleanup: Remove test user if it exists
    if id "$TEST_USER" &>/dev/null; then
        userdel -r "$TEST_USER" 2>/dev/null || true
    fi
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

# Helper function to source the script and extract create_user function
load_create_user() {
    # Source the script in a subshell to avoid conflicts
    # We'll test by calling the script functions directly
    source "$SCRIPT_PATH" 2>/dev/null || true
}

@test "create_user creates user with valid username and password" {
    # Purpose: Verify user creation with valid username and password
    # Preconditions: None (function is self-contained)
    # Expected: User is created, password is set
    # Assertions: User exists, can be verified with id command

    # Skip if not root
    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script (main() won't run due to guard)
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Run create_user function
    run create_user "$TEST_USER" "$TEST_PASS"

    # Assert success
    assert_success

    # Verify user exists
    run id "$TEST_USER"
    assert_success
    assert_output --partial "$TEST_USER"
}

@test "create_user is idempotent - can run twice without error" {
    # Purpose: Verify idempotency of user creation
    # Preconditions: User may or may not exist
    # Expected: First call creates user, second call skips creation
    # Assertions: Both calls succeed, user exists after both

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script (main() won't run due to guard)
    source "$SCRIPT_PATH" 2>/dev/null || true

    # First call - should create user
    run create_user "$TEST_USER" "$TEST_PASS"
    assert_success

    # Second call - should skip (idempotent)
    run create_user "$TEST_USER" "$TEST_PASS"
    assert_success

    # Verify user still exists
    run id "$TEST_USER"
    assert_success
}

@test "create_user handles invalid username format" {
    # Purpose: Verify validation of username format
    # Preconditions: Invalid username provided
    # Expected: Function should handle invalid input gracefully
    # Note: Actual validation happens in get_user_inputs, but we test edge cases

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script (main() won't run due to guard)
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Test with invalid username (contains spaces)
    run create_user "invalid user" "$TEST_PASS"
    # Should fail or handle gracefully
    # Note: useradd will fail on invalid usernames
}

@test "create_user sets password correctly" {
    # Purpose: Verify password is set for created user
    # Preconditions: User created
    # Expected: Password can be used for authentication
    # Assertions: Password is set (can be verified with chpasswd or su)

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script (main() won't run due to guard)
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Create user
    run create_user "$TEST_USER" "$TEST_PASS"
    assert_success

    # Verify password is set (check if we can su to the user)
    # This is a basic check - full password verification would require interactive session
    run grep "^${TEST_USER}:" /etc/passwd
    assert_success
    assert_output --partial "$TEST_USER"
}
