#!/usr/bin/env bats

# bats file_tags=performance,benchmark

# Performance benchmarks for CI/CD integration
# These tests measure performance metrics for critical operations

load "${BATS_TEST_DIRNAME}/../helpers/bats-support/load"
load "${BATS_TEST_DIRNAME}/../helpers/bats-assert/load"

# Source the script to test functions
SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/../../scripts/setup-workstation.sh"

setup() {
    # Source the script
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Create temporary directory for test files
    export TEST_DIR=$(mktemp -d)
    export TEST_USER="testuser_$(date +%s)_$$"
    export TEST_HOME="$TEST_DIR/$TEST_USER"
    mkdir -p "$TEST_HOME"

    # Skip if not root (some tests require root)
    [ "$EUID" -eq 0 ] || skip "Some performance tests require root privileges - run with sudo"
}

teardown() {
    # Cleanup
    if id "$TEST_USER" &>/dev/null; then
        userdel -r "$TEST_USER" 2>/dev/null || true
    fi
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

#######################################
# Benchmark: Function call overhead
#######################################

@test "Benchmark: check_alias_conflict() execution time" {
    # Purpose: Measure execution time of check_alias_conflict()
    # Expected: Function executes in < 10ms
    # Assertions: Execution time is within acceptable limits

    local iterations=100
    local start_time end_time duration_ms

    start_time=$(date +%s%N)
    for i in $(seq 1 $iterations); do
        check_alias_conflict "nonexistent_alias_$i" &>/dev/null || true
    done
    end_time=$(date +%s%N)

    duration_ms=$(( (end_time - start_time) / 1000000 ))
    local avg_ms=$(( duration_ms / iterations ))

    # Average execution time should be < 10ms
    [ "$avg_ms" -lt 10 ] || fail "Average execution time ($avg_ms ms) exceeds 10ms threshold"
}

@test "Benchmark: check_function_conflict() execution time" {
    # Purpose: Measure execution time of check_function_conflict()
    # Expected: Function executes in < 10ms
    # Assertions: Execution time is within acceptable limits

    local iterations=100
    local start_time end_time duration_ms

    start_time=$(date +%s%N)
    for i in $(seq 1 $iterations); do
        check_function_conflict "nonexistent_function_$i" &>/dev/null || true
    done
    end_time=$(date +%s%N)

    duration_ms=$(( (end_time - start_time) / 1000000 ))
    local avg_ms=$(( duration_ms / iterations ))

    # Average execution time should be < 10ms
    [ "$avg_ms" -lt 10 ] || fail "Average execution time ($avg_ms ms) exceeds 10ms threshold"
}

#######################################
# Benchmark: File operations
#######################################

@test "Benchmark: create_bashrc_backup() execution time" {
    # Purpose: Measure execution time of create_bashrc_backup()
    # Expected: Backup creation completes in < 100ms
    # Assertions: Execution time is within acceptable limits

    # Create test user
    if ! id "$TEST_USER" &>/dev/null; then
        useradd -m -d "$TEST_HOME" "$TEST_USER" 2>/dev/null || skip "Cannot create test user"
    fi

    # Create test .bashrc
    echo "# Test .bashrc" > "$TEST_HOME/.bashrc"
    chown "$TEST_USER:$TEST_USER" "$TEST_HOME/.bashrc"

    local bashrc_file="$TEST_HOME/.bashrc"
    local start_time end_time duration_ms

    start_time=$(date +%s%N)
    run create_bashrc_backup "$bashrc_file"
    end_time=$(date +%s%N)

    duration_ms=$(( (end_time - start_time) / 1000000 ))

    # Backup creation should complete in < 100ms
    [ "$duration_ms" -lt 100 ] || fail "Backup creation ($duration_ms ms) exceeds 100ms threshold"
    assert_success
}

#######################################
# Benchmark: Configuration parsing
#######################################

@test "Benchmark: .bashrc grep operations performance" {
    # Purpose: Measure performance of grep operations on .bashrc
    # Expected: Grep operations complete in < 50ms for typical .bashrc
    # Assertions: Execution time is within acceptable limits

    # Create test user
    if ! id "$TEST_USER" &>/dev/null; then
        useradd -m -d "$TEST_HOME" "$TEST_USER" 2>/dev/null || skip "Cannot create test user"
    fi

    # Create realistic .bashrc (200 lines)
    {
        echo "# ~/.bashrc"
        for i in $(seq 1 200); do
            echo "# Line $i"
            if [ $((i % 10)) -eq 0 ]; then
                echo "alias test$i='echo test$i'"
            fi
        done
    } > "$TEST_HOME/.bashrc"
    chown "$TEST_USER:$TEST_USER" "$TEST_HOME/.bashrc"

    local bashrc_file="$TEST_HOME/.bashrc"
    local start_time end_time duration_ms

    # Measure grep performance
    start_time=$(date +%s%N)
    grep -q "alias test" "$bashrc_file" &>/dev/null || true
    end_time=$(date +%s%N)

    duration_ms=$(( (end_time - start_time) / 1000000 ))

    # Grep should complete in < 50ms
    [ "$duration_ms" -lt 50 ] || fail "Grep operation ($duration_ms ms) exceeds 50ms threshold"
}

#######################################
# Benchmark: Memory usage
#######################################

@test "Benchmark: Memory usage during function execution" {
    # Purpose: Measure memory usage of helper functions
    # Expected: Memory usage remains < 10MB
    # Assertions: Memory usage is within acceptable limits

    # Note: This is a simplified test - actual memory profiling requires more sophisticated tools
    # We test that functions don't cause excessive memory growth

    local iterations=1000
    local before_mem after_mem mem_diff

    # Get initial memory (if available)
    if command -v free &>/dev/null; then
        before_mem=$(free -m | awk '/^Mem:/ {print $3}')
    else
        skip "free command not available for memory measurement"
    fi

    # Execute functions multiple times
    for i in $(seq 1 $iterations); do
        check_alias_conflict "test_alias_$i" &>/dev/null || true
        check_function_conflict "test_function_$i" &>/dev/null || true
    done

    # Get final memory
    if command -v free &>/dev/null; then
        after_mem=$(free -m | awk '/^Mem:/ {print $3}')
        mem_diff=$((after_mem - before_mem))

        # Memory increase should be < 10MB
        [ "$mem_diff" -lt 10 ] || fail "Memory increase ($mem_diff MB) exceeds 10MB threshold"
    fi
}

#######################################
# Benchmark: Startup time impact
#######################################

@test "Benchmark: Terminal startup time impact" {
    # Purpose: Measure impact of terminal enhancements on startup time
    # Expected: Startup time increase < 100ms (SC-009)
    # Assertions: Startup time is within acceptable limits

    # Create test user
    if ! id "$TEST_USER" &>/dev/null; then
        useradd -m -d "$TEST_HOME" "$TEST_USER" 2>/dev/null || skip "Cannot create test user"
    fi

    # Create minimal .bashrc
    echo "# Minimal .bashrc" > "$TEST_HOME/.bashrc"
    chown "$TEST_USER:$TEST_USER" "$TEST_HOME/.bashrc"

    # Measure baseline startup time (sourcing minimal .bashrc)
    local baseline_start baseline_end baseline_ms
    baseline_start=$(date +%s%N)
    run sudo -u "$TEST_USER" bash -c "source $TEST_HOME/.bashrc" &>/dev/null
    baseline_end=$(date +%s%N)
    baseline_ms=$(( (baseline_end - baseline_start) / 1000000 ))

    # Add terminal enhancements configuration
    {
        echo "# Terminal Enhancements Configuration"
        echo "export HISTSIZE=10000"
        echo "export HISTFILESIZE=20000"
        echo "bind 'set completion-ignore-case on'"
    } >> "$TEST_HOME/.bashrc"

    # Measure enhanced startup time
    local enhanced_start enhanced_end enhanced_ms
    enhanced_start=$(date +%s%N)
    run sudo -u "$TEST_USER" bash -c "source $TEST_HOME/.bashrc" &>/dev/null
    enhanced_end=$(date +%s%N)
    enhanced_ms=$(( (enhanced_end - enhanced_start) / 1000000 ))

    local overhead_ms=$((enhanced_ms - baseline_ms))

    # Startup time increase should be < 100ms (SC-009)
    [ "$overhead_ms" -lt 100 ] || fail "Startup time increase ($overhead_ms ms) exceeds 100ms threshold (SC-009)"
}

#######################################
# Benchmark: Large file handling
#######################################

@test "Benchmark: Large .bashrc processing performance" {
    # Purpose: Measure performance with large .bashrc files
    # Expected: Processing completes in < 500ms for 10,000 line file
    # Assertions: Execution time scales reasonably

    # Create test user
    if ! id "$TEST_USER" &>/dev/null; then
        useradd -m -d "$TEST_HOME" "$TEST_USER" 2>/dev/null || skip "Cannot create test user"
    fi

    # Create large .bashrc (10,000 lines)
    {
        echo "# Large .bashrc file"
        for i in $(seq 1 10000); do
            echo "# Comment line $i"
        done
    } > "$TEST_HOME/.bashrc"
    chown "$TEST_USER:$TEST_USER" "$TEST_HOME/.bashrc"

    local bashrc_file="$TEST_HOME/.bashrc"
    local start_time end_time duration_ms

    # Measure grep performance on large file
    start_time=$(date +%s%N)
    grep -q "# Comment" "$bashrc_file" &>/dev/null || true
    end_time=$(date +%s%N)

    duration_ms=$(( (end_time - start_time) / 1000000 ))

    # Processing should complete in < 500ms
    [ "$duration_ms" -lt 500 ] || fail "Large file processing ($duration_ms ms) exceeds 500ms threshold"
}
