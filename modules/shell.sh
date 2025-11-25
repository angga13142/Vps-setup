#!/bin/bash

# ==============================================================================
# Shell Module - Zsh & Oh My Zsh
# ==============================================================================

setup_shell() {
    update_progress "setup_shell"
    log_info "Mengonfigurasi Shell (Zsh & Nerd Fonts)..."

    # Install Zsh and fonts (batch install to prevent OOM)
    batch_install_packages "zsh fonts-powerline" "Shell components"

    # Install Nerd Fonts (Hack)
    log_info "Menginstal Nerd Fonts (Hack)..."
    mkdir -p /usr/local/share/fonts
    local FONT_ZIP="/tmp/Hack-$$.zip"
    
    local font_attempt=1
    local font_success=false
    while [ $font_attempt -le 3 ] && [ "$font_success" = false ]; do
        if run_with_progress "Downloading Nerd Fonts (Hack) (attempt $font_attempt/3)" "wget -q -O '$FONT_ZIP' '$NERD_FONTS_URL'"; then
            if unzip -o "$FONT_ZIP" -d /usr/local/share/fonts/ &>/dev/null; then
                fc-cache -fv &>/dev/null
                font_success=true
                log_success "Nerd Fonts (Hack) berhasil diinstal"
            else
                log_warning "Gagal extract font"
            fi
            rm -f "$FONT_ZIP"
        else
            if [ $font_attempt -lt 3 ]; then
                log_warning "Download font gagal, retry dalam 5 detik..."
                sleep 5
            fi
            font_attempt=$((font_attempt + 1))
        fi
    done
    
    if [ "$font_success" = false ]; then
        log_warning "Gagal menginstal Nerd Fonts setelah 3 percobaan, skip..."
    fi

    # Set Zsh as default
    if command_exists zsh; then
        local zsh_path
        zsh_path=$(which zsh)
        
        if ! grep -q "$zsh_path" /etc/shells; then
            echo "$zsh_path" >> /etc/shells
        fi
        
        chsh -s "$zsh_path" "$DEV_USER" || log_warning "Gagal set Zsh sebagai default shell"
        log_success "Zsh set sebagai default shell untuk $DEV_USER"
    fi

    # Install Oh My Zsh
    log_info "Menginstal Oh My Zsh..."
    
    if [ ! -d "/home/$DEV_USER" ]; then
        log_error "Home directory /home/$DEV_USER tidak ditemukan!"
        return 1
    fi
    
    if [ -d "/home/$DEV_USER/.oh-my-zsh" ]; then
        log_info "Oh My Zsh sudah terinstal, melewati..."
    else
        [ -f "/home/$DEV_USER/.zshrc" ] && backup_file "/home/$DEV_USER/.zshrc"
        
        if run_with_progress "Installing Oh My Zsh" "run_as_user \"$DEV_USER\" bash -c \"RUNZSH=no sh -c \\\"\\\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\\\" \\\"\\\" --unattended\""; then
            log_success "Oh My Zsh berhasil diinstal"
        else
            log_warning "Gagal menginstal Oh My Zsh, melanjutkan..."
        fi
    fi

    # Fix ownership
    if [ -d "/home/$DEV_USER/.oh-my-zsh" ]; then
        chown -R "$DEV_USER:$DEV_USER" "/home/$DEV_USER/.oh-my-zsh"
    fi
    
    log_success "Shell setup selesai"
}

