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

# Cleanup function for current temp directory
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        echo -e "${YELLOW}Cleaning up temporary files...${NC}" >&2
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
}

# Cleanup old temp directories (from previous failed runs)
cleanup_old_temp_dirs() {
    local old_dirs
    old_dirs=$(find /tmp -maxdepth 1 -type d -name "vps-bootstrap-*" -mtime +1 2>/dev/null || true)
    if [ -n "$old_dirs" ]; then
        echo -e "${YELLOW}Cleaning up old temporary directories...${NC}" >&2
        echo "$old_dirs" | while IFS= read -r dir; do
            [ -n "$dir" ] && rm -rf "$dir" 2>/dev/null || true
        done
    fi
}

# Register cleanup trap
trap cleanup EXIT INT TERM

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
echo -e "${YELLOW}[1/4] Checking prerequisites...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Git not found. Installing git...${NC}"
    apt-get update -qq
    apt-get install -y -qq git
fi

# Cleanup old temp directories (free up space before download)
echo -e "${YELLOW}[2/4] Cleaning up old temporary files...${NC}"
cleanup_old_temp_dirs

# Remove existing temp directory if it exists (from previous failed run)
if [ -d "$TEMP_DIR" ]; then
    echo -e "${YELLOW}Removing existing temporary directory...${NC}"
    rm -rf "$TEMP_DIR" 2>/dev/null || true
fi

# Create temporary directory
echo -e "${YELLOW}[3/4] Downloading repository...${NC}"
mkdir -p "$TEMP_DIR" || {
    echo -e "${RED}Error: Failed to create temporary directory${NC}"
    exit 1
}

cd "$TEMP_DIR" || {
    echo -e "${RED}Error: Failed to change to temporary directory${NC}"
    cleanup
    exit 1
}

# Clone repository with retry logic
clone_attempt=1
clone_success=false
while [ $clone_attempt -le 3 ] && [ "$clone_success" = false ]; do
    if git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" . 2>&1; then
        clone_success=true
    else
        if [ $clone_attempt -lt 3 ]; then
            echo -e "${YELLOW}Clone failed, retrying in 5 seconds... (attempt $clone_attempt/3)${NC}"
            sleep 5
            # Clean up partial clone before retry
            rm -rf "$TEMP_DIR"/* "$TEMP_DIR"/.* 2>/dev/null || true
        fi
        clone_attempt=$((clone_attempt + 1))
    fi
done

if [ "$clone_success" = false ]; then
    echo -e "${RED}Error: Failed to clone repository after 3 attempts${NC}"
    echo "Please check your internet connection and try again."
    cleanup
    exit 1
fi

# Make setup.sh executable
chmod +x setup.sh

# Verify setup.sh exists and is readable
if [ ! -f "./setup.sh" ]; then
    echo -e "${RED}Error: setup.sh not found in downloaded repository${NC}"
    cleanup
    exit 1
fi

# Make setup.sh executable
chmod +x setup.sh

# Run setup.sh with all arguments passed to bootstrap
# Note: Environment variables set before 'bash' will be available to setup.sh
# Arguments (like --verbose) should be added after 'bash'
echo -e "${GREEN}[4/4] Starting installation...${NC}"
echo ""

# Use exec to replace current process (cleanup will still run on exit)
exec ./setup.sh "$@"

