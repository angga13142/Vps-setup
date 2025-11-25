#!/bin/bash

# ==============================================================================
# Verification Library
# ==============================================================================
# Post-installation verification untuk memastikan semua component terinstal
# ==============================================================================

verify_installation() {
    update_progress "verify_installation"
    log_info "Memverifikasi instalasi..."
    
    local errors=0
    local warnings=0
    
    # Check user
    if id "$DEV_USER" &>/dev/null; then
        log_success "✓ User $DEV_USER ada"
    else
        log_error "✗ User $DEV_USER tidak ditemukan"
        errors=$((errors+1))
    fi
    
    # Check sudo access
    if run_as_user "$DEV_USER" sudo -n true 2>/dev/null; then
        log_success "✓ Sudo access OK"
    else
        log_warning "⚠ Sudo access mungkin bermasalah"
        warnings=$((warnings+1))
    fi
    
    # Check Docker
    if [ "$INSTALL_DOCKER" = "true" ]; then
        if command_exists docker; then
            log_success "✓ Docker terinstal ($(docker --version | cut -d' ' -f3 | tr -d ','))"
        else
            log_warning "⚠ Docker tidak ditemukan"
            warnings=$((warnings+1))
        fi
    fi
    
    # Check Python
    if [ "$INSTALL_PYTHON" = "true" ]; then
        if command_exists python3; then
            log_success "✓ Python terinstal ($(python3 --version | cut -d' ' -f2))"
        else
            log_error "✗ Python tidak ditemukan"
            errors=$((errors+1))
        fi
    fi
    
    # Check Node
    if [ "$INSTALL_NODEJS" = "true" ]; then
        if run_as_user "$DEV_USER" bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; command -v node' &>/dev/null; then
            local node_version
            node_version=$(run_as_user "$DEV_USER" bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node --version')
            log_success "✓ Node.js terinstal ($node_version)"
        else
            log_warning "⚠ Node.js tidak ditemukan (mungkin perlu re-login)"
            warnings=$((warnings+1))
        fi
    fi
    
    # Check VS Code
    if [ "$INSTALL_VSCODE" = "true" ]; then
        if command_exists code; then
            log_success "✓ VS Code terinstal"
        else
            log_warning "⚠ VS Code tidak ditemukan"
            warnings=$((warnings+1))
        fi
    fi
    
    # Check Cursor
    if [ "$INSTALL_CURSOR" = "true" ]; then
        if command_exists cursor || run_as_user "$DEV_USER" bash -c 'command -v cursor' &>/dev/null || [ -f /opt/cursor/cursor.AppImage ]; then
            log_success "✓ Cursor tersedia"
        else
            log_warning "⚠ Cursor tidak ditemukan"
            warnings=$((warnings+1))
        fi
    fi
    
    # Check XRDP
    if [ "$INSTALL_DESKTOP" = "true" ]; then
        if command_exists systemctl && systemctl is-active --quiet xrdp 2>/dev/null; then
            log_success "✓ XRDP service berjalan"
        else
            log_warning "⚠ XRDP service tidak aktif"
            warnings=$((warnings+1))
        fi
    fi
    
    # Check UFW
    if command_exists ufw; then
        if ufw status | grep -q "Status: active"; then
            log_success "✓ UFW firewall aktif"
        else
            log_warning "⚠ UFW firewall tidak aktif"
            warnings=$((warnings+1))
        fi
    fi
    
    # Check Swap
    if swapon --show | grep -q swapfile; then
        log_success "✓ Swap file aktif"
    else
        log_warning "⚠ Swap file tidak aktif"
        warnings=$((warnings+1))
    fi
    
    # Summary
    echo ""
    log_info "=== Verification Summary ==="
    if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
        log_success "Semua komponen terverifikasi dengan baik! ✓"
    elif [ $errors -eq 0 ]; then
        log_warning "Instalasi selesai dengan $warnings warning(s)"
    else
        log_error "Instalasi selesai dengan $errors error(s) dan $warnings warning(s)"
    fi
}

