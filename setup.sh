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
    apt-get install -y curl wget git htop ufw unzip build-essential \
        apt-transport-https ca-certificates gnupg lsb-release fail2ban

    # Handle libfuse2 (Needed for AppImages) - Trixie uses libfuse2t64
    if apt-cache search --names-only '^libfuse2t64$' | grep -q libfuse2t64; then
        log_info "Menginstal libfuse2t64 (Debian Trixie detected)..."
        apt-get install -y libfuse2t64
    else
        log_info "Menginstal libfuse2 (Standard)..."
        apt-get install -y libfuse2
    fi

    # Try installing software-properties-common but don't fail script if missing
    # (We manage repos manually anyway, so this is just a convenience tool)
    if ! apt-get install -y software-properties-common; then
        log_error "software-properties-common tidak ditemukan, melewati (tidak kritis)..."
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
    apt-get install -y xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils xrdp

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
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    usermod -aG docker "$DEV_USER"

    log_info "Menginstal Python Stack..."
    apt-get install -y python3 python3-pip python3-venv

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
    apt-get install -y code

    log_info "Menginstal Cursor AI Editor..."
    # Setup directory
    mkdir -p /opt/cursor
    
    # Download AppImage
    log_info "Downloading Cursor AppImage (ini mungkin memakan waktu)..."
    curl -L "$CURSOR_URL" -o /opt/cursor/cursor.AppImage
    chmod +x /opt/cursor/cursor.AppImage

    # Download Icon (Generic placeholder logic or try to fetch one)
    # Using a generic code icon if specific one isn't available easily, but let's try to be clean.
    # We will skip downloading an icon to keep script robust, system will use default executable icon.

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
    
    # Fix ownership for the directory so user *could* update it if needed (optional)
    chown -R "$DEV_USER:$DEV_USER" /opt/cursor
    
    log_success "Cursor terinstal di /opt/cursor/cursor.AppImage"
}

# --- 6. Shell & Polish (Zsh, Oh My Zsh, Nerd Fonts) ---
setup_shell() {
    log_info "Mengonfigurasi Shell (Zsh & Nerd Fonts)..."

    # Install Zsh
    apt-get install -y zsh fonts-powerline

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

