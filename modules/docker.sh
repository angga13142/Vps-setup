#!/bin/bash

# ==============================================================================
# Docker Module - Docker Installation
# ==============================================================================

setup_docker() {
    update_progress "setup_docker"
    log_info "Menginstal Docker..."
    
    # Check if Docker already installed
    if command_exists docker; then
        log_info "Docker sudah terinstal: $(docker --version)"
        
        # Ensure user in docker group
        if ! groups "$DEV_USER" | grep -q docker; then
            usermod -aG docker "$DEV_USER"
            log_success "User $DEV_USER ditambahkan ke grup docker"
        fi
        
        log_success "Docker setup selesai"
        return 0
    fi
    
    # Determine Debian codename
    local DEBIAN_CODENAME
    DEBIAN_CODENAME=$(lsb_release -cs)
    
    # Fallback for Trixie
    if [ "$DEBIAN_CODENAME" == "trixie" ]; then
        log_info "Debian Trixie terdeteksi, menggunakan repo Bookworm untuk kompatibilitas Docker..."
        DEBIAN_CODENAME="bookworm"
    fi

    # Backup existing configs
    [ -f /etc/apt/sources.list.d/docker.list ] && backup_file "/etc/apt/sources.list.d/docker.list"
    
    # Cleanup old configs
    rm -f /etc/apt/sources.list.d/docker.list
    rm -f /etc/apt/sources.list.d/docker.list.save
    
    # Clean GPG keys using helper function
    clean_gpg_keys "docker"
    
    # Clean apt cache (memory optimization)
    run_with_progress "Cleaning apt cache" "DEBIAN_FRONTEND=noninteractive apt-get clean -qq"
    rm -rf /var/lib/apt/lists/download.docker.com*
    
    # Setup Docker repo directory
    install -m 0755 -d /etc/apt/keyrings
    
    # Install Docker GPG key using helper function with progress
    log_info "Installing Docker GPG key..."
    local gpg_attempt=1
    local gpg_success=false
    while [ $gpg_attempt -le 3 ] && [ "$gpg_success" = false ]; do
        if run_with_progress "Downloading Docker GPG key (attempt $gpg_attempt/3)" "curl -fsSL 'https://download.docker.com/linux/debian/gpg' | gpg --dearmor -o '/etc/apt/keyrings/docker.gpg'"; then
            chmod a+r /etc/apt/keyrings/docker.gpg
            gpg_success=true
            log_success "Docker GPG key installed successfully"
        else
            if [ $gpg_attempt -lt 3 ]; then
                log_warning "GPG key download gagal, retry dalam 5 detik..."
                sleep 5
            fi
            gpg_attempt=$((gpg_attempt + 1))
        fi
    done
    
    if [ "$gpg_success" = false ]; then
        log_error "Failed to install Docker GPG key after 3 attempts"
        return 1
    fi

    # Create Docker repo list
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $DEBIAN_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update apt with proper error handling (memory optimized)
    if ! run_with_progress "Updating apt cache for Docker" "DEBIAN_FRONTEND=noninteractive apt-get update -qq"; then
        log_error "Apt update failed. This indicates a problem with package repository configuration"
        log_error "Cannot proceed with Docker installation with corrupted apt state"
        return 1
    fi
    
    # Aggressive memory optimization before Docker installation
    # Stop unnecessary services to free memory
    log_info "Optimizing system memory before Docker installation..."
    systemctl stop snapd.service 2>/dev/null || true
    systemctl stop unattended-upgrades.service 2>/dev/null || true
    
    # Drop caches to free memory (aggressive approach)
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    # Clean cache after update to free memory before installation
    apt-get clean -qq 2>/dev/null || true
    rm -rf /var/lib/apt/lists/* 2>/dev/null || true
    
    # Ensure swap is active
    ensure_swap_active
    
    # Install Docker components ONE BY ONE to minimize peak memory usage
    # This is more memory-efficient than batch installation for large packages
    # Stage 1: Install containerd.io (runtime dependency) - MUST BE FIRST
    if ! dpkg-query -W -f='${Status}' containerd.io 2>/dev/null | grep -q "install ok installed"; then
        log_info "Installing containerd.io (required runtime dependency)..."
        sync
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
        ensure_swap_active
        
        run_with_progress "Installing containerd.io" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends --no-install-suggests containerd.io" || {
            log_error "Failed to install containerd.io"
            return 1
        }
        
        # Clean and sync after each package
        apt-get clean -qq 2>/dev/null || true
        sync
        sleep 2  # Give system time to recover memory
    fi
    
    # Stage 2: Install docker-ce-cli FIRST (smaller, required for docker-ce)
    if ! dpkg-query -W -f='${Status}' docker-ce-cli 2>/dev/null | grep -q "install ok installed"; then
        log_info "Installing docker-ce-cli (required before docker-ce)..."
        sync
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
        ensure_swap_active
        
        run_with_progress "Installing docker-ce-cli" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends --no-install-suggests docker-ce-cli" || {
            log_warning "Failed to install docker-ce-cli with --no-install-recommends, trying without..."
            run_with_progress "Installing docker-ce-cli (retry)" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-suggests docker-ce-cli" || {
                log_error "Failed to install docker-ce-cli"
                return 1
            }
        }
        
        apt-get clean -qq 2>/dev/null || true
        sync
        sleep 2
    fi
    
    # Stage 3: Install docker-ce (main engine) - LARGEST package, install separately
    if ! dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -q "install ok installed"; then
        log_info "Installing docker-ce (Docker Engine - this may take longer)..."
        sync
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
        ensure_swap_active
        
        run_with_progress "Installing docker-ce" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends --no-install-suggests docker-ce" || {
            log_warning "Failed to install docker-ce with --no-install-recommends, trying without..."
            run_with_progress "Installing docker-ce (retry)" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-suggests docker-ce" || {
                log_error "Failed to install docker-ce"
                return 1
            }
        }
        
        apt-get clean -qq 2>/dev/null || true
        sync
        sleep 3  # Longer delay after largest package
    fi
    
    # Stage 4: Install plugins (optional, can skip if memory constrained)
    # Install one at a time to reduce memory pressure
    if ! dpkg-query -W -f='${Status}' docker-buildx-plugin 2>/dev/null | grep -q "install ok installed"; then
        log_info "Installing docker-buildx-plugin (optional)..."
        sync
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
        ensure_swap_active
        
        run_with_progress "Installing docker-buildx-plugin" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends --no-install-suggests docker-buildx-plugin" || {
            log_warning "Failed to install docker-buildx-plugin, continuing without it..."
        }
        
        apt-get clean -qq 2>/dev/null || true
        sync
        sleep 2
    fi
    
    if ! dpkg-query -W -f='${Status}' docker-compose-plugin 2>/dev/null | grep -q "install ok installed"; then
        log_info "Installing docker-compose-plugin (optional)..."
        sync
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
        ensure_swap_active
        
        run_with_progress "Installing docker-compose-plugin" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends --no-install-suggests docker-compose-plugin" || {
            log_warning "Failed to install docker-compose-plugin, continuing without it..."
        }
        
        apt-get clean -qq 2>/dev/null || true
        sync
    fi

    # Add user to docker group
    if ! groups "$DEV_USER" | grep -q docker; then
        usermod -aG docker "$DEV_USER"
        log_success "User $DEV_USER ditambahkan ke grup docker"
    fi
    
    # Verify installation
    if command_exists docker; then
        log_success "Docker berhasil diinstal: $(docker --version)"
    else
        log_error "Docker tidak terinstal dengan benar"
        return 1
    fi
    
    log_success "Docker setup selesai"
}
