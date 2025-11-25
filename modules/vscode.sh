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
    run_with_progress "Cleaning apt cache for VS Code" "apt-get clean -qq"
    rm -rf /var/lib/apt/lists/packages.microsoft.com*

    # VS Code Repo Setup - Install GPG key with progress
    log_info "Installing Microsoft GPG key..."
    local gpg_attempt=1
    local gpg_success=false
    while [ $gpg_attempt -le 3 ] && [ "$gpg_success" = false ]; do
        if run_with_progress "Downloading Microsoft GPG key (attempt $gpg_attempt/3)" "curl -fsSL 'https://packages.microsoft.com/keys/microsoft.asc' | gpg --dearmor -o '/etc/apt/keyrings/packages.microsoft.gpg'"; then
            chmod a+r /etc/apt/keyrings/packages.microsoft.gpg
            gpg_success=true
            log_success "Microsoft GPG key installed"
        else
            if [ $gpg_attempt -lt 3 ]; then
                log_warning "GPG key download gagal, retry dalam 5 detik..."
                sleep 5
            fi
            gpg_attempt=$((gpg_attempt + 1))
        fi
    done
    
    if [ "$gpg_success" = true ]; then
        sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        
        # Update apt with proper error handling
        if ! run_with_progress "Updating apt cache for VS Code" "apt-get update -qq"; then
            log_error "Apt update failed. This indicates a problem with VS Code repository configuration"
            log_warning "VS Code installation may fail due to apt update errors"
            # Continue anyway for VS Code (non-critical), but log the error
        fi
        
        # Ensure swap is active before installing VS Code
        ensure_swap_active
        
        # Try to install
        check_and_install "code"
        
        # Verify installation
        if command_exists code; then
            log_success "VS Code berhasil diinstal: $(code --version | head -n1)"
        else
            log_warning "VS Code tidak terinstal dengan benar"
        fi
    else
        log_warning "Gagal menginstal Microsoft GPG key setelah 3 percobaan, skip VS Code..."
    fi
    
    log_success "VS Code setup selesai"
}
