#!/bin/bash

# ==============================================================================
# Desktop Module - XFCE & XRDP
# ==============================================================================

setup_desktop() {
    update_progress "setup_desktop"
    log_info "Menginstal XFCE4 dan XRDP..."
    
    # Install XFCE4 & XRDP
    local DESKTOP_PKGS="xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils xrdp xfce4-settings"
    for pkg in $DESKTOP_PKGS; do
        check_and_install "$pkg"
    done

    # Add xrdp user to ssl-cert group
    if getent group ssl-cert > /dev/null; then
        if ! groups xrdp | grep -q ssl-cert; then
            adduser xrdp ssl-cert || log_warning "Gagal menambahkan xrdp ke grup ssl-cert"
        fi
    else
        log_warning "Grup ssl-cert tidak ada, skip"
    fi

    # Configure Xsession
    local xsession_file="/home/$DEV_USER/.xsession"
    backup_file "$xsession_file"
    
    run_as_user "$DEV_USER" bash -c "echo 'xfce4-session' > $xsession_file" || {
        log_error "Gagal membuat .xsession file"
        return 1
    }
    
    chmod +x "$xsession_file"
    chown "$DEV_USER:$DEV_USER" "$xsession_file"

    # Start XRDP service
    enable_and_start_service "xrdp"
    
    # Optimize XFCE for RDP workspace
    optimize_xfce_for_rdp
    
    log_success "Desktop environment setup selesai"
}

# --- Optimize XFCE for RDP Workspace ---
optimize_xfce_for_rdp() {
    update_progress "optimize_xfce_for_rdp"
    log_info "Mengoptimalkan XFCE untuk RDP workspace..."
    
    local user_home="/home/$DEV_USER"
    local xfce_config_dir="$user_home/.config/xfce4"
    
    # Ensure XFCE config directory exists
    mkdir -p "$xfce_config_dir"
    chown -R "$DEV_USER:$DEV_USER" "$xfce_config_dir"
    
    # 1. Disable Screen Lock & Screensaver
    log_info "  Configuring screen lock & screensaver..."
    run_as_user "$DEV_USER" bash <<'XFCE_CONFIG'
# Disable screensaver
xfconf-query -c xfce4-screensaver -p /saver/enabled -s false 2>/dev/null || true
xfconf-query -c xfce4-screensaver -p /saver/idle-activation/enabled -s false 2>/dev/null || true
xfconf-query -c xfce4-screensaver -p /lock/enabled -s false 2>/dev/null || true

# Disable power management (prevent suspend/lock)
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false 2>/dev/null || true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/sleep-display-ac -s 0 2>/dev/null || true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/sleep-display-battery -s 0 2>/dev/null || true
XFCE_CONFIG
    
    # 2. Configure Panel for Workspace
    log_info "  Configuring XFCE panel..."
    run_as_user "$DEV_USER" bash <<'XFCE_CONFIG'
# Panel configuration (if xfconf-query available)
if command -v xfconf-query &>/dev/null; then
    # Set panel to auto-hide (optional, can be customized)
    # xfconf-query -c xfce4-panel -p /panels/panel-1/autohide -s false 2>/dev/null || true
    
    # Enable panel icons
    xfconf-query -c xfce4-panel -p /panels/panel-1/size -s 24 2>/dev/null || true
fi
XFCE_CONFIG
    
    # 3. Window Manager Settings
    log_info "  Configuring window manager..."
    run_as_user "$DEV_USER" bash <<'XFCE_CONFIG'
if command -v xfconf-query &>/dev/null; then
    # Window snapping
    xfconf-query -c xfwm4 -p /general/snap_to_border -s true 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/snap_to_windows -s true 2>/dev/null || true
    
    # Window focus
    xfconf-query -c xfwm4 -p /general/click_to_focus -s false 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/raise_on_focus -s true 2>/dev/null || true
    
    # Compositing (for better RDP performance, can disable)
    xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
fi
XFCE_CONFIG
    
    # 4. Desktop Settings
    log_info "  Configuring desktop settings..."
    run_as_user "$DEV_USER" bash <<'XFCE_CONFIG'
if command -v xfconf-query &>/dev/null; then
    # Desktop icons
    xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0 2>/dev/null || true
    
    # Background (optional - set to solid color for performance)
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "" 2>/dev/null || true
fi
XFCE_CONFIG
    
    # 5. Create XFCE4 Configuration Files
    log_info "  Creating XFCE4 configuration files..."
    
    # Keyboard settings (disable key repeat delay for RDP)
    mkdir -p "$xfce_config_dir/xfconf/xfce-perchannel-xml"
    cat > "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" <<'KEYBOARD_XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="default" type="empty">
      <property name="&lt;Super&gt;e" type="string" value="thunar"/>
      <property name="&lt;Super&gt;t" type="string" value="xfce4-terminal"/>
      <property name="&lt;Alt&gt;F2" type="string" value="xfce4-appfinder"/>
    </property>
  </property>
</channel>
KEYBOARD_XML
    chown "$DEV_USER:$DEV_USER" "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
    
    # 6. Disable Screen Lock via LightDM (if available)
    log_info "  Configuring display manager..."
    if [ -f /etc/lightdm/lightdm.conf ]; then
        backup_file "/etc/lightdm/lightdm.conf"
        
        # Disable screen lock
        if ! grep -q "^\[Seat:\*\]" /etc/lightdm/lightdm.conf; then
            echo "" >> /etc/lightdm/lightdm.conf
            echo "[Seat:*]" >> /etc/lightdm/lightdm.conf
        fi
        
        # Disable autologin timeout (for RDP)
        sed -i '/^\[Seat:\*\]/,/^\[/ {
            /^xserver-command=/d
            /^autologin-user=/d
        }' /etc/lightdm/lightdm.conf
        
        # Add configuration
        if ! grep -q "xserver-command=X" /etc/lightdm/lightdm.conf; then
            sed -i '/^\[Seat:\*\]/a xserver-command=X -nolisten tcp' /etc/lightdm/lightdm.conf
        fi
    fi
    
    # 7. Create RDP-optimized startup script
    log_info "  Creating RDP startup configuration..."
    mkdir -p "$user_home/.config/autostart"
    mkdir -p "$xfce_config_dir/xfconf/xfce-perchannel-xml"
    
    cat > "$user_home/.config/autostart/rdp-optimize.desktop" <<'AUTOSTART'
[Desktop Entry]
Type=Application
Name=RDP Workspace Optimizer
Comment=Optimize XFCE for RDP workspace
Exec=/usr/local/bin/xfce-rdp-optimize.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
AUTOSTART
    chown "$DEV_USER:$DEV_USER" "$user_home/.config/autostart/rdp-optimize.desktop"
    
    # 8. Create optimization script
    log_info "  Creating RDP optimization script..."
    cat > /usr/local/bin/xfce-rdp-optimize.sh <<'OPTIMIZE_SCRIPT'
#!/bin/bash
# XFCE RDP Workspace Optimizer
# Runs on XFCE startup to ensure optimal RDP experience

# Wait for XFCE to fully load
sleep 3

# Disable screensaver and lock
xfconf-query -c xfce4-screensaver -p /saver/enabled -s false 2>/dev/null || true
xfconf-query -c xfce4-screensaver -p /lock/enabled -s false 2>/dev/null || true

# Disable power management
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false 2>/dev/null || true

# Set compositing off for better RDP performance
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true

# Disable desktop effects
xfconf-query -c xfwm4 -p /general/vblank_mode -s xpresent 2>/dev/null || true

# Set window manager to performance mode
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
OPTIMIZE_SCRIPT
    chmod +x /usr/local/bin/xfce-rdp-optimize.sh
    
    # 9. Configure XRDP session settings
    log_info "  Configuring XRDP session settings..."
    if [ -f /etc/xrdp/xrdp.ini ]; then
        backup_file "/etc/xrdp/xrdp.ini"
        
        # Ensure XFCE session is available
        if ! grep -q "\[XFCE\]" /etc/xrdp/xrdp.ini; then
            cat >> /etc/xrdp/xrdp.ini <<'XRDP_CONFIG'

[XFCE]
name=XFCE Session
lib=libvnc.so
username=ask
password=ask
ip=127.0.0.1
port=-1
code=20
XRDP_CONFIG
        fi
    fi
    
    # 10. Set default XFCE session for user
    log_info "  Setting default XFCE session..."
    run_as_user "$DEV_USER" bash <<'XFCE_CONFIG'
# Ensure .xsessionrc exists
cat > ~/.xsessionrc <<'XSESSIONRC'
#!/bin/bash
# XFCE RDP Workspace Configuration

# Disable screen lock
xset s off
xset -dpms
xset s noblank

# Disable screensaver
xset s 0 0

# Export display for RDP
export DISPLAY=:10.0

# XFCE4 session
exec startxfce4
XSESSIONRC
chmod +x ~/.xsessionrc
XFCE_CONFIG
    
    # 11. Create XFCE4 panel workspace switcher (optional)
    log_info "  Configuring workspace switcher..."
    run_as_user "$DEV_USER" bash <<'XFCE_CONFIG'
# Create workspace configuration
mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<'XWM4_XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="workspace_count" type="int" value="4"/>
    <property name="wrap_workspaces" type="bool" value="true"/>
    <property name="use_compositing" type="bool" value="false"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="true"/>
    <property name="raise_on_focus" type="bool" value="true"/>
  </property>
</channel>
XWM4_XML
XFCE_CONFIG
    
    # 12. Set proper permissions
    chown -R "$DEV_USER:$DEV_USER" "$user_home/.config"
    chown -R "$DEV_USER:$DEV_USER" "$user_home/.xsessionrc" 2>/dev/null || true
    
    log_success "  ✓ XFCE optimized for RDP workspace"
    log_info "  Optimizations applied:"
    log_info "    - Screen lock & screensaver disabled"
    log_info "    - Power management disabled (no suspend)"
    log_info "    - Compositing disabled (better RDP performance)"
    log_info "    - Window manager optimized"
    log_info "    - Workspace switcher configured (4 workspaces)"
    log_info "    - Auto-start optimization script created"
    log_info "  Note: Some settings require XFCE session restart to take effect"
}

