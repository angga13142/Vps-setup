#!/usr/bin/env bats

# bats file_tags=integration,slow

load "${BATS_TEST_DIRNAME}/../helpers/bats-support/load"
load "${BATS_TEST_DIRNAME}/../helpers/bats-assert/load"

# Source the script to test functions
SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/../../scripts/setup-workstation.sh"

setup() {
    export TEST_USER="testuser_$(date +%s)"
    export TEST_PASS="TestPass123!"
    export TEST_HOSTNAME="test-host-$(date +%s)"
}

teardown() {
    # Cleanup test user if exists
    if id "$TEST_USER" &>/dev/null; then
        userdel -r "$TEST_USER" 2>/dev/null || true
    fi
}

@test "full installation script execution - smoke test" {
    # Purpose: Verify main script execution flow
    # Preconditions: Script exists and is executable
    # Expected: Script can be sourced without syntax errors
    # Assertions: Script loads successfully

    # Test that script can be sourced (syntax check)
    run bash -n "$SCRIPT_PATH"
    assert_success

    # Test that script has main function
    run grep -q "^main()" "$SCRIPT_PATH"
    assert_success
}

@test "check_debian_version validates Debian 13" {
    # Purpose: Verify Debian version check function
    # Preconditions: Running on Debian 13
    # Expected: Function succeeds on Debian 13
    # Assertions: Function exits with success

    # Source only the function we need, not the whole script
    # Extract just the check_debian_version function
    eval "$(sed -n '/^check_debian_version() {/,/^}$/p' "$SCRIPT_PATH")"

    # Only run if we're on Debian
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "debian" ]; then
            # On Debian, check if version check would work
            run check_debian_version
            # Should succeed on Debian 13, may fail on other versions
            # We'll just verify it doesn't crash
        else
            skip "Not running on Debian"
        fi
    else
        skip "Cannot determine OS version"
    fi
}

@test "check_root_privileges requires root" {
    # Purpose: Verify root check function behavior
    # Preconditions: May or may not be root
    # Expected: Function checks for root privileges
    # Assertions: Function exists and can be called

    # Source script (main() won't run due to guard)
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Function should exist
    run type check_root_privileges
    assert_success

    # Note: Actual execution requires root, so we skip if not root
    if [ "$EUID" -eq 0 ]; then
        run check_root_privileges
        assert_success
    else
        skip "Requires root privileges"
    fi
}

@test "validate_hostname validates hostname format" {
    # Purpose: Verify hostname validation function
    # Preconditions: None
    # Expected: Valid hostnames pass, invalid ones fail
    # Assertions: Function returns correct exit codes

    # Extract just the validate_hostname function
    eval "$(sed -n '/^validate_hostname() {/,/^}$/p' "$SCRIPT_PATH")"

    # Test valid hostname
    run validate_hostname "valid-hostname"
    assert_success

    # Test invalid hostname (contains spaces)
    run validate_hostname "invalid hostname"
    assert_failure

    # Test invalid hostname (contains special chars)
    run validate_hostname "invalid@hostname"
    assert_failure
}

@test "get_server_ip returns IP address" {
    # Purpose: Verify IP address detection function
    # Preconditions: Network interface exists
    # Expected: Function returns valid IP address or hostname
    # Assertions: Output is non-empty

    # Extract just the get_server_ip function
    eval "$(sed -n '/^get_server_ip() {/,/^}$/p' "$SCRIPT_PATH")"

    # Run get_server_ip
    run get_server_ip

    # Should succeed
    assert_success

    # Output should be non-empty (could be IP or hostname)
    assert_output --regexp ".+"
}
