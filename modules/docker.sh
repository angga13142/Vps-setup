#!/bin/bash

# ==============================================================================
# Docker Module - Docker Installation (Fully Refactored for OOM Resistance)
# ==============================================================================

# -----------------------------------------------------------------------------
# Configuration Constants
# -----------------------------------------------------------------------------
readonly MEMORY_THRESHOLD_CRITICAL=200  # MB - minimum to proceed
readonly MEMORY_THRESHOLD_SAFE=400      # MB - safe for operations
readonly MEMORY_CHECK_TIMEOUT=120       # seconds
readonly MAX_INSTALL_RETRIES=3
readonly DOCKER_GPG_URL="https://download.docker.com/linux/debian/gpg"
readonly DOCKER_GPG_KEY="/etc/apt/keyrings/docker.asc"
readonly DOCKER_REPO_FILE="/etc/apt/sources.list.d/docker.sources"

# Package lists
readonly CRITICAL_PACKAGES=("containerd.io" "docker-ce-cli" "docker-ce")
readonly OPTIONAL_PACKAGES=("docker-buildx-plugin" "docker-compose-plugin")
readonly OLD_DOCKER_PACKAGES=("docker" "docker-engine" "docker.io" "containerd" "runc")

# -----------------------------------------------------------------------------
# Memory Management Functions
# -----------------------------------------------------------------------------

# Get current available memory in MB (includes swap calculation)
get_available_memory() {
    local mem_free=$(awk '/^MemAvailable:/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)
    local swap_free=$(awk '/^SwapFree:/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)
    
    # Weight swap at 40% (conservative estimate)
    local effective_memory=$((mem_free + (swap_free * 40 / 100)))
    echo "$effective_memory"
}

# Wait for sufficient memory with exponential backoff
wait_for_memory() {
    local required_mb=${1:-$MEMORY_THRESHOLD_SAFE}
    local max_wait=${2:-$MEMORY_CHECK_TIMEOUT}
    local elapsed=0
    local wait_interval=3
    
    log_info "Checking memory availability (required: ${required_mb}MB)..."
    
    while [ $elapsed -lt $max_wait ]; do
        local available=$(get_available_memory)
        
        if [ "$available" -ge "$required_mb" ]; then
            log_info "Memory check passed: ${available}MB available"
            return 0
        fi
        
        log_warning "Low memory: ${available}MB available, ${required_mb}MB required. Waiting..."
        
        # Aggressive cleanup on each iteration
        perform_memory_cleanup "aggressive"
        
        sleep $wait_interval
        elapsed=$((elapsed + wait_interval))
        
        # Exponential backoff (cap at 10 seconds)
        [ $wait_interval -lt 10 ] && wait_interval=$((wait_interval + 2))
    done
    
    local final_available=$(get_available_memory)
    log_error "Memory timeout after ${max_wait}s (${final_available}MB available, ${required_mb}MB required)"
    return 1
}

# Unified memory cleanup function
perform_memory_cleanup() {
    local mode=${1:-"normal"}  # normal, aggressive, critical
    
    case "$mode" in
        critical)
            log_info "Performing critical memory cleanup..."
            stop_non_essential_services
            clean_apt_cache "aggressive"
            drop_system_caches
            sleep 2
            ;;
        aggressive)
            log_info "Performing aggressive memory cleanup..."
            clean_apt_cache "aggressive"
            drop_system_caches
            sleep 1
            ;;
        *)
            log_info "Performing normal memory cleanup..."
            clean_apt_cache "normal"
            sync
            ;;
    esac
}

# Drop system caches (requires root)
drop_system_caches() {
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
}

# Clean APT cache with memory awareness
clean_apt_cache() {
    local mode=${1:-"normal"}
    
    case "$mode" in
        aggressive)
            # Direct removal to avoid OOM from apt-get clean
            rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
            rm -rf /var/cache/apt/archives/partial/* 2>/dev/null || true
            
            # Remove lists in chunks
            if [ -d /var/lib/apt/lists ]; then
                find /var/lib/apt/lists -type f -name "*.gz" -delete 2>/dev/null || true
                find /var/lib/apt/lists -type f -name "*_Packages" -delete 2>/dev/null || true
            fi
            ;;
        *)
            # Use safe_apt_clean if available, otherwise fallback
            if command -v safe_apt_clean >/dev/null 2>&1; then
                safe_apt_clean 100
            else
                apt-get clean -qq 2>/dev/null || true
            fi
            ;;
    esac
    
    sync
}

# Stop non-essential services
stop_non_essential_services() {
    local services=("snapd.service" "snapd.socket" "unattended-upgrades.service" 
                   "packagekit.service" "apt-daily.timer" "apt-daily-upgrade.timer")
    
    for service in "${services[@]}"; do
        systemctl stop "$service" 2>/dev/null || true
    done
}

# Ensure swap is active
ensure_swap_active() {
    if command -v ensure_swap_active >/dev/null 2>&1; then
        ensure_swap_active
    else
        # Fallback: check if swap is available
        local swap_total=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
        [ "$swap_total" -gt 0 ] || log_warning "No swap space available"
    fi
}

# -----------------------------------------------------------------------------
# Package Installation Functions
# -----------------------------------------------------------------------------

# Check if package is installed
is_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# Install single package with retry logic and memory management
install_package_with_retry() {
    local package_name="$1"
    local is_critical="${2:-true}"
    local retry=1
    
    # Skip if already installed
    if is_package_installed "$package_name"; then
        log_info "$package_name already installed"
        return 0
    fi
    
    log_info "Installing $package_name..."
    
    while [ $retry -le $MAX_INSTALL_RETRIES ]; do
        # Pre-flight checks
        wait_for_memory $MEMORY_THRESHOLD_SAFE $MEMORY_CHECK_TIMEOUT || {
            if [ "$is_critical" = "true" ]; then
                log_error "Insufficient memory for $package_name"
                return 1
            else
                log_warning "Skipping optional package $package_name (low memory)"
                return 0
            fi
        }
        
        ensure_swap_active
        perform_memory_cleanup "aggressive"
        
        # Download phase (separate to manage memory)
        log_info "Downloading $package_name (attempt $retry/$MAX_INSTALL_RETRIES)..."
        if ! download_package "$package_name"; then
            log_warning "Download failed for $package_name"
            handle_failed_attempt "$package_name" $retry
            retry=$((retry + 1))
            continue
        fi
        
        # Install phase
        perform_memory_cleanup "aggressive"
        sleep 2  # Stabilization delay
        
        log_info "Installing $package_name (attempt $retry/$MAX_INSTALL_RETRIES)..."
        if install_downloaded_package "$package_name"; then
            log_success "$package_name installed successfully"
            
            # Post-install cleanup and stabilization
            perform_memory_cleanup "aggressive"
            [ "$package_name" = "docker-ce" ] && sleep 5 || sleep 3
            
            return 0
        else
            log_warning "$package_name installation failed"
            handle_failed_attempt "$package_name" $retry
            retry=$((retry + 1))
        fi
    done
    
    # All retries exhausted
    if [ "$is_critical" = "true" ]; then
        log_error "Failed to install critical package $package_name after $MAX_INSTALL_RETRIES attempts"
        return 1
    else
        log_warning "Skipping optional package $package_name after $MAX_INSTALL_RETRIES attempts"
        return 0
    fi
}

# Download package only
download_package() {
    local package="$1"
    
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        --no-install-recommends \
        --no-install-suggests \
        --download-only \
        -o APT::Cache-Limit=25000000 \
        -o Acquire::http::Timeout=30 \
        -o Acquire::Retries=3 \
        "$package" 2>&1 | grep -v "^Get:" >/dev/null
}

# Install already downloaded package
install_downloaded_package() {
    local package="$1"
    
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        --no-install-recommends \
        --no-install-suggests \
        -o APT::Cache-Limit=25000000 \
        -o DPkg::Options::=--force-confold \
        -o DPkg::Options::=--force-confdef \
        "$package" >/dev/null 2>&1
}

# Handle failed installation attempt
handle_failed_attempt() {
    local package="$1"
    local attempt="$2"
    
    perform_memory_cleanup "critical"
    dpkg --configure -a 2>/dev/null || true
    
    if [ $attempt -lt $MAX_INSTALL_RETRIES ]; then
        log_info "Retrying in 10 seconds..."
        sleep 10
    fi
}

# -----------------------------------------------------------------------------
# Docker Repository Setup Functions
# -----------------------------------------------------------------------------

# Setup Docker GPG key
setup_docker_gpg_key() {
    local attempt=1
    local max_attempts=3
    
    # Ensure prerequisites
    for pkg in ca-certificates curl; do
        if ! is_package_installed "$pkg"; then
            log_info "Installing prerequisite: $pkg"
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$pkg" || return 1
        fi
    done
    
    # Create keyrings directory
    install -m 0755 -d /etc/apt/keyrings
    
    # Download GPG key with retry
    log_info "Installing Docker GPG key..."
    while [ $attempt -le $max_attempts ]; do
        if curl -fsSL "$DOCKER_GPG_URL" -o "$DOCKER_GPG_KEY" 2>/dev/null; then
            chmod a+r "$DOCKER_GPG_KEY"
            
            # Verify key is valid
            if grep -q "BEGIN PGP PUBLIC KEY BLOCK" "$DOCKER_GPG_KEY" 2>/dev/null; then
                log_success "Docker GPG key installed successfully"
                return 0
            else
                log_warning "Downloaded GPG key is invalid"
                rm -f "$DOCKER_GPG_KEY"
            fi
        fi
        
        log_warning "GPG key download failed (attempt $attempt/$max_attempts)"
        [ $attempt -lt $max_attempts ] && sleep 5
        attempt=$((attempt + 1))
    done
    
    log_error "Failed to install Docker GPG key after $max_attempts attempts"
    return 1
}

# Create Docker repository configuration
create_docker_repository() {
    local codename
    
    # Get Debian codename
    if [ -f /etc/os-release ]; then
        codename=$(. /etc/os-release && echo "${VERSION_CODENAME:-$VERSION_ID}")
    else
        codename=$(lsb_release -cs 2>/dev/null || echo "bookworm")
    fi
    
    log_info "Creating Docker repository for Debian $codename..."
    
    # Backup and remove old configurations
    [ -f "$DOCKER_REPO_FILE" ] && backup_file "$DOCKER_REPO_FILE" 2>/dev/null || true
    rm -f /etc/apt/sources.list.d/docker.* 2>/dev/null || true
    
    # Create new repository file (DEB822 format for Debian 12+)
    cat > "$DOCKER_REPO_FILE" <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $codename
Components: stable
Signed-By: $DOCKER_GPG_KEY
EOF
    
    [ -f "$DOCKER_REPO_FILE" ] && log_success "Docker repository configured" || return 1
}

# Update APT with Docker repository
update_apt_with_docker_repo() {
    log_info "Updating package lists..."
    
    # Pre-update cleanup
    perform_memory_cleanup "aggressive"
    wait_for_memory 250 $MEMORY_CHECK_TIMEOUT || {
        log_error "Insufficient memory for apt update"
        return 1
    }
    
    # Run apt-get update
    local update_log=$(mktemp)
    if DEBIAN_FRONTEND=noninteractive apt-get update \
        -o APT::Cache-Limit=25000000 \
        -o Acquire::http::Timeout=30 \
        -o Acquire::Retries=3 \
        2>&1 | tee "$update_log"; then
        
        # Verify Docker repo was fetched
        if grep -qi "download.docker.com" "$update_log" 2>/dev/null; then
            log_success "Package lists updated (Docker repository active)"
            rm -f "$update_log"
            return 0
        else
            log_warning "Docker repository not found in update (may be cached)"
            rm -f "$update_log"
            return 0  # Continue anyway
        fi
    else
        local exit_code=$?
        log_error "APT update failed with exit code: $exit_code"
        
        # Show relevant errors
        if [ -f "$update_log" ]; then
            grep -iE "^E:|error:" "$update_log" 2>/dev/null | head -10 | while read -r line; do
                log_error "  $line"
            done
        fi
        
        rm -f "$update_log"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Docker Setup Functions
# -----------------------------------------------------------------------------

# Remove old Docker versions
remove_old_docker_versions() {
    log_info "Checking for old Docker versions..."
    
    local packages_to_remove=""
    for pkg in "${OLD_DOCKER_PACKAGES[@]}"; do
        if is_package_installed "$pkg"; then
            packages_to_remove="$packages_to_remove $pkg"
        fi
    done
    
    if [ -n "$packages_to_remove" ]; then
        log_info "Removing old Docker packages:$packages_to_remove"
        
        ensure_swap_active
        perform_memory_cleanup "aggressive"
        
        DEBIAN_FRONTEND=noninteractive apt-get purge -y -qq \
            $packages_to_remove 2>/dev/null || log_warning "Some packages could not be removed"
        
        perform_memory_cleanup "aggressive"
        log_success "Old Docker packages removed"
    else
        log_info "No old Docker packages found"
    fi
}

# Install Docker packages in stages
install_docker_packages() {
    log_info "Installing Docker packages..."
    
    # Install critical packages
    for package in "${CRITICAL_PACKAGES[@]}"; do
        install_package_with_retry "$package" "true" || {
            log_error "Failed to install critical package: $package"
            return 1
        }
    done
    
    # Install optional packages (failures are non-fatal)
    for package in "${OPTIONAL_PACKAGES[@]}"; do
        install_package_with_retry "$package" "false" || {
            log_warning "Skipped optional package: $package"
        }
    done
    
    log_success "Docker packages installed successfully"
}

# Configure Docker post-installation
configure_docker_post_install() {
    log_info "Configuring Docker..."
    
    # Start and enable Docker service
    if systemctl start docker 2>/dev/null; then
        log_info "Docker service started"
    fi
    
    if systemctl enable docker 2>/dev/null; then
        log_info "Docker service enabled on boot"
    fi
    
    # Add user to docker group
    if [ -n "${DEV_USER:-}" ] && ! groups "$DEV_USER" 2>/dev/null | grep -q docker; then
        usermod -aG docker "$DEV_USER" 2>/dev/null && {
            log_success "User $DEV_USER added to docker group"
            log_info "Note: User must logout and login to use Docker without sudo"
        }
    fi
    
    # Final cleanup
    perform_memory_cleanup "aggressive"
}

# Verify Docker installation
verify_docker_installation() {
    log_info "Verifying Docker installation..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker command not found"
        return 1
    fi
    
    local version=$(docker --version 2>&1 || echo "unknown")
    log_success "Docker installed: $version"
    
    # Test Docker daemon
    if docker info >/dev/null 2>&1; then
        log_info "Docker daemon is running"
        
        # Optional: Run hello-world test
        log_info "Running hello-world test..."
        if timeout 60 docker run --rm hello-world >/dev/null 2>&1; then
            log_success "Docker hello-world test passed"
        else
            log_warning "Hello-world test failed or timed out (non-critical)"
        fi
    else
        log_warning "Docker daemon not responding (may need restart)"
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Main Setup Function
# -----------------------------------------------------------------------------

setup_docker() {
    update_progress "setup_docker" 2>/dev/null || true
    log_info "Setting up Docker..."
    
    # Check if Docker already installed
    if command -v docker >/dev/null 2>&1; then
        log_info "Docker already installed: $(docker --version 2>/dev/null || echo 'version unknown')"
        configure_docker_post_install
        log_success "Docker setup completed"
        return 0
    fi
    
    # Pre-flight memory check
    local available=$(get_available_memory)
    log_info "Available memory: ${available}MB"
    
    if [ "$available" -lt "$MEMORY_THRESHOLD_CRITICAL" ]; then
        log_error "Insufficient memory for Docker installation"
        log_error "Required: ${MEMORY_THRESHOLD_CRITICAL}MB, Available: ${available}MB"
        log_error "Please upgrade VPS or free up memory"
        return 1
    fi
    
    # Perform installation steps
    perform_memory_cleanup "critical"
    remove_old_docker_versions || return 1
    
    setup_docker_gpg_key || return 1
    create_docker_repository || return 1
    update_apt_with_docker_repo || return 1
    
    perform_memory_cleanup "critical"
    ensure_swap_active
    
    install_docker_packages || return 1
    configure_docker_post_install
    verify_docker_installation || return 1
    
    log_success "Docker setup completed successfully"
    return 0
}

# Export main function
export -f setup_docker