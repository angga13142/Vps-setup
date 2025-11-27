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
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

#######################################
# Check if running on Debian 13 (Trixie)
# Exits with error if not Debian 13
# Returns: 0 if Debian 13, exits with 1 otherwise
#######################################
check_debian_version() {
    if [ ! -f /etc/os-release ]; then
        echo -e "${RED}ERROR: Cannot determine OS version. /etc/os-release not found.${NC}" >&2
        exit 1
    fi

    # Source the os-release file
    . /etc/os-release

    # Check for Debian
    if [ "$ID" != "debian" ]; then
        echo -e "${RED}ERROR: This script requires Debian. Detected: $ID${NC}" >&2
        exit 1
    fi

    # Check for Debian 13 (Trixie)
    if [ "$VERSION_CODENAME" != "trixie" ] && [ "$VERSION_ID" != "13" ]; then
        echo -e "${RED}ERROR: This script requires Debian 13 (Trixie). Detected: $PRETTY_NAME${NC}" >&2
        echo -e "${YELLOW}Please use this script on Debian 13 (Trixie) only.${NC}" >&2
        exit 1
    fi

    echo -e "${GREEN}✓ Debian 13 (Trixie) detected: $PRETTY_NAME${NC}"
}

#######################################
# Check if script is executable
# Provides guidance if not executable
#######################################
check_script_permissions() {
    if [ ! -x "$0" ]; then
        echo -e "${YELLOW}Warning: Script is not executable.${NC}"
        echo -e "${YELLOW}Please run: chmod +x $0${NC}"
        echo ""
    fi
}

#######################################
# Check if script is run with root/sudo privileges
# Exits with error if not root
# Returns: 0 if root, exits with 1 otherwise
#######################################
check_root_privileges() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}ERROR: This script must be run as root or with sudo.${NC}" >&2
        echo -e "${YELLOW}Please run: sudo $0${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}✓ Root privileges confirmed${NC}"
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
# Outputs: CUSTOM_USER, CUSTOM_PASS, CUSTOM_HOSTNAME
# Returns: 0 on success, 1 on cancellation
#######################################
get_user_inputs() {
    show_welcome_banner

    echo -e "${YELLOW}Please provide the following information:${NC}"
    echo ""

    # Username prompt with default
    # Use /dev/tty to ensure we read from the terminal when script is piped
    if [ -t 0 ] && [ -t 1 ]; then
        read -p "Username [coder]: " CUSTOM_USER
    else
        read -p "Username [coder]: " CUSTOM_USER < /dev/tty
    fi
    CUSTOM_USER=${CUSTOM_USER:-coder}

    # Validate username (alphanumeric, underscore, hyphen)
    while [[ ! "$CUSTOM_USER" =~ ^[a-zA-Z0-9_-]+$ ]]; do
        echo -e "${RED}Invalid username. Use only alphanumeric characters, underscore, or hyphen.${NC}"
        if [ -t 0 ] && [ -t 1 ]; then
            read -p "Username [coder]: " CUSTOM_USER
        else
            read -p "Username [coder]: " CUSTOM_USER < /dev/tty
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
            read -sp "Password: " CUSTOM_PASS
        else
            # Non-interactive or piped - force reading from terminal
            read -sp "Password: " CUSTOM_PASS < /dev/tty
        fi
        echo ""  # Newline after hidden input
        if [[ -z "$CUSTOM_PASS" ]]; then
            echo -e "${RED}Password cannot be empty. Please enter a password.${NC}"
        fi
    done

    # Confirm password
    local pass_confirm=""
    if [ -t 0 ] && [ -t 1 ]; then
        read -sp "Confirm password: " pass_confirm
    else
        read -sp "Confirm password: " pass_confirm < /dev/tty
    fi
    echo ""
    if [[ "$CUSTOM_PASS" != "$pass_confirm" ]]; then
        echo -e "${RED}Passwords do not match. Please try again.${NC}"
        return 1
    fi

    # Hostname prompt
    # Initialize CUSTOM_HOSTNAME to empty string to avoid unbound variable error
    CUSTOM_HOSTNAME=""
    # Use /dev/tty to ensure we read from the terminal when script is piped
    if [ -t 0 ] && [ -t 1 ]; then
        read -p "Hostname (e.g., my-vps): " CUSTOM_HOSTNAME
    else
        read -p "Hostname (e.g., my-vps): " CUSTOM_HOSTNAME < /dev/tty
    fi
    while [[ -z "$CUSTOM_HOSTNAME" ]] || ! validate_hostname "$CUSTOM_HOSTNAME"; do
        if [[ -z "$CUSTOM_HOSTNAME" ]]; then
            echo -e "${RED}Hostname cannot be empty.${NC}"
        else
            echo -e "${RED}Invalid hostname format. Use alphanumeric characters and hyphens only.${NC}"
        fi
        if [ -t 0 ] && [ -t 1 ]; then
            read -p "Hostname (e.g., my-vps): " CUSTOM_HOSTNAME
        else
            read -p "Hostname (e.g., my-vps): " CUSTOM_HOSTNAME < /dev/tty
        fi
    done

    # Confirmation prompt
    echo ""
    echo -e "${YELLOW}Summary:${NC}"
    echo "  Username: $CUSTOM_USER"
    echo "  Hostname: $CUSTOM_HOSTNAME"
    echo ""
    # Use /dev/tty to ensure we read from the terminal when script is piped
    if [ -t 0 ] && [ -t 1 ]; then
        read -p "Proceed with installation? (yes/no): " confirm
    else
        read -p "Proceed with installation? (yes/no): " confirm < /dev/tty
    fi
    if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        return 1
    fi

    return 0
}

#######################################
# Prepare system (hostname, packages)
# Inputs: CUSTOM_HOSTNAME
# Returns: 0 on success, 1 on error
#######################################
system_prep() {
    local hostname="$1"
    
    echo -e "${GREEN}Preparing system...${NC}"

    # Set hostname with idempotency check
    local current_hostname
    current_hostname=$(hostname)
    if [ "$current_hostname" != "$hostname" ]; then
        echo -e "${YELLOW}Setting hostname to: $hostname${NC}"
        hostnamectl set-hostname "$hostname"
        echo -e "${GREEN}✓ Hostname set to: $hostname${NC}"
    else
        echo -e "${GREEN}✓ Hostname already set to: $hostname${NC}"
    fi

    # Update APT repositories
    echo -e "${YELLOW}Updating package repositories...${NC}"
    apt-get update -qq
    echo -e "${GREEN}✓ Package repositories updated${NC}"

    # Install essential packages with idempotency checks
    local packages=("curl" "git" "htop" "vim" "build-essential")
    local packages_to_install=()

    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            packages_to_install+=("$package")
        else
            echo -e "${GREEN}✓ $package already installed${NC}"
        fi
    done

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        echo -e "${YELLOW}Installing essential packages: ${packages_to_install[*]}${NC}"
        apt-get install -y "${packages_to_install[@]}"
        echo -e "${GREEN}✓ Essential packages installed${NC}"
    fi
}

#######################################
# Create user account
# Inputs: CUSTOM_USER, CUSTOM_PASS
# Returns: 0 on success, 1 on error
#######################################
create_user() {
    local username="$1"
    local password="$2"

    echo -e "${GREEN}Creating user account...${NC}"

    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo -e "${YELLOW}User '$username' already exists. Skipping user creation.${NC}"
        return 0
    fi

    # Create user with home directory and bash shell
    useradd -m -s /bin/bash "$username"
    
    # Set password
    echo "$username:$password" | chpasswd

    echo -e "${GREEN}✓ User '$username' created successfully${NC}"
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
configure_shell() {
    local username="$1"
    local home_dir="/home/$username"
    local bashrc_file="$home_dir/.bashrc"

    echo -e "${GREEN}Configuring shell environment...${NC}"

    # Check if .bashrc already exists and has our custom configuration
    if [ -f "$bashrc_file" ] && grep -q "# Mobile-Ready Workstation Custom Configuration" "$bashrc_file"; then
        echo -e "${YELLOW}.bashrc already configured. Skipping.${NC}"
        return 0
    fi

    # Create backup if .bashrc exists
    if [ -f "$bashrc_file" ]; then
        cp "$bashrc_file" "${bashrc_file}.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}Backed up existing .bashrc${NC}"
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
    chown "$username:$username" "$bashrc_file"
    chmod 644 "$bashrc_file"

    echo -e "${GREEN}✓ Shell environment configured${NC}"
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
configure_xfce_mobile() {
    local username="$1"
    local home_dir="/home/$username"

    echo -e "${GREEN}Configuring XFCE for mobile optimization...${NC}"

    # Set font size to 12pt (mobile-friendly)
    # Note: xfconf-query may fail if XFCE session is not running, but we'll try anyway
    # The settings will be applied when user logs in via RDP
    if su - "$username" -c "DISPLAY=:0 xfconf-query -c xsettings -p /Gtk/FontName -s 'Sans 12' 2>/dev/null" 2>/dev/null || \
       su - "$username" -c "xfconf-query -c xsettings -p /Gtk/FontName -s 'Sans 12' 2>/dev/null" 2>/dev/null; then
        echo -e "${GREEN}✓ Font size set to 12pt${NC}"
    else
        echo -e "${YELLOW}⚠ Could not set font size (XFCE may not be running). Will apply on next login.${NC}"
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
        echo -e "${GREEN}✓ Desktop icon size configured to 48px${NC}"
    else
        echo -e "${YELLOW}⚠ Desktop icon size will be configured on first login${NC}"
    fi

    # Set panel size to 48px
    if su - "$username" -c "xfconf-query -c xfce4-panel -p /panels/panel-1/size -t int -s 48 2>/dev/null" 2>/dev/null; then
        echo -e "${GREEN}✓ Panel size set to 48px${NC}"
    else
        echo -e "${YELLOW}⚠ Panel size will be configured on first login${NC}"
    fi

    echo -e "${GREEN}✓ XFCE mobile optimization configured${NC}"
    return 0
}

#######################################
# Install and configure desktop environment for mobile
# Inputs: CUSTOM_USER
# Returns: 0 on success, 1 on error
#######################################
setup_desktop_mobile() {
    local username="$1"

    echo -e "${GREEN}Setting up mobile-optimized desktop environment...${NC}"

    # Install XFCE4 with idempotency check
    if dpkg -l | grep -q "^ii  xfce4 "; then
        echo -e "${GREEN}✓ XFCE4 already installed${NC}"
    else
        echo -e "${YELLOW}Installing XFCE4 desktop environment...${NC}"
        # Set DEBIAN_FRONTEND to noninteractive to avoid prompts
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y xfce4 xfce4-goodies
        echo -e "${GREEN}✓ XFCE4 installed${NC}"
    fi

    # Install XRDP with idempotency check
    if dpkg -l | grep -q "^ii  xrdp "; then
        echo -e "${GREEN}✓ XRDP already installed${NC}"
    else
        echo -e "${YELLOW}Installing XRDP remote desktop server...${NC}"
        apt-get install -y xrdp
        echo -e "${GREEN}✓ XRDP installed${NC}"
    fi

    # Enable XRDP service
    if systemctl is-enabled xrdp &>/dev/null; then
        echo -e "${GREEN}✓ XRDP service already enabled${NC}"
    else
        echo -e "${YELLOW}Enabling XRDP service...${NC}"
        systemctl enable xrdp
        echo -e "${GREEN}✓ XRDP service enabled${NC}"
    fi

    # Start XRDP service with idempotency check
    if systemctl is-active --quiet xrdp; then
        echo -e "${GREEN}✓ XRDP service already running${NC}"
    else
        echo -e "${YELLOW}Starting XRDP service...${NC}"
        systemctl start xrdp
        if systemctl is-active --quiet xrdp; then
            echo -e "${GREEN}✓ XRDP service started${NC}"
        else
            echo -e "${YELLOW}⚠ XRDP service start may have failed. Check with: systemctl status xrdp${NC}"
        fi
    fi

    # Configure XFCE for mobile optimization
    configure_xfce_mobile "$username"

    echo -e "${GREEN}✓ Desktop environment setup completed${NC}"
    return 0
}

#######################################
# Setup Docker APT repository
# Returns: 0 on success, 1 on error
#######################################
setup_docker_repository() {
    echo -e "${GREEN}Setting up Docker repository...${NC}"

    # Check if repository already configured
    if [ -f /etc/apt/sources.list.d/docker.sources ]; then
        echo -e "${GREEN}✓ Docker repository already configured${NC}"
        return 0
    fi

    # Install prerequisites
    if ! dpkg -l | grep -q "^ii  ca-certificates " || ! dpkg -l | grep -q "^ii  curl "; then
        echo -e "${YELLOW}Installing Docker repository prerequisites...${NC}"
        apt-get install -y ca-certificates curl
    fi

    # Create keyring directory
    install -m 0755 -d /etc/apt/keyrings

    # Add Docker GPG key
    echo -e "${YELLOW}Adding Docker GPG key...${NC}"
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository
    echo -e "${YELLOW}Adding Docker repository...${NC}"
    . /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" | \
        tee /etc/apt/sources.list.d/docker.sources > /dev/null

    # Update APT
    echo -e "${YELLOW}Updating package list...${NC}"
    apt-get update -qq

    echo -e "${GREEN}✓ Docker repository configured${NC}"
    return 0
}

#######################################
# Install Docker and Docker Compose
# Returns: 0 on success, 1 on error
#######################################
install_docker() {
    local username="$1"

    echo -e "${GREEN}Installing Docker...${NC}"

    # Setup repository
    setup_docker_repository

    # Check if Docker is already installed
    if command -v docker &>/dev/null && dpkg -l | grep -q "^ii  docker-ce "; then
        echo -e "${GREEN}✓ Docker already installed${NC}"
    else
        echo -e "${YELLOW}Installing Docker packages...${NC}"
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        echo -e "${GREEN}✓ Docker installed${NC}"
    fi

    # Add user to docker group
    if groups "$username" | grep -q "\bdocker\b"; then
        echo -e "${GREEN}✓ User '$username' already in docker group${NC}"
    else
        echo -e "${YELLOW}Adding user '$username' to docker group...${NC}"
        usermod -aG docker "$username"
        echo -e "${GREEN}✓ User '$username' added to docker group${NC}"
        echo -e "${YELLOW}Note: User must logout and login again for docker group to take effect${NC}"
    fi

    return 0
}

#######################################
# Install web browsers
# Returns: 0 on success, 1 on error
#######################################
install_browsers() {
    echo -e "${GREEN}Installing web browsers...${NC}"

    # Install Firefox ESR
    if dpkg -l | grep -q "^ii  firefox-esr "; then
        echo -e "${GREEN}✓ Firefox ESR already installed${NC}"
    else
        echo -e "${YELLOW}Installing Firefox ESR...${NC}"
        apt-get install -y firefox-esr
        echo -e "${GREEN}✓ Firefox ESR installed${NC}"
    fi

    # Install Chromium
    if dpkg -l | grep -q "^ii  chromium "; then
        echo -e "${GREEN}✓ Chromium already installed${NC}"
    else
        echo -e "${YELLOW}Installing Chromium...${NC}"
        apt-get install -y chromium
        echo -e "${GREEN}✓ Chromium installed${NC}"
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

    echo -e "${GREEN}Installing NVM and Node.js LTS...${NC}"

    # Check if NVM is already installed
    if [ -d "$nvm_dir" ] && [ -f "$nvm_dir/nvm.sh" ]; then
        echo -e "${GREEN}✓ NVM already installed${NC}"
    else
        echo -e "${YELLOW}Installing NVM...${NC}"
        # Install NVM as the target user
        su - "$username" -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash' 2>&1 | grep -v "Profile" || true
        echo -e "${GREEN}✓ NVM installed${NC}"
    fi

    # Check if NVM configuration is in .bashrc
    if grep -q "NVM_DIR" "$home_dir/.bashrc" 2>/dev/null; then
        echo -e "${GREEN}✓ NVM configuration already in .bashrc${NC}"
    else
        echo -e "${YELLOW}Adding NVM configuration to .bashrc...${NC}"
        cat >> "$home_dir/.bashrc" << 'NVM_EOF'

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
NVM_EOF
        chown "$username:$username" "$home_dir/.bashrc"
        echo -e "${GREEN}✓ NVM configuration added to .bashrc${NC}"
    fi

    # Install Node.js LTS
    echo -e "${YELLOW}Installing Node.js LTS...${NC}"
    # Source NVM and install Node.js LTS as the target user
    su - "$username" -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts && nvm use --default --lts' 2>&1 | tail -5
    echo -e "${GREEN}✓ Node.js LTS installed and set as default${NC}"

    return 0
}

#######################################
# Verify Python 3 availability
# Returns: 0 if available, 1 if not
#######################################
verify_python() {
    echo -e "${GREEN}Verifying Python 3...${NC}"

    if command -v python3 &>/dev/null; then
        local python_version
        python_version=$(python3 --version 2>&1)
        echo -e "${GREEN}✓ Python 3 available: $python_version${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Python 3 not found. Installing...${NC}"
        apt-get install -y python3 python3-pip
        echo -e "${GREEN}✓ Python 3 installed${NC}"
        return 0
    fi
}

#######################################
# Setup development stack
# Inputs: CUSTOM_USER
# Returns: 0 on success, 1 on error
#######################################
setup_dev_stack() {
    local username="$1"

    echo -e "${GREEN}Setting up development stack...${NC}"

    # Install Docker
    install_docker "$username"

    # Install browsers
    install_browsers

    # Install NVM and Node.js
    install_nvm_nodejs "$username"

    # Verify Python
    verify_python

    echo -e "${GREEN}✓ Development stack setup completed${NC}"
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
# Inputs: CUSTOM_USER, CUSTOM_HOSTNAME
# Returns: 0 on success
#######################################
finalize() {
    local username="$1"
    local hostname="$2"

    echo ""
    echo -e "${GREEN}Finalizing installation...${NC}"

    # Clean APT cache
    echo -e "${YELLOW}Cleaning APT cache...${NC}"
    apt-get clean -qq
    apt-get autoclean -qq
    echo -e "${GREEN}✓ APT cache cleaned${NC}"

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

    echo -e "${GREEN}✓ Prerequisites check passed${NC}"
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
    echo -e "${GREEN}✓ All phases completed successfully!${NC}"
}

# Run main function
main "$@"

