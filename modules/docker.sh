#!/bin/bash

# ==============================================================================
# Docker Module - Docker Installation
# ==============================================================================

setup_docker() {
    update_progress "setup_docker"
    log_info "Menginstal Docker..."
    
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

    # Setup Docker repo
    install -m 0755 -d /etc/apt/keyrings
    
    if ! retry_command 3 5 "curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"; then
        log_error "Gagal mendownload Docker GPG key"
        return 1
    fi
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $DEBIAN_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update || {
        log_error "Gagal update apt setelah menambahkan Docker repo"
        return 1
    }
    
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

