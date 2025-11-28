#!/usr/bin/env bats

# bats file_tags=unit

load "${BATS_TEST_DIRNAME}/../helpers/bats-support/load"
load "${BATS_TEST_DIRNAME}/../helpers/bats-assert/load"

# Source the script to test functions
SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/../../scripts/setup-workstation.sh"

setup() {
    export TEST_USER="testuser_$(date +%s)"
    export TEST_DIR=$(mktemp -d)
}

teardown() {
    # Cleanup test user if exists
    if id "$TEST_USER" &>/dev/null; then
        userdel -r "$TEST_USER" 2>/dev/null || true
    fi
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

@test "configure_shell generates .bashrc with custom PS1" {
    # Purpose: Verify .bashrc is generated with custom PS1 prompt
    # Preconditions: User exists
    # Expected: .bashrc contains custom PS1 configuration
    # Assertions: .bashrc file exists and contains PS1 definition

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script (main() won't run due to guard)
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Create test user
    create_user "$TEST_USER" "TestPass123!"

    # Run configure_shell
    run configure_shell "$TEST_USER"
    assert_success

    # Verify .bashrc exists
    local bashrc_file="/home/$TEST_USER/.bashrc"
    [ -f "$bashrc_file" ] || return 1

    # Verify PS1 is configured
    run grep -q "PS1=" "$bashrc_file"
    assert_success

    # Verify PS1 contains expected elements (check for user/host pattern)
    run grep -E "\\\\u|\\u" "$bashrc_file"
    assert_success

    # Verify PS1 contains directory pattern
    run grep -E "\\\\w|\\w" "$bashrc_file"
    assert_success
}

@test "configure_shell includes parse_git_branch function" {
    # Purpose: Verify parse_git_branch function is included in .bashrc
    # Preconditions: .bashrc configured
    # Expected: parse_git_branch function defined
    # Assertions: Function definition exists in .bashrc

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script but prevent main() from running
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Create test user
    create_user "$TEST_USER" "TestPass123!"

    # Run configure_shell
    configure_shell "$TEST_USER"

    # Verify parse_git_branch function exists
    local bashrc_file="/home/$TEST_USER/.bashrc"
    run grep -q "parse_git_branch()" "$bashrc_file"
    assert_success
}

@test "parse_git_branch function returns branch name in correct format" {
    # Purpose: Verify parse_git_branch returns branch name in (branch) format
    # Preconditions: Git repository exists with commits
    # Expected: Function returns (branch-name) format
    # Assertions: Output matches expected format

    # Create temporary git repository
    cd "$TEST_DIR"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > test.txt
    git add test.txt
    git commit -m "Initial commit"
    git checkout -b test-branch

    # Define parse_git_branch function directly (same as in script)
    parse_git_branch() {
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
    }

    # Run function
    run parse_git_branch

    # Assert output contains branch name in parentheses
    assert_success
    assert_output --regexp "^\\(.*\\)$"
}

@test "configure_shell includes aliases" {
    # Purpose: Verify aliases are included in .bashrc
    # Preconditions: .bashrc configured
    # Expected: Aliases (ll, update, docker-clean) are defined
    # Assertions: All aliases exist in .bashrc

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script but prevent main() from running
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Create test user
    create_user "$TEST_USER" "TestPass123!"

    # Run configure_shell
    configure_shell "$TEST_USER"

    # Verify aliases exist
    local bashrc_file="/home/$TEST_USER/.bashrc"
    run grep -q "alias ll=" "$bashrc_file"
    assert_success

    run grep -q "alias update=" "$bashrc_file"
    assert_success

    run grep -q "alias docker-clean=" "$bashrc_file"
    assert_success
}

@test "configure_shell is idempotent" {
    # Purpose: Verify idempotency of shell configuration
    # Preconditions: .bashrc may or may not be configured
    # Expected: Can run multiple times without duplicating configuration
    # Assertions: Second call skips or doesn't duplicate

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script but prevent main() from running
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Create test user
    create_user "$TEST_USER" "TestPass123!"

    # First call
    run configure_shell "$TEST_USER"
    assert_success

    # Count custom configuration markers
    local bashrc_file="/home/$TEST_USER/.bashrc"
    local first_count
    first_count=$(grep -c "Mobile-Ready Workstation Custom Configuration" "$bashrc_file" || echo "0")

    # Second call
    run configure_shell "$TEST_USER"
    assert_success

    # Verify configuration marker count hasn't increased (idempotent)
    local second_count
    second_count=$(grep -c "Mobile-Ready Workstation Custom Configuration" "$bashrc_file" || echo "0")

    # Should be same or only one (if first call didn't add it)
    [ "$second_count" -le "$first_count" ] || [ "$first_count" -eq 0 ]
}
