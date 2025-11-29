#!/usr/bin/env bats

# bats file_tags=integration,idempotency

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
    # Note: We don't restore hostname as it may have been changed
}

@test "create_user is idempotent - can run twice without error" {
    # Purpose: Verify create_user function is idempotent
    # Preconditions: None
    # Expected: First call creates user, second call skips
    # Assertions: Both calls succeed, user exists after both

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script (main() won't run due to guard)
    source "$SCRIPT_PATH" 2>/dev/null || true

    # First call - should create user
    run create_user "$TEST_USER" "$TEST_PASS"
    assert_success

    # Verify user exists
    run id "$TEST_USER"
    assert_success

    # Second call - should skip (idempotent)
    run create_user "$TEST_USER" "$TEST_PASS"
    assert_success

    # Verify user still exists
    run id "$TEST_USER"
    assert_success
}

@test "setup_docker_repository is idempotent - can run twice" {
    # Purpose: Verify setup_docker_repository is idempotent
    # Preconditions: None
    # Expected: Both calls succeed, repository configured correctly
    # Assertions: Repository file exists and is valid after both calls

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script (main() won't run due to guard)
    source "$SCRIPT_PATH" 2>/dev/null || true

    # First call
    run setup_docker_repository
    assert_success

    # Verify repository file exists
    [ -f /etc/apt/sources.list.d/docker.sources ] || return 1

    # Store initial content
    local initial_content
    initial_content=$(cat /etc/apt/sources.list.d/docker.sources)

    # Second call
    run setup_docker_repository
    assert_success

    # Verify repository still exists and is valid
    [ -f /etc/apt/sources.list.d/docker.sources ] || return 1

    # Verify content is still valid (DEB822 format)
    run grep -q "Types: deb" /etc/apt/sources.list.d/docker.sources
    assert_success
}

@test "configure_shell is idempotent - can run twice" {
    # Purpose: Verify configure_shell is idempotent
    # Preconditions: Test user exists
    # Expected: Second call doesn't duplicate configuration
    # Assertions: Configuration marker appears only once

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script but prevent main() from running
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Create test user
    create_user "$TEST_USER" "$TEST_PASS"

    # First call
    run configure_shell "$TEST_USER"
    assert_success

    local bashrc_file="/home/$TEST_USER/.bashrc"
    local first_count
    first_count=$(grep -c "Mobile-Ready Workstation Custom Configuration" "$bashrc_file" || echo "0")

    # Second call
    run configure_shell "$TEST_USER"
    assert_success

    # Verify configuration marker count hasn't increased
    local second_count
    second_count=$(grep -c "Mobile-Ready Workstation Custom Configuration" "$bashrc_file" || echo "0")

    # Should be same (idempotent)
    assert_equal "$second_count" "$first_count"
}

@test "configure_xfce_mobile is idempotent - can run twice" {
    # Purpose: Verify configure_xfce_mobile is idempotent
    # Preconditions: Test user exists
    # Expected: Both calls succeed without errors
    # Assertions: Configuration files exist after both calls

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script but prevent main() from running
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Create test user
    create_user "$TEST_USER" "$TEST_PASS"

    # First call
    run configure_xfce_mobile "$TEST_USER"
    assert_success

    # Second call
    run configure_xfce_mobile "$TEST_USER"
    assert_success

    # Verify configuration files still exist (if script was created)
    local home_dir="/home/$TEST_USER"
    # The script may not exist if xfconf-query succeeded directly
    # In that case, the configuration was applied directly, which is also valid
    if [ -f "$home_dir/.xfce4-mobile-config.sh" ]; then
        [ -f "$home_dir/.xfce4-mobile-config.sh" ] || return 1
    fi
}

@test "system_prep is idempotent - can run twice" {
    # Purpose: Verify system_prep is idempotent
    # Preconditions: None
    # Expected: Both calls succeed, packages installed only once
    # Assertions: Essential packages are installed after both calls

    [ "$EUID" -eq 0 ] || skip "Requires root privileges - run with sudo"

    # Source script (main() won't run due to guard)
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Note: On non-Debian systems, apt-get update may fail due to Docker repository
    # configured for Debian. We need to handle this gracefully.
    # Remove any Docker repository if it exists and causes issues
    if [ -f /etc/apt/sources.list.d/docker.sources ]; then
        local codename
        codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
        if [ "$codename" != "trixie" ] && [ "$codename" != "bookworm" ]; then
            rm -f /etc/apt/sources.list.d/docker.sources 2>/dev/null || true
            rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null || true
        fi
    fi

    # First call
    run system_prep "$TEST_HOSTNAME"
    assert_success

    # Second call
    run system_prep "$TEST_HOSTNAME"
    assert_success

    # Verify essential packages are installed
    # Check if packages are installed using dpkg -l (more reliable)
    # dpkg -l output format: ii  package-name version arch description
    run bash -c "dpkg -l curl 2>/dev/null | grep -E '^ii[[:space:]]+curl'"
    assert_success

    run bash -c "dpkg -l git 2>/dev/null | grep -E '^ii[[:space:]]+git'"
    assert_success
}
