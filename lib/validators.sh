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
    log_info "[DEBUG] Checking for existing lock file: $LOCK_FILE"
    
    if [ -f "$LOCK_FILE" ]; then
        local pid
        pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "unknown")
        
        log_info "[DEBUG] Lock file found with PID: $pid"
        
        # Check if --force-lock option is set
        if [ "${FORCE_LOCK:-false}" = "true" ]; then
            log_warning "=== Force Lock Removal ==="
            log_warning "Force removing lock file (--force-lock option enabled)..."
            log_warning "Lock file: $LOCK_FILE"
            log_warning "Previous PID: $pid"
            rm -f "$LOCK_FILE"
            log_success "Lock file removed successfully"
            log_info "Continuing with installation..."
        else
            # Check if PID is still running
            if [ "$pid" != "unknown" ] && [ -n "$pid" ]; then
                log_info "[DEBUG] Checking if PID $pid is still running..."
                
                # Check if process exists and is actually our script
                if kill -0 "$pid" 2>/dev/null; then
                    # Process is running - check if it's actually our script
                    local proc_cmd
                    proc_cmd=$(ps -p "$pid" -o cmd= 2>/dev/null || echo "")
                    local proc_stat
                    proc_stat=$(ps -p "$pid" -o stat= 2>/dev/null || echo "")
                    local proc_time
                    proc_time=$(ps -p "$pid" -o etime= 2>/dev/null || echo "")
                    
                    log_info "[DEBUG] Process found:"
                    log_info "[DEBUG]   PID: $pid"
                    log_info "[DEBUG]   Command: $proc_cmd"
                    log_info "[DEBUG]   Status: $proc_stat"
                    log_info "[DEBUG]   Runtime: $proc_time"
                    
                    if echo "$proc_cmd" | grep -q "setup.sh\|bootstrap.sh"; then
                        log_error "=== Lock File Conflict Detected ==="
                        log_error "Script sudah berjalan dengan PID: $pid"
                        log_error "Lock file: $LOCK_FILE"
                        log_error ""
                        log_error "Process Details:"
                        log_error "  PID: $pid"
                        log_error "  Command: $proc_cmd"
                        log_error "  Status: $proc_stat"
                        log_error "  Runtime: $proc_time"
                        log_error ""
                        log_error "Solusi:"
                        log_error "  1. Tunggu script sebelumnya selesai, atau"
                        log_error "  2. Jika yakin tidak ada instance lain, gunakan:"
                        log_error "     sudo ./setup.sh --force-lock"
                        log_error "  3. Atau hapus manual:"
                        log_error "     sudo rm $LOCK_FILE"
                        exit 1
                    else
                        # PID exists but not our script - stale lock file
                        log_warning "=== Stale Lock File Detected ==="
                        log_warning "Lock file ditemukan dengan PID $pid, tapi bukan script ini"
                        log_warning "Lock file: $LOCK_FILE"
                        log_warning "PID $pid adalah process lain: $proc_cmd"
                        log_warning "Status: $proc_stat"
                        log_warning ""
                        log_warning "Menghapus stale lock file..."
                        rm -f "$LOCK_FILE"
                        log_success "Stale lock file removed successfully"
                    fi
                else
                    # PID not running - stale lock file
                    log_warning "=== Stale Lock File Detected ==="
                    log_warning "Lock file ditemukan dengan PID $pid, tapi process tidak berjalan"
                    log_warning "Lock file: $LOCK_FILE"
                    log_warning "PID: $pid (process tidak ditemukan)"
                    log_warning ""
                    log_warning "Kemungkinan: Script sebelumnya crash atau di-interrupt"
                    log_warning "Menghapus stale lock file..."
                    rm -f "$LOCK_FILE"
                    log_success "Stale lock file removed successfully"
                fi
            else
                # Invalid PID in lock file - stale lock file
                log_warning "=== Invalid Lock File Detected ==="
                log_warning "Lock file ditemukan tapi berisi PID yang tidak valid"
                log_warning "Lock file: $LOCK_FILE"
                log_warning "PID value: '$pid' (invalid)"
                log_warning ""
                log_warning "Menghapus invalid lock file..."
                rm -f "$LOCK_FILE"
                log_success "Invalid lock file removed successfully"
            fi
        fi
    else
        log_info "[DEBUG] No existing lock file found"
    fi
    
    # Create new lock file
    log_info "[DEBUG] Creating new lock file..."
    echo $$ > "$LOCK_FILE"
    if [ -f "$LOCK_FILE" ]; then
        log_info "[DEBUG] Lock file created successfully: $LOCK_FILE"
        log_info "[DEBUG] Current PID: $$"
        log_success "Lock file created (PID: $$)"
    else
        log_error "Failed to create lock file: $LOCK_FILE"
        exit 1
    fi
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

