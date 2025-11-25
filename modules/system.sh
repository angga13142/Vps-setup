#!/bin/bash

# ==============================================================================
# System Module - System Preparation & Optimization
# ==============================================================================

setup_system() {
    update_progress "setup_system"
    log_info "Memulai update sistem dan instalasi dependensi dasar..."
    
    # Set Timezone
    if command_exists timedatectl; then
        timedatectl set-timezone "$TIMEZONE" || log_warning "Gagal set timezone"
    else
        log_warning "timedatectl tidak tersedia, skip timezone setup"
    fi

    # Update Repos & Upgrade with retry
    log_info "Updating package repositories..."
    retry_command 3 5 "apt-get update"
    apt-get upgrade -y || log_warning "apt-get upgrade mengalami masalah, melanjutkan..."

    # Install Essential Tools
    local ESSENTIAL_PKGS="curl wget git htop ufw unzip build-essential apt-transport-https ca-certificates gnupg lsb-release fail2ban"
    
    log_info "Menginstal essential packages..."
    for pkg in $ESSENTIAL_PKGS; do
        check_and_install "$pkg"
    done

    # Handle libfuse2 (Needed for AppImages)
    log_info "Mencoba menginstal library FUSE (libfuse2 / libfuse2t64)..."
    if apt-get install -y libfuse2t64 2>/dev/null; then
        log_success "libfuse2t64 berhasil diinstal."
    elif apt-get install -y libfuse2 2>/dev/null; then
        log_success "libfuse2 berhasil diinstal."
    else
        log_warning "Gagal menginstal libfuse2 atau libfuse2t64. AppImage mungkin tidak berjalan."
        true
    fi

    # --- Swap Configuration (4GB) ---
    if ! grep -q "swapfile" /etc/fstab; then
        log_info "Mengonfigurasi 4GB Swap..."
        
        local available_gb
        available_gb=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
        if [ "$available_gb" -lt 4 ]; then
            log_warning "Space tidak cukup untuk 4GB swap, skip swap creation"
        else
            backup_file "/etc/fstab"
            
            fallocate -l 4G /swapfile || {
                log_warning "fallocate gagal, mencoba dd..."
                dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress || {
                    log_error "Gagal membuat swap file"
                    return 1
                }
            }
            
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            echo '/swapfile none swap sw 0 0' >> /etc/fstab
            
            backup_file "/etc/sysctl.conf"
            sysctl vm.swappiness=10
            if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
                echo 'vm.swappiness=10' >> /etc/sysctl.conf
            fi
            log_success "Swap 4GB berhasil dikonfigurasi"
        fi
    else
        log_info "Swap sudah ada, melewati..."
    fi

    # --- System Limit Tweak ---
    backup_file "/etc/sysctl.conf"
    if ! grep -q "fs.inotify.max_user_watches" /etc/sysctl.conf; then
        echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
        sysctl -p || log_warning "Gagal reload sysctl"
    fi

    # --- Firewall (UFW) ---
    log_info "Mengonfigurasi Firewall (UFW)..."
    if command_exists ufw; then
        [ -d /etc/ufw ] && backup_file "/etc/ufw/user.rules"
        
        ufw --force reset || log_warning "UFW reset gagal"
        ufw allow 22/tcp comment 'SSH'
        ufw allow 3389/tcp comment 'XRDP'
        ufw --force enable
        log_success "UFW dikonfigurasi dan diaktifkan"
    else
        log_warning "UFW tidak tersedia, skip firewall setup"
    fi
    
    log_success "System setup selesai"
}

