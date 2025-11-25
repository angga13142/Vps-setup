#!/bin/bash

# ==============================================================================
# VS Code Module - Visual Studio Code
# ==============================================================================

setup_vscode() {
    update_progress "setup_vscode"
    log_info "Menginstal VS Code..."
    
    # Backup existing configs
    [ -f /etc/apt/sources.list.d/vscode.list ] && backup_file "/etc/apt/sources.list.d/vscode.list"
    
    # Clean up conflicting files
    rm -f /etc/apt/sources.list.d/vscode.list
    rm -f /etc/apt/keyrings/packages.microsoft.gpg
    rm -f /usr/share/keyrings/microsoft.gpg

    # VS Code Repo Setup with retry
    if retry_command 3 5 "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg"; then
        install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        rm -f packages.microsoft.gpg
        
        sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        
        apt-get update || log_warning "Gagal update apt setelah menambahkan VS Code repo"
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

