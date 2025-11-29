#!/bin/bash

# Mutation testing framework for critical functions
# This script performs basic mutation testing by introducing intentional bugs
# and verifying that tests catch them

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/setup-workstation.sh"
BACKUP_DIR="$SCRIPT_DIR/.mutations_backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Statistics
TOTAL_MUTATIONS=0
DETECTED_MUTATIONS=0
UNDETECTED_MUTATIONS=0

#######################################
# Helper functions
#######################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

backup_script() {
    log_info "Creating backup of original script..."
    mkdir -p "$BACKUP_DIR"
    cp "$SCRIPT_PATH" "$BACKUP_DIR/setup-workstation.sh.original"
}

restore_script() {
    log_info "Restoring original script..."
    if [ -f "$BACKUP_DIR/setup-workstation.sh.original" ]; then
        cp "$BACKUP_DIR/setup-workstation.sh.original" "$SCRIPT_PATH"
    fi
}

run_tests() {
    local test_file="$1"
    if [ -f "$test_file" ]; then
        bats "$test_file" &>/dev/null
        return $?
    fi
    return 1
}

#######################################
# Mutation operators
#######################################

mutate_check_alias_conflict() {
    # Mutation 1: Change return value (should return 1 but returns 0)
    log_info "Mutation 1: check_alias_conflict() - inverted return value"
    sed -i 's/return 1  # No conflict/return 0  # No conflict (MUTATED)/' "$SCRIPT_PATH"
    TOTAL_MUTATIONS=$((TOTAL_MUTATIONS + 1))

    if run_tests "$PROJECT_ROOT/tests/unit/test_helper_functions.bats"; then
        log_error "Mutation 1 NOT DETECTED - tests should fail!"
        UNDETECTED_MUTATIONS=$((UNDETECTED_MUTATIONS + 1))
    else
        log_info "Mutation 1 DETECTED - tests correctly failed"
        DETECTED_MUTATIONS=$((DETECTED_MUTATIONS + 1))
    fi

    restore_script
}

mutate_check_function_conflict() {
    # Mutation 2: Change return value (should return 1 but returns 0)
    log_info "Mutation 2: check_function_conflict() - inverted return value"
    sed -i 's/return 1  # No conflict$/return 0  # No conflict (MUTATED)/' "$SCRIPT_PATH"
    TOTAL_MUTATIONS=$((TOTAL_MUTATIONS + 1))

    if run_tests "$PROJECT_ROOT/tests/unit/test_helper_functions.bats"; then
        log_error "Mutation 2 NOT DETECTED - tests should fail!"
        UNDETECTED_MUTATIONS=$((UNDETECTED_MUTATIONS + 1))
    else
        log_info "Mutation 2 DETECTED - tests correctly failed"
        DETECTED_MUTATIONS=$((DETECTED_MUTATIONS + 1))
    fi

    restore_script
}

mutate_create_bashrc_backup() {
    # Mutation 3: Remove backup creation (critical function)
    log_info "Mutation 3: create_bashrc_backup() - removed backup creation"
    sed -i 's/if ! cp "$bashrc_path" "$backup_path"; then/if ! true; then  # MUTATED: backup disabled/' "$SCRIPT_PATH"
    TOTAL_MUTATIONS=$((TOTAL_MUTATIONS + 1))

    if run_tests "$PROJECT_ROOT/tests/integration/test_terminal_enhancements.bats"; then
        log_error "Mutation 3 NOT DETECTED - tests should fail!"
        UNDETECTED_MUTATIONS=$((UNDETECTED_MUTATIONS + 1))
    else
        log_info "Mutation 3 DETECTED - tests correctly failed"
        DETECTED_MUTATIONS=$((DETECTED_MUTATIONS + 1))
    fi

    restore_script
}

mutate_install_bat_username() {
    # Mutation 4: Use wrong username variable (should use $username but uses $HOME)
    log_info "Mutation 4: install_bat() - wrong username variable"
    sed -i 's|local home_dir="/home/$username"|local home_dir="$HOME"  # MUTATED: wrong variable|' "$SCRIPT_PATH"
    TOTAL_MUTATIONS=$((TOTAL_MUTATIONS + 1))

    if run_tests "$PROJECT_ROOT/tests/integration/test_terminal_enhancements.bats"; then
        log_error "Mutation 4 NOT DETECTED - tests should fail!"
        UNDETECTED_MUTATIONS=$((UNDETECTED_MUTATIONS + 1))
    else
        log_info "Mutation 4 DETECTED - tests correctly failed"
        DETECTED_MUTATIONS=$((DETECTED_MUTATIONS + 1))
    fi

    restore_script
}

#######################################
# Main execution
#######################################

main() {
    log_info "Starting mutation testing..."
    log_info "This will introduce intentional bugs and verify tests catch them"
    echo

    # Create backup
    backup_script

    # Trap to ensure script is restored on exit
    trap restore_script EXIT

    # Run mutations
    mutate_check_alias_conflict
    echo
    mutate_check_function_conflict
    echo
    mutate_create_bashrc_backup
    echo
    mutate_install_bat_username
    echo

    # Print summary
    log_info "========================================="
    log_info "Mutation Testing Summary"
    log_info "========================================="
    log_info "Total mutations: $TOTAL_MUTATIONS"
    log_info "Detected: $DETECTED_MUTATIONS"
    log_info "Undetected: $UNDETECTED_MUTATIONS"

    if [ "$UNDETECTED_MUTATIONS" -gt 0 ]; then
        local detection_rate=$(( (DETECTED_MUTATIONS * 100) / TOTAL_MUTATIONS ))
        log_warn "Detection rate: ${detection_rate}%"
        log_warn "Some mutations were not detected - consider improving test coverage"
        return 1
    else
        log_info "Detection rate: 100%"
        log_info "All mutations were detected - excellent test coverage!"
        return 0
    fi
}

# Run main function
main "$@"
