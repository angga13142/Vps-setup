#!/bin/bash

# ==============================================================================
# Cursor Module - Cursor AI Editor
# ==============================================================================

setup_cursor() {
    update_progress "setup_cursor"
    log_info "Menginstal Cursor AI Editor..."
    
    local CURSOR_INSTALLED=false
    
    # Method 1: Official installer (recommended)
    if run_with_progress "Installing Cursor (official installer)" "run_as_user \"$DEV_USER\" bash -c \"curl -fsSL https://cursor.com/install | bash\""; then
        log_success "Cursor berhasil diinstal menggunakan installer resmi"
        CURSOR_INSTALLED=true
        
        # Create desktop entry
        [ -f /usr/share/applications/cursor.desktop ] && backup_file "/usr/share/applications/cursor.desktop"
        
        local CURSOR_BIN
        CURSOR_BIN=$(run_as_user "$DEV_USER" bash -c 'command -v cursor' 2>/dev/null || echo "/home/$DEV_USER/.local/bin/cursor")
        
        cat > /usr/share/applications/cursor.desktop <<EOF
[Desktop Entry]
Name=Cursor
Comment=AI-first Code Editor
Exec=$CURSOR_BIN %F
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Development;IDE;
StartupNotify=true
EOF
        chmod 644 /usr/share/applications/cursor.desktop
    else
        log_warning "Installer resmi gagal, mencoba metode alternatif..."
    fi
    
    # Method 2: Snap (fallback)
    if [ "$CURSOR_INSTALLED" = false ] && command_exists snap; then
        if run_with_progress "Installing Cursor via Snap" "snap install cursor --classic"; then
            log_success "Cursor berhasil diinstal via Snap"
            CURSOR_INSTALLED=true
        else
            log_warning "Instalasi via Snap gagal"
        fi
    fi
    
    # Method 3: AppImage download (last resort)
    if [ "$CURSOR_INSTALLED" = false ]; then
        log_info "Mencoba download Cursor AppImage manual..."
        
        local APPIMAGE_URLS=(
            "https://downloader.cursor.sh/linux/appImage/x64"
            "https://download.cursor.sh/linux/appImage/x64"
        )
        
        mkdir -p /opt/cursor
        local DOWNLOAD_SUCCESS=false
        
        for url in "${APPIMAGE_URLS[@]}"; do
            log_info "Mencoba download dari: $url"
            if run_with_progress "Downloading Cursor AppImage" "curl -L --max-time 300 -o '/opt/cursor/cursor.AppImage' '$url'"; then
                local file_size
                file_size=$(stat -c%s /opt/cursor/cursor.AppImage 2>/dev/null || echo 0)
                
                if [ "$file_size" -gt 52428800 ]; then  # > 50MB
                    chmod +x /opt/cursor/cursor.AppImage
                    DOWNLOAD_SUCCESS=true
                    CURSOR_INSTALLED=true
                    log_success "Cursor AppImage berhasil didownload"
                    break
                else
                    log_warning "File terlalu kecil ($file_size bytes), mencoba URL lain..."
                    rm -f /opt/cursor/cursor.AppImage
                fi
            fi
        done
        
        if [ "$DOWNLOAD_SUCCESS" = true ]; then
            [ -f /usr/share/applications/cursor.desktop ] && backup_file "/usr/share/applications/cursor.desktop"
            
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
            chmod 644 /usr/share/applications/cursor.desktop
            chown -R "$DEV_USER:$DEV_USER" /opt/cursor
            ln -sf /opt/cursor/cursor.AppImage /usr/local/bin/cursor 2>/dev/null || true
        fi
    fi
    
    # Final status
    if [ "$CURSOR_INSTALLED" = true ]; then
        log_success "Cursor AI Editor berhasil diinstal!"
    else
        log_warning "Gagal menginstal Cursor. Anda dapat menginstal manual:"
        log_warning "  curl https://cursor.com/install | bash"
    fi
    
    log_success "Cursor setup selesai"
}

