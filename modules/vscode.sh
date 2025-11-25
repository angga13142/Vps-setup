#!/bin/bash

# ==============================================================================
# VS Code Module - Visual Studio Code
# ==============================================================================

setup_vscode() {
    update_progress "setup_vscode"
    log_info "Menginstal VS Code..."
    
    # Check if already installed
    if command_exists code; then
        log_info "VS Code sudah terinstal: $(code --version | head -n1)"
        log_success "VS Code setup selesai"
        return 0
    fi
    
    # Backup existing configs
    [ -f /etc/apt/sources.list.d/vscode.list ] && backup_file "/etc/apt/sources.list.d/vscode.list"
    
    # Cleanup old configs and sources
    rm -f /etc/apt/sources.list.d/vscode.list
    rm -f /etc/apt/sources.list.d/vscode.list.save
    
    # Clean GPG keys using helper function
    clean_gpg_keys "microsoft"
    clean_gpg_keys "packages.microsoft"
    
    # Clean apt cache to avoid conflicts
    apt-get clean
    rm -rf /var/lib/apt/lists/packages.microsoft.com*

    # VS Code Repo Setup - Install GPG key
    if install_gpg_key "https://packages.microsoft.com/keys/microsoft.asc" "/etc/apt/keyrings/packages.microsoft.gpg" "Microsoft"; then
        log_success "Microsoft GPG key installed"
        
        sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        
        # Update apt with error handling
        if ! apt-get update 2>&1 | tee /tmp/apt-update.log | grep -v "Conflicting values"; then
            log_warning "Apt update had warnings, checking if we can continue..."
        fi
        
        # Try to install
        check_and_install "code"
        
        # Verify installation
        if command_exists code; then
            log_success "VS Code berhasil diinstal: $(code --version | head -n1)"
        else
            log_warning "VS Code tidak terinstal dengan benar"
        fi
    else
        log_warning "Gagal menginstal VS Code setelah 3 percobaan, skip..."
    fi
    
    log_success "VS Code setup selesai"
}
