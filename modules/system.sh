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

    # --- Swap Configuration (4GB) - CREATE FIRST to prevent OOM during apt-get upgrade ---
    if ! grep -q "swapfile" /etc/fstab; then
        log_info "Mengonfigurasi 4GB Swap (sebelum update sistem untuk mencegah OOM)..."
        
        local available_gb
        available_gb=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
        if [ "$available_gb" -lt 4 ]; then
            log_warning "Space tidak cukup untuk 4GB swap, skip swap creation"
        else
            backup_file "/etc/fstab"
            
            # Use fallocate first (faster, less memory intensive)
            if ! run_with_progress "Creating 4GB swap file" "fallocate -l 4G /swapfile"; then
                log_warning "fallocate gagal, mencoba dd dengan chunking untuk mengurangi memory usage..."
                # Use smaller chunks to reduce memory pressure
                run_with_progress "Creating swap file with dd (chunked)" "dd if=/dev/zero of=/swapfile bs=1M count=0 seek=4096 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=4096" || {
                    log_error "Gagal membuat swap file"
                    return 1
                }
            fi
            
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
        log_info "Swap sudah ada, memastikan swap aktif..."
        # Ensure swap is active even if it exists in fstab
        if ! swapon --show | grep -q swapfile; then
            if [ -f /swapfile ]; then
                swapon /swapfile || log_warning "Gagal mengaktifkan swap file yang sudah ada"
            fi
        fi
    fi

    # Update Repos & Upgrade with retry
    # Use retry logic directly in run_with_progress
    local update_attempt=1
    local update_success=false
    while [ $update_attempt -le 3 ] && [ "$update_success" = false ]; do
        if run_with_progress "Updating package repositories (attempt $update_attempt/3)" "apt-get update -qq"; then
            update_success=true
        else
            if [ $update_attempt -lt 3 ]; then
                log_warning "Apt update gagal, retry dalam 5 detik..."
                sleep 5
            fi
            update_attempt=$((update_attempt + 1))
        fi
    done
    
    if [ "$update_success" = false ]; then
        log_error "Apt update gagal setelah 3 attempts"
        return 1
    fi
    
    run_with_progress "Upgrading system packages" "apt-get upgrade -y -qq" || log_warning "apt-get upgrade mengalami masalah, melanjutkan..."

    # Install Essential Tools
    # Install all packages in one command to reduce memory overhead and prevent OOM
    local ESSENTIAL_PKGS="curl wget git htop ufw unzip build-essential apt-transport-https ca-certificates gnupg lsb-release fail2ban"
    
    log_info "Menginstal essential packages (batch install untuk mengurangi memory usage)..."
    
    # Check which packages are already installed
    local packages_to_install=""
    for pkg in $ESSENTIAL_PKGS; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            if [ -z "$packages_to_install" ]; then
                packages_to_install="$pkg"
            else
                packages_to_install="$packages_to_install $pkg"
            fi
        fi
    done
    
    # Install all missing packages in one batch (more memory efficient)
    if [ -n "$packages_to_install" ]; then
        run_with_progress "Installing essential packages: $packages_to_install" "apt-get install -y -qq $packages_to_install" || {
            log_warning "Batch install gagal, mencoba install satu per satu..."
            # Fallback: install one by one if batch fails
            for pkg in $packages_to_install; do
                check_and_install "$pkg"
            done
        }
    else
        log_info "Semua essential packages sudah terinstal"
    fi

    # Handle libfuse2 (Needed for AppImages)
    if ! dpkg-query -W -f='${Status}' libfuse2t64 2>/dev/null | grep -q "install ok installed"; then
        if ! run_with_progress "Installing libfuse2t64" "apt-get install -y -qq libfuse2t64"; then
            run_with_progress "Installing libfuse2" "apt-get install -y -qq libfuse2" || log_warning "Gagal menginstal libfuse2. AppImage mungkin tidak berjalan."
        fi
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

