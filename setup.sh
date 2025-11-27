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
source "$SCRIPT_DIR/modules/healthcheck.sh"
source "$SCRIPT_DIR/modules/rollback.sh"
source "$SCRIPT_DIR/modules/devtools.sh"
source "$SCRIPT_DIR/modules/monitoring.sh"
source "$SCRIPT_DIR/modules/hostname.sh"

# --- Register Cleanup Handler ---
# Handle EXIT, SIGINT (Ctrl+C), and SIGTERM
trap cleanup_on_error EXIT INT TERM

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
    
    # Hostname customization (always run for better UX)
    setup_hostname
    
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

# --- Parse Arguments & Command Routing ---
parse_args() {
    # No arguments = run main installation
    if [ $# -eq 0 ]; then
        main
        exit 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            # Help
            --help|-h|help)
                show_help
                exit 0
                ;;
            
            # Health Check & Monitoring
            --check|--healthcheck|check|healthcheck)
                show_banner
                init_logging
                run_healthcheck
                exit 0
                ;;
            
            --stats|stats)
                quick_status
                exit 0
                ;;
            
            --monitor|--monitoring|monitor)
                show_banner
                init_logging
                setup_monitoring
                show_monitoring_info
                exit 0
                ;;
            
            --realtime|realtime)
                realtime_monitor
                exit 0
                ;;
            
            --report|report)
                /opt/vps-monitor/performance-report.sh 2>/dev/null || {
                    echo "Performance monitoring not installed"
                    echo "Run: sudo ./setup.sh --monitor"
                    exit 1
                }
                exit 0
                ;;
            
            # Rollback & Backup
            --rollback|rollback)
                show_banner
                init_logging
                interactive_restore
                exit 0
                ;;
            
            --list-backups|list-backups)
                list_backups
                exit 0
                ;;
            
            --cleanup-backups|cleanup-backups)
                show_banner
                init_logging
                cleanup_old_backups 5
                exit 0
                ;;
            
            # Developer Tools
            --devtools|devtools)
                show_banner
                init_logging
                run_preflight_checks
                setup_devtools
                show_devtools_info
                exit 0
                ;;
            
            # Hostname Customization
            --hostname|--set-hostname|hostname)
                show_banner
                init_logging
                change_hostname_interactive
                show_hostname_info
                exit 0
                ;;
            
            # Selective Installation Options
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
            --skip-python)
                export INSTALL_PYTHON=false
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
            --skip-shell)
                export INSTALL_SHELL=false
                shift
                ;;
            
            # Security Options
            --keep-other-users|--no-remove-users)
                export REMOVE_OTHER_USERS=false
                shift
                ;;
            
            --remove-other-users)
                export REMOVE_OTHER_USERS=true
                shift
                ;;
            
            # Output Options
            --verbose|-v)
                export VERBOSE_MODE=true
                shift
                ;;
            
            --dry-run|--test)
                export DRY_RUN_MODE=true
                export VERBOSE_MODE=true  # Enable verbose in dry-run to see all commands
                log_warning "DRY-RUN MODE ENABLED - No system changes will be made"
                log_warning "This will only show what would be executed"
                shift
                ;;
            
            --force-lock)
                export FORCE_LOCK=true
                shift
                ;;
            
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # If only --skip flags were provided, run main installation
    main
}

show_help() {
    cat <<'HELP'
VPS Remote Dev Bootstrap - Modular Edition v2.1

Usage: sudo ./setup.sh [COMMAND] [OPTIONS]

COMMANDS:
  (no command)              Run full installation
  help, --help, -h          Show this help message
  
  Health & Monitoring:
    check, --check          Run full health check
    stats, --stats          Quick system stats
    monitor, --monitor      Setup performance monitoring
    realtime, --realtime    Real-time resource monitor
    report, --report        Generate performance report
  
  Maintenance:
    rollback, --rollback    Restore from backup (interactive)
    list-backups            List available backups
    cleanup-backups         Remove old backups (keep last 5)
  
  Developer Tools:
    devtools, --devtools    Setup Git, SSH keys, aliases, etc
  
  Customization:
    hostname, --hostname    Change hostname (interactive)

INSTALLATION OPTIONS:
  --skip-desktop            Skip desktop environment installation
  --skip-docker             Skip Docker installation
  --skip-nodejs             Skip Node.js installation
  --skip-python             Skip Python installation
  --skip-vscode             Skip VS Code installation
  --skip-cursor             Skip Cursor installation
  --skip-shell              Skip Zsh/Oh My Zsh installation

OUTPUT OPTIONS:
  --verbose, -v             Enable verbose output (show command output details)
                           Default: non-verbose (only info/warning/error/success)
  
  --dry-run, --test         Dry-run mode: show what would be executed without
                           actually making any system changes (safe for debugging)
                           Automatically enables --verbose mode

SECURITY OPTIONS:
  --keep-other-users        Keep other users (don't remove them)
  --remove-other-users      Remove other users except root & DEV_USER (default)

ENVIRONMENT VARIABLES:
  DEV_USER                  Username for development user (default: developer)
  DEV_USER_PASSWORD         Password for user (default: DevPass123!)
  TIMEZONE                  System timezone (default: Asia/Jakarta)
  CUSTOM_HOSTNAME           Custom hostname (default: auto-generated)
  INSTALL_STARSHIP          Install Starship prompt (default: false)
  REMOVE_OTHER_USERS        Remove other users except root & DEV_USER (default: true)
  GIT_USER_NAME             Git user name (for devtools)
  GIT_USER_EMAIL            Git user email (for devtools)

EXAMPLES:
  # Full installation (default)
  sudo ./setup.sh
  
  # Full installation with custom user
  sudo DEV_USER='angga' DEV_USER_PASSWORD='Secret123!' ./setup.sh
  
  # Selective installation (skip some components)
  sudo ./setup.sh --skip-cursor --skip-vscode --skip-desktop
  
  # Run health check
  sudo ./setup.sh --check
  
  # Setup developer tools only
  sudo GIT_USER_NAME="John Doe" GIT_USER_EMAIL="john@example.com" ./setup.sh --devtools
  
  # Setup monitoring
  sudo ./setup.sh --monitor
  
  # Restore from backup
  sudo ./setup.sh --rollback
  
  # Change hostname (interactive)
  sudo ./setup.sh --hostname
  
  # Install with custom hostname
  sudo CUSTOM_HOSTNAME="my-dev-server" ./setup.sh
  
  # Install with Starship prompt
  sudo INSTALL_STARSHIP=true ./setup.sh
  
  # Real-time resource monitoring
  sudo ./setup.sh --realtime
  
  # Quick status
  ./setup.sh --stats

AFTER INSTALLATION:
  - Monitoring: vps-stats, vps-report, vps-monitor
  - Health Check: ./setup.sh --check
  - Rollback: ./setup.sh --rollback

For more information, see: MODULAR.md
HELP
}

# --- Entry Point ---
parse_args "$@"

