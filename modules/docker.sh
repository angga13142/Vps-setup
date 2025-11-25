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
    
    # Clean cache after update to free memory before installation
    apt-get clean -qq 2>/dev/null || true
    
    # Install Docker components in stages to reduce memory pressure
    # Best practice: Install core components first, then plugins
    # Stage 1: Install containerd.io (runtime dependency)
    if ! dpkg-query -W -f='${Status}' containerd.io 2>/dev/null | grep -q "install ok installed"; then
        ensure_swap_active
        run_with_progress "Installing containerd.io (Docker runtime)" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends containerd.io" || {
            log_error "Failed to install containerd.io"
            return 1
        }
        apt-get clean -qq 2>/dev/null || true
    fi
    
    # Stage 2: Install docker-ce and docker-ce-cli together (core components)
    local docker_core=""
    if ! dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -q "install ok installed"; then
        docker_core="docker-ce"
    fi
    if ! dpkg-query -W -f='${Status}' docker-ce-cli 2>/dev/null | grep -q "install ok installed"; then
        if [ -z "$docker_core" ]; then
            docker_core="docker-ce-cli"
        else
            docker_core="$docker_core docker-ce-cli"
        fi
    fi
    
    if [ -n "$docker_core" ]; then
        ensure_swap_active
        run_with_progress "Installing Docker Engine core: $docker_core" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends $docker_core" || {
            log_warning "Failed to install Docker core with --no-install-recommends, trying without..."
            run_with_progress "Installing Docker Engine core (retry): $docker_core" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $docker_core" || {
                log_error "Failed to install Docker Engine core"
                return 1
            }
        }
        apt-get clean -qq 2>/dev/null || true
    fi
    
    # Stage 3: Install plugins (less critical, can be installed separately)
    local docker_plugins=""
    if ! dpkg-query -W -f='${Status}' docker-buildx-plugin 2>/dev/null | grep -q "install ok installed"; then
        docker_plugins="docker-buildx-plugin"
    fi
    if ! dpkg-query -W -f='${Status}' docker-compose-plugin 2>/dev/null | grep -q "install ok installed"; then
        if [ -z "$docker_plugins" ]; then
            docker_plugins="docker-compose-plugin"
        else
            docker_plugins="$docker_plugins docker-compose-plugin"
        fi
    fi
    
    if [ -n "$docker_plugins" ]; then
        ensure_swap_active
        run_with_progress "Installing Docker plugins: $docker_plugins" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends $docker_plugins" || {
            log_warning "Failed to install Docker plugins with --no-install-recommends, trying without..."
            run_with_progress "Installing Docker plugins (retry): $docker_plugins" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $docker_plugins" || {
                log_warning "Failed to install Docker plugins, continuing without them..."
            }
        }
        apt-get clean -qq 2>/dev/null || true
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
