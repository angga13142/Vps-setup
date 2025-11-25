#!/bin/bash

# ==============================================================================
# VS Code Module - Visual Studio Code
# ==============================================================================

setup_vscode() {
    update_progress "setup_vscode"
    log_info "Menginstal VS Code..."
    
    # Backup existing configs
    [ -f /etc/apt/sources.list.d/vscode.list ] && backup_file "/etc/apt/sources.list.d/vscode.list"
    
    # Thorough cleanup of all possible conflicting files and configs
    log_info "Cleaning up old VS Code configurations..."
    rm -f /etc/apt/sources.list.d/vscode.list
    rm -f /etc/apt/sources.list.d/vscode.list.save
    rm -f /etc/apt/keyrings/packages.microsoft.gpg
    rm -f /usr/share/keyrings/microsoft.gpg
    rm -f /etc/apt/trusted.gpg.d/microsoft.gpg
    
    # Clean up apt cache to avoid conflicts
    apt-get clean 2>/dev/null || true

    # VS Code Repo Setup with retry
    if retry_command 3 5 "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg"; then
        install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        rm -f packages.microsoft.gpg
        
        # Create vscode.list with proper format
        cat > /etc/apt/sources.list.d/vscode.list <<EOF
# VS Code Repository
deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main
EOF
        
        # Update with error handling
        if apt-get update 2>&1 | grep -q "Conflicting values"; then
            log_warning "Detected conflicting GPG keys, attempting cleanup..."
            # More aggressive cleanup
            rm -f /etc/apt/sources.list.d/vscode.list*
            rm -f /etc/apt/keyrings/packages.microsoft.gpg
            rm -f /usr/share/keyrings/microsoft.gpg
            rm -rf /var/lib/apt/lists/*microsoft*
            
            # Recreate
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
            install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
            rm -f /tmp/packages.microsoft.gpg
            
            cat > /etc/apt/sources.list.d/vscode.list <<EOF
deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main
EOF
            apt-get update
        fi
        
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

