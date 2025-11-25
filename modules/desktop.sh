#!/bin/bash

# ==============================================================================
# Desktop Module - XFCE & XRDP
# ==============================================================================

setup_desktop() {
    update_progress "setup_desktop"
    log_info "Menginstal XFCE4 dan XRDP..."
    
    # Install XFCE4 & XRDP
    local DESKTOP_PKGS="xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils xrdp"
    for pkg in $DESKTOP_PKGS; do
        check_and_install "$pkg"
    done

    # Add xrdp user to ssl-cert group
    if getent group ssl-cert > /dev/null; then
        if ! groups xrdp | grep -q ssl-cert; then
            adduser xrdp ssl-cert || log_warning "Gagal menambahkan xrdp ke grup ssl-cert"
        fi
    else
        log_warning "Grup ssl-cert tidak ada, skip"
    fi

    # Configure Xsession
    local xsession_file="/home/$DEV_USER/.xsession"
    backup_file "$xsession_file"
    
    run_as_user "$DEV_USER" bash -c "echo 'xfce4-session' > $xsession_file" || {
        log_error "Gagal membuat .xsession file"
        return 1
    }
    
    chmod +x "$xsession_file"
    chown "$DEV_USER:$DEV_USER" "$xsession_file"

    # Start XRDP service
    enable_and_start_service "xrdp"
    
    log_success "Desktop environment setup selesai"
}

