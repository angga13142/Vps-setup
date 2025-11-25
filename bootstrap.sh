#!/bin/bash

# ==============================================================================
# VPS Remote Dev Bootstrap - Bootstrap Script
# ==============================================================================
# Script ini akan mendownload seluruh repository dan menjalankan setup.sh
# Gunakan script ini untuk instalasi via curl | bash
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository info
REPO_URL="https://github.com/angga13142/Vps-setup.git"
REPO_BRANCH="master"
TEMP_DIR="/tmp/vps-bootstrap-$$"

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        echo -e "${YELLOW}Cleaning up temporary files...${NC}"
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run: sudo bash <(curl -fsSL ...)"
    exit 1
fi

# Banner
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     VPS Remote Dev Bootstrap - Bootstrap Script          ║${NC}"
echo -e "${BLUE}║           Modular Edition v2.1                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check for required commands
echo -e "${YELLOW}[1/3] Checking prerequisites...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Git not found. Installing git...${NC}"
    apt-get update -qq
    apt-get install -y -qq git
fi

# Create temporary directory
echo -e "${YELLOW}[2/3] Downloading repository...${NC}"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Clone repository
if ! git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" . 2>&1; then
    echo -e "${RED}Error: Failed to clone repository${NC}"
    echo "Please check your internet connection and try again."
    exit 1
fi

# Make setup.sh executable
chmod +x setup.sh

# Run setup.sh with all arguments passed to bootstrap
# Note: Environment variables set before 'bash' will be available to setup.sh
# Arguments (like --verbose) should be added after 'bash'
echo -e "${GREEN}[3/3] Starting installation...${NC}"
echo ""
exec ./setup.sh "$@"

