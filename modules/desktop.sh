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
    mkdir -p "$xfce_config_dir/xfconf/xfce-perchannel-xml"
    chown -R "$DEV_USER:$DEV_USER" "$xfce_config_dir"
    
    # 1. Create Screensaver Configuration (via XML file)
    log_info "  Configuring screen lock & screensaver..."
    cat > "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfce4-screensaver.xml" <<'SCREENSAVER_XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-screensaver" version="1.0">
  <property name="saver" type="empty">
    <property name="enabled" type="bool" value="false"/>
    <property name="idle-activation" type="empty">
      <property name="enabled" type="bool" value="false"/>
    </property>
  </property>
  <property name="lock" type="empty">
    <property name="enabled" type="bool" value="false"/>
  </property>
</channel>
SCREENSAVER_XML
    chown "$DEV_USER:$DEV_USER" "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfce4-screensaver.xml"
    
    # 2. Create Power Manager Configuration (via XML file)
    log_info "  Configuring power management..."
    cat > "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml" <<'POWER_XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-power-manager" version="1.0">
  <property name="xfce4-power-manager" type="empty">
    <property name="dpms-enabled" type="bool" value="false"/>
    <property name="sleep-display-ac" type="int" value="0"/>
    <property name="sleep-display-battery" type="int" value="0"/>
  </property>
</channel>
POWER_XML
    chown "$DEV_USER:$DEV_USER" "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml"
    
    # 3. Create Window Manager Configuration (via XML file)
    log_info "  Configuring window manager..."
    cat > "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfwm4.xml" <<'XWM4_XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="workspace_count" type="int" value="4"/>
    <property name="wrap_workspaces" type="bool" value="true"/>
    <property name="use_compositing" type="bool" value="false"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="true"/>
    <property name="click_to_focus" type="bool" value="false"/>
    <property name="raise_on_focus" type="bool" value="true"/>
    <property name="vblank_mode" type="string" value="xpresent"/>
  </property>
</channel>
XWM4_XML
    chown "$DEV_USER:$DEV_USER" "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfwm4.xml"
    
    # 4. Create Panel Configuration (via XML file)
    log_info "  Configuring XFCE panel..."
    cat > "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfce4-panel.xml" <<'PANEL_XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="empty">
    <property name="panel-1" type="empty">
      <property name="size" type="int" value="24"/>
      <property name="autohide" type="bool" value="false"/>
    </property>
  </property>
</channel>
PANEL_XML
    chown "$DEV_USER:$DEV_USER" "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
    
    # 5. Create Desktop Configuration (via XML file)
    log_info "  Configuring desktop settings..."
    cat > "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" <<'DESKTOP_XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="0"/>
  </property>
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value=""/>
        </property>
      </property>
    </property>
  </property>
</channel>
DESKTOP_XML
    chown "$DEV_USER:$DEV_USER" "$xfce_config_dir/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
    
    # 6. Create Keyboard Shortcuts Configuration
    log_info "  Creating keyboard shortcuts..."
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
    
    # 7. Disable Screen Lock via LightDM (if available)
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
    
    # 8. Create RDP-optimized startup script
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
    
    # 9. Create optimization script (runs when XFCE session starts)
    log_info "  Creating RDP optimization script..."
    cat > /usr/local/bin/xfce-rdp-optimize.sh <<'OPTIMIZE_SCRIPT'
#!/bin/bash
# XFCE RDP Workspace Optimizer
# Runs on XFCE startup to ensure optimal RDP experience

# Wait for XFCE to fully load and xfconfd to be ready
sleep 5

# Check if xfconf-query is available and XFCE session is running
if ! command -v xfconf-query &>/dev/null; then
    exit 0
fi

# Ensure DISPLAY is set (for RDP sessions)
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:10.0
fi

# Reload xfconfd to apply XML configurations
if pgrep -x xfconfd > /dev/null; then
    # Apply settings via xfconf-query (as backup, XML files should already be loaded)
    xfconf-query -c xfce4-screensaver -p /saver/enabled -s false 2>/dev/null || true
    xfconf-query -c xfce4-screensaver -p /lock/enabled -s false 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/vblank_mode -s xpresent 2>/dev/null || true
fi

# Disable screen lock via xset (additional safety)
if command -v xset &>/dev/null; then
    xset s off 2>/dev/null || true
    xset -dpms 2>/dev/null || true
    xset s noblank 2>/dev/null || true
fi
OPTIMIZE_SCRIPT
    chmod +x /usr/local/bin/xfce-rdp-optimize.sh
    
    # 10. Configure XRDP session settings
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
    
    # 11. Set default XFCE session for user
    log_info "  Setting default XFCE session..."
    local xsessionrc_file="$user_home/.xsessionrc"
    cat > "$xsessionrc_file" <<'XSESSIONRC'
#!/bin/bash
# XFCE RDP Workspace Configuration

# Disable screen lock
if command -v xset &>/dev/null; then
    xset s off 2>/dev/null || true
    xset -dpms 2>/dev/null || true
    xset s noblank 2>/dev/null || true
    xset s 0 0 2>/dev/null || true
fi

# Export display for RDP (will be set by XRDP automatically)
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:10.0
fi
XSESSIONRC
    chmod +x "$xsessionrc_file"
    chown "$DEV_USER:$DEV_USER" "$xsessionrc_file"
    
    # 12. Set proper permissions
    chown -R "$DEV_USER:$DEV_USER" "$user_home/.config"
    chown -R "$DEV_USER:$DEV_USER" "$user_home/.xsessionrc" 2>/dev/null || true
    
    log_success "  ✓ XFCE optimized for RDP workspace"
    log_info "  Optimizations applied:"
    log_info "    - Screen lock & screensaver disabled (via XML config)"
    log_info "    - Power management disabled (no suspend, via XML config)"
    log_info "    - Compositing disabled (better RDP performance, via XML config)"
    log_info "    - Window manager optimized (4 workspaces, snap enabled, via XML config)"
    log_info "    - Panel configured (via XML config)"
    log_info "    - Desktop settings optimized (via XML config)"
    log_info "    - Keyboard shortcuts configured (Super+E, Super+T, Alt+F2)"
    log_info "    - Auto-start optimization script created (/usr/local/bin/xfce-rdp-optimize.sh)"
    log_info "  Note: XML configurations will be loaded automatically when XFCE session starts"
    log_info "        Optimization script will run on each XFCE login to ensure settings persist"
}

