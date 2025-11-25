#!/bin/bash

# ==============================================================================
# Helper Functions Library
# ==============================================================================
# Utility functions yang digunakan di berbagai module
# ==============================================================================

# --- Loading Animation Helper ---
# Global variable untuk menyimpan PID spinner
_SPINNER_PID=""

# Start loading spinner in background (npm-style)
start_spinner() {
    local message="$1"
    # npm-style spinner using Braille pattern dots (Unicode)
    # Characters: ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏
    local spinner_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local delay=0.08
    
    # Print message on new line, then spinner on same line with space
    echo -e "\033[1;34m[INFO] ${message}\033[0m"
    echo -ne "  "
    
    # Start spinner in background with proper error handling
    (
        # Ignore signals in spinner process to prevent interference
        trap '' INT TERM
        # Redirect errors to /dev/null to prevent spinner errors from affecting main script
        exec 2>/dev/null
        
        while true; do
            for char in "${spinner_chars[@]}"; do
                # Check if parent process still exists
                if ! kill -0 $$ 2>/dev/null; then
                    exit 0
                fi
                echo -ne "\b\b $char" 2>/dev/null || exit 0
                sleep $delay 2>/dev/null || exit 0
            done
        done
    ) &
    
    _SPINNER_PID=$!
}

# Stop loading spinner
stop_spinner() {
    if [ -n "$_SPINNER_PID" ]; then
        # Check if process still exists
        if kill -0 "$_SPINNER_PID" 2>/dev/null; then
            # Send TERM signal first (graceful)
            kill -TERM "$_SPINNER_PID" 2>/dev/null
            # Wait briefly for graceful shutdown
            sleep 0.1 2>/dev/null
            # If still running, force kill
            if kill -0 "$_SPINNER_PID" 2>/dev/null; then
                kill -KILL "$_SPINNER_PID" 2>/dev/null
            fi
            wait "$_SPINNER_PID" 2>/dev/null
        fi
        _SPINNER_PID=""
        # Clear spinner character (2 chars: space + spinner) and return to start of line
        echo -ne "\b\b  \r" 2>/dev/null || true
    fi
}

# Run command with progress indicator and limited verbose output
run_with_progress() {
    local message="$1"
    shift
    local cmd="$@"
    
    # Dry-run mode: just show what would be executed
    if [ "${DRY_RUN_MODE:-false}" = "true" ]; then
        echo ""
        echo -e "\033[1;33m[DRY-RUN] ${message}\033[0m"
        echo -e "\033[0;33m  Would execute: ${cmd}\033[0m"
        return 0
    fi
    
    # Start spinner
    start_spinner "$message"
    
    # Create temporary file for command output
    local tmp_output=$(mktemp)
    local tmp_error=$(mktemp)
    
    # Run command, capture all output
    # Capture exit code without stopping script execution
    local exit_code=0
    eval "$cmd" > "$tmp_output" 2> "$tmp_error" || exit_code=$?
    
    # Always stop spinner, even if command failed or was interrupted
    stop_spinner
    
    # Show verbose output only if VERBOSE_MODE is enabled
    if [ "${VERBOSE_MODE:-false}" = "true" ]; then
        # Show last 3 meaningful lines of output if there's any (filter out common apt noise)
        if [ -s "$tmp_output" ] || [ -s "$tmp_error" ]; then
            # Combine stdout and stderr, filter out common apt messages, show last 3 lines
            {
                [ -s "$tmp_output" ] && cat "$tmp_output"
                [ -s "$tmp_error" ] && cat "$tmp_error"
            } | grep -vE "^(Reading|Preparing|Unpacking|Setting up|Processing triggers|Get:|Fetched|Selecting|Building|Need to get|After this|Do you want|WARNING: apt does not)" | \
              grep -vE "^$" | \
              tail -n 3 | \
              while IFS= read -r line; do
                  if [ -n "$line" ]; then
                      echo -e "  \033[0;36m${line}\033[0m"
                  fi
              done
        fi
    fi
    
    # Show result (on new line after spinner)
    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "\033[1;32m[SUCCESS] ${message}\033[0m"
        # Cleanup
        rm -f "$tmp_output" "$tmp_error"
        return 0
    else
        echo ""
        echo -e "\033[1;31m[ERROR] ${message} (exit code: $exit_code)\033[0m"
        # In verbose mode, show error output even on failure
        if [ "${VERBOSE_MODE:-false}" = "true" ] && [ -s "$tmp_error" ]; then
            echo -e "\033[0;31mError details:\033[0m"
            cat "$tmp_error" | head -n 10 | while IFS= read -r line; do
                echo -e "  \033[0;31m${line}\033[0m"
            done
        fi
        # Cleanup
        rm -f "$tmp_output" "$tmp_error"
        return $exit_code
    fi
}

# --- Package Management Helper ---
check_and_install() {
    local pkg="$1"
    
    # Dry-run mode: just check and report
    if [ "${DRY_RUN_MODE:-false}" = "true" ]; then
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            echo -e "\033[1;34m[DRY-RUN] Paket '$pkg' sudah terinstal. Melewati...\033[0m"
        else
            echo -e "\033[1;33m[DRY-RUN] Would install package: $pkg\033[0m"
        fi
        return 0
    fi
    
    # Check if package is installed (status 'ii' means installed correctly)
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        echo -e "\033[1;34m[INFO] Paket '$pkg' sudah terinstal. Melewati...\033[0m"
    else
        # Ensure swap is active and clean cache before installation
        ensure_swap_active
        apt-get clean -qq 2>/dev/null || true
        # Use memory-optimized installation flags
        run_with_progress "Menginstal paket: $pkg" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends --reinstall '$pkg'" || {
            # Fallback: try without --no-install-recommends if it fails
            run_with_progress "Menginstal paket: $pkg (retry)" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --reinstall '$pkg'"
        }
        # Clean cache after installation
        apt-get clean -qq 2>/dev/null || true
    fi
}

# --- Backup Functions ---
create_backup_dir() {
    # Dry-run mode: just report
    if [ "${DRY_RUN_MODE:-false}" = "true" ]; then
        echo -e "\033[1;33m[DRY-RUN] Would create backup directory: $BACKUP_DIR\033[0m"
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    log_info "Backup directory: $BACKUP_DIR"
}

backup_file() {
    local file="$1"
    
    # Dry-run mode: just report
    if [ "${DRY_RUN_MODE:-false}" = "true" ]; then
        if [ -f "$file" ]; then
            echo -e "\033[1;33m[DRY-RUN] Would backup file: $file\033[0m"
        else
            echo -e "\033[1;34m[DRY-RUN] File does not exist: $file (skip backup)\033[0m"
        fi
        return 0
    fi
    
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
    
    # Dry-run mode: just report
    if [ "${DRY_RUN_MODE:-false}" = "true" ]; then
        if systemctl list-unit-files 2>/dev/null | grep -q "$service"; then
            echo -e "\033[1;33m[DRY-RUN] Would enable and start service: $service\033[0m"
        else
            echo -e "\033[1;34m[DRY-RUN] Service $service not found\033[0m"
        fi
        return 0
    fi
    
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
    local cmd="$@"
    
    # Dry-run mode: just report
    if [ "${DRY_RUN_MODE:-false}" = "true" ]; then
        echo -e "\033[1;33m[DRY-RUN] Would run as user '$user': ${cmd}\033[0m"
        return 0
    fi
    
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
            rm -f /etc/apt/keyrings/docker.asc
            rm -f /etc/apt/keyrings/docker.asc~
            rm -f /etc/apt/sources.list.d/docker.list
            rm -f /etc/apt/sources.list.d/docker.list.save
            rm -f /etc/apt/sources.list.d/docker.sources
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

# --- Swap Management Helper ---
ensure_swap_active() {
    # Dry-run mode: just check and report
    if [ "${DRY_RUN_MODE:-false}" = "true" ]; then
        if grep -q "swapfile" /etc/fstab; then
            if ! swapon --show | grep -q swapfile; then
                if [ -f /swapfile ]; then
                    echo -e "\033[1;33m[DRY-RUN] Would activate swap file\033[0m"
                else
                    echo -e "\033[1;34m[DRY-RUN] Swap file not found: /swapfile\033[0m"
                fi
            else
                echo -e "\033[1;34m[DRY-RUN] Swap already active\033[0m"
            fi
        else
            echo -e "\033[1;34m[DRY-RUN] No swapfile configured\033[0m"
        fi
        return 0
    fi
    
    # Ensure swap is active to prevent OOM kill
    if grep -q "swapfile" /etc/fstab; then
        if ! swapon --show | grep -q swapfile; then
            if [ -f /swapfile ]; then
                swapon /swapfile || log_warning "Gagal mengaktifkan swap file"
            fi
        fi
    fi
}

# --- Memory Management Helper ---
# Wait for sufficient memory before proceeding
wait_for_memory() {
    local required_mb=${1:-300}  # Default 300MB required
    local max_wait=${2:-60}       # Max wait 60 seconds
    
    # Dry-run mode: just check and report
    if [ "${DRY_RUN_MODE:-false}" = "true" ]; then
        local available_mb
        available_mb=$(free -m | awk '/^Mem:/ {print $7}')
        if [ "$available_mb" -gt "$required_mb" ]; then
            echo -e "\033[1;34m[DRY-RUN] Memory check: ${available_mb}MB available (need ${required_mb}MB) ✓\033[0m"
            return 0
        else
            echo -e "\033[1;33m[DRY-RUN] Memory check: ${available_mb}MB available (need ${required_mb}MB) - would wait\033[0m"
            return 0
        fi
    fi
    
    local waited=0
    while [ $waited -lt $max_wait ]; do
        local available_mb
        available_mb=$(free -m | awk '/^Mem:/ {print $7}')
        if [ "$available_mb" -gt "$required_mb" ]; then
            return 0
        fi
        log_warning "Low memory (${available_mb}MB free, need ${required_mb}MB), waiting for memory to clear..."
        sleep 5
        waited=$((waited + 5))
        
        # Force cleanup
        sync
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
    done
    
    log_error "Insufficient memory after waiting ${max_wait}s (need ${required_mb}MB)"
    return 1
}

# --- Batch Package Installation Helper (OOM Prevention) ---
batch_install_packages() {
    local packages_list="$1"
    local description="${2:-packages}"
    
    # Dry-run mode: just check and report
    if [ "${DRY_RUN_MODE:-false}" = "true" ]; then
        local packages_to_install=""
        for pkg in $packages_list; do
            if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
                if [ -z "$packages_to_install" ]; then
                    packages_to_install="$pkg"
                else
                    packages_to_install="$packages_to_install $pkg"
                fi
            fi
        done
        
        if [ -n "$packages_to_install" ]; then
            echo -e "\033[1;33m[DRY-RUN] Would install $description: $packages_to_install\033[0m"
        else
            echo -e "\033[1;34m[DRY-RUN] Semua $description sudah terinstal\033[0m"
        fi
        return 0
    fi
    
    # Ensure swap is active before installing packages
    ensure_swap_active
    
    # Clean apt cache to free memory before installation
    apt-get clean -qq 2>/dev/null || true
    
    # Check which packages are already installed
    local packages_to_install=""
    for pkg in $packages_list; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            if [ -z "$packages_to_install" ]; then
                packages_to_install="$pkg"
            else
                packages_to_install="$packages_to_install $pkg"
            fi
        fi
    done
    
    # Install all missing packages in one batch with memory optimizations
    if [ -n "$packages_to_install" ]; then
        # Use DEBIAN_FRONTEND=noninteractive and --no-install-recommends to reduce memory usage
        # --no-install-recommends: Don't install recommended packages (reduces dependencies)
        # DEBIAN_FRONTEND=noninteractive: Reduces overhead from interactive prompts
        run_with_progress "Installing $description: $packages_to_install" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends $packages_to_install" || {
            log_warning "Batch install gagal, mencoba install satu per satu..."
            # Fallback: install one by one if batch fails
            for pkg in $packages_to_install; do
                ensure_swap_active
                run_with_progress "Installing $pkg" "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends $pkg" || {
                    log_warning "Gagal install $pkg dengan --no-install-recommends, mencoba tanpa flag..."
                    check_and_install "$pkg"
                }
            done
        }
        
        # Clean apt cache after installation to free memory
        apt-get clean -qq 2>/dev/null || true
    else
        log_info "Semua $description sudah terinstal"
    fi
}

