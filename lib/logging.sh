#!/bin/bash

# ==============================================================================
# Logging Library
# ==============================================================================
# Fungsi-fungsi untuk logging dengan warna dan file output
# ==============================================================================

# --- Logging Functions with File Support ---
log_info() {
    local msg="[INFO] $1"
    echo -e "\033[1;34m${msg}\033[0m" | tee -a "$LOG_FILE"
}

log_success() {
    local msg="[SUCCESS] $1"
    echo -e "\033[1;32m${msg}\033[0m" | tee -a "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] $1"
    echo -e "\033[1;31m${msg}\033[0m" | tee -a "$LOG_FILE" >&2
}

log_warning() {
    local msg="[WARNING] $1"
    echo -e "\033[1;33m${msg}\033[0m" | tee -a "$LOG_FILE"
}

# --- Progress Tracking ---
update_progress() {
    local step="$1"
    echo "$step" > "$PROGRESS_FILE"
    log_info "Progress: $step"
}

# --- Cleanup Function (Called on Exit/Error) ---
cleanup_on_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Script gagal dengan exit code: $exit_code"
        log_error "Lihat log lengkap di: $LOG_FILE"
        log_error "Backup config ada di: $BACKUP_DIR (jika ada)"
        
        # Baca progress terakhir
        if [ -f "$PROGRESS_FILE" ]; then
            local last_step
            last_step=$(cat "$PROGRESS_FILE")
            log_error "Gagal pada step: $last_step"
        fi
    fi
    
    # Cleanup lock file
    rm -f "$LOCK_FILE"
    rm -f "$PROGRESS_FILE"
}

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
    
    log_info "=== VPS Remote Dev Bootstrap v2.0 (Modular Edition) ==="
    log_info "Log file: $LOG_FILE"
    log_info "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

