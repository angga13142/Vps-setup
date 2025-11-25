#!/bin/bash

# ==============================================================================
# Docker Module - Docker Installation (OOM-Resistant Version)
# ==============================================================================

# Helper: Check available memory and wait if too low
wait_for_memory() {
    local required_mb=${1:-300}  # Default 300MB required
    local max_wait=${2:-60}      # Max wait 60 seconds
    local waited=0
    
    while [ $waited -lt $max_wait ]; do
        local available_mb=$(free -m | awk '/^Mem:/ {print $7}')
        local swap_free=$(free -m | awk '/^Swap:/ {print $4}')
        
        # Consider swap in calculation (50% weight)
        local effective_memory=$((available_mb + swap_free / 2))
        
        if [ "$effective_memory" -gt "$required_mb" ]; then
            log_info "Memory check passed: ${available_mb}MB RAM + ${swap_free}MB swap"
            return 0
        fi
        
        log_warning "Low memory (${available_mb}MB RAM, ${swap_free}MB swap free), waiting..."
        
        # Aggressive cleanup
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        apt-get clean -qq 2>/dev/null || true
        
        sleep 5
        waited=$((waited + 5))
    done
    
    log_error "Insufficient memory after waiting ${max_wait}s"
    return 1
}

# Helper: Force garbage collection and memory release
force_memory_release() {
    log_info "Forcing memory release..."
    
    # Kill any apt processes that might be hanging
    pkill -9 apt-get 2>/dev/null || true
    pkill -9 dpkg 2>/dev/null || true
    
    # Clean apt thoroughly
    apt-get clean -qq 2>/dev/null || true
    rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
    rm -rf /var/cache/apt/archives/partial/*.deb 2>/dev/null || true
    
    # Drop all caches
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    # Give system time to reclaim memory
    sleep 2
}

# Helper: Install single package with memory management
install_package_safe() {
    local package_name="$1"
    local is_critical="${2:-true}"  # true/false
    
    # Dry-run mode: just check and report
    if [ "${DRY_RUN_MODE:-false}" = "true" ]; then
        if dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q "install ok installed"; then
            echo -e "\033[1;34m[DRY-RUN] $package_name already installed, skipping...\033[0m"
        else
            local critical_label=""
            [ "$is_critical" = "true" ] && critical_label=" (CRITICAL)" || critical_label=" (OPTIONAL)"
            echo -e "\033[1;33m[DRY-RUN] Would install package: $package_name$critical_label\033[0m"
            wait_for_memory 400 120  # Check memory in dry-run mode
        fi
        return 0
    fi
    
    local max_retries=3
    local retry=1
    
    # Check if already installed
    if dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q "install ok installed"; then
        log_info "$package_name already installed, skipping..."
        return 0
    fi
    
    log_info "Installing $package_name..."
    
    while [ $retry -le $max_retries ]; do
        # Wait for sufficient memory
        wait_for_memory 400 120 || {
            if [ "$is_critical" = "true" ]; then
                log_error "Cannot proceed with $package_name - insufficient memory"
                return 1
            else
                log_warning "Skipping optional package $package_name due to low memory"
                return 0
            fi
        }
        
        # Ensure swap is active
        ensure_swap_active
        
        # Aggressive pre-installation cleanup
        apt-get clean -qq 2>/dev/null || true
        rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
        sync
        
        # Download package first (separate from install to manage memory)
        log_info "Downloading $package_name..."
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
            --no-install-recommends --no-install-suggests \
            --download-only \
            -o APT::Cache-Limit=25000000 \
            -o Acquire::http::Timeout=30 \
            -o Acquire::ForceIPv4=true \
            "$package_name" 2>&1 | grep -v "^Get:"; then
            
            log_warning "Download failed for $package_name"
            force_memory_release
            continue
        fi
        
        # Wait and cleanup before actual installation
        force_memory_release
        wait_for_memory 300 60 || continue
        
        # Now install the downloaded package
        if run_with_progress "Installing $package_name (attempt $retry/$max_retries)" \
            "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
            --no-install-recommends --no-install-suggests \
            -o APT::Cache-Limit=25000000 \
            -o DPkg::Options::=--force-confold \
            $package_name"; then
            
            log_success "$package_name installed successfully"
            
            # Aggressive post-installation cleanup
            force_memory_release
            
            # Longer stabilization time for large packages
            if [ "$package_name" = "docker-ce" ]; then
                sleep 5
            else
                sleep 3
            fi
            
            return 0
        else
            local exit_code=$?
            log_warning "$package_name installation failed (attempt $retry/$max_retries), exit code: $exit_code"
            
            # Cleanup after failed attempt
            force_memory_release
            dpkg --configure -a 2>/dev/null || true
            
            if [ $retry -lt $max_retries ]; then
                log_info "Retrying in 10 seconds..."
                sleep 10
            fi
            
            retry=$((retry + 1))
        fi
    done
    
    # All retries failed
    if [ "$is_critical" = "true" ]; then
        log_error "Failed to install critical package $package_name after $max_retries attempts"
        return 1
    else
        log_warning "Skipping optional package $package_name after $max_retries failed attempts"
        return 0
    fi
}

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
    
    # Pre-flight memory check
    local available_mb=$(free -m | awk '/^Mem:/ {print $7}')
    log_info "Available memory: ${available_mb}MB"
    
    if [ "$available_mb" -lt 200 ]; then
        log_error "Insufficient memory for Docker installation (need at least 200MB free)"
        log_error "Current: ${available_mb}MB. Please upgrade VPS or close other services."
        return 1
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
    
    # AGGRESSIVE memory optimization
    log_info "Preparing system for Docker installation..."
    
    # Stop all non-essential services
    systemctl stop snapd.service snapd.socket 2>/dev/null || true
    systemctl stop unattended-upgrades.service 2>/dev/null || true
    systemctl stop packagekit.service 2>/dev/null || true
    systemctl stop apt-daily.service apt-daily.timer 2>/dev/null || true
    systemctl stop apt-daily-upgrade.service apt-daily-upgrade.timer 2>/dev/null || true
    
    # Clean apt cache aggressively
    run_with_progress "Cleaning apt cache" "DEBIAN_FRONTEND=noninteractive apt-get clean -qq"
    rm -rf /var/lib/apt/lists/* 2>/dev/null || true
    rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
    sync
    
    # Setup Docker repo directory
    install -m 0755 -d /etc/apt/keyrings
    
    # Install Docker GPG key
    log_info "Installing Docker GPG key..."
    local gpg_attempt=1
    local gpg_success=false
    while [ $gpg_attempt -le 3 ] && [ "$gpg_success" = false ]; do
        if run_with_progress "Downloading Docker GPG key (attempt $gpg_attempt/3)" \
            "curl -fsSL 'https://download.docker.com/linux/debian/gpg' | gpg --dearmor -o '/etc/apt/keyrings/docker.gpg'"; then
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

    # Update apt with memory optimization
    log_info "Updating package lists (this may take a moment)..."
    wait_for_memory 250 120 || {
        log_error "Insufficient memory for apt update"
        return 1
    }
    
    # Use minimal cache limit for apt update
    if ! run_with_progress "Updating apt cache for Docker" \
        "DEBIAN_FRONTEND=noninteractive apt-get update -qq \
        -o APT::Cache-Limit=25000000 \
        -o Acquire::http::Timeout=30"; then
        log_error "Apt update failed"
        return 1
    fi
    
    # Aggressive cleanup immediately after update
    force_memory_release
    
    # Ensure swap is active
    ensure_swap_active
    
    # ============================================================================
    # STAGED INSTALLATION - Install packages one by one with memory management
    # ============================================================================
    
    log_info "Beginning staged Docker installation..."
    
    # Stage 1: containerd.io (CRITICAL - runtime dependency)
    install_package_safe "containerd.io" "true" || return 1
    
    # Stage 2: docker-ce-cli (CRITICAL - required for docker-ce)
    install_package_safe "docker-ce-cli" "true" || return 1
    
    # Stage 3: docker-ce (CRITICAL - main engine)
    install_package_safe "docker-ce" "true" || return 1
    
    # Stage 4: docker-buildx-plugin (OPTIONAL)
    install_package_safe "docker-buildx-plugin" "false"
    
    # Stage 5: docker-compose-plugin (OPTIONAL)
    install_package_safe "docker-compose-plugin" "false"

    # Add user to docker group
    if ! groups "$DEV_USER" | grep -q docker; then
        usermod -aG docker "$DEV_USER"
        log_success "User $DEV_USER ditambahkan ke grup docker"
    fi
    
    # Final cleanup
    apt-get clean -qq 2>/dev/null || true
    rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
    
    # Verify installation
    if command_exists docker; then
        log_success "Docker berhasil diinstal: $(docker --version)"
    else
        log_error "Docker tidak terinstal dengan benar"
        return 1
    fi
    
    log_success "Docker setup selesai"
}