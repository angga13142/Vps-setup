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

# --- Cleanup Function (Called on Exit/Error/Signal) ---
cleanup_on_error() {
    local exit_code=$?
    
    # Stop spinner if running (must be done first to clean up terminal)
    if [ -n "$_SPINNER_PID" ] && kill -0 "$_SPINNER_PID" 2>/dev/null; then
        kill "$_SPINNER_PID" 2>/dev/null
        wait "$_SPINNER_PID" 2>/dev/null
        _SPINNER_PID=""
        echo -ne "\b \b\r"  # Clear spinner and return to start of line
    fi
    
    # Handle different exit codes
    if [ $exit_code -eq 0 ]; then
        # Normal exit - just cleanup
        :
    elif [ $exit_code -eq 130 ] || [ $exit_code -eq 143 ]; then
        # SIGINT (130 = 128 + 2) or SIGTERM (143 = 128 + 15) - user interrupt
        echo ""
        log_warning "Script di-interrupt oleh user (exit code: $exit_code)"
        log_info "Cleanup sedang dilakukan..."
    else
        # Other errors
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

