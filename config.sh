#!/bin/bash

# ==============================================================================
# VPS Remote Dev Bootstrap - Configuration
# ==============================================================================
# Semua konfigurasi terpusat di file ini
# Anda dapat menimpa dengan environment variables saat menjalankan
# ==============================================================================

# --- User Configuration ---
export DEV_USER="${DEV_USER:-developer}"
export DEV_USER_PASSWORD="${DEV_USER_PASSWORD:-DevPass123!}"
# Note: Root password akan di-set sama dengan DEV_USER_PASSWORD untuk kemudahan

# --- System Configuration ---
export TIMEZONE="${TIMEZONE:-Asia/Jakarta}"
export CUSTOM_HOSTNAME="${CUSTOM_HOSTNAME:-}"  # Leave empty for auto-generated
export INSTALL_STARSHIP="${INSTALL_STARSHIP:-false}"  # Set true for fancy Starship prompt

# --- Development Stack Versions ---
export NODE_VERSION="${NODE_VERSION:-lts/*}"
export NVM_VERSION="${NVM_VERSION:-v0.39.7}"

# --- Git Configuration (for devtools) ---
export GIT_USER_NAME="${GIT_USER_NAME:-}"
export GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"

# --- URLs ---
export CURSOR_INSTALLER_URL="https://cursor.com/install"
export NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"
export NERD_FONTS_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip"

# --- Internal Paths ---
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LOG_FILE="${LOG_FILE:-/var/log/vps-bootstrap-$(date +%Y%m%d-%H%M%S).log}"
export LOCK_FILE="/var/lock/vps-bootstrap.lock"
export BACKUP_DIR="/root/.vps-bootstrap-backups-$(date +%Y%m%d-%H%M%S)"
export PROGRESS_FILE="/tmp/vps-bootstrap-progress.txt"

# --- Installation Options (Set to 'true' or 'false') ---
export INSTALL_SYSTEM="${INSTALL_SYSTEM:-true}"
export INSTALL_USER="${INSTALL_USER:-true}"
export INSTALL_DESKTOP="${INSTALL_DESKTOP:-true}"
export INSTALL_DOCKER="${INSTALL_DOCKER:-true}"
export INSTALL_NODEJS="${INSTALL_NODEJS:-true}"
export INSTALL_PYTHON="${INSTALL_PYTHON:-true}"
export INSTALL_VSCODE="${INSTALL_VSCODE:-true}"
export INSTALL_CURSOR="${INSTALL_CURSOR:-true}"
export INSTALL_SHELL="${INSTALL_SHELL:-true}"

# --- Security Options ---
export REMOVE_OTHER_USERS="${REMOVE_OTHER_USERS:-true}"  # Remove other users except root and DEV_USER (security)

# --- Output Options ---
export VERBOSE_MODE="${VERBOSE_MODE:-false}"  # Enable verbose output (default: false, only show info/warning/error/success)
export DRY_RUN_MODE="${DRY_RUN_MODE:-false}"   # Dry-run mode: show what would be done without actually executing (default: false)

# --- Error Handling ---
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

