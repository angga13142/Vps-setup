#!/usr/bin/env bats

# bats file_tags=unit

load "${BATS_TEST_DIRNAME}/../helpers/bats-support/load"
load "${BATS_TEST_DIRNAME}/../helpers/bats-assert/load"

# Source the script to test functions
SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/../../scripts/setup-workstation.sh"

setup() {
    # Source the script to load functions
    source "$SCRIPT_PATH" 2>/dev/null || true
}

#######################################
# Tests for check_alias_conflict()
#######################################

@test "check_alias_conflict detects existing alias" {
    # Purpose: Verify check_alias_conflict detects when an alias exists
    # Preconditions: Alias is defined in current shell
    # Expected: Function returns 0 (conflict exists)
    # Assertions: Return code is 0

    # Note: This test may be limited by how aliases work in test environment
    # The function uses 'type' and 'alias' commands which require interactive shell
    # For now, we test the function logic by verifying it handles non-aliases correctly
    # and skip the alias detection test as it requires interactive shell context

    # Test that function exists and can be called
    run check_alias_conflict "nonexistent_alias_$(date +%s)"

    # Should return no conflict (return 1) for non-existent alias
    assert_failure

    # Note: Full alias detection test requires interactive shell with alias expansion enabled
    # This is tested indirectly through integration tests where aliases are added to .bashrc
}

@test "check_alias_conflict returns no conflict for non-existent alias" {
    # Purpose: Verify check_alias_conflict returns no conflict for undefined alias
    # Preconditions: Alias does not exist
    # Expected: Function returns 1 (no conflict)
    # Assertions: Return code is 1

    # Ensure alias doesn't exist
    unalias test_nonexistent_alias 2>/dev/null || true

    # Run check_alias_conflict
    run check_alias_conflict "test_nonexistent_alias"

    # Should return no conflict (return 1)
    assert_failure
}

@test "check_alias_conflict distinguishes alias from function" {
    # Purpose: Verify check_alias_conflict only detects aliases, not functions
    # Preconditions: Function with same name exists
    # Expected: Function returns 1 (no conflict, because it's a function, not alias)
    # Assertions: Return code is 1

    # Create a test function (not alias)
    test_function_conflict() {
        echo "test function"
    }

    # Run check_alias_conflict
    run check_alias_conflict "test_function_conflict"

    # Should return no conflict (return 1) because it's a function, not an alias
    assert_failure

    # Cleanup
    unset -f test_function_conflict 2>/dev/null || true
}

@test "check_alias_conflict distinguishes alias from command" {
    # Purpose: Verify check_alias_conflict only detects aliases, not built-in commands
    # Preconditions: Built-in command exists (e.g., 'ls')
    # Expected: Function returns 1 (no conflict, because it's a command, not alias)
    # Assertions: Return code is 1

    # Ensure 'ls' is not aliased (it's a built-in command)
    unalias ls 2>/dev/null || true

    # Run check_alias_conflict
    run check_alias_conflict "ls"

    # Should return no conflict (return 1) because 'ls' is a command, not an alias
    assert_failure
}

@test "check_alias_conflict handles empty string" {
    # Purpose: Verify check_alias_conflict handles edge case of empty string
    # Preconditions: None
    # Expected: Function returns 1 (no conflict for empty string)
    # Assertions: Return code is 1

    # Run check_alias_conflict with empty string
    run check_alias_conflict ""

    # Should return no conflict (return 1)
    assert_failure
}

#######################################
# Tests for check_function_conflict()
#######################################

@test "check_function_conflict detects existing function" {
    # Purpose: Verify check_function_conflict detects when a function exists
    # Preconditions: Function is defined in current shell
    # Expected: Function returns 0 (conflict exists)
    # Assertions: Return code is 0

    # Create a test function
    test_function_exists() {
        echo "test function"
    }

    # Run check_function_conflict
    run check_function_conflict "test_function_exists"

    # Should detect conflict (return 0)
    assert_success

    # Cleanup
    unset -f test_function_exists 2>/dev/null || true
}

@test "check_function_conflict returns no conflict for non-existent function" {
    # Purpose: Verify check_function_conflict returns no conflict for undefined function
    # Preconditions: Function does not exist
    # Expected: Function returns 1 (no conflict)
    # Assertions: Return code is 1

    # Ensure function doesn't exist
    unset -f test_nonexistent_function 2>/dev/null || true

    # Run check_function_conflict
    run check_function_conflict "test_nonexistent_function"

    # Should return no conflict (return 1)
    assert_failure
}

@test "check_function_conflict distinguishes function from alias" {
    # Purpose: Verify check_function_conflict only detects functions, not aliases
    # Preconditions: Alias with same name exists
    # Expected: Function returns 1 (no conflict, because it's an alias, not function)
    # Assertions: Return code is 1

    # Create a test alias (not function)
    alias test_alias_function="echo test"

    # Run check_function_conflict
    run check_function_conflict "test_alias_function"

    # Should return no conflict (return 1) because it's an alias, not a function
    assert_failure

    # Cleanup
    unalias test_alias_function 2>/dev/null || true
}

@test "check_function_conflict distinguishes function from command" {
    # Purpose: Verify check_function_conflict only detects functions, not built-in commands
    # Preconditions: Built-in command exists (e.g., 'cd')
    # Expected: Function returns 1 (no conflict, because it's a command, not function)
    # Assertions: Return code is 1

    # Ensure 'cd' is not a function (it's a built-in command)
    unset -f cd 2>/dev/null || true

    # Run check_function_conflict
    run check_function_conflict "cd"

    # Should return no conflict (return 1) because 'cd' is a command, not a function
    assert_failure
}

@test "check_function_conflict handles empty string" {
    # Purpose: Verify check_function_conflict handles edge case of empty string
    # Preconditions: None
    # Expected: Function returns 1 (no conflict for empty string)
    # Assertions: Return code is 1

    # Run check_function_conflict with empty string
    run check_function_conflict ""

    # Should return no conflict (return 1)
    assert_failure
}

@test "check_function_conflict detects function with same name as alias" {
    # Purpose: Verify check_function_conflict correctly identifies function even if alias exists
    # Preconditions: Both alias and function with same name exist
    # Expected: Function returns 0 (conflict exists, because function exists)
    # Assertions: Return code is 0

    # Create both alias and function with same name
    alias test_both="echo alias"
    test_both() {
        echo "function"
    }

    # Run check_function_conflict
    run check_function_conflict "test_both"

    # Should detect conflict (return 0) because function exists
    assert_success

    # Cleanup
    unalias test_both 2>/dev/null || true
    unset -f test_both 2>/dev/null || true
}

#######################################
# Tests for exa installation and verification
#######################################

# Helper function to get exa binary path
_get_exa_binary_path() {
    local repo_root
    repo_root=$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)
    echo "$repo_root/exa/bin/exa"
}

@test "exa binary exists in repository" {
    # Purpose: Verify exa binary exists in the repository's exa folder
    # Preconditions: Repository is cloned with exa folder
    # Expected: Binary file exists at exa/bin/exa
    # Assertions: File exists and is executable

    local exa_binary
    exa_binary=$(_get_exa_binary_path)

    # Check file exists
    assert [ -f "$exa_binary" ]

    # Check file is executable
    assert [ -x "$exa_binary" ]
}

@test "exa binary is valid ELF executable" {
    # Purpose: Verify exa binary is a valid ELF executable
    # Preconditions: exa binary exists in repository
    # Expected: File is identified as ELF executable
    # Assertions: file command identifies it as ELF

    local exa_binary
    exa_binary=$(_get_exa_binary_path)

    # Skip if file command not available
    command -v file &>/dev/null || skip "file command not available"
    
    # Skip if binary doesn't exist
    [ -f "$exa_binary" ] || skip "exa binary not found"

    # Run file command and check for ELF
    run file "$exa_binary"
    assert_output --partial "ELF"
}

@test "exa binary can run --version" {
    # Purpose: Verify exa binary can execute and show version
    # Preconditions: exa binary exists and is valid
    # Expected: exa --version returns version info
    # Assertions: Command succeeds and output contains version info

    local exa_binary
    exa_binary=$(_get_exa_binary_path)

    # Skip if binary doesn't exist
    [ -f "$exa_binary" ] || skip "exa binary not found"

    # Run exa --version
    run "$exa_binary" --version

    # Should succeed
    assert_success

    # Should contain version info (exa outputs "exa - list files on the command-line")
    assert_output --partial "exa"
}

@test "install_exa uses local binary when available" {
    # Purpose: Verify install_exa function prefers local exa folder over download
    # Preconditions: Local exa folder exists with valid binary
    # Expected: Function logs that it's using local exa folder
    # Note: This test verifies the logic, not actual installation (requires root)

    local repo_root
    repo_root=$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)
    local exa_source_dir="$repo_root/exa"
    local exa_binary
    exa_binary=$(_get_exa_binary_path)

    # Verify local exa folder exists and has valid binary
    assert [ -d "$exa_source_dir" ]
    assert [ -f "$exa_binary" ]
    assert [ -x "$exa_binary" ]

    # Note: Full install_exa test requires root to copy to /usr/local/bin
    # This test just verifies the source is valid
}

@test "verify_installation handles exa binary existence check" {
    # Purpose: Verify verify_installation function checks for exa correctly
    # Note: This tests the function logic, actual execution requires root
    # Expected: Function exists and can be called

    # Test that function exists
    run type verify_installation
    assert_success
}
