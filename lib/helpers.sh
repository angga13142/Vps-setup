#!/bin/bash

# ==============================================================================
# Helper Functions Library
# ==============================================================================
# Utility functions yang digunakan di berbagai module
# ==============================================================================

# --- Loading Animation Helper ---
# Global variable untuk menyimpan PID spinner
_SPINNER_PID=""

# Start loading spinner in background
start_spinner() {
    local message="$1"
    local spinner_chars="/-\|"
    local delay=0.1
    
    # Print message without newline
    echo -ne "\033[1;34m[INFO] ${message}\033[0m "
    
    # Start spinner in background
    (
        while true; do
            for char in $spinner_chars; do
                echo -ne "\b$char"
                sleep $delay
            done
        done
    ) &
    
    _SPINNER_PID=$!
}

# Stop loading spinner
stop_spinner() {
    if [ -n "$_SPINNER_PID" ]; then
        kill $_SPINNER_PID 2>/dev/null
        wait $_SPINNER_PID 2>/dev/null
        _SPINNER_PID=""
        echo -ne "\b \b"  # Clear spinner character
    fi
}

# Run command with progress indicator and limited verbose output
run_with_progress() {
    local message="$1"
    shift
    local cmd="$@"
    
    # Start spinner
    start_spinner "$message"
    
    # Create temporary file for command output
    local tmp_output=$(mktemp)
    local tmp_error=$(mktemp)
    
    # Run command, capture all output
    if eval "$cmd" > "$tmp_output" 2> "$tmp_error"; then
        local exit_code=0
    else
        local exit_code=$?
    fi
    
    # Stop spinner
    stop_spinner
    
    # Show last 3 lines of output if there's any (filter out common apt noise)
    local verbose_lines=0
    if [ -s "$tmp_output" ] || [ -s "$tmp_error" ]; then
        # Combine stdout and stderr, filter and show last 3 meaningful lines
        {
            [ -s "$tmp_output" ] && cat "$tmp_output"
            [ -s "$tmp_error" ] && cat "$tmp_error"
        } | grep -vE "^(Reading|Preparing|Unpacking|Setting up|Processing triggers|Get:|Fetched|Selecting|Building|Need to get|After this|Do you want|WARNING: apt does not)" | \
          grep -vE "^$" | \
          tail -n 3 | \
          while IFS= read -r line; do
              if [ -n "$line" ] && [ $verbose_lines -lt 3 ]; then
                  echo -e "  \033[0;36m${line}\033[0m"
                  verbose_lines=$((verbose_lines + 1))
              fi
          done
    fi
    
    # Cleanup
    rm -f "$tmp_output" "$tmp_error"
    
    # Show result
    if [ $exit_code -eq 0 ]; then
        echo -e "\r\033[1;32m[SUCCESS] ${message}\033[0m"
        return 0
    else
        echo -e "\r\033[1;31m[ERROR] ${message} (exit code: $exit_code)\033[0m"
        return $exit_code
    fi
}

# --- Package Management Helper ---
check_and_install() {
    local pkg="$1"
    # Check if package is installed (status 'ii' means installed correctly)
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        echo -e "\033[1;34m[INFO] Paket '$pkg' sudah terinstal. Melewati...\033[0m"
    else
        run_with_progress "Menginstal paket: $pkg" "apt-get install -y --reinstall '$pkg'"
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

