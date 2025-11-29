#!/usr/bin/env bash

#######################################
# Script Name: setup-workstation.sh
# Description: Mobile-Ready Coding Workstation Installation Script for Debian 13 (Trixie)
# Author: DevOps Automation
# Date: 2025-01-27
# Version: 1.0.0
#######################################

# Exit on error
set -e

# Exit on undefined variable
set -u

# Exit on pipe failure
set -o pipefail

# Color variables for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'  # No Color

# Script configuration
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC2034  # SCRIPT_NAME and SCRIPT_DIR kept for future logging/debugging
readonly SCRIPT_NAME
# shellcheck disable=SC2034  # SCRIPT_DIR kept for future logging/debugging
readonly SCRIPT_DIR

# Log file configuration
# Default to /var/log/setup-workstation.log, fallback to user's home directory if /var/log is not writable
if [ -w "/var/log" ] 2>/dev/null; then
    LOG_FILE="/var/log/setup-workstation.log"
else
    # Fallback to user's home directory if /var/log is not writable
    if [ -d "${HOME:-/tmp}" ] && [ -w "${HOME:-/tmp}" ] 2>/dev/null; then
        LOG_FILE="${HOME:-/tmp}/.setup-workstation.log"
    else
        # Last resort: use /tmp
        LOG_FILE="/tmp/setup-workstation.log"
    fi
fi
readonly LOG_FILE

#######################################
# Structured logging function
# Purpose: Centralized logging with timestamps, levels, and context
# Inputs:
#   - level: Log level (INFO, WARNING, ERROR, DEBUG)
#   - message: Log message
#   - context: Optional context information (function name, variable values, etc.)
# Outputs: Writes to log file and displays to stdout/stderr
# Side Effects: Creates log file if it doesn't exist, sets permissions to 600
# Returns: 0 on success
# Idempotency: Safe to call multiple times
# Examples:
#   log "INFO" "Starting installation" "main()"
#   log "ERROR" "User creation failed" "create_user()" "username=testuser"
# Notes:
#   - Logs are written in ISO 8601 UTC format for consistency
#   - Log file permissions: 600 (user read/write only) (FR-029)
#   - Log retention: 30 days or 100MB, whichever comes first (FR-030)
#
# Operations That Must Be Logged (FR-041):
#   - All function calls (entry/exit with INFO level)
#   - All errors (ERROR level with context)
#   - All warnings (WARNING level with context)
#   - Major state changes:
#     * User creation
#     * Package installation
#     * Service configuration
#     * Docker setup
#     * Desktop environment configuration
#     * Development stack installation
#     * System configuration changes
#######################################
log() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")  # ISO 8601 UTC

    # Build log entry with context if provided
    local log_entry
    if [ -n "$context" ]; then
        log_entry="[$timestamp] [$level] [$context] $message"
    else
        log_entry="[$timestamp] [$level] $message"
    fi

    # Create log file if it doesn't exist and set permissions (600 - user read/write only) (FR-029)
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE" 2>/dev/null || true
        chmod 600 "$LOG_FILE" 2>/dev/null || true
    fi

    # Write to log file (append mode)
    echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true

    # Apply log retention policy: 30 days or 100MB, whichever comes first (FR-030)
    # Check file size (in bytes) and age (in days)
    if [ -f "$LOG_FILE" ]; then
        local log_size
        log_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo "0")
        local max_size=$((100 * 1024 * 1024))  # 100MB in bytes

        # Check if log file exceeds size limit
        if [ "$log_size" -gt "$max_size" ]; then
            # Rotate log: keep last 1000 lines
            if tail -n 1000 "$LOG_FILE" > "${LOG_FILE}.tmp" 2>/dev/null; then
                mv "${LOG_FILE}.tmp" "$LOG_FILE" 2>/dev/null || true
            fi
            chmod 600 "$LOG_FILE" 2>/dev/null || true
        fi

        # Check if log file is older than 30 days (check on first log entry of day)
        local log_mtime
        log_mtime=$(stat -f%m "$LOG_FILE" 2>/dev/null || stat -c%Y "$LOG_FILE" 2>/dev/null || echo "0")
        local current_time
        current_time=$(date +%s)
        local age_days=$(((current_time - log_mtime) / 86400))

        if [ "$age_days" -gt 30 ]; then
            # Archive old log and start fresh
            mv "$LOG_FILE" "${LOG_FILE}.$(date +%Y%m%d).old" 2>/dev/null || true
            touch "$LOG_FILE" 2>/dev/null || true
            chmod 600 "$LOG_FILE" 2>/dev/null || true
        fi
    fi

    # Display to stdout/stderr with colors based on level
    case "$level" in
        ERROR)
            echo -e "${RED}${message}${NC}" >&2
            ;;
        WARNING)
            echo -e "${YELLOW}${message}${NC}"
            ;;
        INFO)
            echo -e "${GREEN}${message}${NC}"
            ;;
        DEBUG)
            if [ "${DEBUG:-0}" = "1" ]; then
                echo -e "${YELLOW}[DEBUG] ${message}${NC}"
            fi
            ;;
        *)
            echo -e "${message}"
            ;;
    esac
}

#######################################
# Verify installation success
# Purpose: Check that all critical components were installed successfully
# Inputs:
#   - username: Username to verify installation for
# Outputs: Logs verification results
# Side Effects: None
# Returns:
#   0 - All components verified successfully
#   1 - One or more components failed verification
# Idempotency: Safe to call multiple times
# Example:
#   verify_installation "coder"
#######################################
verify_installation() {
    local username="$1"
    local home_dir="/home/$username"
    local all_ok=true

    log "INFO" "Verifying installation..." "verify_installation()" "username=$username"

    # Verify user exists
    if ! id "$username" &>/dev/null; then
        log "ERROR" "User '$username' does not exist" "verify_installation()" "username=$username"
        all_ok=false
    else
        log "INFO" "✓ User '$username' exists" "verify_installation()"
    fi

    # Verify essential packages
    local essential_packages=("curl" "git" "htop" "vim" "build-essential")
    for package in "${essential_packages[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
            log "WARNING" "Package '$package' is not installed" "verify_installation()" "package=$package"
            all_ok=false
        else
            log "INFO" "✓ Package '$package' is installed" "verify_installation()"
        fi
    done

    # Verify XFCE4
    if ! dpkg-query -W -f='${Status}' "xfce4" 2>/dev/null | grep -q "install ok installed"; then
        log "WARNING" "XFCE4 is not installed" "verify_installation()"
        all_ok=false
    else
        log "INFO" "✓ XFCE4 is installed" "verify_installation()"
    fi

    # Verify XRDP
    if ! dpkg-query -W -f='${Status}' "xrdp" 2>/dev/null | grep -q "install ok installed"; then
        log "WARNING" "XRDP is not installed" "verify_installation()"
        all_ok=false
    else
        log "INFO" "✓ XRDP is installed" "verify_installation()"
    fi

    # Verify XRDP service
    if ! systemctl is-enabled xrdp &>/dev/null; then
        log "WARNING" "XRDP service is not enabled" "verify_installation()"
        all_ok=false
    else
        log "INFO" "✓ XRDP service is enabled" "verify_installation()"
    fi

    # Verify Docker
    if ! command -v docker &>/dev/null; then
        log "WARNING" "Docker is not installed or not in PATH" "verify_installation()"
        all_ok=false
    else
        log "INFO" "✓ Docker is installed" "verify_installation()"
    fi

    # Verify user is in docker group
    if ! groups "$username" | grep -q "\bdocker\b"; then
        log "WARNING" "User '$username' is not in docker group" "verify_installation()" "username=$username"
        all_ok=false
    else
        log "INFO" "✓ User '$username' is in docker group" "verify_installation()" "username=$username"
    fi

    # Verify NVM
    if [ ! -d "$home_dir/.nvm" ] || [ ! -f "$home_dir/.nvm/nvm.sh" ]; then
        log "WARNING" "NVM is not installed for user '$username'" "verify_installation()" "username=$username"
        all_ok=false
    else
        log "INFO" "✓ NVM is installed" "verify_installation()" "username=$username"
    fi

    # Verify Python 3
    if ! command -v python3 &>/dev/null; then
        log "WARNING" "Python 3 is not installed or not in PATH" "verify_installation()"
        all_ok=false
    else
        local python_version
        python_version=$(python3 --version 2>&1)
        log "INFO" "✓ Python 3 is available: $python_version" "verify_installation()"
    fi

    # Verify Terminal Enhancement Tools (T075)
    log "INFO" "Verifying terminal enhancement tools..." "verify_installation()" "username=$username"

    # Verify Starship
    if ! command -v starship &>/dev/null; then
        log "WARNING" "Starship is not installed or not in PATH" "verify_installation()"
        all_ok=false
    else
        log "INFO" "✓ Starship is installed" "verify_installation()"
    fi

    # Verify fzf
    if ! command -v fzf &>/dev/null && ! dpkg-query -W -f='${Status}' "fzf" 2>/dev/null | grep -q "install ok installed"; then
        log "WARNING" "fzf is not installed" "verify_installation()"
        all_ok=false
    else
        log "INFO" "✓ fzf is installed" "verify_installation()"
    fi

    # Verify bat
    if ! command -v batcat &>/dev/null && ! command -v bat &>/dev/null && ! dpkg-query -W -f='${Status}' "bat" 2>/dev/null | grep -q "install ok installed"; then
        log "WARNING" "bat is not installed" "verify_installation()"
        all_ok=false
    else
        log "INFO" "✓ bat is installed" "verify_installation()"
    fi

    # Verify exa
    # Check both command availability and binary existence (exa is installed to /usr/local/bin/exa)
    # This handles cases where PATH is not updated or bash hash table is not refreshed
    # Also check if binary is executable
    # Try with explicit PATH to ensure /usr/local/bin is checked
    local exa_installed=false
    local exa_path

    # First try with current PATH
    if command -v exa &>/dev/null; then
        exa_installed=true
        exa_path=$(command -v exa)
    # Then try with explicit /usr/local/bin in PATH
    elif PATH="/usr/local/bin:$PATH" command -v exa &>/dev/null; then
        exa_installed=true
        exa_path="/usr/local/bin/exa"
    # Finally check if binary file exists and is executable
    elif [ -f /usr/local/bin/exa ] && [ -x /usr/local/bin/exa ]; then
        exa_installed=true
        exa_path="/usr/local/bin/exa"
    fi

    if [ "$exa_installed" = true ]; then
        log "INFO" "✓ exa is installed (found at: ${exa_path:-unknown})" "verify_installation()"
    else
        log "WARNING" "exa is not installed or not in PATH. Note: exa installation may have failed during setup. You can install it manually or re-run the script. If /usr/local/bin/exa exists, ensure /usr/local/bin is in your PATH." "verify_installation()"
        all_ok=false
    fi

    # Verify terminal enhancements configuration marker
    local bashrc_file="$home_dir/.bashrc"
    if [ -f "$bashrc_file" ] && grep -q "# Terminal Enhancements Configuration - Added by setup-workstation.sh" "$bashrc_file" 2>/dev/null; then
        log "INFO" "✓ Terminal enhancements configuration marker found in .bashrc" "verify_installation()"
    else
        log "WARNING" "Terminal enhancements configuration marker not found in .bashrc" "verify_installation()"
        all_ok=false
    fi

    # Verify .bashrc configuration
    if [ ! -f "$home_dir/.bashrc" ] || ! grep -q "# Mobile-Ready Workstation Custom Configuration" "$home_dir/.bashrc" 2>/dev/null; then
        log "WARNING" ".bashrc is not configured for user '$username'" "verify_installation()" "username=$username"
        all_ok=false
    else
        log "INFO" "✓ .bashrc is configured" "verify_installation()" "username=$username"
    fi

    if [ "$all_ok" = true ]; then
        log "INFO" "✓ All installation components verified successfully" "verify_installation()" "username=$username"
        return 0
    else
        log "WARNING" "Some installation components failed verification. Review warnings above." "verify_installation()" "username=$username"
        return 1
    fi
}

#######################################
# Check if running on Debian 13 (Trixie)
# Exits with error if not Debian 13
# Returns: 0 if Debian 13, exits with 1 otherwise
#######################################
check_debian_version() {
    if [ ! -f /etc/os-release ]; then
        log "ERROR" "Cannot determine OS version. /etc/os-release not found. Context: Function check_debian_version() attempted to read /etc/os-release but file does not exist. Recovery: Ensure you are running on a Linux system with systemd or equivalent that provides /etc/os-release." "check_debian_version()" "file=/etc/os-release"
        exit 1
    fi

    # Source the os-release file
    # shellcheck disable=SC1091  # /etc/os-release is a standard system file, safe to source
    . /etc/os-release

    # Check for Debian
    if [ "$ID" != "debian" ]; then
        log "ERROR" "This script requires Debian OS. Detected OS ID: $ID, PRETTY_NAME: ${PRETTY_NAME:-unknown}. Context: Function check_debian_version() verified OS distribution but found non-Debian system. Recovery: This script is designed specifically for Debian 13 (Trixie). Please run on a Debian system or modify the script for your distribution." "check_debian_version()" "detected_id=$ID detected_name=${PRETTY_NAME:-unknown}"
        exit 1
    fi

    # Check for Debian 13 (Trixie)
    if [ "$VERSION_CODENAME" != "trixie" ] && [ "$VERSION_ID" != "13" ]; then
        log "ERROR" "This script requires Debian 13 (Trixie). Detected: ${PRETTY_NAME:-unknown} (VERSION_CODENAME: ${VERSION_CODENAME:-unknown}, VERSION_ID: ${VERSION_ID:-unknown}). Context: Function check_debian_version() verified Debian version but found version other than 13/Trixie. Recovery: Please upgrade to Debian 13 (Trixie) or use a compatible version of this script for your Debian version." "check_debian_version()" "detected_codename=${VERSION_CODENAME:-unknown} detected_version=${VERSION_ID:-unknown}"
        exit 1
    fi

    log "INFO" "✓ Debian 13 (Trixie) detected: $PRETTY_NAME" "check_debian_version()"
}

#######################################
# Check if script is executable
# Provides guidance if not executable
#######################################
check_script_permissions() {
    if [ ! -x "$0" ]; then
        log "WARNING" "Script is not executable. Please run: chmod +x $0" "check_script_permissions()"
    fi
}

#######################################
# Check if script is run with root/sudo privileges
# Exits with error if not root
# Returns: 0 if root, exits with 1 otherwise
#######################################
check_root_privileges() {
    if [ "$EUID" -ne 0 ]; then
        log "ERROR" "This script must be run as root or with sudo. Current EUID: $EUID. Context: Function check_root_privileges() verified user privileges but script is not running as root. Recovery: Run the script with sudo: sudo $0" "check_root_privileges()" "euid=$EUID"
        exit 1
    fi
    log "INFO" "✓ Root privileges confirmed" "check_root_privileges()"
}

#######################################
# Display welcome banner with ASCII art
#######################################
show_welcome_banner() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     ███╗   ███╗ ██████╗ ██████╗ ██╗     ██╗ ██████╗          ║
║     ████╗ ████║██╔═══██╗██╔══██╗██║     ██║██╔═══██╗         ║
║     ██╔████╔██║██║   ██║██║  ██║██║     ██║██║   ██║         ║
║     ██║╚██╔╝██║██║   ██║██║  ██║██║     ██║██║   ██║         ║
║     ██║ ╚═╝ ██║╚██████╔╝██████╔╝███████╗██║╚██████╔╝         ║
║     ╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝ ╚═════╝          ║
║                                                              ║
║        Coding Workstation Setup for Debian 13 (Trixie)      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
}

#######################################
# Validate hostname format (RFC 1123)
# Returns: 0 if valid, 1 if invalid
#######################################
validate_hostname() {
    local hostname="$1"
    # Hostname must be 1-63 characters, alphanumeric and hyphens only
    # Cannot start or end with hyphen
    if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then
        return 1
    fi
    return 0
}

#######################################
# Save user inputs to configuration file
#
# Purpose: Persist user inputs (username, password, hostname) to file for reuse
#
# Inputs:
#   - username: Username to save (string)
#   - password: Password to save (string, will be base64 encoded)
#   - hostname: Hostname to save (string)
#
# Outputs: None
#
# Side Effects:
#   - Creates /etc/setup-workstation.conf with saved inputs
#   - Sets file permissions to 600 (root read/write only)
#
# Returns:
#   0 - Success (config saved)
#   1 - Error (failed to save config)
#
# Idempotency: Yes (overwrites existing config)
#
# Example:
#   save_user_inputs "coder" "SecurePass123!" "my-vps"
#######################################
save_user_inputs() {
    local username="$1"
    local password="$2"
    local hostname="$3"
    local config_file="/etc/setup-workstation.conf"

    log "INFO" "Saving user inputs to configuration file..." "save_user_inputs()" "config_file=$config_file"

    # Encode password with base64 for storage (basic obfuscation, not encryption)
    local encoded_password
    encoded_password=$(echo -n "$password" | base64 2>/dev/null || echo "")

    if [ -z "$encoded_password" ]; then
        log "ERROR" "Failed to encode password. Context: Function save_user_inputs() attempted to encode password with base64 but failed. Recovery: Check if base64 command is available, or save config manually." "save_user_inputs()"
        return 1
    fi

    # Write config file
    if ! cat > "$config_file" <<EOF
# Setup Workstation Configuration
# Generated by setup-workstation.sh
# DO NOT EDIT MANUALLY - This file is managed by the installation script

CUSTOM_USER="$username"
CUSTOM_PASS_B64="$encoded_password"
CUSTOM_HOSTNAME="$hostname"
EOF
    then
        log "ERROR" "Failed to write configuration file. Context: Function save_user_inputs() attempted to write config file but failed. Recovery: Check filesystem permissions, verify /etc is writable, or create file manually." "save_user_inputs()" "config_file=$config_file"
        return 1
    fi

    # Set secure permissions (600 - root read/write only)
    chmod 600 "$config_file" 2>/dev/null || true

    log "INFO" "✓ User inputs saved to configuration file" "save_user_inputs()" "config_file=$config_file"
    return 0
}

#######################################
# Load user inputs from configuration file
#
# Purpose: Read previously saved user inputs from configuration file
#
# Inputs: None
#
# Outputs:
#   - CUSTOM_USER: Username from config (string, via global variable)
#   - CUSTOM_PASS: Password from config (string, decoded from base64, via global variable)
#   - CUSTOM_HOSTNAME: Hostname from config (string, via global variable)
#
# Side Effects:
#   - Sets global variables CUSTOM_USER, CUSTOM_PASS, CUSTOM_HOSTNAME
#
# Returns:
#   0 - Success (config loaded)
#   1 - Error (config file not found or invalid)
#
# Idempotency: Safe to call multiple times
#
# Example:
#   if load_user_inputs; then
#       echo "Username: $CUSTOM_USER"
#   fi
#######################################
load_user_inputs() {
    local config_file="/etc/setup-workstation.conf"

    log "INFO" "Loading user inputs from configuration file..." "load_user_inputs()" "config_file=$config_file"

    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        log "INFO" "Configuration file not found, will prompt for inputs" "load_user_inputs()" "config_file=$config_file"
        return 1
    fi

    # Source the config file
    # shellcheck disable=SC1090  # Config file is created by this script, safe to source
    if ! . "$config_file" 2>/dev/null; then
        log "WARNING" "Failed to load configuration file, will prompt for inputs" "load_user_inputs()" "config_file=$config_file"
        return 1
    fi

    # Check if all required variables are set
    if [ -z "${CUSTOM_USER:-}" ] || [ -z "${CUSTOM_PASS_B64:-}" ] || [ -z "${CUSTOM_HOSTNAME:-}" ]; then
        log "WARNING" "Configuration file is incomplete, will prompt for inputs" "load_user_inputs()" "config_file=$config_file"
        return 1
    fi

    # Decode password from base64
    CUSTOM_PASS=$(echo -n "$CUSTOM_PASS_B64" | base64 -d 2>/dev/null || echo "")

    if [ -z "$CUSTOM_PASS" ]; then
        log "WARNING" "Failed to decode password from config, will prompt for inputs" "load_user_inputs()" "config_file=$config_file"
        return 1
    fi

    # Validate loaded values
    if [[ ! "$CUSTOM_USER" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log "WARNING" "Invalid username in config file, will prompt for inputs" "load_user_inputs()" "config_file=$config_file username=$CUSTOM_USER"
        return 1
    fi

    if ! validate_hostname "$CUSTOM_HOSTNAME"; then
        log "WARNING" "Invalid hostname in config file, will prompt for inputs" "load_user_inputs()" "config_file=$config_file hostname=$CUSTOM_HOSTNAME"
        return 1
    fi

    log "INFO" "✓ User inputs loaded from configuration file" "load_user_inputs()" "config_file=$config_file username=$CUSTOM_USER hostname=$CUSTOM_HOSTNAME"
    return 0
}

#######################################
# Remove unnecessary users (except root and specified user)
#
# Purpose: Clean up system by removing all users except root and the specified user
#
# Inputs:
#   - keep_username: Username to keep (string, required)
#
# Outputs: None
#
# Side Effects:
#   - Removes user accounts and their home directories
#   - Logs all user removals
#
# Returns:
#   0 - Success (users removed or no users to remove)
#   1 - Error (removal failed for one or more users)
#
# Idempotency: Yes (safe to run multiple times)
#
# Example:
#   remove_unnecessary_users "coder"
#
# Notes:
#   - Never removes root user (UID 0)
#   - Never removes the specified keep_username
#   - Never removes current logged-in user (to prevent disconnection)
#   - Never removes users with active login sessions (to prevent disconnection)
#   - Removes home directories with -r flag
#   - Skips system users (UID < 1000) except root
#######################################
remove_unnecessary_users() {
    local keep_username="$1"
    local users_removed=0
    local users_failed=0

    log "INFO" "Removing unnecessary users (keeping root and $keep_username)..." "remove_unnecessary_users()" "keep_username=$keep_username"

    # Detect current logged-in user(s) to avoid disconnecting active sessions
    # Priority: SUDO_USER (if script run with sudo) > USER > whoami
    local current_user=""
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        current_user="$SUDO_USER"
    elif [ -n "${USER:-}" ] && [ "$USER" != "root" ]; then
        current_user="$USER"
    else
        current_user=$(whoami 2>/dev/null || echo "")
    fi

    # Get list of all logged-in users (from who command)
    local logged_in_users=""
    if command -v who &>/dev/null; then
        logged_in_users=$(who 2>/dev/null | awk '{print $1}' | sort -u | tr '\n' ' ' || echo "")
    fi

    log "INFO" "Current user: ${current_user:-unknown}, Logged-in users: ${logged_in_users:-none}" "remove_unnecessary_users()" "current_user=$current_user logged_in_users=$logged_in_users"

    # Get list of all users (excluding system users with UID < 1000, except root)
    # Also exclude the user we want to keep
    local all_users
    all_users=$(getent passwd | awk -F: '$3 >= 1000 || $3 == 0 {print $1}' | grep -v "^root$" | grep -v "^${keep_username}$" || true)

    if [ -z "$all_users" ]; then
        log "INFO" "No unnecessary users found to remove" "remove_unnecessary_users()" "keep_username=$keep_username"
        return 0
    fi

    # Remove each user
    while IFS= read -r username; do
        # Skip if username is empty
        [ -z "$username" ] && continue

        # Skip root and keep_username (shouldn't happen due to grep, but double-check)
        if [ "$username" = "root" ] || [ "$username" = "$keep_username" ]; then
            continue
        fi

        # Skip current user to avoid disconnecting active session
        if [ -n "$current_user" ] && [ "$username" = "$current_user" ]; then
            log "WARNING" "Skipping removal of current user '$username' to prevent disconnection from server. Please logout and remove manually if needed." "remove_unnecessary_users()" "username=$username reason=current_user"
            continue
        fi

        # Skip logged-in users to avoid disconnecting active sessions
        if [ -n "$logged_in_users" ] && echo "$logged_in_users" | grep -qw "$username"; then
            log "WARNING" "Skipping removal of logged-in user '$username' to prevent disconnection from server. Please logout and remove manually if needed." "remove_unnecessary_users()" "username=$username reason=logged_in"
            continue
        fi

        # Check if user exists
        if ! id "$username" &>/dev/null; then
            log "INFO" "User '$username' does not exist, skipping" "remove_unnecessary_users()" "username=$username"
            continue
        fi

        # Get user UID to check if it's a system user
        local user_uid
        user_uid=$(id -u "$username" 2>/dev/null || echo "0")

        # Skip system users (UID < 1000) except root
        if [ "$user_uid" -lt 1000 ] && [ "$user_uid" -ne 0 ]; then
            log "INFO" "Skipping system user '$username' (UID: $user_uid)" "remove_unnecessary_users()" "username=$username uid=$user_uid"
            continue
        fi

        # Always attempt to kill processes before removal (even if count is 0, user might be logged in)
        log "INFO" "Terminating all processes for user '$username'..." "remove_unnecessary_users()" "username=$username"

        # Get process count for logging
        local process_count
        process_count=$(pgrep -u "$username" 2>/dev/null | wc -l || echo "0")
        if [ "$process_count" -gt 0 ]; then
            log "INFO" "Found $process_count active process(es) for user '$username'" "remove_unnecessary_users()" "username=$username process_count=$process_count"
        fi

        # Kill all processes owned by the user (try multiple methods for robustness)
        # Method 1: pkill (preferred)
        if command -v pkill &>/dev/null; then
            pkill -u "$username" 2>/dev/null || true
            sleep 1
            # Force kill any remaining processes
            pkill -9 -u "$username" 2>/dev/null || true
            sleep 1
        fi

        # Method 2: killall (alternative)
        if command -v killall &>/dev/null; then
            killall -u "$username" 2>/dev/null || true
            sleep 1
            killall -9 -u "$username" 2>/dev/null || true
            sleep 1
        fi

        # Method 3: Direct kill via ps and kill (fallback)
        local pids
        pids=$(ps -u "$username" -o pid= 2>/dev/null | tr '\n' ' ' || true)
        if [ -n "$pids" ]; then
            for pid in $pids; do
                kill "$pid" 2>/dev/null || true
            done
            sleep 1
            # Force kill any remaining
            pids=$(ps -u "$username" -o pid= 2>/dev/null | tr '\n' ' ' || true)
            if [ -n "$pids" ]; then
                for pid in $pids; do
                    kill -9 "$pid" 2>/dev/null || true
                done
                sleep 1
            fi
        fi

        # Verify processes are terminated
        process_count=$(pgrep -u "$username" 2>/dev/null | wc -l || echo "0")
        if [ "$process_count" -gt 0 ]; then
            log "WARNING" "Some processes for user '$username' could not be terminated ($process_count remaining). Attempting forced removal anyway..." "remove_unnecessary_users()" "username=$username remaining_processes=$process_count"
        fi

        # Remove user and home directory
        # Use -f flag to force removal even if user is logged in or has processes
        log "INFO" "Removing user '$username'..." "remove_unnecessary_users()" "username=$username"
        if userdel -rf "$username" 2>/dev/null; then
            log "INFO" "✓ User '$username' removed successfully" "remove_unnecessary_users()" "username=$username"
            users_removed=$((users_removed + 1))
        else
            log "WARNING" "Failed to remove user '$username'. Context: Function remove_unnecessary_users() attempted to remove user but userdel failed even after killing processes. Recovery: Check if user has locked files, verify user exists, or remove manually: userdel -rf $username" "remove_unnecessary_users()" "username=$username"
            users_failed=$((users_failed + 1))
        fi
    done <<< "$all_users"

    if [ "$users_removed" -gt 0 ]; then
        log "INFO" "✓ Removed $users_removed unnecessary user(s)" "remove_unnecessary_users()" "users_removed=$users_removed users_failed=$users_failed"
    fi

    if [ "$users_failed" -gt 0 ]; then
        log "WARNING" "$users_failed user(s) could not be removed" "remove_unnecessary_users()" "users_failed=$users_failed"
        return 1
    fi

    return 0
}

#######################################
# Collect user inputs interactively
#
# Purpose: Prompt user for username, password, and hostname with validation
#
# Inputs: None (reads from terminal interactively)
#
# Outputs:
#   - CUSTOM_USER: Username for the new user account (default: "coder")
#   - CUSTOM_PASS: Password for the new user account
#   - CUSTOM_HOSTNAME: System hostname (validated RFC 1123 format)
#
# Side Effects:
#   - Displays welcome banner
#   - Prompts user for input (may read from /dev/tty if script is piped)
#   - Validates username format (alphanumeric, underscore, hyphen)
#   - Validates password (non-empty, confirmation required)
#   - Validates hostname format (RFC 1123 compliant)
#
# Returns:
#   0 - Success (all inputs collected and validated)
#   1 - User cancelled or validation failed
#
# Idempotency: N/A (interactive function, not meant to be re-run)
#
# Example:
#   get_user_inputs
#   echo "Username: $CUSTOM_USER"
#   echo "Hostname: $CUSTOM_HOSTNAME"
#######################################
get_user_inputs() {
    # Try to load saved inputs first
    if load_user_inputs; then
        log "INFO" "Using saved configuration from previous installation" "get_user_inputs()"
        log "INFO" "Summary:" "get_user_inputs()"
        echo "  Username: $CUSTOM_USER"
        echo "  Hostname: $CUSTOM_HOSTNAME"
        echo ""
        log "INFO" "Skipping input prompts (using saved configuration)" "get_user_inputs()"
        return 0
    fi

    # If config not found or invalid, prompt for inputs
    show_welcome_banner

    log "INFO" "Please provide the following information:" "get_user_inputs()"
    echo ""

    # Username prompt with default
    # Use /dev/tty to ensure we read from the terminal when script is piped
    if [ -t 0 ] && [ -t 1 ]; then
        read -rp "Username [coder]: " CUSTOM_USER
    else
        read -rp "Username [coder]: " CUSTOM_USER < /dev/tty
    fi
    CUSTOM_USER=${CUSTOM_USER:-coder}

    # Validate username (alphanumeric, underscore, hyphen)
    while [[ ! "$CUSTOM_USER" =~ ^[a-zA-Z0-9_-]+$ ]]; do
        log "WARNING" "Invalid username. Use only alphanumeric characters, underscore, or hyphen." "get_user_inputs()" "username=$CUSTOM_USER"
        if [ -t 0 ] && [ -t 1 ]; then
            read -rp "Username [coder]: " CUSTOM_USER
        else
            read -rp "Username [coder]: " CUSTOM_USER < /dev/tty
        fi
        CUSTOM_USER=${CUSTOM_USER:-coder}
    done

    # Password prompt with hidden input
    # Initialize CUSTOM_PASS to empty string to avoid unbound variable error
    CUSTOM_PASS=""
    while [[ -z "$CUSTOM_PASS" ]]; do
        # Use /dev/tty to ensure we read from the terminal, not from stdin (important for piped scripts)
        # This is necessary when script is run via: curl ... | bash
        if [ -t 0 ] && [ -t 1 ]; then
            # Interactive terminal - use standard read
            read -rsp "Password: " CUSTOM_PASS
        else
            # Non-interactive or piped - force reading from terminal
            read -rsp "Password: " CUSTOM_PASS < /dev/tty
        fi
        echo ""  # Newline after hidden input
        if [[ -z "$CUSTOM_PASS" ]]; then
            log "WARNING" "Password cannot be empty. Please enter a password." "get_user_inputs()"
        fi
    done

    # Confirm password
    local pass_confirm=""
    if [ -t 0 ] && [ -t 1 ]; then
        read -rsp "Confirm password: " pass_confirm
    else
        read -rsp "Confirm password: " pass_confirm < /dev/tty
    fi
    echo ""
    if [[ "$CUSTOM_PASS" != "$pass_confirm" ]]; then
        log "ERROR" "Passwords do not match. Please try again." "get_user_inputs()"
        return 1
    fi

    # Hostname prompt
    # Initialize CUSTOM_HOSTNAME to empty string to avoid unbound variable error
    CUSTOM_HOSTNAME=""
    # Use /dev/tty to ensure we read from the terminal when script is piped
    if [ -t 0 ] && [ -t 1 ]; then
        read -rp "Hostname (e.g., my-vps): " CUSTOM_HOSTNAME
    else
        read -rp "Hostname (e.g., my-vps): " CUSTOM_HOSTNAME < /dev/tty
    fi
    while [[ -z "$CUSTOM_HOSTNAME" ]] || ! validate_hostname "$CUSTOM_HOSTNAME"; do
        if [[ -z "$CUSTOM_HOSTNAME" ]]; then
            log "WARNING" "Hostname cannot be empty." "get_user_inputs()"
        else
            log "WARNING" "Invalid hostname format. Use alphanumeric characters and hyphens only." "get_user_inputs()" "hostname=$CUSTOM_HOSTNAME"
        fi
        if [ -t 0 ] && [ -t 1 ]; then
            read -rp "Hostname (e.g., my-vps): " CUSTOM_HOSTNAME
        else
            read -rp "Hostname (e.g., my-vps): " CUSTOM_HOSTNAME < /dev/tty
        fi
    done

    # Confirmation prompt
    echo ""
    log "INFO" "Summary:" "get_user_inputs()"
    echo "  Username: $CUSTOM_USER"
    echo "  Hostname: $CUSTOM_HOSTNAME"
    echo ""
    # Use /dev/tty to ensure we read from the terminal when script is piped
    if [ -t 0 ] && [ -t 1 ]; then
        read -rp "Proceed with installation? (yes/no): " confirm
    else
        read -rp "Proceed with installation? (yes/no): " confirm < /dev/tty
    fi
    if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
        log "WARNING" "Installation cancelled by user." "get_user_inputs()"
        return 1
    fi

    # Save inputs to config file for future use
    if ! save_user_inputs "$CUSTOM_USER" "$CUSTOM_PASS" "$CUSTOM_HOSTNAME"; then
        log "WARNING" "Failed to save user inputs to config file, but continuing with installation" "get_user_inputs()"
    fi

    return 0
}

#######################################
# Prepare system (hostname, packages)
#
# Purpose: Set system hostname and install essential packages
#
# Inputs:
#   - hostname: System hostname to set (string, RFC 1123 format)
#
# Outputs: None
#
# Side Effects:
#   - Sets system hostname via hostnamectl
#   - Updates APT package repositories
#   - Installs essential packages: curl, git, htop, vim, build-essential
#   - Creates package installation log
#
# Returns:
#   0 - Success (hostname set, packages installed or already present)
#   1 - Error (hostname setting failed, package installation failed)
#
# Idempotency: Yes
#   - Checks current hostname before setting (skips if already set)
#   - Checks package installation status before installing (skips if already installed)
#   - Safe to run multiple times
#
# Example:
#   system_prep "my-vps"
#######################################
system_prep() {
    local hostname="$1"

    log "INFO" "Preparing system..." "system_prep()"

    # Set hostname with idempotency check
    local current_hostname
    current_hostname=$(hostname)
    if [ "$current_hostname" != "$hostname" ]; then
        log "INFO" "Setting hostname to: $hostname" "system_prep()"
        if ! hostnamectl set-hostname "$hostname"; then
            log "ERROR" "Failed to set hostname to '$hostname'. Context: Function system_prep() attempted to set hostname via hostnamectl but command failed. Recovery: Check system permissions, ensure hostnamectl is available, or set hostname manually: hostnamectl set-hostname $hostname" "system_prep()" "hostname=$hostname current=$current_hostname"
            return 1
        fi
        log "INFO" "✓ Hostname set to: $hostname" "system_prep()"
    else
        log "INFO" "✓ Hostname already set to: $hostname" "system_prep()"
    fi

    # Update APT repositories
    log "INFO" "Updating package repositories..." "system_prep()"
    if ! apt-get update -qq; then
        log "ERROR" "Failed to update APT repositories. Context: Function system_prep() attempted to update package repositories but apt-get update failed. Recovery: Check network connectivity, verify /etc/apt/sources.list configuration, or run manually: apt-get update" "system_prep()"
        return 1
    fi
    log "INFO" "✓ Package repositories updated" "system_prep()"

    # Install essential packages with idempotency checks
    local packages=("curl" "git" "htop" "vim" "build-essential")
    local packages_to_install=()

    for package in "${packages[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
            packages_to_install+=("$package")
        else
            log "INFO" "✓ $package already installed" "system_prep()"
        fi
    done

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        log "INFO" "Installing essential packages: ${packages_to_install[*]} (this may take a few minutes)..." "system_prep()"
        if ! apt-get install -y "${packages_to_install[@]}"; then
            log "ERROR" "Failed to install essential packages: ${packages_to_install[*]}. Context: Function system_prep() attempted to install packages but apt-get install failed. Recovery: Check package availability, verify APT repository configuration, or install manually: apt-get install -y ${packages_to_install[*]}" "system_prep()" "packages=${packages_to_install[*]}"
            return 1
        fi
        log "INFO" "✓ Essential packages installed" "system_prep()"
    fi
}

#######################################
# Create user account
# Inputs: CUSTOM_USER, CUSTOM_PASS
# Returns: 0 on success, 1 on error
#######################################
#######################################
# Create user account with password
#
# Purpose: Create a new system user with home directory and set password
#
# Inputs:
#   - username: Username for the new account (string, validated format)
#   - password: Password for the new account (string, plain text)
#
# Outputs: None
#
# Side Effects:
#   - Creates new user account with home directory (/home/username)
#   - Sets user password via chpasswd
#   - Creates home directory structure
#   - Sets default shell to /bin/bash
#
# Returns:
#   0 - Success (user created or already exists)
#   1 - Error (user creation failed)
#
# Idempotency: Yes
#   - Checks if user exists before creation (skips if user already exists)
#   - Safe to run multiple times (won't create duplicate users)
#
# Example:
#   create_user "coder" "SecurePass123!"
#######################################
create_user() {
    local username="$1"
    local password="$2"

    log "INFO" "Creating user account..." "create_user()" "username=$username"

    # Check if user already exists
    if id "$username" &>/dev/null; then
        log "INFO" "User '$username' already exists. Skipping user creation." "create_user()" "username=$username"
        return 0
    fi

    # Create user with home directory and bash shell
    if ! useradd -m -s /bin/bash "$username"; then
        log "ERROR" "Failed to create user '$username'. Context: Function create_user() attempted to create user account via useradd but command failed. Possible causes: username conflicts, invalid username format, or system user limit reached. Recovery: Check if username is valid (alphanumeric, underscore, hyphen), verify no conflicting user exists, check system limits (/etc/login.defs), or create user manually: useradd -m -s /bin/bash $username" "create_user()" "username=$username"
        return 1
    fi

    # Set password
    if ! echo "$username:$password" | chpasswd; then
        log "ERROR" "Failed to set password for user '$username'. Context: Function create_user() attempted to set user password via chpasswd but command failed. Recovery: Verify password meets system requirements, check chpasswd availability, or set password manually: echo '$username:$password' | chpasswd" "create_user()" "username=$username"
        return 1
    fi

    # Add user to sudo group (for sudo access)
    # Check if sudo group exists (Debian/Ubuntu typically has 'sudo' group)
    if getent group sudo &>/dev/null; then
        if ! usermod -aG sudo "$username" 2>/dev/null; then
            log "WARNING" "Failed to add user '$username' to sudo group. User may not have sudo access. Recovery: Add manually: usermod -aG sudo $username" "create_user()" "username=$username"
        else
            log "INFO" "✓ User '$username' added to sudo group" "create_user()" "username=$username"
        fi
    else
        log "WARNING" "Sudo group not found. User '$username' may not have sudo access. Recovery: Ensure sudo package is installed and sudo group exists." "create_user()" "username=$username"
    fi

    log "INFO" "✓ User '$username' created successfully" "create_user()" "username=$username"
    return 0
}

#######################################
# Parse Git branch name for PS1 prompt
# Returns: Branch name in format (branch) or empty string
#######################################
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

#######################################
# Check if an alias already exists (for conflict detection)
# Purpose: Detect existing aliases to preserve user customizations
# Inputs:
#   - alias_name: Name of alias to check (string, required)
# Returns:
#   0 - Conflict exists (alias already defined)
#   1 - No conflict (alias not defined)
# Side Effects: None
# Idempotency: Safe to call multiple times
# Example:
#   if check_alias_conflict "gst"; then
#       log "WARNING" "Alias 'gst' already exists, skipping"
#   fi
#######################################
check_alias_conflict() {
    local alias_name="$1"

    # Check if alias exists using 'type' command
    # type returns 0 if alias/function/command exists, 1 if not
    if type "$alias_name" &>/dev/null; then
        # Check if it's specifically an alias (not a function or command)
        if alias "$alias_name" &>/dev/null 2>&1; then
            return 0  # Conflict exists
        fi
    fi
    return 1  # No conflict
}

#######################################
# Check if a function already exists (for conflict detection)
# Purpose: Detect existing functions to preserve user customizations
# Inputs:
#   - function_name: Name of function to check (string, required)
# Returns:
#   0 - Conflict exists (function already defined)
#   1 - No conflict (function not defined)
# Side Effects: None
# Idempotency: Safe to call multiple times
# Example:
#   if check_function_conflict "mkcd"; then
#       log "WARNING" "Function 'mkcd' already exists, skipping"
#   fi
#######################################
check_function_conflict() {
    local function_name="$1"

    # Check if function exists using 'type' command
    # type returns 0 if function/command exists, 1 if not
    if type "$function_name" &>/dev/null; then
        # Check if it's specifically a function (not an alias or command)
        if declare -f "$function_name" &>/dev/null; then
            return 0  # Conflict exists
        fi
    fi
    return 1  # No conflict
}

#######################################
# Create timestamped backup of .bashrc before modifications
# Purpose: Ensure recovery capability before making configuration changes
# Inputs:
#   - bashrc_path: Path to .bashrc file (string, required)
# Returns:
#   0 - Success (backup created)
#   1 - Error (backup failed) - ABORTS with error message
# Side Effects:
#   - Creates backup file with format: {bashrc_path}.backup.YYYYMMDD_HHMMSS
#   - Preserves original file permissions
# Idempotency: Safe to call multiple times (creates new backup each time)
# Example:
#   if ! create_bashrc_backup "/home/coder/.bashrc"; then
#       return 1  # Abort on backup failure
#   fi
# Notes:
#   - Must abort if backup creation fails (FR-012, T003)
#   - Backup format: ~/.bashrc.backup.YYYYMMDD_HHMMSS
#######################################
create_bashrc_backup() {
    local bashrc_path="$1"
    local backup_path
    local timestamp

    # Generate timestamp in format YYYYMMDD_HHMMSS
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_path="${bashrc_path}.backup.${timestamp}"

    # Check if .bashrc exists
    if [ ! -f "$bashrc_path" ]; then
        log "INFO" "No existing .bashrc found, skipping backup" "create_bashrc_backup()" "bashrc_path=$bashrc_path"
        return 0  # No file to backup is not an error
    fi

    # Create backup
    if ! cp "$bashrc_path" "$backup_path"; then
        log "ERROR" "[ERROR] [terminal-enhancements] Failed to create .bashrc backup, aborting configuration changes. Ensure write permissions to home directory." "create_bashrc_backup()" "bashrc_path=$bashrc_path backup_path=$backup_path"
        return 1  # Abort on backup failure (T003 requirement)
    fi

    # Preserve original file permissions
    if [ -f "$backup_path" ]; then
        chmod 600 "$backup_path" 2>/dev/null || true
    fi

    log "INFO" "Created .bashrc backup: $backup_path" "create_bashrc_backup()" "bashrc_path=$bashrc_path backup_path=$backup_path"
    return 0
}

#######################################
# Install Starship prompt tool
#
# Purpose: Install Starship prompt via official installer script
#
# Inputs: None
#
# Outputs: None (uses structured logging)
#
# Side Effects:
#   - Downloads and installs Starship binary
#   - Adds Starship to system PATH (~/.local/bin/starship)
#
# Returns:
#   0 - Success (Starship installed or already installed)
#   1 - Error (installation failed)
#
# Idempotency: Yes
#   - Checks if starship command exists in PATH before installing
#   - Skips installation if already present
#
# Dependencies:
#   - curl or wget (for downloading installer)
#   - Internet connectivity
#   - Write permissions for installation directory
#
# Verification:
#   - After installation, verifies: command -v starship &>/dev/null
#
# Example:
#   if install_starship; then
#       log "INFO" "Starship installed successfully"
#   fi
#######################################
install_starship() {
    # Idempotency check (T006, FR-014)
    if command -v starship &>/dev/null; then
        log "INFO" "Starship already installed, skipping installation" "install_starship()"
        return 0
    fi

    log "INFO" "Installing Starship prompt..." "install_starship()"

    # Determine download command (curl or wget)
    local download_cmd
    if command -v curl &>/dev/null; then
        download_cmd="curl -sS"
    elif command -v wget &>/dev/null; then
        download_cmd="wget -qO-"
    else
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install starship. Continuing with remaining tools." "install_starship()" "reason=curl_or_wget_not_available"
        return 1
    fi

    # Install Starship via official installer (T007)
    if ! $download_cmd https://starship.rs/install.sh | sh -s -- --yes; then
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install starship. Continuing with remaining tools." "install_starship()" "reason=installer_failed"
        return 1
    fi

    # Verify installation (T008, FR-014)
    if ! command -v starship &>/dev/null; then
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install starship. Continuing with remaining tools." "install_starship()" "reason=verification_failed"
        return 1
    fi

    # Visual feedback (T008, FR-015)
    log "INFO" "[INFO] [terminal-enhancements] ✓ starship installed and configured successfully" "install_starship()"
    return 0
}

#######################################
# Configure Starship prompt in .bashrc
#
# Purpose: Configure Starship prompt by removing existing PS1/PROMPT_COMMAND and adding Starship initialization
#
# Inputs:
#   - username: Username for which to configure Starship (string, required)
#
# Outputs: None (uses structured logging)
#
# Side Effects:
#   - Creates backup of .bashrc before modification
#   - Removes existing PS1 and PROMPT_COMMAND settings
#   - Adds Starship initialization to .bashrc
#   - Sets file ownership and permissions
#
# Returns:
#   0 - Success (Starship configured or already configured)
#   1 - Error (configuration failed)
#
# Idempotency: Yes
#   - Checks for configuration marker before adding
#   - Safe to run multiple times
#
# Dependencies:
#   - install_starship() must succeed first
#   - create_bashrc_backup() function
#   - starship command must be available
#
# Example:
#   configure_starship_prompt "coder"
#######################################
configure_starship_prompt() {
    local username="$1"
    local home_dir="/home/$username"
    local bashrc_file="$home_dir/.bashrc"
    local starship_marker="# Starship Prompt Configuration - Added by setup-workstation.sh"

    log "INFO" "Configuring Starship prompt..." "configure_starship_prompt()" "username=$username"

    # Verify Starship is installed before configuring
    if ! command -v starship &>/dev/null; then
        log "WARNING" "Starship not installed, skipping configuration" "configure_starship_prompt()" "username=$username"
        return 1
    fi

    # Configuration marker check (T013)
    if [ -f "$bashrc_file" ] && grep -q "$starship_marker" "$bashrc_file"; then
        log "INFO" "Starship already configured, skipping" "configure_starship_prompt()" "username=$username"
        return 0
    fi

    # Backup creation (T010)
    if ! create_bashrc_backup "$bashrc_file"; then
        log "ERROR" "Failed to create backup, aborting Starship configuration" "configure_starship_prompt()" "username=$username bashrc_file=$bashrc_file"
        return 1
    fi

    # Ensure .bashrc exists
    if [ ! -f "$bashrc_file" ]; then
        touch "$bashrc_file"
        chown "$username:$username" "$bashrc_file"
        chmod 644 "$bashrc_file"
    fi

    # Remove existing PS1 and PROMPT_COMMAND (T011, FR-023)
    # Create temporary file for processing
    local temp_file
    temp_file=$(mktemp)
    if [ ! -f "$temp_file" ]; then
        log "ERROR" "Failed to create temporary file for .bashrc processing" "configure_starship_prompt()" "username=$username"
        return 1
    fi

    # Remove lines containing PS1= or PROMPT_COMMAND= (but preserve other content)
    # If filtered output is empty, create minimal .bashrc to avoid conflicts
    if [ -f "$bashrc_file" ]; then
        grep -v "^PS1=" "$bashrc_file" 2>/dev/null | grep -v "^PROMPT_COMMAND=" > "$temp_file" || true
        # If temp file is empty, create minimal .bashrc to avoid PS1/PROMPT_COMMAND conflicts
        if [ -s "$temp_file" ]; then
            mv "$temp_file" "$bashrc_file"
        else
            # Create minimal .bashrc with just a comment to avoid conflicts
            echo "# Bash configuration - PS1/PROMPT_COMMAND removed for Starship" > "$bashrc_file"
            log "INFO" "Filtered .bashrc was empty, created minimal .bashrc to avoid prompt conflicts" "configure_starship_prompt()" "username=$username bashrc_file=$bashrc_file"
            rm -f "$temp_file"
        fi
    fi

    # Add Starship configuration (T012)
    {
        echo ""
        echo "$starship_marker"
        echo "# Initialize Starship prompt"
        echo 'eval "$(starship init bash)"'
    } >> "$bashrc_file"

    # Ensure correct ownership and permissions
    chown "$username:$username" "$bashrc_file" 2>/dev/null || true
    chmod 644 "$bashrc_file" 2>/dev/null || true

    log "INFO" "✓ Starship prompt configured successfully" "configure_starship_prompt()" "username=$username"
    return 0
}

#######################################
# Install fzf (fuzzy finder) tool
#
# Purpose: Install fzf via APT package manager
#
# Inputs: None
#
# Outputs: None (uses structured logging)
#
# Side Effects:
#   - Installs fzf package via APT
#   - Makes fzf available in system PATH
#
# Returns:
#   0 - Success (fzf installed or already installed)
#   1 - Error (installation failed)
#
# Idempotency: Yes
#   - Checks package status using dpkg-query before installing
#   - Skips installation if package already installed
#
# Dependencies:
#   - apt package manager
#   - Internet connectivity
#   - Root/sudo privileges
#
# Verification:
#   - After installation, verifies: command -v fzf &>/dev/null
#
# Example:
#   if install_fzf; then
#       log "INFO" "fzf installed successfully"
#   fi
#######################################
install_fzf() {
    # Idempotency check (T016, FR-014)
    if dpkg-query -W -f='${Status}' "fzf" 2>/dev/null | grep -q "install ok installed"; then
        log "INFO" "fzf already installed, skipping installation" "install_fzf()"
        return 0
    fi

    log "INFO" "Installing fzf (fuzzy finder)..." "install_fzf()"

    # Install fzf via APT (T017)
    if ! (sudo apt-get update -qq && sudo apt-get install -y fzf); then
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install fzf. Continuing with remaining tools." "install_fzf()" "reason=apt_install_failed"
        return 1
    fi

    # Verify installation (T018, FR-014)
    if ! command -v fzf &>/dev/null; then
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install fzf. Continuing with remaining tools." "install_fzf()" "reason=verification_failed"
        return 1
    fi

    # Visual feedback (T018, FR-015)
    log "INFO" "[INFO] [terminal-enhancements] ✓ fzf installed and configured successfully" "install_fzf()"
    return 0
}

#######################################
# Configure fzf key bindings in .bashrc
#
# Purpose: Configure fzf key bindings (Ctrl+R for history, Ctrl+T for files) with ignore patterns
#
# Inputs:
#   - username: Username for which to configure fzf (string, required)
#
# Outputs: None (uses structured logging)
#
# Side Effects:
#   - Adds fzf key bindings to .bashrc
#   - Configures FZF_DEFAULT_OPTS environment variable
#   - Configures FZF_CTRL_T_COMMAND with ignore patterns (node_modules, .git)
#   - Sets file ownership and permissions
#
# Returns:
#   0 - Success (fzf configured or already configured)
#   1 - Error (configuration failed)
#
# Idempotency: Yes
#   - Checks for configuration marker before adding
#   - Safe to run multiple times
#
# Dependencies:
#   - install_fzf() must succeed first
#   - fzf command must be available
#   - User's .bashrc file must exist or be creatable
#
# Example:
#   configure_fzf_key_bindings "coder"
#######################################
configure_fzf_key_bindings() {
    local username="$1"
    local home_dir="/home/$username"
    local bashrc_file="$home_dir/.bashrc"
    local fzf_marker="# fzf Key Bindings Configuration - Added by setup-workstation.sh"

    log "INFO" "Configuring fzf key bindings..." "configure_fzf_key_bindings()" "username=$username"

    # Verify fzf is installed before configuring
    if ! command -v fzf &>/dev/null; then
        log "WARNING" "fzf not installed, skipping configuration" "configure_fzf_key_bindings()" "username=$username"
        return 1
    fi

    # Configuration marker check (T019)
    if [ -f "$bashrc_file" ] && grep -q "$fzf_marker" "$bashrc_file"; then
        log "INFO" "fzf key bindings already configured, skipping" "configure_fzf_key_bindings()" "username=$username"
        return 0
    fi

    # Ensure .bashrc exists
    if [ ! -f "$bashrc_file" ]; then
        touch "$bashrc_file"
        chown "$username:$username" "$bashrc_file"
        chmod 644 "$bashrc_file"
    fi

    # Add fzf key bindings (T020)
    {
        echo ""
        echo "$fzf_marker"
        echo "# Initialize fzf key bindings (Ctrl+R for history, Ctrl+T for files)"
        echo 'eval "$(fzf --bash)"'
        echo ""
        echo "# fzf default options (T021)"
        echo 'export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"'
        echo ""
        echo "# fzf file search command with ignore patterns (T022, FR-017)"
        echo 'export FZF_CTRL_T_COMMAND="find . -type f -not -path '\''*/\.git/*'\'' -not -path '\''*/node_modules/*'\'' 2>/dev/null"'
    } >> "$bashrc_file"

    # Ensure correct ownership and permissions
    chown "$username:$username" "$bashrc_file" 2>/dev/null || true
    chmod 644 "$bashrc_file" 2>/dev/null || true

    log "INFO" "✓ fzf key bindings configured successfully" "configure_fzf_key_bindings()" "username=$username"
    return 0
}

#######################################
# Install bat (better cat) tool
#
# Purpose: Install bat via APT and create symlink bat → batcat
#
# Inputs:
#   - username: Username for which to install bat (string, required)
#
# Outputs: None (uses structured logging)
#
# Side Effects:
#   - Installs bat package via APT (installs as batcat)
#   - Creates symlink bat → batcat in /home/$username/.local/bin/
#   - Ensures /home/$username/.local/bin exists and is in PATH
#
# Returns:
#   0 - Success (bat installed and symlink created, or already installed)
#   1 - Error (installation or symlink creation failed)
#
# Idempotency: Yes
#   - Checks package status using dpkg-query before installing
#   - Checks if symlink exists before creating
#   - Skips if already installed and configured
#
# Dependencies:
#   - apt package manager
#   - /home/$username/.local/bin directory (created if needed)
#   - Write permissions for user's home directory
#
# Verification:
#   - After installation, verifies: command -v batcat &>/dev/null
#   - After symlink, verifies: command -v bat &>/dev/null
#
# Example:
#   if install_bat "coder"; then
#       log "INFO" "bat installed and symlink created"
#   fi
#######################################
install_bat() {
    local username="$1"
    local home_dir="/home/$username"
    local local_bin_dir="$home_dir/.local/bin"
    local bat_symlink="$local_bin_dir/bat"

    # Idempotency check (T024, FR-014)
    if dpkg-query -W -f='${Status}' "bat" 2>/dev/null | grep -q "install ok installed"; then
        # Check if symlink exists in user's home directory
        if [ -L "$bat_symlink" ] || command -v bat &>/dev/null; then
            log "INFO" "bat already installed and configured, skipping installation" "install_bat()" "username=$username"
            return 0
        fi
    fi

    log "INFO" "Installing bat (better cat)..." "install_bat()" "username=$username"

    # Install bat via APT (T026)
    if ! (sudo apt-get update -qq && sudo apt-get install -y bat); then
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install bat. Continuing with remaining tools." "install_bat()" "username=$username reason=apt_install_failed"
        return 1
    fi

    # Ensure user's ~/.local/bin exists and has correct ownership (T028)
    if [ ! -d "$local_bin_dir" ]; then
        mkdir -p "$local_bin_dir"
        chown "$username:$username" "$local_bin_dir" 2>/dev/null || true
    fi

    # Create symlink bat → batcat in user's home directory (T027)
    if [ ! -L "$bat_symlink" ] && [ ! -f "$bat_symlink" ]; then
        if ! ln -s /usr/bin/batcat "$bat_symlink" 2>/dev/null; then
            log "WARNING" "Failed to create bat symlink, but batcat is available" "install_bat()" "username=$username"
            # Continue - user can use batcat directly
        else
            # Set correct ownership for symlink
            chown "$username:$username" "$bat_symlink" 2>/dev/null || true
        fi
    fi

    # Verify installation (T029, FR-014)
    if ! command -v batcat &>/dev/null; then
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install bat. Continuing with remaining tools." "install_bat()" "username=$username reason=verification_failed"
        return 1
    fi

    # Visual feedback (T029, FR-015)
    log "INFO" "[INFO] [terminal-enhancements] ✓ bat installed and configured successfully" "install_bat()" "username=$username"
    return 0
}

#######################################
# Install exa (modern ls) tool
#
# Purpose: Install exa binary from GitHub releases
#
# Inputs: None
#
# Outputs: None (uses structured logging)
#
# Side Effects:
#   - Downloads exa binary from GitHub releases
#   - Installs binary to /usr/local/bin/exa
#   - Makes exa available in system PATH
#
# Returns:
#   0 - Success (exa installed or already installed)
#   1 - Error (download or installation failed)
#
# Idempotency: Yes
#   - Checks if exa command exists in PATH before installing
#   - Skips installation if already present
#
# Dependencies:
#   - wget or curl (for downloading)
#   - unzip (for extracting binary)
#   - Internet connectivity
#   - Root/sudo privileges (for /usr/local/bin/)
#
# Verification:
#   - After installation, verifies: command -v exa &>/dev/null
#
# Example:
#   if install_exa; then
#       log "INFO" "exa installed successfully"
#   fi
#######################################
install_exa() {
    # Idempotency check (T025, FR-014)
    if command -v exa &>/dev/null; then
        log "INFO" "exa already installed, skipping installation" "install_exa()"
        return 0
    fi

    log "INFO" "Installing exa (modern ls)..." "install_exa()"

    # Check disk space (T031, Edge Cases: Disk Space Exhaustion)
    local available_space
    available_space=$(df /usr/local/bin 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
    if [ "$available_space" -lt 524288 ]; then  # 500MB in KB
        log "ERROR" "[ERROR] [terminal-enhancements] Disk space exhausted. Free at least 500MB and retry installation." "install_exa()" "available_space=${available_space}KB"
        return 1
    fi

    # Determine architecture
    local arch
    arch=$(uname -m)
    if [ "$arch" != "x86_64" ]; then
        log "WARNING" "Unsupported architecture for exa: $arch. Skipping installation." "install_exa()"
        return 1
    fi

    # Use local exa folder as source (T030)
    # Calculate path to exa folder relative to script location
    local project_root
    project_root=$(cd "$SCRIPT_DIR/.." && pwd)
    local exa_source_dir="$project_root/exa"
    local exa_binary="$exa_source_dir/bin/exa"

    # Verify local exa folder exists
    if [ ! -d "$exa_source_dir" ]; then
        log "ERROR" "[ERROR] [terminal-enhancements] Failed to install exa: local exa folder not found at '$exa_source_dir'. Skipping exa installation. Remaining tools will continue installation." "install_exa()" "reason=local_folder_not_found"
        return 1
    fi

    # Verify binary exists in local folder
    if [ ! -f "$exa_binary" ]; then
        log "ERROR" "[ERROR] [terminal-enhancements] Failed to install exa: binary not found at '$exa_binary'. Skipping exa installation. Remaining tools will continue installation." "install_exa()" "reason=binary_not_found"
        return 1
    fi

    # Verify binary is executable
    if [ ! -x "$exa_binary" ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Binary at '$exa_binary' is not executable. Setting executable permission..." "install_exa()"
        chmod +x "$exa_binary" 2>/dev/null || true
    fi

    # Install binary to /usr/local/bin/exa (T031)
    if ! cp "$exa_binary" /usr/local/bin/exa; then
        log "ERROR" "[ERROR] [terminal-enhancements] Failed to install exa: permission denied or filesystem error during installation. Skipping exa installation. Remaining tools will continue installation." "install_exa()" "reason=installation_failed"
        return 1
    fi

    # Set permissions
    chmod +x /usr/local/bin/exa 2>/dev/null || true

    # Verify installation (T032, FR-014)
    # Check both command availability and binary existence
    # PATH may not be updated immediately, so check binary file directly
    if command -v exa &>/dev/null || [ -f /usr/local/bin/exa ]; then
        # Visual feedback (T032, FR-015)
        log "INFO" "[INFO] [terminal-enhancements] ✓ exa installed and configured successfully" "install_exa()"
        return 0
    else
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install exa. Continuing with remaining tools." "install_exa()" "reason=verification_failed"
        return 1
    fi
}

#######################################
# Configure terminal aliases (bat, exa, and future aliases)
#
# Purpose: Add aliases for bat and exa to user's .bashrc with conflict detection
#
# Inputs:
#   - username: Username for which to configure aliases (string, required)
#
# Outputs: None (uses structured logging)
#
# Side Effects:
#   - Adds bat and exa aliases to .bashrc
#   - Sets file ownership and permissions
#
# Returns:
#   0 - Success (aliases configured or already configured)
#   1 - Error (configuration failed)
#
# Idempotency: Yes
#   - Checks for configuration marker before adding
#   - Checks for conflicts before adding aliases
#   - Safe to run multiple times
#
# Dependencies:
#   - install_bat() and install_exa() should succeed first
#   - check_alias_conflict() function
#   - User's .bashrc file must exist or be creatable
#
# Example:
#   configure_terminal_aliases "coder"
#######################################
configure_terminal_aliases() {
    local username="$1"
    local home_dir="/home/$username"
    local bashrc_file="$home_dir/.bashrc"
    local aliases_marker="# Terminal Aliases Configuration - Added by setup-workstation.sh"

    log "INFO" "Configuring terminal aliases..." "configure_terminal_aliases()" "username=$username"

    # Configuration marker check
    if [ -f "$bashrc_file" ] && grep -q "$aliases_marker" "$bashrc_file"; then
        log "INFO" "Terminal aliases already configured, skipping" "configure_terminal_aliases()" "username=$username"
        return 0
    fi

    # Ensure .bashrc exists
    if [ ! -f "$bashrc_file" ]; then
        touch "$bashrc_file"
        chown "$username:$username" "$bashrc_file"
        chmod 644 "$bashrc_file"
    fi

    # Check for existing aliases in .bashrc (for conflict detection)
    local cat_alias_exists=false
    local ls_alias_exists=false
    local ll_alias_exists=false
    local gst_alias_exists=false
    local gco_alias_exists=false
    local gcm_alias_exists=false
    local gpl_alias_exists=false
    local gps_alias_exists=false
    local dc_alias_exists=false
    local dps_alias_exists=false
    local dlog_alias_exists=false

    if [ -f "$bashrc_file" ]; then
        if grep -qE "^alias cat=" "$bashrc_file" 2>/dev/null; then
            cat_alias_exists=true
        fi
        if grep -qE "^alias ls=" "$bashrc_file" 2>/dev/null; then
            ls_alias_exists=true
        fi
        if grep -qE "^alias ll=" "$bashrc_file" 2>/dev/null; then
            ll_alias_exists=true
        fi
        # Git aliases (T037)
        if grep -qE "^alias gst=" "$bashrc_file" 2>/dev/null; then
            gst_alias_exists=true
        fi
        if grep -qE "^alias gco=" "$bashrc_file" 2>/dev/null; then
            gco_alias_exists=true
        fi
        if grep -qE "^alias gcm=" "$bashrc_file" 2>/dev/null; then
            gcm_alias_exists=true
        fi
        if grep -qE "^alias gpl=" "$bashrc_file" 2>/dev/null; then
            gpl_alias_exists=true
        fi
        if grep -qE "^alias gps=" "$bashrc_file" 2>/dev/null; then
            gps_alias_exists=true
        fi
        # Docker aliases (T039)
        if grep -qE "^alias dc=" "$bashrc_file" 2>/dev/null; then
            dc_alias_exists=true
        fi
        if grep -qE "^alias dps=" "$bashrc_file" 2>/dev/null; then
            dps_alias_exists=true
        fi
        if grep -qE "^alias dlog=" "$bashrc_file" 2>/dev/null; then
            dlog_alias_exists=true
        fi
    fi

    # Add aliases (T033, T034, T038, T040)
    {
        echo ""
        echo "$aliases_marker"
        echo "# bat alias (better cat)"
        if [ "$cat_alias_exists" = false ]; then
            if command -v bat &>/dev/null; then
                echo "alias cat='bat'"
            elif command -v batcat &>/dev/null; then
                echo "alias cat='batcat'"
            fi
        fi
        echo ""
        echo "# exa aliases (modern ls)"
        if [ "$ls_alias_exists" = false ]; then
            if command -v exa &>/dev/null; then
                echo "alias ls='exa'"
            fi
        fi
        if [ "$ll_alias_exists" = false ]; then
            if command -v exa &>/dev/null; then
                echo "alias ll='exa -lah'"
            fi
        fi
        echo ""
        echo "# Git aliases (T038, FR-005)"
        if [ "$gst_alias_exists" = false ]; then
            echo "alias gst='git status'"
        fi
        if [ "$gco_alias_exists" = false ]; then
            echo "alias gco='git checkout'"
        fi
        if [ "$gcm_alias_exists" = false ]; then
            echo "alias gcm='git commit -m'"
        fi
        if [ "$gpl_alias_exists" = false ]; then
            echo "alias gpl='git pull'"
        fi
        if [ "$gps_alias_exists" = false ]; then
            echo "alias gps='git push'"
        fi
        echo ""
        echo "# Docker aliases (T040, FR-006)"
        if [ "$dc_alias_exists" = false ]; then
            echo "alias dc='docker-compose'"
        fi
        if [ "$dps_alias_exists" = false ]; then
            echo "alias dps='docker ps'"
        fi
        if [ "$dlog_alias_exists" = false ]; then
            echo "alias dlog='docker logs -f'"
        fi
    } >> "$bashrc_file"

    # Log warnings for skipped aliases (moved outside redirection block)
    if [ "$cat_alias_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'cat' already exists, skipping to preserve user customization." "configure_terminal_aliases()" "username=$username"
    fi
    if [ "$ls_alias_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'ls' already exists, skipping to preserve user customization." "configure_terminal_aliases()" "username=$username"
    fi
    if [ "$ll_alias_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'll' already exists, skipping to preserve user customization." "configure_terminal_aliases()" "username=$username"
    fi
    if [ "$gst_alias_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'gst' already exists, skipping to preserve user customization." "configure_terminal_aliases()" "username=$username"
    fi
    if [ "$gco_alias_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'gco' already exists, skipping to preserve user customization." "configure_terminal_aliases()" "username=$username"
    fi
    if [ "$gcm_alias_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'gcm' already exists, skipping to preserve user customization." "configure_terminal_aliases()" "username=$username"
    fi
    if [ "$gpl_alias_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'gpl' already exists, skipping to preserve user customization." "configure_terminal_aliases()" "username=$username"
    fi
    if [ "$gps_alias_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'gps' already exists, skipping to preserve user customization." "configure_terminal_aliases()" "username=$username"
    fi
    if [ "$dc_alias_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'dc' already exists, skipping to preserve user customization." "configure_terminal_aliases()" "username=$username"
    fi
    if [ "$dps_alias_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'dps' already exists, skipping to preserve user customization." "configure_terminal_aliases()" "username=$username"
    fi
    if [ "$dlog_alias_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'dlog' already exists, skipping to preserve user customization." "configure_terminal_aliases()" "username=$username"
    fi

    # Ensure correct ownership and permissions
    chown "$username:$username" "$bashrc_file" 2>/dev/null || true
    chmod 644 "$bashrc_file" 2>/dev/null || true

    log "INFO" "✓ Terminal aliases configured successfully" "configure_terminal_aliases()" "username=$username"
    return 0
}

#######################################
# Configure terminal functions (utility functions)
#
# Purpose: Add utility functions (mkcd, extract, ports, weather) to user's .bashrc with conflict detection
#
# Inputs:
#   - username: Username for which to configure functions (string, required)
#
# Outputs: None (uses structured logging)
#
# Side Effects:
#   - Checks for existing functions before adding
#   - Adds non-conflicting functions to .bashrc
#   - Logs warnings for skipped conflicts
#
# Returns:
#   0 - Success (functions configured or already configured)
#   1 - Error (configuration failed)
#
# Idempotency: Yes
#   - Checks for configuration marker before adding
#   - Checks each function for conflicts before adding
#   - Safe to run multiple times
#
# Dependencies:
#   - check_function_conflict() function
#   - User's .bashrc file must exist or be creatable
#   - Write permissions for user's home directory
#
# Functions Added (if no conflicts):
#   - mkcd() - Create and enter directory
#   - extract() - Extract archives
#   - ports() - Show listening ports
#   - weather() - Weather info (with error handling for wttr.in)
#
# Example:
#   configure_terminal_functions "coder"
#######################################
configure_terminal_functions() {
    local username="$1"
    local home_dir="/home/$username"
    local bashrc_file="$home_dir/.bashrc"
    local functions_marker="# Terminal Functions Configuration - Added by setup-workstation.sh"

    log "INFO" "Configuring terminal functions..." "configure_terminal_functions()" "username=$username"

    # Configuration marker check (T041)
    if [ -f "$bashrc_file" ] && grep -q "$functions_marker" "$bashrc_file"; then
        log "INFO" "Terminal functions already configured, skipping" "configure_terminal_functions()" "username=$username"
        return 0
    fi

    # Ensure .bashrc exists
    if [ ! -f "$bashrc_file" ]; then
        touch "$bashrc_file"
        chown "$username:$username" "$bashrc_file"
        chmod 644 "$bashrc_file"
    fi

    # Check for existing functions in .bashrc (T042)
    local mkcd_exists=false
    local extract_exists=false
    local ports_exists=false
    local weather_exists=false

    if [ -f "$bashrc_file" ]; then
        if grep -qE "^mkcd\(\)|^function mkcd" "$bashrc_file" 2>/dev/null; then
            mkcd_exists=true
        fi
        if grep -qE "^extract\(\)|^function extract" "$bashrc_file" 2>/dev/null; then
            extract_exists=true
        fi
        if grep -qE "^ports\(\)|^function ports" "$bashrc_file" 2>/dev/null; then
            ports_exists=true
        fi
        if grep -qE "^weather\(\)|^function weather" "$bashrc_file" 2>/dev/null; then
            weather_exists=true
        fi
    fi

    # Add functions (T043, T044, T045, T046)
    {
        echo ""
        echo "$functions_marker"
        echo ""
        echo "# mkcd() - Create and enter directory (T043)"
        if [ "$mkcd_exists" = false ]; then
            cat << 'MKCD_EOF'
mkcd() {
    mkdir -p "$1" && cd "$1" || return 1
}
MKCD_EOF
        fi
        echo ""
        echo "# extract() - Extract archives (T044)"
        if [ "$extract_exists" = false ]; then
            cat << 'EXTRACT_EOF'
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar x "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
EXTRACT_EOF
        fi
        echo ""
        echo "# ports() - Show listening ports (T045)"
        if [ "$ports_exists" = false ]; then
            cat << 'PORTS_EOF'
ports() {
    netstat -tulanp 2>/dev/null | grep LISTEN || ss -tulanp 2>/dev/null | grep LISTEN || echo "Unable to list listening ports. Install net-tools or iproute2."
}
PORTS_EOF
        fi
        echo ""
        echo "# weather() - Weather info with error handling (T046, FR-024)"
        if [ "$weather_exists" = false ]; then
            cat << 'WEATHER_EOF'
weather() {
    if command -v curl &>/dev/null; then
        if ! curl -s --max-time 5 "wttr.in" &>/dev/null; then
            echo "[ERROR] [weather] Weather service unavailable. Check internet connection or try again later." >&2
            return 1
        fi
        curl -s "wttr.in"
    elif command -v wget &>/dev/null; then
        if ! wget -q --timeout=5 --spider "wttr.in" &>/dev/null; then
            echo "[ERROR] [weather] Weather service unavailable. Check internet connection or try again later." >&2
            return 1
        fi
        wget -qO- "wttr.in"
    else
        echo "[ERROR] [weather] Weather service unavailable. Check internet connection or try again later." >&2
        return 1
    fi
}
WEATHER_EOF
        fi
    } >> "$bashrc_file"

    # Log warnings for skipped functions (moved outside redirection block)
    if [ "$mkcd_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'mkcd' already exists, skipping to preserve user customization." "configure_terminal_functions()" "username=$username"
    fi
    if [ "$extract_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'extract' already exists, skipping to preserve user customization." "configure_terminal_functions()" "username=$username"
    fi
    if [ "$ports_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'ports' already exists, skipping to preserve user customization." "configure_terminal_functions()" "username=$username"
    fi
    if [ "$weather_exists" = true ]; then
        log "WARNING" "[WARN] [terminal-enhancements] Alias/function 'weather' already exists, skipping to preserve user customization." "configure_terminal_functions()" "username=$username"
    fi

    # Ensure correct ownership and permissions
    chown "$username:$username" "$bashrc_file" 2>/dev/null || true
    chmod 644 "$bashrc_file" 2>/dev/null || true

    log "INFO" "✓ Terminal functions configured successfully" "configure_terminal_functions()" "username=$username"
    return 0
}

#######################################
# Configure Bash history and completion enhancements
#
# Purpose: Configure Bash history to persist across sessions with timestamps, duplicate removal,
#          and enhanced tab completion with case-insensitive menu-style selection
#
# Inputs:
#   - username: Username for which to configure enhancements (string, required)
#
# Outputs: None (uses structured logging)
#
# Side Effects:
#   - Modifies .bashrc with history and completion settings
#   - Sets environment variables (HISTSIZE, HISTFILESIZE, etc.)
#   - Configures readline bindings
#   - Checks and truncates history file if > 100MB
#
# Returns:
#   0 - Success (enhancements configured or already configured)
#   1 - Error (configuration failed)
#
# Idempotency: Yes
#   - Checks for configuration marker before adding
#   - Safe to run multiple times
#
# Dependencies:
#   - User's .bashrc file must exist or be creatable
#   - Write permissions for user's home directory
#
# Configuration Added:
#   - History size: 10000 commands (HISTSIZE)
#   - History file size: 20000 commands (HISTFILESIZE)
#   - History control: ignore duplicates, timestamps (HISTCONTROL, HISTTIMEFORMAT)
#   - Completion: case-insensitive, menu-style (readline bindings)
#
# Example:
#   configure_bash_enhancements "coder"
#######################################
configure_bash_enhancements() {
    local username="$1"
    local home_dir="/home/$username"
    local bashrc_file="$home_dir/.bashrc"
    local enhancements_marker="# Bash History & Completion Enhancements - Added by setup-workstation.sh"

    log "INFO" "Configuring Bash history and completion enhancements..." "configure_bash_enhancements()" "username=$username"

    # Configuration marker check (T049)
    if [ -f "$bashrc_file" ] && grep -q "$enhancements_marker" "$bashrc_file"; then
        log "INFO" "Bash enhancements already configured, skipping" "configure_bash_enhancements()" "username=$username"
        return 0
    fi

    # Ensure .bashrc exists
    if [ ! -f "$bashrc_file" ]; then
        touch "$bashrc_file"
        chown "$username:$username" "$bashrc_file"
        chmod 644 "$bashrc_file"
    fi

    # Check and truncate history file if > 100MB (T089, Edge Cases: Large History Files)
    local history_file="$home_dir/.bash_history"
    if [ -f "$history_file" ]; then
        local history_size
        history_size=$(stat -f%z "$history_file" 2>/dev/null || stat -c%s "$history_file" 2>/dev/null || echo "0")
        # 100MB = 104857600 bytes
        if [ "$history_size" -gt 104857600 ]; then
            log "WARNING" "[WARN] [terminal-enhancements] History file exceeds 100MB, truncating to last 10,000 entries." "configure_bash_enhancements()" "username=$username history_size=${history_size}bytes"
            # Get last 10,000 lines and write back
            tail -n 10000 "$history_file" > "${history_file}.tmp" 2>/dev/null && mv "${history_file}.tmp" "$history_file" 2>/dev/null || true
            chown "$username:$username" "$history_file" 2>/dev/null || true
            chmod 600 "$history_file" 2>/dev/null || true
        fi
    fi

    # Add Bash enhancements (T050, T051, T052, T053, T054, T055, T056, T057)
    {
        echo ""
        echo "$enhancements_marker"
        echo ""
        echo "# PATH Configuration - Ensure /usr/local/bin is in PATH"
        echo "# This ensures tools like exa installed to /usr/local/bin are accessible"
        if ! echo "$PATH" | grep -q "/usr/local/bin"; then
            echo 'export PATH="/usr/local/bin:$PATH"'
        fi
        echo ""
        echo "# Bash History Configuration (T050, T051, T052, T053, T054, FR-008, FR-010)"
        echo "export HISTSIZE=10000"
        echo "export HISTFILESIZE=20000"
        echo "export HISTCONTROL=ignoreboth:erasedups"
        echo "shopt -s histappend"
        echo 'export HISTTIMEFORMAT="%F %T "'
        echo ""
        echo "# Bash Completion Enhancements (T055, T056, T057, FR-009)"
        echo "bind 'set completion-ignore-case on'"
        echo "bind 'set show-all-if-ambiguous on'"
        echo "bind 'set menu-complete-display-prefix on'"
    } >> "$bashrc_file"

    # Ensure correct ownership and permissions
    chown "$username:$username" "$bashrc_file" 2>/dev/null || true
    chmod 644 "$bashrc_file" 2>/dev/null || true

    log "INFO" "✓ Bash history and completion enhancements configured successfully" "configure_bash_enhancements()" "username=$username"
    return 0
}

#######################################
# Configure terminal visual enhancements
#
# Purpose: Install modern fonts (if desktop environment available) and document color scheme options
#          for improved visual comfort and professional appearance
#
# Inputs:
#   - username: Username for which to configure visual enhancements (string, required)
#
# Outputs: None (uses structured logging)
#
# Side Effects:
#   - Installs fonts-firacode package if desktop environment detected
#   - Skips font installation gracefully in headless environments (no error logged)
#
# Returns:
#   0 - Success (enhancements configured or skipped in headless)
#   1 - Error (configuration failed)
#
# Idempotency: Yes
#   - Checks for desktop environment before attempting font installation
#   - Safe to run multiple times
#
# Dependencies:
#   - Desktop environment detection (via $DISPLAY or $XDG_SESSION_TYPE)
#   - APT package manager for font installation
#
# Configuration:
#   - Installs fonts-firacode if desktop environment detected (FR-016)
#   - Skips font installation in headless environments gracefully (FR-016, Edge Cases)
#   - Tools (Starship, bat, exa) auto-detect terminal color capabilities (FR-025)
#
# Example:
#   configure_terminal_visuals "coder"
#######################################
configure_terminal_visuals() {
    local username="$1"
    local home_dir="/home/$username"

    log "INFO" "Configuring terminal visual enhancements..." "configure_terminal_visuals()" "username=$username"

    # Desktop environment detection (T060, FR-016)
    local has_desktop=false
    if [ -n "${DISPLAY:-}" ] || [ -n "${XDG_SESSION_TYPE:-}" ]; then
        # Check if DISPLAY is set and not empty, or XDG_SESSION_TYPE indicates desktop
        if [ -n "${DISPLAY:-}" ] && [ "$DISPLAY" != "" ]; then
            has_desktop=true
        elif [ -n "${XDG_SESSION_TYPE:-}" ] && ([ "$XDG_SESSION_TYPE" = "x11" ] || [ "$XDG_SESSION_TYPE" = "wayland" ]); then
            has_desktop=true
        fi
    fi

    # Install fonts if desktop environment detected (T061, T062, FR-016, Edge Cases: Font Installation in Headless)
    if [ "$has_desktop" = true ]; then
        log "INFO" "Desktop environment detected, installing Fira Code font..." "configure_terminal_visuals()" "username=$username"

        # Check if font is already installed
        if dpkg-query -W -f='${Status}' "fonts-firacode" 2>/dev/null | grep -q "install ok installed"; then
            log "INFO" "Fira Code font already installed, skipping" "configure_terminal_visuals()" "username=$username"
        else
            # Install fonts-firacode via APT
            if ! (sudo apt-get update -qq && sudo apt-get install -y fonts-firacode); then
                log "WARNING" "Failed to install Fira Code font, but continuing (non-critical)" "configure_terminal_visuals()" "username=$username"
            else
                log "INFO" "✓ Fira Code font installed successfully" "configure_terminal_visuals()" "username=$username"
            fi
        fi
    else
        # Headless environment - skip font installation gracefully (T062, FR-016, Edge Cases)
        # No error logged as per requirements - this is expected behavior
        log "INFO" "Headless environment detected, skipping font installation" "configure_terminal_visuals()" "username=$username"
    fi

    # Note: Tools (Starship, bat, exa) automatically detect terminal color capabilities (T064, FR-025)
    # These tools handle graceful degradation when terminal doesn't support colors or ANSI escape sequences
    # No additional configuration needed - tools auto-detect and disable color features as needed

    log "INFO" "✓ Terminal visual enhancements configured successfully" "configure_terminal_visuals()" "username=$username"
    return 0
}

#######################################
# Setup terminal enhancements (main orchestration function)
#
# Purpose: Main orchestration function for installing and configuring all terminal enhancements
#
# Inputs:
#   - username: Username for which to configure terminal enhancements (string, required)
#
# Outputs: None (uses structured logging via log() function)
#
# Side Effects:
#   - Verifies tool-specific prerequisites (curl/wget, tar/unzip, grep/sed/awk, bash 5.2+, dpkg-query)
#   - Detects Git availability
#   - Checks for configuration marker in .bashrc
#   - Installs and configures terminal enhancement tools (to be implemented in later phases)
#   - Modifies user's .bashrc file (with backup)
#   - Sets file ownership and permissions
#
# Returns:
#   0 - Success (all tools installed and configured, or already configured)
#   1 - Error (critical failure preventing configuration)
#
# Idempotency: Yes
#   - Checks for configuration marker in .bashrc: "# Terminal Enhancements Configuration - Added by setup-workstation.sh"
#   - Skips installation if tools already installed
#   - Safe to run multiple times
#
# Example:
#   setup_terminal_enhancements "coder"
#
# Notes:
#   - This is the main entry point for all terminal enhancement features
#   - Prerequisites are verified before any tool installation
#   - Git detection is performed to enable/disable Git-related features
#######################################
setup_terminal_enhancements() {
    local username="$1"
    local home_dir="/home/$username"
    local bashrc_file="$home_dir/.bashrc"
    local config_marker="# Terminal Enhancements Configuration - Added by setup-workstation.sh"

    log "INFO" "Setting up terminal enhancements..." "setup_terminal_enhancements()" "username=$username"

    # Check if already configured (idempotency check)
    if [ -f "$bashrc_file" ] && grep -q "$config_marker" "$bashrc_file"; then
        log "INFO" "Terminal enhancements already configured. Skipping." "setup_terminal_enhancements()" "username=$username"
        return 0
    fi

    # Verify tool-specific prerequisites (T087)
    log "INFO" "Verifying tool-specific prerequisites..." "setup_terminal_enhancements()" "username=$username"

    local missing_prereqs=()

    # Check for curl or wget
    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        missing_prereqs+=("curl or wget")
    fi

    # Check for tar or unzip
    if ! command -v tar &>/dev/null && ! command -v unzip &>/dev/null; then
        missing_prereqs+=("tar or unzip")
    fi

    # Check for grep, sed, awk
    if ! command -v grep &>/dev/null; then
        missing_prereqs+=("grep")
    fi
    if ! command -v sed &>/dev/null; then
        missing_prereqs+=("sed")
    fi
    if ! command -v awk &>/dev/null; then
        missing_prereqs+=("awk")
    fi

    # Check for bash 5.2+
    local bash_version
    bash_version=$(bash --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1 || echo "0.0")
    local bash_major bash_minor
    bash_major=$(echo "$bash_version" | cut -d. -f1)
    bash_minor=$(echo "$bash_version" | cut -d. -f2)
    if [ "$bash_major" -lt 5 ] || ([ "$bash_major" -eq 5 ] && [ "${bash_minor:-0}" -lt 2 ]); then
        missing_prereqs+=("bash 5.2+")
    fi

    # Check for dpkg-query
    if ! command -v dpkg-query &>/dev/null; then
        missing_prereqs+=("dpkg-query")
    fi

    # Report missing prerequisites
    if [ ${#missing_prereqs[@]} -gt 0 ]; then
        log "ERROR" "Missing required prerequisites: ${missing_prereqs[*]}. Context: Function setup_terminal_enhancements() requires these tools for terminal enhancement installation. Recovery: Install missing tools: sudo apt install ${missing_prereqs[*]}" "setup_terminal_enhancements()" "username=$username missing_prereqs=${missing_prereqs[*]}"
        return 1
    fi

    log "INFO" "✓ All prerequisites verified" "setup_terminal_enhancements()" "username=$username"

    # Detect Git availability (T088)
    if ! command -v git &>/dev/null; then
        log "WARNING" "[WARN] [terminal-enhancements] Git is not installed. Git-related features will be disabled." "setup_terminal_enhancements()" "username=$username"
    else
        log "INFO" "Git detected and available" "setup_terminal_enhancements()" "username=$username"
    fi

    # Create backup before any modifications
    if ! create_bashrc_backup "$bashrc_file"; then
        log "ERROR" "Failed to create backup, aborting terminal enhancements setup" "setup_terminal_enhancements()" "username=$username bashrc_file=$bashrc_file"
        return 1
    fi

    # Install and configure terminal enhancement tools
    # User Story 1: Starship prompt
    if install_starship; then
        configure_starship_prompt "$username"
    else
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install starship. Continuing with remaining tools." "setup_terminal_enhancements()" "username=$username"
    fi

    # User Story 2: fzf (fuzzy finder)
    if install_fzf; then
        configure_fzf_key_bindings "$username"
    else
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install fzf. Continuing with remaining tools." "setup_terminal_enhancements()" "username=$username"
    fi

    # User Story 3: bat and exa (file viewing and listing)
    local bat_installed=false
    local exa_installed=false

    if install_bat "$username"; then
        bat_installed=true
    else
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install bat. Continuing with remaining tools." "setup_terminal_enhancements()" "username=$username"
    fi

    if install_exa; then
        exa_installed=true
    else
        log "WARNING" "[WARN] [terminal-enhancements] Failed to install exa. Continuing with remaining tools." "setup_terminal_enhancements()" "username=$username"
    fi

    # Configure aliases (includes bat/exa aliases if tools installed, plus Git/Docker aliases) (T048)
    configure_terminal_aliases "$username"

    # Configure utility functions (T048)
    configure_terminal_functions "$username"

    # Configure Bash history and completion enhancements (T058)
    configure_bash_enhancements "$username"

    # Configure terminal visual enhancements (T065)
    configure_terminal_visuals "$username"

    # Add configuration marker to .bashrc
    if [ -f "$bashrc_file" ]; then
        if ! grep -q "$config_marker" "$bashrc_file"; then
            echo "" >> "$bashrc_file"
            echo "$config_marker" >> "$bashrc_file"
            log "INFO" "Added configuration marker to .bashrc" "setup_terminal_enhancements()" "username=$username"
        fi
    fi

    # Ensure correct ownership and permissions
    if [ -f "$bashrc_file" ]; then
        chown "$username:$username" "$bashrc_file" 2>/dev/null || true
        chmod 644 "$bashrc_file" 2>/dev/null || true
    fi

    log "INFO" "✓ Terminal enhancements setup completed (foundational phase)" "setup_terminal_enhancements()" "username=$username"
    return 0
}

#######################################
# Configure shell environment (.bashrc)
# Inputs: username
# Returns: 0 on success, 1 on error
#######################################
#######################################
# Configure shell environment (.bashrc)
#
# Purpose: Configure custom PS1 prompt, Git branch detection, and aliases
#
# Inputs:
#   - username: Username for which to configure shell (string)
#
# Outputs: None
#
# Side Effects:
#   - Creates backup of existing .bashrc if it exists
#   - Appends custom configuration to .bashrc file
#   - Sets custom PS1 prompt: [User@Hostname] [CurrentDir] [GitBranch] $
#   - Adds parse_git_branch() function for Git branch detection
#   - Adds aliases: ll, update, docker-clean
#   - Sets file ownership and permissions
#
# Returns:
#   0 - Success (configuration applied or already configured)
#   1 - Error (file creation failed, permission setting failed)
#
# Idempotency: Yes
#   - Checks if custom configuration marker exists in .bashrc (skips if found)
#   - Safe to run multiple times (won't duplicate configuration)
#
# Example:
#   configure_shell "coder"
#
# Notes:
#   - Configuration is appended to existing .bashrc (does not replace)
#   - Backup is created with timestamp before modification
#   - Custom configuration marker: "# Mobile-Ready Workstation Custom Configuration"
#######################################
configure_shell() {
    local username="$1"
    local home_dir="/home/$username"
    local bashrc_file="$home_dir/.bashrc"

    log "INFO" "Configuring shell environment..." "configure_shell()" "username=$username"

    # Check if .bashrc already exists and has our custom configuration
    if [ -f "$bashrc_file" ] && grep -q "# Mobile-Ready Workstation Custom Configuration" "$bashrc_file"; then
        log "INFO" ".bashrc already configured. Skipping." "configure_shell()" "username=$username"
        return 0
    fi

    # Create backup if .bashrc exists
    if [ -f "$bashrc_file" ]; then
        if ! cp "$bashrc_file" "${bashrc_file}.backup.$(date +%Y%m%d_%H%M%S)"; then
            log "WARNING" "Failed to backup existing .bashrc. Continuing anyway." "configure_shell()" "username=$username bashrc_file=$bashrc_file"
        else
            log "INFO" "Backed up existing .bashrc" "configure_shell()" "username=$username"
        fi
    fi

    # Append custom configuration to .bashrc
    cat >> "$bashrc_file" << 'BASHRC_EOF'

# Mobile-Ready Workstation Custom Configuration
# Added by setup-workstation.sh

# Git branch detection function
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Custom PS1 prompt: [User@Hostname] [CurrentDir] [GitBranch] $
# Colors: Neon green for user/host, Blue for directory, Yellow for Git branch
PS1='\[\033[01;32m\][\u@\h]\[\033[00m\] \[\033[01;34m\][\w]\[\033[00m\] \[\033[01;33m\]$(parse_git_branch)\[\033[00m\] \$ '

# Aliases
alias ll='ls -alFh --color=auto'
alias update='sudo apt update && sudo apt upgrade -y'
alias docker-clean='docker container prune -f && docker image prune -f'

BASHRC_EOF

    # Ensure correct ownership and permissions
    if ! chown "$username:$username" "$bashrc_file"; then
        log "ERROR" "Failed to set ownership of .bashrc. Context: Function configure_shell() attempted to change ownership of .bashrc but chown failed. Recovery: Check filesystem permissions, verify user exists, or set ownership manually: chown $username:$username $bashrc_file" "configure_shell()" "username=$username bashrc_file=$bashrc_file"
        return 1
    fi
    chmod 644 "$bashrc_file"

    log "INFO" "✓ Shell environment configured" "configure_shell()" "username=$username"
    return 0
}

#######################################
# Create user and configure shell
# Inputs: CUSTOM_USER, CUSTOM_PASS
# Returns: 0 on success, 1 on error
#######################################
create_user_and_shell() {
    local username="$1"
    local password="$2"

    # Create user account
    create_user "$username" "$password"

    # Configure shell environment
    configure_shell "$username"
}

#######################################
# Configure XFCE for mobile optimization
# Inputs: username
# Returns: 0 on success, 1 on error
# Note: Must run as target user (not root)
#######################################
#######################################
# Configure XFCE for mobile optimization
#
# Purpose: Configure XFCE desktop environment with mobile-friendly settings
#
# Inputs:
#   - username: Username for which to configure XFCE (string)
#
# Outputs: None
#
# Side Effects:
#   - Sets XFCE font size to 12pt (mobile-friendly)
#   - Sets desktop icon size to 48px (touch-friendly)
#   - Sets panel size to 48px (finger-friendly)
#   - Creates autostart script if XFCE session is not running (fallback mechanism)
#   - Creates autostart desktop entry for configuration script
#   - Modifies user's home directory files (.xfce4-mobile-config.sh, .config/autostart/)
#
# Returns:
#   0 - Success (configuration applied or fallback script created)
#   1 - Error (configuration failed, script creation failed)
#
# Idempotency: Yes
#   - Checks if configuration can be applied directly (xfconf-query)
#   - Creates fallback script only if direct configuration fails
#   - Safe to run multiple times (won't duplicate autostart entries)
#
# Example:
#   configure_xfce_mobile "coder"
#
# Notes:
#   - If XFCE session is not running, creates autostart script that applies settings on first login
#   - Autostart script removes itself after execution
#   - Settings are applied via xfconf-query when XFCE is running, or via autostart script on login
#######################################
configure_xfce_mobile() {
    local username="$1"
    local home_dir="/home/$username"

    log "INFO" "Configuring XFCE for mobile optimization..." "configure_xfce_mobile()" "username=$username"

    # Set font size to 12pt (mobile-friendly)
    # Note: xfconf-query may fail if XFCE session is not running, but we'll try anyway
    # The settings will be applied when user logs in via RDP
    if su - "$username" -c "DISPLAY=:0 xfconf-query -c xsettings -p /Gtk/FontName -s 'Sans 12' 2>/dev/null" 2>/dev/null || \
       su - "$username" -c "xfconf-query -c xsettings -p /Gtk/FontName -s 'Sans 12' 2>/dev/null" 2>/dev/null; then
        log "INFO" "✓ Font size set to 12pt" "configure_xfce_mobile()" "username=$username"
    else
        log "WARNING" "Could not set font size (XFCE may not be running). Will apply on next login." "configure_xfce_mobile()" "username=$username"
        # Create a script to run on first login
        cat > "$home_dir/.xfce4-mobile-config.sh" << 'XFCE_CONFIG_EOF'
#!/bin/bash
# Mobile optimization script for XFCE
# This will be executed on first XFCE session

# Wait for XFCE to be ready
sleep 2

# Set font size
xfconf-query -c xsettings -p /Gtk/FontName -s "Sans 12" 2>/dev/null

# Set desktop icon size (48px)
# Note: Icon size is typically controlled via Thunar file manager settings
# We'll set it via xfconf-query for desktop icons
xfconf-query -c xfce4-desktop -p /desktop-icons/icon-size -t int -s 48 2>/dev/null || \
xfconf-query -c thunar -p /default-view-icon-size -t string -s "THUNAR_ICON_SIZE_48" 2>/dev/null || true

# Set panel size (48px height)
xfconf-query -c xfce4-panel -p /panels/panel-1/size -t int -s 48 2>/dev/null || true

# Remove this script after execution
rm -f ~/.xfce4-mobile-config.sh
rm -f ~/.config/autostart/xfce4-mobile-config.desktop
XFCE_CONFIG_EOF
        chmod +x "$home_dir/.xfce4-mobile-config.sh"
        chown "$username:$username" "$home_dir/.xfce4-mobile-config.sh"

        # Create autostart entry
        mkdir -p "$home_dir/.config/autostart"
        cat > "$home_dir/.config/autostart/xfce4-mobile-config.desktop" << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=Mobile Optimization
Exec=/home/USERNAME/.xfce4-mobile-config.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
DESKTOP_EOF
        sed -i "s/USERNAME/$username/g" "$home_dir/.config/autostart/xfce4-mobile-config.desktop"
        chown -R "$username:$username" "$home_dir/.config"
    fi

    # Set desktop icon size (try to set via xfconf-query)
    # Note: Icon size configuration may vary by XFCE version
    if su - "$username" -c "xfconf-query -c xfce4-desktop -p /desktop-icons/icon-size -t int -s 48 2>/dev/null" 2>/dev/null || \
       su - "$username" -c "xfconf-query -c thunar -p /default-view-icon-size -t string -s 'THUNAR_ICON_SIZE_48' 2>/dev/null" 2>/dev/null; then
        log "INFO" "✓ Desktop icon size configured to 48px" "configure_xfce_mobile()" "username=$username"
    else
        log "WARNING" "Desktop icon size will be configured on first login" "configure_xfce_mobile()" "username=$username"
    fi

    # Set panel size to 48px
    if su - "$username" -c "xfconf-query -c xfce4-panel -p /panels/panel-1/size -t int -s 48 2>/dev/null" 2>/dev/null; then
        log "INFO" "✓ Panel size set to 48px" "configure_xfce_mobile()" "username=$username"
    else
        log "WARNING" "Panel size will be configured on first login" "configure_xfce_mobile()" "username=$username"
    fi

    log "INFO" "✓ XFCE mobile optimization configured" "configure_xfce_mobile()" "username=$username"
    return 0
}

#######################################
# Install and configure desktop environment for mobile
# Inputs: CUSTOM_USER
# Returns: 0 on success, 1 on error
#######################################
setup_desktop_mobile() {
    local username="$1"

    log "INFO" "Setting up mobile-optimized desktop environment..." "setup_desktop_mobile()" "username=$username"

    # Install XFCE4 with idempotency check
    if dpkg-query -W -f='${Status}' "xfce4" 2>/dev/null | grep -q "install ok installed"; then
        log "INFO" "✓ XFCE4 already installed" "setup_desktop_mobile()"
    else
        log "INFO" "Installing XFCE4 desktop environment... (this may take 5-10 minutes)" "setup_desktop_mobile()"
        # Set DEBIAN_FRONTEND to noninteractive to avoid prompts
        export DEBIAN_FRONTEND=noninteractive
        if ! apt-get install -y xfce4 xfce4-goodies; then
            log "ERROR" "Failed to install XFCE4. Context: Function setup_desktop_mobile() attempted to install xfce4 and xfce4-goodies but apt-get install failed. Recovery: Check APT repository configuration, verify package availability, or install manually: apt-get install -y xfce4 xfce4-goodies" "setup_desktop_mobile()" "username=$username"
            return 1
        fi
        log "INFO" "✓ XFCE4 installed" "setup_desktop_mobile()"
    fi

    # Install XRDP with idempotency check
    if dpkg-query -W -f='${Status}' "xrdp" 2>/dev/null | grep -q "install ok installed"; then
        log "INFO" "✓ XRDP already installed" "setup_desktop_mobile()"
    else
        log "INFO" "Installing XRDP remote desktop server..." "setup_desktop_mobile()"
        if ! apt-get install -y xrdp; then
            log "ERROR" "Failed to install XRDP. Context: Function setup_desktop_mobile() attempted to install xrdp but apt-get install failed. Recovery: Check APT repository configuration, verify package availability, or install manually: apt-get install -y xrdp" "setup_desktop_mobile()" "username=$username"
            return 1
        fi
        log "INFO" "✓ XRDP installed" "setup_desktop_mobile()"
    fi

    # Enable XRDP service
    if systemctl is-enabled xrdp &>/dev/null; then
        log "INFO" "✓ XRDP service already enabled" "setup_desktop_mobile()"
    else
        log "INFO" "Enabling XRDP service..." "setup_desktop_mobile()"
        if ! systemctl enable xrdp; then
            log "ERROR" "Failed to enable XRDP service. Context: Function setup_desktop_mobile() attempted to enable xrdp service but systemctl enable failed. Recovery: Check systemd permissions, verify xrdp service exists, or enable manually: systemctl enable xrdp" "setup_desktop_mobile()" "username=$username"
            return 1
        fi
        log "INFO" "✓ XRDP service enabled" "setup_desktop_mobile()"
    fi

    # Start XRDP service with idempotency check
    if systemctl is-active --quiet xrdp; then
        log "INFO" "✓ XRDP service already running" "setup_desktop_mobile()"
    else
        log "INFO" "Starting XRDP service..." "setup_desktop_mobile()"
        if ! systemctl start xrdp; then
            log "ERROR" "Failed to start XRDP service. Context: Function setup_desktop_mobile() attempted to start xrdp service but systemctl start failed. Recovery: Check systemd logs (journalctl -u xrdp), verify xrdp configuration, or start manually: systemctl start xrdp" "setup_desktop_mobile()" "username=$username"
            return 1
        fi
        if systemctl is-active --quiet xrdp; then
            log "INFO" "✓ XRDP service started" "setup_desktop_mobile()"
        else
            log "WARNING" "XRDP service start may have failed. Check with: systemctl status xrdp" "setup_desktop_mobile()" "username=$username"
        fi
    fi

    # Configure XFCE for mobile optimization
    if ! configure_xfce_mobile "$username"; then
        log "ERROR" "XFCE mobile configuration failed. Context: Function setup_desktop_mobile() called configure_xfce_mobile() but it failed. Recovery: See configure_xfce_mobile() error messages above for specific recovery steps." "setup_desktop_mobile()" "username=$username"
        return 1
    fi

    log "INFO" "✓ Desktop environment setup completed" "setup_desktop_mobile()" "username=$username"
    return 0
}

#######################################
# Set up Docker APT repository
#
# Purpose: Configure Docker's official APT repository for Debian 13
#
# Inputs: None
#
# Outputs: None
#
# Side Effects:
#   - Creates /etc/apt/keyrings/ directory if it doesn't exist
#   - Downloads and installs Docker GPG key to /etc/apt/keyrings/docker.asc
#   - Creates /etc/apt/sources.list.d/docker.sources file in DEB822 format
#   - Removes old .list or .gpg files if present (migration)
#   - Updates APT package list
#   - Installs prerequisites (ca-certificates, curl) if needed
#
# Returns:
#   0 - Success (repository configured or already configured)
#   1 - Error (GPG key download failed, repository file creation failed)
#
# Idempotency: Yes
#   - Checks if repository file exists before creating (skips if exists)
#   - Always refreshes GPG key to ensure it's up to date
#   - Migrates old .list format to .sources format if needed
#   - Safe to run multiple times
#
# Example:
#   setup_docker_repository
#
# Notes:
#   - Uses DEB822 format (.sources) as per official Docker documentation
#   - GPG key is refreshed on each run to ensure validity
#   - Automatically handles migration from legacy .list format
#######################################
setup_docker_repository() {
    log "INFO" "Setting up Docker repository..." "setup_docker_repository()"

    # Check if repository already configured
    # Check for both .list and .sources files (legacy support)
    if [ -f /etc/apt/sources.list.d/docker.list ] || [ -f /etc/apt/sources.list.d/docker.sources ]; then
        log "INFO" "✓ Docker repository already configured" "setup_docker_repository()"
        # Always refresh GPG key to ensure it's up to date
        log "INFO" "Refreshing Docker GPG key..." "setup_docker_repository()"
        if [ -f /etc/apt/keyrings/docker.asc ]; then
            rm -f /etc/apt/keyrings/docker.asc
        fi
        if [ -f /etc/apt/keyrings/docker.gpg ]; then
            rm -f /etc/apt/keyrings/docker.gpg
        fi
        if ! curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc; then
            log "ERROR" "Failed to download Docker GPG key. Context: Function setup_docker_repository() attempted to download GPG key from Docker repository but curl failed. Recovery: Check network connectivity, verify Docker GPG key URL is accessible, or download manually: curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc" "setup_docker_repository()"
            return 1
        fi
        chmod a+r /etc/apt/keyrings/docker.asc

        # If old .list file exists, remove it and use .sources format
        if [ -f /etc/apt/sources.list.d/docker.list ]; then
            log "INFO" "Migrating to DEB822 format (.sources)..." "setup_docker_repository()"
            rm -f /etc/apt/sources.list.d/docker.list
            # Recreate with proper format
            # shellcheck disable=SC1091
            . /etc/os-release
            cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
        fi
        return 0
    fi

    # Install prerequisites
    if ! dpkg-query -W -f='${Status}' "ca-certificates" 2>/dev/null | grep -q "install ok installed" || ! dpkg-query -W -f='${Status}' "curl" 2>/dev/null | grep -q "install ok installed"; then
        log "INFO" "Installing Docker repository prerequisites..." "setup_docker_repository()"
        if ! apt-get install -y ca-certificates curl; then
            log "ERROR" "Failed to install Docker repository prerequisites (ca-certificates, curl). Context: Function setup_docker_repository() attempted to install prerequisites but apt-get install failed. Recovery: Check APT repository configuration, verify network connectivity, or install manually: apt-get install -y ca-certificates curl" "setup_docker_repository()"
            return 1
        fi
    fi

    # Create keyring directory
    if ! install -m 0755 -d /etc/apt/keyrings; then
        log "ERROR" "Failed to create /etc/apt/keyrings directory. Context: Function setup_docker_repository() attempted to create keyring directory but install command failed. Recovery: Check filesystem permissions, verify /etc/apt exists, or create manually: install -m 0755 -d /etc/apt/keyrings" "setup_docker_repository()"
        return 1
    fi

    # Remove old Docker GPG key if exists (for clean reinstall)
    if [ -f /etc/apt/keyrings/docker.asc ]; then
        log "INFO" "Removing old Docker GPG key..." "setup_docker_repository()"
        rm -f /etc/apt/keyrings/docker.asc
    fi
    # Also check for .gpg extension (alternative format)
    if [ -f /etc/apt/keyrings/docker.gpg ]; then
        log "INFO" "Removing old Docker GPG key (.gpg)..." "setup_docker_repository()"
        rm -f /etc/apt/keyrings/docker.gpg
    fi

    # Add Docker GPG key
    log "INFO" "Adding Docker GPG key..." "setup_docker_repository()"
    if ! curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc; then
        log "ERROR" "Failed to download Docker GPG key. Context: Function setup_docker_repository() attempted to download GPG key from Docker repository but curl failed. Recovery: Check network connectivity, verify Docker GPG key URL is accessible, or download manually: curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc" "setup_docker_repository()"
        return 1
    fi
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository
    log "INFO" "Adding Docker repository..." "setup_docker_repository()"
    # shellcheck disable=SC1091
    . /etc/os-release

    # Use DEB822 format (.sources) as per official Docker documentation
    # Reference: https://docs.docker.com/engine/install/debian/
    # Note: Components field is optional for Docker repository
    if ! cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    then
        log "ERROR" "Failed to write Docker repository configuration file. Context: Function setup_docker_repository() attempted to create /etc/apt/sources.list.d/docker.sources but file write failed. Recovery: Check filesystem permissions, verify /etc/apt/sources.list.d is writable, or create file manually with correct DEB822 format" "setup_docker_repository()"
        return 1
    fi

    # Update APT
    log "INFO" "Updating package list..." "setup_docker_repository()"
    if ! apt-get update -qq; then
        log "ERROR" "Failed to update APT package list after adding Docker repository. Context: Function setup_docker_repository() attempted to refresh APT cache but apt-get update failed. Recovery: Check Docker repository configuration file format, verify GPG key is valid, check network connectivity, or run manually: apt-get update" "setup_docker_repository()"
        return 1
    fi

    log "INFO" "✓ Docker repository configured" "setup_docker_repository()"
    return 0
}

#######################################
# Install Docker and Docker Compose
#
# Purpose: Install Docker Engine, Docker Compose, and add user to docker group
#
# Inputs:
#   - username: Username to add to docker group (string)
#
# Outputs: None
#
# Side Effects:
#   - Calls setup_docker_repository() to ensure repository is configured
#   - Installs Docker packages: docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin
#   - Adds user to docker group (requires logout/login to take effect)
#   - Creates docker group if it doesn't exist
#
# Returns:
#   0 - Success (Docker installed or already installed, user added to group)
#   1 - Error (package installation failed, user addition failed)
#
# Idempotency: Yes
#   - Checks if Docker is installed before installing (skips if already installed)
#   - Checks if user is in docker group before adding (skips if already member)
#   - Safe to run multiple times
#
# Example:
#   install_docker "coder"
#
# Notes:
#   - User must logout and login again for docker group membership to take effect
#   - Docker service is automatically started by package installation
#######################################
install_docker() {
    local username="$1"

    log "INFO" "Installing Docker..." "install_docker()" "username=$username"

    # Setup repository
    if ! setup_docker_repository; then
        log "ERROR" "Failed to setup Docker repository. Context: Function install_docker() called setup_docker_repository() but it failed. Recovery: See setup_docker_repository() error messages above for specific recovery steps." "install_docker()" "username=$username"
        return 1
    fi

    # Check if Docker is already installed
    if command -v docker &>/dev/null && dpkg-query -W -f='${Status}' "docker-ce" 2>/dev/null | grep -q "install ok installed"; then
        log "INFO" "✓ Docker already installed" "install_docker()"
    else
        log "INFO" "Installing Docker packages... (this may take a few minutes)" "install_docker()"
        if ! apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
            log "ERROR" "Failed to install Docker packages. Context: Function install_docker() attempted to install Docker packages but apt-get install failed. Recovery: Check Docker repository configuration, verify package availability, check network connectivity, or install manually: apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" "install_docker()" "username=$username"
            return 1
        fi
        log "INFO" "✓ Docker installed" "install_docker()"
    fi

    # Add user to docker group
    if groups "$username" | grep -q "\bdocker\b"; then
        log "INFO" "✓ User '$username' already in docker group" "install_docker()" "username=$username"
    else
        log "INFO" "Adding user '$username' to docker group..." "install_docker()" "username=$username"
        if ! usermod -aG docker "$username"; then
            log "ERROR" "Failed to add user '$username' to docker group. Context: Function install_docker() attempted to add user to docker group via usermod but command failed. Recovery: Check if user exists, verify docker group exists, or add manually: usermod -aG docker $username" "install_docker()" "username=$username"
            return 1
        fi
        log "INFO" "✓ User '$username' added to docker group" "install_docker()" "username=$username"
        log "WARNING" "Note: User must logout and login again for docker group to take effect" "install_docker()" "username=$username"
    fi

    return 0
}

#######################################
# Install web browsers
# Returns: 0 on success, 1 on error
#######################################
install_browsers() {
    log "INFO" "Installing web browsers..." "install_browsers()"

    # Install Firefox ESR
    if dpkg-query -W -f='${Status}' "firefox-esr" 2>/dev/null | grep -q "install ok installed"; then
        log "INFO" "✓ Firefox ESR already installed" "install_browsers()"
    else
        log "INFO" "Installing Firefox ESR..." "install_browsers()"
        if ! apt-get install -y firefox-esr; then
            log "ERROR" "Failed to install Firefox ESR. Context: Function install_browsers() attempted to install firefox-esr but apt-get install failed. Recovery: Check APT repository configuration, verify package availability, or install manually: apt-get install -y firefox-esr" "install_browsers()"
            return 1
        fi
        log "INFO" "✓ Firefox ESR installed" "install_browsers()"
    fi

    # Install Chromium
    if dpkg-query -W -f='${Status}' "chromium" 2>/dev/null | grep -q "install ok installed"; then
        log "INFO" "✓ Chromium already installed" "install_browsers()"
    else
        log "INFO" "Installing Chromium..." "install_browsers()"
        if ! apt-get install -y chromium; then
            log "ERROR" "Failed to install Chromium. Context: Function install_browsers() attempted to install chromium but apt-get install failed. Recovery: Check APT repository configuration, verify package availability, or install manually: apt-get install -y chromium" "install_browsers()"
            return 1
        fi
        log "INFO" "✓ Chromium installed" "install_browsers()"
    fi

    return 0
}

#######################################
# Install NVM and Node.js LTS for user
# Inputs: username
# Returns: 0 on success, 1 on error
#######################################
install_nvm_nodejs() {
    local username="$1"
    local home_dir="/home/$username"
    local nvm_dir="$home_dir/.nvm"

    log "INFO" "Installing NVM and Node.js LTS..." "install_nvm_nodejs()" "username=$username"

    # Check if NVM is already installed
    if [ -d "$nvm_dir" ] && [ -f "$nvm_dir/nvm.sh" ]; then
        log "INFO" "✓ NVM already installed" "install_nvm_nodejs()" "username=$username"
    else
        log "INFO" "Installing NVM..." "install_nvm_nodejs()" "username=$username"
        # Install NVM as the target user
        if ! su - "$username" -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash" 2>&1 | grep -v "Profile" || true; then
            log "WARNING" "NVM installation may have encountered issues. Check logs for details." "install_nvm_nodejs()" "username=$username"
        fi
        log "INFO" "✓ NVM installed" "install_nvm_nodejs()" "username=$username"
    fi

    # Check if NVM configuration is in .bashrc
    if grep -q "NVM_DIR" "$home_dir/.bashrc" 2>/dev/null; then
        log "INFO" "✓ NVM configuration already in .bashrc" "install_nvm_nodejs()" "username=$username"
    else
        log "INFO" "Adding NVM configuration to .bashrc..." "install_nvm_nodejs()" "username=$username"
        if ! cat >> "$home_dir/.bashrc" << 'NVM_EOF'

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
NVM_EOF
        then
            log "ERROR" "Failed to add NVM configuration to .bashrc. Context: Function install_nvm_nodejs() attempted to append NVM configuration to .bashrc but file write failed. Recovery: Check filesystem permissions, verify home directory exists, or add configuration manually" "install_nvm_nodejs()" "username=$username home_dir=$home_dir"
            return 1
        fi
        chown "$username:$username" "$home_dir/.bashrc"
        log "INFO" "✓ NVM configuration added to .bashrc" "install_nvm_nodejs()" "username=$username"
    fi

    # Install Node.js LTS
    log "INFO" "Installing Node.js LTS... (this may take 2-5 minutes)" "install_nvm_nodejs()" "username=$username"
    # Source NVM and install Node.js LTS as the target user
    # shellcheck disable=SC2016  # Variables need to expand in user's shell, not current shell
    if ! su - "$username" -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\" && nvm install --lts && nvm use --default --lts" 2>&1 | tail -5; then
        log "WARNING" "Node.js LTS installation may have encountered issues. Check logs for details." "install_nvm_nodejs()" "username=$username"
    fi
    log "INFO" "✓ Node.js LTS installed and set as default" "install_nvm_nodejs()" "username=$username"

    return 0
}

#######################################
# Verify Python 3 availability
# Returns: 0 if available, 1 if not
#######################################
verify_python() {
    log "INFO" "Verifying Python 3..." "verify_python()"

    if command -v python3 &>/dev/null; then
        local python_version
        python_version=$(python3 --version 2>&1)
        log "INFO" "✓ Python 3 available: $python_version" "verify_python()"
        return 0
    else
        log "WARNING" "Python 3 not found. Installing..." "verify_python()"
        if ! apt-get install -y python3 python3-pip; then
            log "ERROR" "Failed to install Python 3. Context: Function verify_python() attempted to install python3 and python3-pip but apt-get install failed. Recovery: Check APT repository configuration, verify package availability, or install manually: apt-get install -y python3 python3-pip" "verify_python()"
            return 1
        fi
        log "INFO" "✓ Python 3 installed" "verify_python()"
        return 0
    fi
}

#######################################
# Setup development stack
# Inputs: CUSTOM_USER
# Returns: 0 on success, 1 on error
#######################################
#######################################
# Set up development stack
#
# Purpose: Install and configure all development tools (Docker, browsers, Node.js, Python)
#
# Inputs:
#   - username: Username for which to set up development tools (string)
#
# Outputs: None
#
# Side Effects:
#   - Calls install_docker() to install Docker and add user to docker group
#   - Calls install_browsers() to install Firefox ESR and Chromium
#   - Calls install_nvm_nodejs() to install NVM and Node.js LTS
#   - Calls verify_python() to verify Python installation
#
# Returns:
#   0 - Success (all components installed or verified)
#   1 - Error (one or more components failed to install)
#
# Idempotency: Yes
#   - All called functions are idempotent
#   - Safe to run multiple times
#
# Example:
#   setup_dev_stack "coder"
#
# Notes:
#   - This is a convenience function that orchestrates multiple installation functions
#   - Each component installation is independent and can succeed/fail independently
#######################################
setup_dev_stack() {
    local username="$1"

    log "INFO" "Setting up development stack..." "setup_dev_stack()" "username=$username"

    # Install Docker
    if ! install_docker "$username"; then
        log "ERROR" "Docker installation failed. Context: Function setup_dev_stack() called install_docker() but it failed. Recovery: See install_docker() error messages above for specific recovery steps." "setup_dev_stack()" "username=$username"
        return 1
    fi

    # Install browsers
    if ! install_browsers; then
        log "ERROR" "Browser installation failed. Context: Function setup_dev_stack() called install_browsers() but it failed. Recovery: See install_browsers() error messages above for specific recovery steps." "setup_dev_stack()" "username=$username"
        return 1
    fi

    # Install NVM and Node.js
    if ! install_nvm_nodejs "$username"; then
        log "ERROR" "NVM/Node.js installation failed. Context: Function setup_dev_stack() called install_nvm_nodejs() but it failed. Recovery: See install_nvm_nodejs() error messages above for specific recovery steps." "setup_dev_stack()" "username=$username"
        return 1
    fi

    # Verify Python
    if ! verify_python; then
        log "ERROR" "Python verification/installation failed. Context: Function setup_dev_stack() called verify_python() but it failed. Recovery: See verify_python() error messages above for specific recovery steps." "setup_dev_stack()" "username=$username"
        return 1
    fi

    log "INFO" "✓ Development stack setup completed" "setup_dev_stack()" "username=$username"
    return 0
}

#######################################
# Get server IP address
# Returns: IP address string
#######################################
get_server_ip() {
    local ip_address

    # Try hostname -I first (simpler, works on most systems)
    if command -v hostname &>/dev/null; then
        ip_address=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi

    # Fallback to ip command if hostname -I didn't work
    if [ -z "$ip_address" ] && command -v ip &>/dev/null; then
        ip_address=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    fi

    # Final fallback to ifconfig
    if [ -z "$ip_address" ] && command -v ifconfig &>/dev/null; then
        ip_address=$(ifconfig | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | head -1)
    fi

    # If still no IP, return placeholder
    if [ -z "$ip_address" ]; then
        ip_address="<detect-ip-address>"
    fi

    echo "$ip_address"
}

#######################################
# Finalize installation: cleanup and display summary
#
# Purpose: Clean up APT cache and display installation summary with connection information
#
# Inputs:
#   - username: Username that was created (string)
#   - hostname: Hostname that was set (string)
#
# Outputs: None (displays summary to stdout)
#
# Side Effects:
#   - Cleans APT cache (apt-get clean, apt-get autoclean)
#   - Calls get_server_ip() to retrieve server IP address
#   - Displays formatted summary box with:
#     - Server IP address
#     - Username
#     - Hostname
#     - Reboot instructions
#     - RDP connection information
#
# Returns:
#   0 - Success (cleanup completed, summary displayed)
#
# Idempotency: Yes
#   - APT cache cleanup is safe to run multiple times
#   - Summary display is informational only
#   - Safe to run multiple times
#
# Example:
#   finalize "coder" "my-vps"
#
# Notes:
#   - Summary includes RDP connection information (IP:3389)
#   - User is reminded to reboot the system
#######################################
finalize() {
    local username="$1"
    local hostname="$2"

    echo ""
    log "INFO" "Finalizing installation..." "finalize()" "username=$username hostname=$hostname"

    # Clean APT cache
    log "INFO" "Cleaning APT cache..." "finalize()"
    apt-get clean -qq
    apt-get autoclean -qq
    log "INFO" "✓ APT cache cleaned" "finalize()"

    # Verify installation
    verify_installation "$username"

    # Get server IP address
    local server_ip
    server_ip=$(get_server_ip)

    # Display summary box
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║              Installation Completed Successfully!            ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    printf "${GREEN}║  ${YELLOW}Server IP:${NC}   %-47s${GREEN}║${NC}\n" "$server_ip"
    printf "${GREEN}║  ${YELLOW}Username:${NC}   %-47s${GREEN}║${NC}\n" "$username"
    printf "${GREEN}║  ${YELLOW}Hostname:${NC}    %-47s${GREEN}║${NC}\n" "$hostname"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║  ${RED}⚠️  REBOOT REQUIRED ⚠️${NC}${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║  Please reboot the system to apply all changes:${NC}"
    echo -e "${GREEN}║  ${YELLOW}sudo reboot${NC}${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║  After reboot, you can connect via RDP:${NC}"
    printf "${GREEN}║  ${YELLOW}%-58s${GREEN}║${NC}\n" "${server_ip}:3389"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

#######################################
# Main script entry point
#######################################
main() {
    # Check script permissions (informational only)
    check_script_permissions

    # Check prerequisites first
    check_debian_version
    check_root_privileges

    log "INFO" "✓ Prerequisites check passed" "main()"
    echo ""

    # Get user inputs
    if ! get_user_inputs; then
        echo -e "${RED}Installation cancelled by user.${NC}"
        exit 1
    fi

    # Prepare system
    system_prep "$CUSTOM_HOSTNAME"

    # Create user
    create_user_and_shell "$CUSTOM_USER" "$CUSTOM_PASS"

    # Remove unnecessary users (except root and the created user)
    remove_unnecessary_users "$CUSTOM_USER"

    # Setup terminal enhancements
    setup_terminal_enhancements "$CUSTOM_USER"

    # Setup desktop environment
    setup_desktop_mobile "$CUSTOM_USER"

    # Setup development stack
    setup_dev_stack "$CUSTOM_USER"

    # Finalize
    finalize "$CUSTOM_USER" "$CUSTOM_HOSTNAME"

    echo ""
    log "INFO" "✓ All phases completed successfully!" "main()"
}

# Run main function only if script is executed directly
# Use default value to avoid unbound variable error with set -u
if [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]]; then
    main "$@"
fi
