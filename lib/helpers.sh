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

