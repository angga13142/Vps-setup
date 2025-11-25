#!/bin/bash

# ==============================================================================
# VPS Remote Dev Bootstrap - Debian 13 (Trixie/Bookworm)
# ==============================================================================
# Role:       Linux Systems Administrator / DevOps
# Target OS:  Debian 13 (Trixie) / 12 (Bookworm)
# Description: Provisions a complete remote GUI dev environment.
#              (XFCE, XRDP, Docker, Node, Python, VS Code, Cursor)
# ==============================================================================

# --- Configuration Variables ---
# Anda dapat menimpa variabel ini dengan environment variables saat menjalankan skrip.
# Contoh: DEV_USER="angga" ./setup.sh

DEV_USER="${DEV_USER:-developer}"
DEV_USER_PASSWORD="${DEV_USER_PASSWORD:-DevPass123!}"
TIMEZONE="${TIMEZONE:-Asia/Jakarta}"
NODE_VERSION="lts/*"  # Install latest LTS
CURSOR_URL="https://downloader.cursor.sh/linux/appImage/x64"

# --- Strict Error Handling ---
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- Logging Functions ---
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

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

# --- 1. System Preparation & Optimization ---
setup_system() {
    log_info "Memulai update sistem dan instalasi dependensi dasar..."
    
    # Set Timezone
    timedatectl set-timezone "$TIMEZONE"

    # Update Repos & Upgrade
    apt-get update && apt-get upgrade -y

    # Install Essential Tools
    # Split install to handle Trixie/Bookworm quirks better
    # software-properties-common is removed as it's unstable in testing/Trixie and we don't use add-apt-repository
    local ESSENTIAL_PKGS="curl wget git htop ufw unzip build-essential apt-transport-https ca-certificates gnupg lsb-release fail2ban"
    
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
        log_error "Gagal menginstal libfuse2 atau libfuse2t64. AppImage (Cursor) mungkin tidak berjalan."
        log_error "Namun instalasi komponen lain akan dilanjutkan."
        # Ensure we don't exit due to set -e
        true
    fi

    # --- Swap Configuration (4GB) ---
    if ! grep -q "swapfile" /etc/fstab; then
        log_info "Mengonfigurasi 4GB Swap..."
        fallocate -l 4G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        
        # Optimize Swappiness (10 is good for VPS to avoid using swap aggressively)
        sysctl vm.swappiness=10
        echo 'vm.swappiness=10' >> /etc/sysctl.conf
    else
        log_info "Swap sudah ada, melewati..."
    fi

    # --- System Limit Tweak (Crucial for VS Code / Webpack watchers) ---
    if ! grep -q "fs.inotify.max_user_watches" /etc/sysctl.conf; then
        echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
        sysctl -p
    fi

    # --- Firewall (UFW) ---
    log_info "Mengonfigurasi Firewall (UFW)..."
    ufw allow 22/tcp comment 'SSH'
    ufw allow 3389/tcp comment 'XRDP'
    # Aktifkan UFW tanpa prompt
    ufw --force enable
}

# --- 2. User Management ---
setup_user() {
    log_info "Menyiapkan user non-root: $DEV_USER..."

    if id "$DEV_USER" &>/dev/null; then
        log_info "User $DEV_USER sudah ada."
    else
        useradd -m -s /bin/bash -G sudo "$DEV_USER"
        echo "$DEV_USER:$DEV_USER_PASSWORD" | chpasswd
        log_success "User $DEV_USER dibuat."
    fi
    
    # Enable sudo without password for convenience (Optional, remove if strict security needed)
    echo "$DEV_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$DEV_USER"
}

# --- 3. Desktop Environment (XFCE & XRDP) ---
setup_desktop() {
    log_info "Menginstal XFCE4 dan XRDP..."
    
    # Install XFCE4 (lightweight) & XRDP
    local DESKTOP_PKGS="xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils xrdp"
    for pkg in $DESKTOP_PKGS; do
        check_and_install "$pkg"
    done

    # Add xrdp user to ssl-cert group (Fixes permission issues)
    adduser xrdp ssl-cert

    # Configure Xsession for the user to ensure XFCE starts properly
    # We write this to the user's home directory
    sudo -u "$DEV_USER" bash -c "echo 'xfce4-session' > /home/$DEV_USER/.xsession"

    # Restart XRDP to apply changes
    systemctl enable xrdp
    systemctl restart xrdp
}

# --- 4. Developer Stack (Node, Python, Docker) ---
setup_dev_stack() {
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

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $DEBIAN_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    check_and_install "docker-ce"
    check_and_install "docker-ce-cli"
    check_and_install "containerd.io"
    check_and_install "docker-buildx-plugin"
    check_and_install "docker-compose-plugin"

    # Add user to docker group
    usermod -aG docker "$DEV_USER"

    log_info "Menginstal Python Stack..."
    check_and_install "python3"
    check_and_install "python3-pip"
    check_and_install "python3-venv"

    log_info "Menginstal Node.js via NVM (sebagai user $DEV_USER)..."
    # Install NVM & Node as the user to avoid permission hell
    sudo -u "$DEV_USER" bash <<EOF
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        
        export NVM_DIR="\$HOME/.nvm"
        [ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
        
        nvm install --lts
        nvm use --lts
        nvm alias default lts/*
        
        npm install -g yarn pnpm typescript ts-node
EOF
}

# --- 5. Code Editors (VS Code & Cursor) ---
setup_editors() {
    log_info "Menginstal VS Code..."
    # VS Code Repo
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    
    apt-get update
    check_and_install "code"

    log_info "Menginstal Cursor AI Editor..."
    # Setup directory
    mkdir -p /opt/cursor
    
    # Download AppImage
    log_info "Downloading Cursor AppImage..."
    
    # Retry logic for download (5 attempts)
    local RETRY_COUNT=0
    local MAX_RETRIES=5
    local DOWNLOAD_SUCCESS=false

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -L "$CURSOR_URL" -o /opt/cursor/cursor.AppImage; then
            DOWNLOAD_SUCCESS=true
            break
        else
            log_error "Download gagal, mencoba lagi dalam 5 detik... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
            sleep 5
            RETRY_COUNT=$((RETRY_COUNT+1))
        fi
    done

    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        log_error "Gagal mengunduh Cursor setelah $MAX_RETRIES percobaan."
        log_error "Melewati instalasi Cursor. Anda dapat mengunduhnya manual nanti."
    else
        chmod +x /opt/cursor/cursor.AppImage
        
        # Create Desktop Entry
        cat > /usr/share/applications/cursor.desktop <<EOF
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
    fi
}

# --- 6. Shell & Polish (Zsh, Oh My Zsh, Nerd Fonts) ---
setup_shell() {
    log_info "Mengonfigurasi Shell (Zsh & Nerd Fonts)..."

    # Install Zsh
    check_and_install "zsh"
    check_and_install "fonts-powerline"

    # Install Nerd Fonts (Hack)
    mkdir -p /usr/local/share/fonts
    local FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip"
    wget -O /tmp/Hack.zip "$FONT_URL"
    unzip -o /tmp/Hack.zip -d /usr/local/share/fonts/
    fc-cache -fv
    rm /tmp/Hack.zip

    # Set Zsh as default for user
    chsh -s "$(which zsh)" "$DEV_USER"

    log_info "Menginstal Oh My Zsh (Unattended)..."
    # Install OMZ as user
    sudo -u "$DEV_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Set Theme (robbyrussell is default, let's ensure it's set or use something nicer if desired)
    # Default setup is usually fine for stability.
}

# --- Main Execution Flow ---
main() {
    check_root
    
    log_info "=== Memulai VPS Remote Dev Bootstrap ==="
    log_info "User Target: $DEV_USER"
    
    setup_system
    setup_user
    setup_desktop
    setup_dev_stack
    setup_editors
    setup_shell
    
    log_success "=== Instalasi Selesai! ==="
    log_info "-----------------------------------------------------"
    log_info "Panduan Koneksi:"
    log_info "1. Reboot VPS Anda: 'reboot'"
    log_info "2. Buka RDP Client (Remote Desktop Connection) di PC Anda."
    log_info "3. Masukkan IP Server dan User: $DEV_USER"
    log_info "4. Password: (yang Anda set di script / default: DevPass123!)"
    log_info "5. Buka Terminal, ketik 'cursor' atau cari di Menu Aplikasi."
    log_info "-----------------------------------------------------"
}

main

