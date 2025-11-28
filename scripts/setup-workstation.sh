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
# shellcheck disable=SC2034  # SCRIPT_NAME and SCRIPT_DIR kept for future logging/debugging
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
readonly SCRIPT_NAME
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
# Side Effects: Creates log file if it doesn't exist
# Returns: 0 on success
# Idempotency: Safe to call multiple times
# Examples:
#   log "INFO" "Starting installation" "main()"
#   log "ERROR" "User creation failed" "create_user()" "username=testuser"
# Notes: Logs are written in ISO 8601 UTC format for consistency
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

    # Write to log file (append mode)
    echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true

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
        if ! dpkg -l | grep -q "^ii  $package "; then
            packages_to_install+=("$package")
        else
            log "INFO" "✓ $package already installed" "system_prep()"
        fi
    done

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        log "INFO" "Installing essential packages: ${packages_to_install[*]}" "system_prep()"
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
    if dpkg -l | grep -q "^ii  xfce4 "; then
        log "INFO" "✓ XFCE4 already installed" "setup_desktop_mobile()"
    else
        log "INFO" "Installing XFCE4 desktop environment..." "setup_desktop_mobile()"
        # Set DEBIAN_FRONTEND to noninteractive to avoid prompts
        export DEBIAN_FRONTEND=noninteractive
        if ! apt-get install -y xfce4 xfce4-goodies; then
            log "ERROR" "Failed to install XFCE4. Context: Function setup_desktop_mobile() attempted to install xfce4 and xfce4-goodies but apt-get install failed. Recovery: Check APT repository configuration, verify package availability, or install manually: apt-get install -y xfce4 xfce4-goodies" "setup_desktop_mobile()" "username=$username"
            return 1
        fi
        log "INFO" "✓ XFCE4 installed" "setup_desktop_mobile()"
    fi

    # Install XRDP with idempotency check
    if dpkg -l | grep -q "^ii  xrdp "; then
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
    if ! dpkg -l | grep -q "^ii  ca-certificates " || ! dpkg -l | grep -q "^ii  curl "; then
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
    if command -v docker &>/dev/null && dpkg -l | grep -q "^ii  docker-ce "; then
        log "INFO" "✓ Docker already installed" "install_docker()"
    else
        log "INFO" "Installing Docker packages..." "install_docker()"
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
    if dpkg -l | grep -q "^ii  firefox-esr "; then
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
    if dpkg -l | grep -q "^ii  chromium "; then
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
        if ! su - "$username" -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash' 2>&1 | grep -v "Profile" || true; then
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
    log "INFO" "Installing Node.js LTS..." "install_nvm_nodejs()" "username=$username"
    # Source NVM and install Node.js LTS as the target user
    if ! su - "$username" -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts && nvm use --default --lts' 2>&1 | tail -5; then
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
