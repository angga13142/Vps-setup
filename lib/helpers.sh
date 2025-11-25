#!/bin/bash

# ==============================================================================
# Helper Functions Library
# ==============================================================================
# Utility functions yang digunakan di berbagai module
# ==============================================================================

# --- Package Management Helper ---
check_and_install() {
    local pkg="$1"
    # Check if package is installed (status 'ii' means installed correctly)
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        log_info "Paket '$pkg' sudah terinstal dengan benar. Melewati..."
    else
        log_info "Menginstal/Memperbaiki paket: '$pkg'..."
        # Force reinstall if broken, or install if missing
        apt-get install -y --reinstall "$pkg"
    fi
}

# --- Backup Functions ---
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    log_info "Backup directory: $BACKUP_DIR"
}

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup_path="$BACKUP_DIR$(dirname "$file")"
        mkdir -p "$backup_path"
        cp -a "$file" "$backup_path/"
        log_info "Backed up: $file"
    fi
}

# --- Command Existence Check ---
command_exists() {
    command -v "$1" &>/dev/null
}

# --- Retry Logic Helper ---
retry_command() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    local cmd="$@"
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if eval "$cmd"; then
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                log_warning "Command gagal, retry $attempt/$max_attempts dalam $delay detik..."
                sleep "$delay"
            fi
            attempt=$((attempt + 1))
        fi
    done
    
    return 1
}

# --- Service Management ---
enable_and_start_service() {
    local service="$1"
    
    if ! command_exists systemctl; then
        log_warning "Systemd tidak tersedia, skip service management"
        return 0
    fi
    
    if systemctl list-unit-files 2>/dev/null | grep -q "$service"; then
        systemctl enable "$service" || log_warning "Gagal enable $service"
        systemctl restart "$service" || log_warning "Gagal restart $service"
        
        if systemctl is-active --quiet "$service"; then
            log_success "Service $service berjalan"
        else
            log_warning "Service $service tidak aktif"
        fi
    else
        log_warning "Service $service tidak ditemukan"
    fi
}

# --- User Execution Helper ---
run_as_user() {
    local user="$1"
    shift
    sudo -H -u "$user" "$@"
}

# --- GPG Key Management Helper ---
clean_gpg_keys() {
    local key_name="$1"  # e.g., "docker", "microsoft"
    
    log_info "Cleaning up old $key_name GPG keys..."
    
    # Remove from all possible locations
    rm -f "/etc/apt/keyrings/${key_name}.gpg"
    rm -f "/etc/apt/keyrings/${key_name}.gpg~"
    rm -f "/usr/share/keyrings/${key_name}.gpg"
    rm -f "/etc/apt/trusted.gpg.d/${key_name}.gpg"
    
    # Clean specific patterns
    case "$key_name" in
        "microsoft"|"packages.microsoft")
            rm -f /etc/apt/keyrings/packages.microsoft.gpg
            rm -f /usr/share/keyrings/microsoft.gpg
            rm -f /usr/share/keyrings/packages.microsoft.gpg
            ;;
        "docker")
            rm -f /etc/apt/keyrings/docker.gpg
            rm -f /etc/apt/keyrings/docker.gpg~
            ;;
    esac
}

install_gpg_key() {
    local url="$1"
    local output_path="$2"
    local key_name="$3"
    
    log_info "Installing $key_name GPG key..."
    
    # Ensure directory exists
    mkdir -p "$(dirname "$output_path")"
    
    # Download and install with retry (properly quoted variables to prevent word-splitting)
    if retry_command 3 5 "curl -fsSL \"$url\" | gpg --dearmor -o \"$output_path\""; then
        chmod a+r "$output_path"
        log_success "$key_name GPG key installed successfully"
        return 0
    else
        log_error "Failed to install $key_name GPG key after retries"
        return 1
    fi
}

