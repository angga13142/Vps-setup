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
    
    # Clean apt cache
    apt-get clean
    rm -rf /var/lib/apt/lists/download.docker.com*

    # Setup Docker repo directory
    install -m 0755 -d /etc/apt/keyrings
    
    # Install Docker GPG key using helper function
    if ! install_gpg_key "https://download.docker.com/linux/debian/gpg" "/etc/apt/keyrings/docker.gpg" "Docker"; then
        return 1
    fi

    # Create Docker repo list
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $DEBIAN_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update apt with error handling
    log_info "Updating apt cache..."
    if ! apt-get update 2>&1 | tee /tmp/apt-docker-update.log; then
        log_warning "Apt update had issues, checking if we can continue..."
        # Check if it's just warnings
        if grep -qi "error" /tmp/apt-docker-update.log; then
            log_error "Critical apt update errors detected"
            cat /tmp/apt-docker-update.log
            return 1
        fi
    fi
    
    # Install Docker components
    check_and_install "docker-ce"
    check_and_install "docker-ce-cli"
    check_and_install "containerd.io"
    check_and_install "docker-buildx-plugin"
    check_and_install "docker-compose-plugin"

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

