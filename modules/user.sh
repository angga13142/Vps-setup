#!/bin/bash

# ==============================================================================
# User Module - User Management
# ==============================================================================

setup_user() {
    update_progress "setup_user"
    log_info "Menyiapkan user non-root: $DEV_USER..."

    check_and_install "sudo"

    if id "$DEV_USER" &>/dev/null; then
        log_info "User $DEV_USER sudah ada."
        echo "$DEV_USER:$DEV_USER_PASSWORD" | chpasswd
        log_info "Password untuk $DEV_USER diupdate."
        
        if ! groups "$DEV_USER" | grep -q sudo; then
            usermod -aG sudo "$DEV_USER"
            log_info "User $DEV_USER ditambahkan ke grup sudo."
        fi
    else
        useradd -m -s /bin/bash -G sudo "$DEV_USER" || {
            log_error "Gagal membuat user $DEV_USER"
            return 1
        }
        echo "$DEV_USER:$DEV_USER_PASSWORD" | chpasswd
        log_success "User $DEV_USER dibuat."
    fi
    
    # Verify home directory
    if [ ! -d "/home/$DEV_USER" ]; then
        log_error "Home directory /home/$DEV_USER tidak ada!"
        return 1
    fi
    chown -R "$DEV_USER:$DEV_USER" "/home/$DEV_USER"
    
    # Configure sudoers
    [ -f "/etc/sudoers.d/$DEV_USER" ] && backup_file "/etc/sudoers.d/$DEV_USER"
    
    echo "$DEV_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$DEV_USER"
    chmod 0440 "/etc/sudoers.d/$DEV_USER"
    
    if visudo -c -f "/etc/sudoers.d/$DEV_USER" &>/dev/null; then
        log_success "Konfigurasi sudo untuk $DEV_USER valid."
    else
        log_error "Konfigurasi sudo tidak valid! Menghapus file untuk keamanan."
        rm -f "/etc/sudoers.d/$DEV_USER"
        return 1
    fi
    
    # Set root password sama dengan user password untuk kemudahan
    log_info "Setting root password sama dengan user password..."
    echo "root:$DEV_USER_PASSWORD" | chpasswd
    log_success "✓ Root password di-set (sama dengan user password)"
    log_info "  Root login: su"
    log_info "  Password: (sama dengan $DEV_USER)"
    
    log_success "User setup selesai"
}

