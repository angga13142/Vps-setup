#!/bin/bash

# ==============================================================================
# VPS Remote Dev Bootstrap - Debian 13 (Trixie/Bookworm)
# ==============================================================================
# Role:       Linux Systems Administrator / DevOps
# Target OS:  Debian 13 (Trixie) / 12 (Bookworm)
# Description: Provisions a complete remote GUI dev environment.
#              (XFCE, XRDP, Docker, Node, Python, VS Code, Cursor)
# Version:    2.0 (Robust Edition)
# ==============================================================================

# --- Configuration Variables ---
# Anda dapat menimpa variabel ini dengan environment variables saat menjalankan skrip.
# Contoh: DEV_USER="angga" ./setup.sh

DEV_USER="${DEV_USER:-developer}"
DEV_USER_PASSWORD="${DEV_USER_PASSWORD:-DevPass123!}"
TIMEZONE="${TIMEZONE:-Asia/Jakarta}"
NODE_VERSION="lts/*"  # Install latest LTS
CURSOR_URL="https://downloader.cursor.sh/linux/appImage/x64"

# --- Internal Variables ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_FILE:-/var/log/vps-bootstrap-$(date +%Y%m%d-%H%M%S).log}"
LOCK_FILE="/var/lock/vps-bootstrap.lock"
BACKUP_DIR="/root/.vps-bootstrap-backups-$(date +%Y%m%d-%H%M%S)"
PROGRESS_FILE="/tmp/vps-bootstrap-progress.txt"

# --- Strict Error Handling ---
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

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

# Register cleanup function
trap cleanup_on_error EXIT

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

# --- Pre-flight Checks ---
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

# --- 1. System Preparation & Optimization ---
setup_system() {
    update_progress "setup_system"
    log_info "Memulai update sistem dan instalasi dependensi dasar..."
    
    # Set Timezone
    if command -v timedatectl &> /dev/null; then
        timedatectl set-timezone "$TIMEZONE" || log_warning "Gagal set timezone"
    else
        log_warning "timedatectl tidak tersedia, skip timezone setup"
    fi

    # Update Repos & Upgrade with retry
    log_info "Updating package repositories..."
    local retry=0
    while [ $retry -lt 3 ]; do
        if apt-get update; then
            break
        else
            retry=$((retry+1))
            log_warning "apt-get update gagal, retry $retry/3..."
            sleep 5
        fi
    done
    
    apt-get upgrade -y || log_warning "apt-get upgrade mengalami masalah, melanjutkan..."

    # Install Essential Tools
    # Split install to handle Trixie/Bookworm quirks better
    # software-properties-common is removed as it's unstable in testing/Trixie and we don't use add-apt-repository
    local ESSENTIAL_PKGS="curl wget git htop ufw unzip build-essential apt-transport-https ca-certificates gnupg lsb-release fail2ban"
    
    log_info "Menginstal essential packages..."
    for pkg in $ESSENTIAL_PKGS; do
        check_and_install "$pkg"
    done

    # Handle libfuse2 (Needed for AppImages) - Robust Logic
    # Try installing libfuse2t64 (Debian 13/Trixie+)
    # If fails, try installing libfuse2 (Debian 12/Bookworm)
    # If both fail, log error but DO NOT EXIT (using || true) to allow script to proceed
    log_info "Mencoba menginstal library FUSE (libfuse2 / libfuse2t64)..."
    if apt-get install -y libfuse2t64 2>/dev/null; then
        log_success "libfuse2t64 berhasil diinstal."
    elif apt-get install -y libfuse2 2>/dev/null; then
        log_success "libfuse2 berhasil diinstal."
    else
        log_warning "Gagal menginstal libfuse2 atau libfuse2t64. AppImage (Cursor) mungkin tidak berjalan."
        log_warning "Namun instalasi komponen lain akan dilanjutkan."
        # Ensure we don't exit due to set -e
        true
    fi

    # --- Swap Configuration (4GB) ---
    if ! grep -q "swapfile" /etc/fstab; then
        log_info "Mengonfigurasi 4GB Swap..."
        
        # Check if we have space for swap
        local available_gb
        available_gb=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
        if [ "$available_gb" -lt 4 ]; then
            log_warning "Space tidak cukup untuk 4GB swap, skip swap creation"
        else
            # Backup fstab before modifying
            backup_file "/etc/fstab"
            
            fallocate -l 4G /swapfile || {
                log_warning "fallocate gagal, mencoba dd..."
                dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress || {
                    log_error "Gagal membuat swap file"
                    return 1
                }
            }
            
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            echo '/swapfile none swap sw 0 0' >> /etc/fstab
            
            # Optimize Swappiness (10 is good for VPS to avoid using swap aggressively)
            backup_file "/etc/sysctl.conf"
            sysctl vm.swappiness=10
            if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
                echo 'vm.swappiness=10' >> /etc/sysctl.conf
            fi
            log_success "Swap 4GB berhasil dikonfigurasi"
        fi
    else
        log_info "Swap sudah ada, melewati..."
    fi

    # --- System Limit Tweak (Crucial for VS Code / Webpack watchers) ---
    backup_file "/etc/sysctl.conf"
    if ! grep -q "fs.inotify.max_user_watches" /etc/sysctl.conf; then
        echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
        sysctl -p || log_warning "Gagal reload sysctl"
    fi

    # --- Firewall (UFW) ---
    log_info "Mengonfigurasi Firewall (UFW)..."
    if command -v ufw &> /dev/null; then
        # Backup UFW rules if exist
        [ -d /etc/ufw ] && backup_file "/etc/ufw/user.rules"
        
        ufw --force reset || log_warning "UFW reset gagal"
        ufw allow 22/tcp comment 'SSH'
        ufw allow 3389/tcp comment 'XRDP'
        # Aktifkan UFW tanpa prompt
        ufw --force enable
        log_success "UFW dikonfigurasi dan diaktifkan"
    else
        log_warning "UFW tidak tersedia, skip firewall setup"
    fi
}

# --- 2. User Management ---
setup_user() {
    update_progress "setup_user"
    log_info "Menyiapkan user non-root: $DEV_USER..."

    # Install sudo if missing (some minimal images don't have it)
    check_and_install "sudo"

    if id "$DEV_USER" &>/dev/null; then
        log_info "User $DEV_USER sudah ada."
        # Update password anyway in case it changed
        echo "$DEV_USER:$DEV_USER_PASSWORD" | chpasswd
        log_info "Password untuk $DEV_USER diupdate."
        
        # Ensure user is in sudo group
        if ! groups "$DEV_USER" | grep -q sudo; then
            usermod -aG sudo "$DEV_USER"
            log_info "User $DEV_USER ditambahkan ke grup sudo."
        fi
    else
        # Create user with proper groups
        useradd -m -s /bin/bash -G sudo "$DEV_USER" || {
            log_error "Gagal membuat user $DEV_USER"
            return 1
        }
        echo "$DEV_USER:$DEV_USER_PASSWORD" | chpasswd
        log_success "User $DEV_USER dibuat."
    fi
    
    # Verify home directory exists and has correct ownership
    if [ ! -d "/home/$DEV_USER" ]; then
        log_error "Home directory /home/$DEV_USER tidak ada!"
        return 1
    fi
    chown -R "$DEV_USER:$DEV_USER" "/home/$DEV_USER"
    
    # Backup existing sudoers config if exists
    [ -f "/etc/sudoers.d/$DEV_USER" ] && backup_file "/etc/sudoers.d/$DEV_USER"
    
    # Enable sudo without password for convenience
    echo "$DEV_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$DEV_USER"
    
    # Crucial: Fix permissions for sudoers file (must be 0440)
    chmod 0440 "/etc/sudoers.d/$DEV_USER"
    
    # Validate sudoers configuration to prevent locking out
    if visudo -c -f "/etc/sudoers.d/$DEV_USER" &>/dev/null; then
        log_success "Konfigurasi sudo untuk $DEV_USER valid."
    else
        log_error "Konfigurasi sudo tidak valid! Menghapus file untuk keamanan."
        rm -f "/etc/sudoers.d/$DEV_USER"
        return 1
    fi
}

# --- 3. Desktop Environment (XFCE & XRDP) ---
setup_desktop() {
    update_progress "setup_desktop"
    log_info "Menginstal XFCE4 dan XRDP..."
    
    # Install XFCE4 (lightweight) & XRDP
    local DESKTOP_PKGS="xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils xrdp"
    for pkg in $DESKTOP_PKGS; do
        check_and_install "$pkg"
    done

    # Add xrdp user to ssl-cert group (Fixes permission issues)
    if getent group ssl-cert > /dev/null; then
        if ! groups xrdp | grep -q ssl-cert; then
            adduser xrdp ssl-cert || log_warning "Gagal menambahkan xrdp ke grup ssl-cert"
        fi
    else
        log_warning "Grup ssl-cert tidak ada, skip"
    fi

    # Configure Xsession for the user to ensure XFCE starts properly
    # We write this to the user's home directory
    local xsession_file="/home/$DEV_USER/.xsession"
    backup_file "$xsession_file"
    
    sudo -u "$DEV_USER" bash -c "echo 'xfce4-session' > $xsession_file" || {
        log_error "Gagal membuat .xsession file"
        return 1
    }
    
    # Set proper permissions
    chmod +x "$xsession_file"
    chown "$DEV_USER:$DEV_USER" "$xsession_file"

    # Restart XRDP to apply changes
    # Wrap in conditional to prevent script exit on containerized environments without systemd
    if command -v systemctl &> /dev/null && systemctl list-unit-files 2>/dev/null | grep -q xrdp; then
        log_info "Mengaktifkan service XRDP..."
        systemctl enable xrdp || log_warning "Gagal enable XRDP (Non-fatal)"
        systemctl restart xrdp || log_warning "Gagal restart XRDP (Non-fatal)"
        
        # Verify XRDP is running
        if systemctl is-active --quiet xrdp; then
            log_success "XRDP service berjalan"
        else
            log_warning "XRDP service tidak berjalan, mungkin perlu manual start"
        fi
    else
        log_warning "Service XRDP tidak ditemukan atau Systemd tidak aktif. Melewati start service..."
    fi
}

# --- 4. Developer Stack (Node, Python, Docker) ---
setup_dev_stack() {
    update_progress "setup_dev_stack"
    log_info "Menginstal Docker..."
    
    # Docker Official Repo
    # Note: For Debian Trixie, we might need to fallback to Bookworm repo if Trixie specific not ready
    local DEBIAN_CODENAME
    DEBIAN_CODENAME=$(lsb_release -cs)
    
    # Safe fallback for testing branch
    if [ "$DEBIAN_CODENAME" == "trixie" ]; then
        # Check if docker has trixie repo, otherwise use bookworm
        log_info "Debian Trixie terdeteksi, menggunakan repo Bookworm untuk kompatibilitas Docker..."
        DEBIAN_CODENAME="bookworm"
    fi

    # Backup existing Docker configs if present
    [ -f /etc/apt/sources.list.d/docker.list ] && backup_file "/etc/apt/sources.list.d/docker.list"

    install -m 0755 -d /etc/apt/keyrings
    
    # Download Docker GPG key with retry
    local retry=0
    while [ $retry -lt 3 ]; do
        if curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
            chmod a+r /etc/apt/keyrings/docker.gpg
            break
        else
            retry=$((retry+1))
            log_warning "Gagal download Docker GPG key, retry $retry/3..."
            sleep 5
        fi
    done
    
    if [ $retry -eq 3 ]; then
        log_error "Gagal mendownload Docker GPG key setelah 3 percobaan"
        return 1
    fi

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $DEBIAN_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update || {
        log_error "Gagal update apt setelah menambahkan Docker repo"
        return 1
    }
    
    check_and_install "docker-ce"
    check_and_install "docker-ce-cli"
    check_and_install "containerd.io"
    check_and_install "docker-buildx-plugin"
    check_and_install "docker-compose-plugin"

    # Add user to docker group
    if ! groups "$DEV_USER" | grep -q docker; then
        usermod -aG docker "$DEV_USER"
        log_success "User $DEV_USER ditambahkan ke grup docker"
    fi
    
    # Verify Docker installation
    if command -v docker &> /dev/null; then
        log_success "Docker berhasil diinstal: $(docker --version)"
    else
        log_error "Docker tidak terinstal dengan benar"
        return 1
    fi

    log_info "Menginstal Python Stack..."
    check_and_install "python3"
    check_and_install "python3-pip"
    check_and_install "python3-venv"
    
    # Verify Python
    if command -v python3 &> /dev/null; then
        log_success "Python berhasil diinstal: $(python3 --version)"
    fi

    log_info "Menginstal Node.js via NVM (sebagai user $DEV_USER)..."
    # Install NVM & Node as the user to avoid permission hell
    sudo -H -u "$DEV_USER" bash <<'EOF' || {
        log_error "Gagal menginstal Node.js via NVM"
        return 1
    }
        set -e
        
        # Download and install NVM
        if [ ! -d "$HOME/.nvm" ]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        else
            echo "NVM sudah terinstal, skip download"
        fi
        
        # Load NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Verify NVM loaded
        if ! command -v nvm &> /dev/null; then
            echo "ERROR: NVM gagal dimuat"
            exit 1
        fi
        
        # Install LTS Node
        nvm install --lts
        nvm use --lts
        nvm alias default lts/*
        
        # Verify Node installation
        if ! command -v node &> /dev/null; then
            echo "ERROR: Node.js tidak terinstal dengan benar"
            exit 1
        fi
        
        echo "Node.js berhasil diinstal: $(node --version)"
        echo "NPM version: $(npm --version)"
        
        # Install global packages (allow errors to not block)
        npm install -g yarn pnpm typescript ts-node || echo "WARNING: Beberapa npm global packages gagal diinstal"
EOF
    
    log_success "Development stack (Docker, Python, Node.js) berhasil diinstal"
}

# --- 5. Code Editors (VS Code & Cursor) ---
setup_editors() {
    update_progress "setup_editors"
    log_info "Menginstal VS Code..."
    
    # Backup existing configs
    [ -f /etc/apt/sources.list.d/vscode.list ] && backup_file "/etc/apt/sources.list.d/vscode.list"
    
    # Clean up potential conflicting legacy repo/keys from previous runs
    rm -f /etc/apt/sources.list.d/vscode.list
    rm -f /etc/apt/keyrings/packages.microsoft.gpg
    rm -f /usr/share/keyrings/microsoft.gpg

    # VS Code Repo Setup with error handling
    local retry=0
    while [ $retry -lt 3 ]; do
        if wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg; then
            install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
            rm -f packages.microsoft.gpg
            break
        else
            retry=$((retry+1))
            log_warning "Gagal download VS Code GPG key, retry $retry/3..."
            sleep 5
        fi
    done
    
    if [ $retry -eq 3 ]; then
        log_warning "Gagal menginstal VS Code setelah 3 percobaan, skip..."
    else
        sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        
        apt-get update || log_warning "Gagal update apt setelah menambahkan VS Code repo"
        check_and_install "code"
        
        # Verify installation
        if command -v code &> /dev/null; then
            log_success "VS Code berhasil diinstal: $(code --version | head -n1)"
        else
            log_warning "VS Code tidak terinstal dengan benar"
        fi
    fi

    log_info "Menginstal Cursor AI Editor..."
    # Setup directory
    mkdir -p /opt/cursor
    
    # Check if libfuse is installed (required for AppImage)
    if ! dpkg -l | grep -qE "libfuse2(t64)?"; then
        log_warning "libfuse2 tidak terinstal, Cursor AppImage mungkin tidak berjalan"
    fi
    
    # Download AppImage
    log_info "Downloading Cursor AppImage..."
    
    # Retry logic for download (5 attempts)
    local RETRY_COUNT=0
    local MAX_RETRIES=5
    local DOWNLOAD_SUCCESS=false
    local TEMP_CURSOR="/tmp/cursor-$$.AppImage"

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -L --progress-bar "$CURSOR_URL" -o "$TEMP_CURSOR"; then
            # Verify download (check file size is reasonable, > 100MB)
            local file_size
            file_size=$(stat -f%z "$TEMP_CURSOR" 2>/dev/null || stat -c%s "$TEMP_CURSOR" 2>/dev/null || echo 0)
            
            if [ "$file_size" -gt 104857600 ]; then  # 100MB in bytes
                mv "$TEMP_CURSOR" /opt/cursor/cursor.AppImage
                DOWNLOAD_SUCCESS=true
                break
            else
                log_warning "Download corrupt (size: $file_size bytes), mencoba lagi..."
                rm -f "$TEMP_CURSOR"
            fi
        fi
        
        log_warning "Download gagal, mencoba lagi dalam 5 detik... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
        sleep 5
        RETRY_COUNT=$((RETRY_COUNT+1))
    done

    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        log_warning "Gagal mengunduh Cursor setelah $MAX_RETRIES percobaan."
        log_warning "Melewati instalasi Cursor. Anda dapat mengunduhnya manual nanti dari: $CURSOR_URL"
        rm -f "$TEMP_CURSOR"
    else
        chmod +x /opt/cursor/cursor.AppImage
        
        # Backup existing desktop entry if exists
        [ -f /usr/share/applications/cursor.desktop ] && backup_file "/usr/share/applications/cursor.desktop"
        
        # Create Desktop Entry
        cat > /usr/share/applications/cursor.desktop <<'EOF'
[Desktop Entry]
Name=Cursor
Comment=AI-first Code Editor
Exec=/opt/cursor/cursor.AppImage --no-sandbox %F
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Development;IDE;
StartupNotify=true
EOF
        
        # Fix ownership
        chown -R "$DEV_USER:$DEV_USER" /opt/cursor
        log_success "Cursor terinstal di /opt/cursor/cursor.AppImage"
        
        # Test if AppImage can be executed
        if /opt/cursor/cursor.AppImage --version &>/dev/null; then
            log_success "Cursor AppImage verified OK"
        else
            log_warning "Cursor AppImage mungkin tidak bisa dijalankan. Cek libfuse2."
        fi
    fi
}

# --- 6. Shell & Polish (Zsh, Oh My Zsh, Nerd Fonts) ---
setup_shell() {
    update_progress "setup_shell"
    log_info "Mengonfigurasi Shell (Zsh & Nerd Fonts)..."

    # Install Zsh
    check_and_install "zsh"
    check_and_install "fonts-powerline"

    # Install Nerd Fonts (Hack)
    log_info "Menginstal Nerd Fonts (Hack)..."
    mkdir -p /usr/local/share/fonts
    local FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip"
    local FONT_ZIP="/tmp/Hack-$$.zip"
    
    local retry=0
    while [ $retry -lt 3 ]; do
        if wget -q --show-progress -O "$FONT_ZIP" "$FONT_URL"; then
            if unzip -o "$FONT_ZIP" -d /usr/local/share/fonts/ &>/dev/null; then
                fc-cache -fv &>/dev/null
                rm -f "$FONT_ZIP"
                log_success "Nerd Fonts (Hack) berhasil diinstal"
                break
            else
                log_warning "Gagal extract font, retry..."
                rm -f "$FONT_ZIP"
            fi
        fi
        retry=$((retry+1))
        sleep 5
    done
    
    if [ $retry -eq 3 ]; then
        log_warning "Gagal menginstal Nerd Fonts setelah 3 percobaan, skip..."
    fi

    # Set Zsh as default for user
    if command -v zsh &> /dev/null; then
        local zsh_path
        zsh_path=$(which zsh)
        
        # Check if zsh is in /etc/shells
        if ! grep -q "$zsh_path" /etc/shells; then
            echo "$zsh_path" >> /etc/shells
        fi
        
        chsh -s "$zsh_path" "$DEV_USER" || log_warning "Gagal set Zsh sebagai default shell"
        log_success "Zsh set sebagai default shell untuk $DEV_USER"
    else
        log_warning "Zsh tidak terinstal, skip set default shell"
    fi

    log_info "Menginstal Oh My Zsh (Unattended)..."
    
    # Ensure user home exists and ownership is correct
    if [ ! -d "/home/$DEV_USER" ]; then
        log_error "Home directory /home/$DEV_USER tidak ditemukan!"
        return 1
    fi
    
    # Install OMZ as user with explicit HOME set
    # We use 'sudo -u user -H' to ensure HOME env var is set correctly
    # We also use a checking logic to avoid reinstalling if already exists
    if [ -d "/home/$DEV_USER/.oh-my-zsh" ]; then
        log_info "Oh My Zsh sudah terinstal di /home/$DEV_USER/.oh-my-zsh. Melewati..."
    else
        # Backup .zshrc if exists
        [ -f "/home/$DEV_USER/.zshrc" ] && backup_file "/home/$DEV_USER/.zshrc"
        
        sudo -H -u "$DEV_USER" bash -c 'RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' || {
            log_warning "Gagal menginstal Oh My Zsh, melanjutkan..."
            return 0
        }
        
        log_success "Oh My Zsh berhasil diinstal"
    fi

    # Verify installation
    if [ -d "/home/$DEV_USER/.oh-my-zsh" ]; then
        chown -R "$DEV_USER:$DEV_USER" "/home/$DEV_USER/.oh-my-zsh"
        log_success "Shell setup complete"
    fi
}

# --- Post-Installation Verification ---
verify_installation() {
    update_progress "verify_installation"
    log_info "Memverifikasi instalasi..."
    
    local errors=0
    local warnings=0
    
    # Check user exists
    if id "$DEV_USER" &>/dev/null; then
        log_success "✓ User $DEV_USER ada"
    else
        log_error "✗ User $DEV_USER tidak ditemukan"
        errors=$((errors+1))
    fi
    
    # Check sudo access
    if sudo -u "$DEV_USER" sudo -n true 2>/dev/null; then
        log_success "✓ Sudo access OK"
    else
        log_warning "⚠ Sudo access mungkin bermasalah"
        warnings=$((warnings+1))
    fi
    
    # Check Docker
    if command -v docker &>/dev/null; then
        log_success "✓ Docker terinstal ($(docker --version | cut -d' ' -f3 | tr -d ','))"
    else
        log_warning "⚠ Docker tidak ditemukan"
        warnings=$((warnings+1))
    fi
    
    # Check Python
    if command -v python3 &>/dev/null; then
        log_success "✓ Python terinstal ($(python3 --version | cut -d' ' -f2))"
    else
        log_error "✗ Python tidak ditemukan"
        errors=$((errors+1))
    fi
    
    # Check Node (as user)
    if sudo -u "$DEV_USER" bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; command -v node' &>/dev/null; then
        local node_version
        node_version=$(sudo -u "$DEV_USER" bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node --version')
        log_success "✓ Node.js terinstal ($node_version)"
    else
        log_warning "⚠ Node.js tidak ditemukan (mungkin perlu re-login)"
        warnings=$((warnings+1))
    fi
    
    # Check VS Code
    if command -v code &>/dev/null; then
        log_success "✓ VS Code terinstal"
    else
        log_warning "⚠ VS Code tidak ditemukan"
        warnings=$((warnings+1))
    fi
    
    # Check Cursor
    if [ -f /opt/cursor/cursor.AppImage ]; then
        log_success "✓ Cursor AppImage tersedia"
    else
        log_warning "⚠ Cursor tidak ditemukan"
        warnings=$((warnings+1))
    fi
    
    # Check XRDP
    if command -v systemctl &>/dev/null && systemctl is-active --quiet xrdp 2>/dev/null; then
        log_success "✓ XRDP service berjalan"
    else
        log_warning "⚠ XRDP service tidak aktif"
        warnings=$((warnings+1))
    fi
    
    # Check UFW
    if command -v ufw &>/dev/null; then
        if ufw status | grep -q "Status: active"; then
            log_success "✓ UFW firewall aktif"
        else
            log_warning "⚠ UFW firewall tidak aktif"
            warnings=$((warnings+1))
        fi
    fi
    
    # Check Swap
    if swapon --show | grep -q swapfile; then
        log_success "✓ Swap file aktif"
    else
        log_warning "⚠ Swap file tidak aktif"
        warnings=$((warnings+1))
    fi
    
    # Summary
    echo ""
    log_info "=== Verification Summary ==="
    if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
        log_success "Semua komponen terverifikasi dengan baik! ✓"
    elif [ $errors -eq 0 ]; then
        log_warning "Instalasi selesai dengan $warnings warning(s)"
    else
        log_error "Instalasi selesai dengan $errors error(s) dan $warnings warning(s)"
    fi
}

# --- Main Execution Flow ---
main() {
    # Initialize log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
    
    log_info "=== VPS Remote Dev Bootstrap v2.0 (Robust Edition) ==="
    log_info "Log file: $LOG_FILE"
    log_info "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # Pre-flight checks
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
    log_info "=== Starting Installation ==="
    log_info "User Target: $DEV_USER"
    log_info "Timezone: $TIMEZONE"
    echo ""
    
    # Main installation steps
    setup_system
    setup_user
    setup_desktop
    setup_dev_stack
    setup_editors
    setup_shell
    
    echo ""
    log_info "=== Running Post-Installation Verification ==="
    verify_installation
    
    echo ""
    log_success "=== Instalasi Selesai! ==="
    log_info "-----------------------------------------------------"
    log_info "Log lengkap tersimpan di: $LOG_FILE"
    log_info "Backup config tersimpan di: $BACKUP_DIR"
    log_info ""
    log_info "Panduan Koneksi:"
    log_info "1. Reboot VPS Anda: 'sudo reboot'"
    log_info "2. Buka RDP Client (Remote Desktop Connection) di PC Anda."
    log_info "3. Masukkan IP Server dan User: $DEV_USER"
    log_info "4. Password: (yang Anda set di DEV_USER_PASSWORD)"
    log_info "5. Setelah login RDP, buka Terminal:"
    log_info "   - Jalankan: /opt/cursor/cursor.AppImage"
    log_info "   - Atau cari 'Cursor' di Menu Aplikasi XFCE"
    log_info ""
    log_info "Node.js tersedia via NVM (gunakan di shell user $DEV_USER):"
    log_info "   source ~/.nvm/nvm.sh && node --version"
    log_info "-----------------------------------------------------"
}

main "$@"

