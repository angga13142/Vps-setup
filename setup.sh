#!/bin/bash

# ==============================================================================
# VPS Remote Dev Bootstrap - Debian 13 (Trixie/Bookworm)
# ==============================================================================
# Role:       Linux Systems Administrator / DevOps
# Target OS:  Debian 13 (Trixie) / 12 (Bookworm)
# Description: Provisions a complete remote GUI dev environment.
#              (XFCE, XRDP, Docker, Node, Python, VS Code, Cursor)
# Version:    2.1 (Modular Edition)
# ==============================================================================

# --- Get Script Directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Load Configuration ---
source "$SCRIPT_DIR/config.sh"

# --- Load Libraries ---
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/helpers.sh"
source "$SCRIPT_DIR/lib/validators.sh"
source "$SCRIPT_DIR/lib/verification.sh"

# --- Load Modules ---
source "$SCRIPT_DIR/modules/system.sh"
source "$SCRIPT_DIR/modules/user.sh"
source "$SCRIPT_DIR/modules/desktop.sh"
source "$SCRIPT_DIR/modules/docker.sh"
source "$SCRIPT_DIR/modules/nodejs.sh"
source "$SCRIPT_DIR/modules/python.sh"
source "$SCRIPT_DIR/modules/vscode.sh"
source "$SCRIPT_DIR/modules/cursor.sh"
source "$SCRIPT_DIR/modules/shell.sh"

# --- Register Cleanup Handler ---
trap cleanup_on_error EXIT

# --- Show Banner ---
show_banner() {
    echo ""
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║     VPS Remote Dev Bootstrap - Modular Edition v2.1      ║"
    echo "  ║           Debian 12 (Bookworm) / 13 (Trixie)             ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo ""
}

# --- Show Installation Plan ---
show_installation_plan() {
    log_info "=== Installation Plan ==="
    log_info "User Target: $DEV_USER"
    log_info "Timezone: $TIMEZONE"
    echo ""
    log_info "Components to Install:"
    [ "$INSTALL_SYSTEM" = "true" ] && log_info "  ✓ System Preparation & Optimization"
    [ "$INSTALL_USER" = "true" ] && log_info "  ✓ User Management"
    [ "$INSTALL_DESKTOP" = "true" ] && log_info "  ✓ Desktop Environment (XFCE & XRDP)"
    [ "$INSTALL_DOCKER" = "true" ] && log_info "  ✓ Docker"
    [ "$INSTALL_NODEJS" = "true" ] && log_info "  ✓ Node.js (via NVM)"
    [ "$INSTALL_PYTHON" = "true" ] && log_info "  ✓ Python Stack"
    [ "$INSTALL_VSCODE" = "true" ] && log_info "  ✓ VS Code"
    [ "$INSTALL_CURSOR" = "true" ] && log_info "  ✓ Cursor IDE"
    [ "$INSTALL_SHELL" = "true" ] && log_info "  ✓ Shell (Zsh & Oh My Zsh)"
    echo ""
}

# --- Main Execution Flow ---
main() {
    show_banner
    init_logging
    
    # Pre-flight checks
    run_preflight_checks
    
    # Show what will be installed
    show_installation_plan
    
    # Main installation steps (selective based on config)
    log_info "=== Starting Installation ==="
    echo ""
    
    [ "$INSTALL_SYSTEM" = "true" ] && setup_system
    [ "$INSTALL_USER" = "true" ] && setup_user
    [ "$INSTALL_DESKTOP" = "true" ] && setup_desktop
    
    # Development stack
    if [ "$INSTALL_DOCKER" = "true" ] || [ "$INSTALL_NODEJS" = "true" ] || [ "$INSTALL_PYTHON" = "true" ]; then
        log_info "=== Installing Development Stack ==="
        [ "$INSTALL_DOCKER" = "true" ] && setup_docker
        [ "$INSTALL_NODEJS" = "true" ] && setup_nodejs
        [ "$INSTALL_PYTHON" = "true" ] && setup_python
    fi
    
    # Code editors
    if [ "$INSTALL_VSCODE" = "true" ] || [ "$INSTALL_CURSOR" = "true" ]; then
        log_info "=== Installing Code Editors ==="
        [ "$INSTALL_VSCODE" = "true" ] && setup_vscode
        [ "$INSTALL_CURSOR" = "true" ] && setup_cursor
    fi
    
    [ "$INSTALL_SHELL" = "true" ] && setup_shell
    
    # Post-installation verification
    echo ""
    log_info "=== Running Post-Installation Verification ==="
    verify_installation
    
    # Final summary
    echo ""
    log_success "=== Instalasi Selesai! ==="
    log_info "-----------------------------------------------------"
    log_info "Log lengkap tersimpan di: $LOG_FILE"
    log_info "Backup config tersimpan di: $BACKUP_DIR"
    log_info ""
    log_info "Panduan Koneksi:"
    log_info "1. Reboot VPS Anda: 'sudo reboot'"
    log_info "2. Buka RDP Client (Remote Desktop Connection) di PC Anda."
    log_info "3. Masukkan IP Server dan User: $DEV_USER"
    log_info "4. Password: (yang Anda set di DEV_USER_PASSWORD)"
    
    if [ "$INSTALL_DESKTOP" = "true" ]; then
        log_info "5. Setelah login RDP, buka Cursor:"
        log_info "   - Menu: Applications > Development > Cursor"
        log_info "   - Terminal: ketik 'cursor'"
    fi
    
    if [ "$INSTALL_NODEJS" = "true" ]; then
        log_info ""
        log_info "Node.js tersedia via NVM (gunakan di shell user $DEV_USER):"
        log_info "   source ~/.nvm/nvm.sh && node --version"
    fi
    log_info "-----------------------------------------------------"
    echo ""
}

# --- Parse Arguments (Optional: untuk future enhancement) ---
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                echo "Usage: sudo ./setup.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --help, -h              Show this help message"
                echo "  --skip-desktop          Skip desktop environment installation"
                echo "  --skip-docker           Skip Docker installation"
                echo "  --skip-nodejs           Skip Node.js installation"
                echo "  --skip-vscode           Skip VS Code installation"
                echo "  --skip-cursor           Skip Cursor installation"
                echo ""
                echo "Environment Variables:"
                echo "  DEV_USER                Username for development user (default: developer)"
                echo "  DEV_USER_PASSWORD       Password for development user (default: DevPass123!)"
                echo "  TIMEZONE                System timezone (default: Asia/Jakarta)"
                echo ""
                echo "Examples:"
                echo "  sudo ./setup.sh"
                echo "  sudo DEV_USER='angga' DEV_USER_PASSWORD='Secret123!' ./setup.sh"
                echo "  sudo ./setup.sh --skip-cursor --skip-vscode"
                exit 0
                ;;
            --skip-desktop)
                export INSTALL_DESKTOP=false
                shift
                ;;
            --skip-docker)
                export INSTALL_DOCKER=false
                shift
                ;;
            --skip-nodejs)
                export INSTALL_NODEJS=false
                shift
                ;;
            --skip-vscode)
                export INSTALL_VSCODE=false
                shift
                ;;
            --skip-cursor)
                export INSTALL_CURSOR=false
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# --- Entry Point ---
parse_args "$@"
main

