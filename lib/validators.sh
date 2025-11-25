#!/bin/bash

# ==============================================================================
# Validators Library
# ==============================================================================
# Pre-flight checks dan validasi sebelum instalasi
# ==============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Skrip ini harus dijalankan sebagai root (gunakan sudo)."
        exit 1
    fi
}

check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid
        pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "unknown")
        log_error "Script sudah berjalan (PID: $pid) atau lock file tersisa."
        log_error "Jika yakin tidak ada instance lain, hapus: rm $LOCK_FILE"
        exit 1
    fi
    echo $$ > "$LOCK_FILE"
}

check_disk_space() {
    log_info "Memeriksa disk space..."
    local available_gb
    available_gb=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
    
    if [ "$available_gb" -lt 10 ]; then
        log_error "Disk space tidak cukup! Tersedia: ${available_gb}GB, minimal 10GB diperlukan."
        exit 1
    fi
    log_success "Disk space OK: ${available_gb}GB tersedia"
}

check_memory() {
    log_info "Memeriksa RAM..."
    local total_ram_mb
    total_ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    
    if [ "$total_ram_mb" -lt 1024 ]; then
        log_warning "RAM kurang dari 1GB (${total_ram_mb}MB). Instalasi mungkin lambat."
    else
        log_success "RAM OK: ${total_ram_mb}MB"
    fi
}

check_internet() {
    log_info "Memeriksa koneksi internet..."
    local test_urls=("8.8.8.8" "1.1.1.1" "packages.debian.org")
    local success=false
    
    for url in "${test_urls[@]}"; do
        if ping -c 1 -W 3 "$url" &>/dev/null; then
            success=true
            break
        fi
    done
    
    if [ "$success" = false ]; then
        log_error "Tidak ada koneksi internet! Instalasi memerlukan internet."
        exit 1
    fi
    log_success "Koneksi internet OK"
}

check_debian_version() {
    log_info "Memeriksa versi Debian..."
    if [ ! -f /etc/debian_version ]; then
        log_error "Ini bukan sistem Debian! Script ini hanya untuk Debian 12/13."
        exit 1
    fi
    
    local version
    version=$(cat /etc/debian_version | cut -d. -f1)
    if [ "$version" != "12" ] && [ "$version" != "13" ]; then
        log_warning "Debian versi $version terdeteksi. Script dioptimalkan untuk Debian 12/13."
        log_warning "Lanjutkan dengan risiko Anda sendiri."
    else
        log_success "Debian $version terdeteksi - OK"
    fi
}

validate_password() {
    log_info "Memvalidasi password..."
    local pass="$DEV_USER_PASSWORD"
    local pass_len=${#pass}
    
    if [ "$pass_len" -lt 8 ]; then
        log_error "Password terlalu pendek (minimum 8 karakter)!"
        log_error "Set dengan: DEV_USER_PASSWORD='YourStrongPass123!' ./setup.sh"
        exit 1
    fi
    
    # Check complexity (at least one uppercase, lowercase, digit)
    if ! echo "$pass" | grep -q '[A-Z]' || \
       ! echo "$pass" | grep -q '[a-z]' || \
       ! echo "$pass" | grep -q '[0-9]'; then
        log_warning "Password lemah! Sebaiknya gunakan kombinasi huruf besar, kecil, dan angka."
    fi
    
    log_success "Password validation OK"
}

validate_username() {
    log_info "Memvalidasi username..."
    # Check if username is valid (alphanumeric and underscore only)
    if ! echo "$DEV_USER" | grep -qE '^[a-z][a-z0-9_-]*$'; then
        log_error "Username tidak valid: $DEV_USER"
        log_error "Username harus: diawali huruf kecil, hanya huruf kecil/angka/underscore/dash"
        exit 1
    fi
    
    # Reserved usernames
    local reserved=("root" "admin" "administrator" "system" "daemon")
    for name in "${reserved[@]}"; do
        if [ "$DEV_USER" = "$name" ]; then
            log_error "Username '$name' adalah reserved username. Pilih yang lain."
            exit 1
        fi
    done
    
    log_success "Username validation OK"
}

# Run all pre-flight checks
run_preflight_checks() {
    log_info "=== Running Pre-flight Checks ==="
    check_root
    check_lock
    validate_username
    validate_password
    check_debian_version
    check_disk_space
    check_memory
    check_internet
    create_backup_dir
    echo ""
}

