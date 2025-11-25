#!/bin/bash

# ==============================================================================
# Docker Module - Docker Installation (OOM-Resistant Version)
# ==============================================================================

# Helper: Check available memory and wait if too low
wait_for_memory() {
    local required_mb=${1:-300}  # Default 300MB required
    local max_wait=${2:-60}      # Max wait 60 seconds
    local waited=0
    
    log_info "[DEBUG] wait_for_memory: Required ${required_mb}MB, max wait ${max_wait}s"
    
    while [ $waited -lt $max_wait ]; do
        local available_mb=$(free -m | awk '/^Mem:/ {print $7}')
        local swap_free=$(free -m | awk '/^Swap:/ {print $4}')
        local swap_total=$(free -m | awk '/^Swap:/ {print $2}')
        
        # Consider swap in calculation (50% weight)
        local effective_memory=$((available_mb + swap_free / 2))
        
        log_info "[DEBUG] Memory status: ${available_mb}MB RAM free, ${swap_free}MB/${swap_total}MB swap free, effective: ${effective_memory}MB"
        
        if [ "$effective_memory" -gt "$required_mb" ]; then
            log_info "Memory check passed: ${available_mb}MB RAM + ${swap_free}MB swap (effective: ${effective_memory}MB)"
            return 0
        fi
        
        log_warning "Low memory (${available_mb}MB RAM, ${swap_free}MB swap free, effective: ${effective_memory}MB), waiting... (${waited}/${max_wait}s)"
        
        # Aggressive cleanup
        log_info "[DEBUG] Performing aggressive memory cleanup..."
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        apt-get clean -qq 2>/dev/null || true
        
        sleep 5
        waited=$((waited + 5))
    done
    
    log_error "Insufficient memory after waiting ${max_wait}s (required: ${required_mb}MB, effective: ${effective_memory}MB)"
    return 1
}

# Helper: Safe apt-get clean (memory-aware)
safe_apt_clean() {
    local min_memory=${1:-100}  # Minimum memory required (default 100MB)
    
    log_info "[DEBUG] safe_apt_clean: Checking memory before cleanup..."
    local available_mb=$(free -m | awk '/^Mem:/ {print $7}')
    log_info "[DEBUG] Available memory: ${available_mb}MB (required: ${min_memory}MB)"
    
    if [ "$available_mb" -lt "$min_memory" ]; then
        log_warning "[DEBUG] Memory too low (${available_mb}MB < ${min_memory}MB), skipping apt-get clean"
        log_info "[DEBUG] Using direct file removal instead..."
        # Use direct rm instead of apt-get clean (lighter weight)
        rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
        rm -rf /var/cache/apt/archives/partial/*.deb 2>/dev/null || true
        return 0
    fi
    
    # Memory is sufficient, use apt-get clean but with timeout
    log_info "[DEBUG] Memory sufficient, running apt-get clean with timeout..."
    timeout 30 apt-get clean -qq 2>/dev/null || {
        log_warning "[DEBUG] apt-get clean failed or timed out, using direct removal..."
        rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
        rm -rf /var/cache/apt/archives/partial/*.deb 2>/dev/null || true
    }
}

# Helper: Force garbage collection and memory release
force_memory_release() {
    log_info "[DEBUG] force_memory_release: Starting aggressive cleanup..."
    
    # Check memory before cleanup
    local mem_before=$(free -m | awk '/^Mem:/ {print $7}')
    log_info "[DEBUG] Memory before cleanup: ${mem_before}MB free"
    
    # Kill any apt processes that might be hanging
    local apt_procs=$(pgrep -c apt-get 2>/dev/null || echo 0)
    local dpkg_procs=$(pgrep -c dpkg 2>/dev/null || echo 0)
    if [ "$apt_procs" -gt 0 ] || [ "$dpkg_procs" -gt 0 ]; then
        log_warning "[DEBUG] Found hanging processes: apt-get($apt_procs), dpkg($dpkg_procs), killing..."
        pkill -9 apt-get 2>/dev/null || true
        pkill -9 dpkg 2>/dev/null || true
        sleep 1
    fi
    
    # Clean apt thoroughly using safe method
    log_info "[DEBUG] Cleaning apt cache (safe method)..."
    safe_apt_clean 100
    local cache_size=$(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1 || echo "unknown")
    log_info "[DEBUG] APT cache size after cleanup: ${cache_size}"
    
    # Drop all caches
    log_info "[DEBUG] Dropping system caches..."
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    # Check memory after cleanup
    sleep 2
    local mem_after=$(free -m | awk '/^Mem:/ {print $7}')
    local mem_freed=$((mem_after - mem_before))
    log_info "[DEBUG] Memory after cleanup: ${mem_after}MB free (freed: ${mem_freed}MB)"
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
    
    log_info "Installing $package_name... (critical: $is_critical)"
    
    while [ $retry -le $max_retries ]; do
        log_info "[DEBUG] install_package_safe: Attempt $retry/$max_retries for $package_name"
        
        # Wait for sufficient memory
        log_info "[DEBUG] Checking memory before installation..."
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
        log_info "[DEBUG] Ensuring swap is active..."
        ensure_swap_active
        
        # Aggressive pre-installation cleanup (using safe method)
        log_info "[DEBUG] Pre-installation cleanup for $package_name..."
        safe_apt_clean 100
        rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
        sync
        
        # Download package first (separate from install to manage memory)
        log_info "Downloading $package_name..."
        log_info "[DEBUG] Download command: apt-get install --download-only $package_name"
        local download_output
        download_output=$(DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
            --no-install-recommends --no-install-suggests \
            --download-only \
            -o APT::Cache-Limit=25000000 \
            -o Acquire::http::Timeout=30 \
            -o Acquire::ForceIPv4=true \
            "$package_name" 2>&1 | grep -v "^Get:" || true)
        
        if [ $? -ne 0 ]; then
            log_warning "Download failed for $package_name"
            log_warning "[DEBUG] Download error output: ${download_output}"
            force_memory_release
            continue
        else
            log_info "[DEBUG] Download successful for $package_name"
        fi
        
        # Wait and cleanup before actual installation
        log_info "[DEBUG] Pre-installation memory cleanup..."
        force_memory_release
        wait_for_memory 300 60 || {
            log_warning "[DEBUG] Insufficient memory after download, continuing anyway..."
            # Continue anyway, we already downloaded
        }
        
        # Now install the downloaded package
        log_info "[DEBUG] Installing downloaded package $package_name..."
        if run_with_progress "Installing $package_name (attempt $retry/$max_retries)" \
            "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
            --no-install-recommends --no-install-suggests \
            -o APT::Cache-Limit=25000000 \
            -o DPkg::Options::=--force-confold \
            $package_name"; then
            
            log_success "$package_name installed successfully"
            log_info "[DEBUG] Installation successful for $package_name"
            
            # Aggressive post-installation cleanup
            log_info "[DEBUG] Post-installation cleanup..."
            force_memory_release
            
            # Longer stabilization time for large packages
            if [ "$package_name" = "docker-ce" ]; then
                log_info "[DEBUG] Waiting 5s for docker-ce to stabilize..."
                sleep 5
            else
                log_info "[DEBUG] Waiting 3s for package to stabilize..."
                sleep 3
            fi
            
            return 0
        else
            local exit_code=$?
            log_warning "$package_name installation failed (attempt $retry/$max_retries), exit code: $exit_code"
            log_warning "[DEBUG] Installation failed for $package_name, exit code: $exit_code"
            
            # Cleanup after failed attempt
            log_info "[DEBUG] Cleanup after failed installation attempt..."
            force_memory_release
            log_info "[DEBUG] Running dpkg --configure -a..."
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
    local total_mb=$(free -m | awk '/^Mem:/ {print $2}')
    local swap_free=$(free -m | awk '/^Swap:/ {print $4}')
    local swap_total=$(free -m | awk '/^Swap:/ {print $2}')
    
    log_info "[DEBUG] === Docker Installation Memory Check ==="
    log_info "[DEBUG] Total RAM: ${total_mb}MB"
    log_info "[DEBUG] Available RAM: ${available_mb}MB"
    log_info "[DEBUG] Swap total: ${swap_total}MB"
    log_info "[DEBUG] Swap free: ${swap_free}MB"
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
    log_info "[DEBUG] === Stopping Non-Essential Services ==="
    
    # Stop all non-essential services
    log_info "[DEBUG] Stopping snapd services..."
    systemctl stop snapd.service snapd.socket 2>/dev/null && log_info "[DEBUG] snapd stopped" || log_warning "[DEBUG] snapd not running or failed to stop"
    
    log_info "[DEBUG] Stopping unattended-upgrades..."
    systemctl stop unattended-upgrades.service 2>/dev/null && log_info "[DEBUG] unattended-upgrades stopped" || log_warning "[DEBUG] unattended-upgrades not running or failed to stop"
    
    log_info "[DEBUG] Stopping packagekit..."
    systemctl stop packagekit.service 2>/dev/null && log_info "[DEBUG] packagekit stopped" || log_warning "[DEBUG] packagekit not running or failed to stop"
    
    log_info "[DEBUG] Stopping apt-daily services..."
    systemctl stop apt-daily.service apt-daily.timer 2>/dev/null && log_info "[DEBUG] apt-daily stopped" || log_warning "[DEBUG] apt-daily not running or failed to stop"
    
    log_info "[DEBUG] Stopping apt-daily-upgrade services..."
    systemctl stop apt-daily-upgrade.service apt-daily-upgrade.timer 2>/dev/null && log_info "[DEBUG] apt-daily-upgrade stopped" || log_warning "[DEBUG] apt-daily-upgrade not running or failed to stop"
    
    log_info "[DEBUG] Service stop operations completed"
    
    # Clean apt cache aggressively (using safe method)
    log_info "[DEBUG] === Aggressive APT Cache Cleanup ==="
    
    # Check memory before cleanup
    local mem_before_cleanup=$(free -m | awk '/^Mem:/ {print $7}')
    log_info "[DEBUG] Memory before cleanup: ${mem_before_cleanup}MB"
    
    # Use safe apt clean (memory-aware)
    log_info "[DEBUG] Running safe apt-get clean..."
    safe_apt_clean 150 || {
        log_warning "[DEBUG] apt-get clean failed, using direct file removal..."
        rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
        rm -rf /var/cache/apt/archives/partial/*.deb 2>/dev/null || true
    }
    
    log_info "[DEBUG] Removing apt lists..."
    local lists_size=$(du -sh /var/lib/apt/lists 2>/dev/null | cut -f1 || echo "unknown")
    log_info "[DEBUG] APT lists size before removal: ${lists_size}"
    
    # Remove lists in smaller chunks to avoid OOM
    if [ -d /var/lib/apt/lists ]; then
        find /var/lib/apt/lists -type f -name "*.gz" -delete 2>/dev/null || true
        find /var/lib/apt/lists -type f -name "*_Packages" -delete 2>/dev/null || true
        find /var/lib/apt/lists -type f -name "*_Sources" -delete 2>/dev/null || true
        # Only remove all if memory is sufficient
        if [ "$mem_before_cleanup" -gt 200 ]; then
            rm -rf /var/lib/apt/lists/* 2>/dev/null || true
        else
            log_info "[DEBUG] Memory low, keeping some apt lists for stability"
        fi
    fi
    
    log_info "[DEBUG] Removing apt archives (direct removal)..."
    local archives_size=$(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1 || echo "unknown")
    log_info "[DEBUG] APT archives size before removal: ${archives_size}"
    # Direct removal is safer than apt-get clean
    rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
    rm -rf /var/cache/apt/archives/partial/*.deb 2>/dev/null || true
    
    log_info "[DEBUG] Syncing filesystem..."
    sync
    
    local mem_after_cleanup=$(free -m | awk '/^Mem:/ {print $7}')
    local mem_freed_cleanup=$((mem_after_cleanup - mem_before_cleanup))
    log_info "[DEBUG] Memory after cleanup: ${mem_after_cleanup}MB (freed: ${mem_freed_cleanup}MB)"
    log_info "[DEBUG] APT cache cleanup completed"
    
    # Setup Docker repo directory
    install -m 0755 -d /etc/apt/keyrings
    
    # Install Docker GPG key
    log_info "Installing Docker GPG key..."
    log_info "[DEBUG] === Docker GPG Key Installation ==="
    log_info "[DEBUG] GPG key URL: https://download.docker.com/linux/debian/gpg"
    log_info "[DEBUG] GPG key output: /etc/apt/keyrings/docker.gpg"
    
    local gpg_attempt=1
    local gpg_success=false
    while [ $gpg_attempt -le 3 ] && [ "$gpg_success" = false ]; do
        log_info "[DEBUG] GPG key download attempt $gpg_attempt/3"
        if run_with_progress "Downloading Docker GPG key (attempt $gpg_attempt/3)" \
            "curl -fsSL 'https://download.docker.com/linux/debian/gpg' | gpg --dearmor -o '/etc/apt/keyrings/docker.gpg'"; then
            log_info "[DEBUG] GPG key download successful, setting permissions..."
            chmod a+r /etc/apt/keyrings/docker.gpg
            if [ -f /etc/apt/keyrings/docker.gpg ]; then
                local gpg_size=$(stat -c%s /etc/apt/keyrings/docker.gpg 2>/dev/null || echo "unknown")
                log_info "[DEBUG] GPG key file size: ${gpg_size} bytes"
                gpg_success=true
                log_success "Docker GPG key installed successfully"
            else
                log_error "[DEBUG] GPG key file not found after download!"
                gpg_success=false
            fi
        else
            local curl_exit=$?
            log_warning "[DEBUG] GPG key download failed, exit code: $curl_exit"
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
    local docker_arch=$(dpkg --print-architecture)
    log_info "[DEBUG] === Creating Docker Repository ==="
    log_info "[DEBUG] Architecture: $docker_arch"
    log_info "[DEBUG] Debian codename: $DEBIAN_CODENAME"
    log_info "[DEBUG] Repository URL: https://download.docker.com/linux/debian"
    
    echo \
      "deb [arch=$docker_arch signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $DEBIAN_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    if [ -f /etc/apt/sources.list.d/docker.list ]; then
        log_info "[DEBUG] Docker repository file created successfully"
        log_info "[DEBUG] Repository contents:"
        cat /etc/apt/sources.list.d/docker.list | sed 's/^/[DEBUG]   /'
    else
        log_error "[DEBUG] Failed to create Docker repository file!"
        return 1
    fi

    # Update apt with memory optimization
    log_info "Updating package lists (this may take a moment)..."
    log_info "[DEBUG] === APT Update ==="
    log_info "[DEBUG] Checking memory before apt update..."
    wait_for_memory 250 120 || {
        log_error "Insufficient memory for apt update"
        return 1
    }
    
    # Use minimal cache limit for apt update
    log_info "[DEBUG] Running apt-get update with cache limit 25MB..."
    if ! run_with_progress "Updating apt cache for Docker" \
        "DEBIAN_FRONTEND=noninteractive apt-get update -qq \
        -o APT::Cache-Limit=25000000 \
        -o Acquire::http::Timeout=30"; then
        log_error "Apt update failed"
        log_error "[DEBUG] APT update failed, checking for errors..."
        return 1
    else
        log_info "[DEBUG] APT update completed successfully"
    fi
    
    # Aggressive cleanup immediately after update
    log_info "[DEBUG] Post-update memory cleanup..."
    force_memory_release
    
    # Ensure swap is active
    ensure_swap_active
    
    # ============================================================================
    # STAGED INSTALLATION - Install packages one by one with memory management
    # ============================================================================
    
    log_info "Beginning staged Docker installation..."
    log_info "[DEBUG] === Staged Docker Package Installation ==="
    
    # Stage 1: containerd.io (CRITICAL - runtime dependency)
    log_info "[DEBUG] === Stage 1: containerd.io (CRITICAL) ==="
    install_package_safe "containerd.io" "true" || {
        log_error "[DEBUG] Stage 1 failed: containerd.io installation failed"
        return 1
    }
    
    # Stage 2: docker-ce-cli (CRITICAL - required for docker-ce)
    log_info "[DEBUG] === Stage 2: docker-ce-cli (CRITICAL) ==="
    install_package_safe "docker-ce-cli" "true" || {
        log_error "[DEBUG] Stage 2 failed: docker-ce-cli installation failed"
        return 1
    }
    
    # Stage 3: docker-ce (CRITICAL - main engine)
    log_info "[DEBUG] === Stage 3: docker-ce (CRITICAL) ==="
    install_package_safe "docker-ce" "true" || {
        log_error "[DEBUG] Stage 3 failed: docker-ce installation failed"
        return 1
    }
    
    # Stage 4: docker-buildx-plugin (OPTIONAL)
    log_info "[DEBUG] === Stage 4: docker-buildx-plugin (OPTIONAL) ==="
    install_package_safe "docker-buildx-plugin" "false" || {
        log_warning "[DEBUG] Stage 4 failed: docker-buildx-plugin installation failed (non-critical)"
    }
    
    # Stage 5: docker-compose-plugin (OPTIONAL)
    log_info "[DEBUG] === Stage 5: docker-compose-plugin (OPTIONAL) ==="
    install_package_safe "docker-compose-plugin" "false" || {
        log_warning "[DEBUG] Stage 5 failed: docker-compose-plugin installation failed (non-critical)"
    }
    
    log_info "[DEBUG] All Docker package installation stages completed"

    # Add user to docker group
    log_info "[DEBUG] === Adding User to Docker Group ==="
    if ! groups "$DEV_USER" | grep -q docker; then
        log_info "[DEBUG] Adding $DEV_USER to docker group..."
        usermod -aG docker "$DEV_USER"
        log_success "User $DEV_USER ditambahkan ke grup docker"
    else
        log_info "[DEBUG] User $DEV_USER already in docker group"
    fi
    
    # Final cleanup
    log_info "[DEBUG] === Final Cleanup ==="
    apt-get clean -qq 2>/dev/null || true
    rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
    log_info "[DEBUG] Final cleanup completed"
    
    # Verify installation
    log_info "[DEBUG] === Verifying Docker Installation ==="
    if command_exists docker; then
        local docker_version=$(docker --version 2>&1 || echo "unknown")
        log_info "[DEBUG] Docker command found, version: $docker_version"
        log_success "Docker berhasil diinstal: $docker_version"
        
        # Test docker daemon
        log_info "[DEBUG] Testing Docker daemon..."
        if docker info >/dev/null 2>&1; then
            log_info "[DEBUG] Docker daemon is running"
        else
            log_warning "[DEBUG] Docker daemon may not be running (this is OK if service needs to be started)"
        fi
    else
        log_error "Docker tidak terinstal dengan benar"
        log_error "[DEBUG] Docker command not found in PATH"
        return 1
    fi
    
    log_info "[DEBUG] === Docker Setup Completed Successfully ==="
    log_success "Docker setup selesai"
}