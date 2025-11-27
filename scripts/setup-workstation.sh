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
# Main script entry point
#######################################
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Mobile-Ready Coding Workstation Setup${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    # Check prerequisites first
    check_debian_version
    check_root_privileges

    echo -e "${GREEN}✓ Prerequisites check passed${NC}"
    echo ""
}

# Run main function
main "$@"

