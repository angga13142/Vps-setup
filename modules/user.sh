#!/bin/bash

# ==============================================================================
# User Module - User Management
# ==============================================================================

setup_user() {
    update_progress "setup_user"
    log_info "Menyiapkan user non-root: $DEV_USER..."

    check_and_install "sudo"

    if id "$DEV_USER" &>/dev/null; then
        log_info "User $DEV_USER sudah ada."
        echo "$DEV_USER:$DEV_USER_PASSWORD" | chpasswd
        log_info "Password untuk $DEV_USER diupdate."
        
        if ! groups "$DEV_USER" | grep -q sudo; then
            usermod -aG sudo "$DEV_USER"
            log_info "User $DEV_USER ditambahkan ke grup sudo."
        fi
    else
        useradd -m -s /bin/bash -G sudo "$DEV_USER" || {
            log_error "Gagal membuat user $DEV_USER"
            return 1
        }
        echo "$DEV_USER:$DEV_USER_PASSWORD" | chpasswd
        log_success "User $DEV_USER dibuat."
    fi
    
    # Verify home directory
    if [ ! -d "/home/$DEV_USER" ]; then
        log_error "Home directory /home/$DEV_USER tidak ada!"
        return 1
    fi
    chown -R "$DEV_USER:$DEV_USER" "/home/$DEV_USER"
    
    # Configure sudoers
    [ -f "/etc/sudoers.d/$DEV_USER" ] && backup_file "/etc/sudoers.d/$DEV_USER"
    
    echo "$DEV_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$DEV_USER"
    chmod 0440 "/etc/sudoers.d/$DEV_USER"
    
    if visudo -c -f "/etc/sudoers.d/$DEV_USER" &>/dev/null; then
        log_success "Konfigurasi sudo untuk $DEV_USER valid."
    else
        log_error "Konfigurasi sudo tidak valid! Menghapus file untuk keamanan."
        rm -f "/etc/sudoers.d/$DEV_USER"
        return 1
    fi
    
    # Set root password sama dengan user password untuk kemudahan
    log_info "Setting root password (sama dengan user password)..."
    echo "root:$DEV_USER_PASSWORD" | chpasswd
    if [ $? -eq 0 ]; then
        log_success "Root password berhasil di-set"
        log_info "  Root password: (sama dengan $DEV_USER)"
    else
        log_warning "Gagal set root password (non-critical)"
    fi
    
    # Remove other users (security: only keep root and dev user)
    if [ "$REMOVE_OTHER_USERS" = "true" ]; then
        remove_other_users
    fi
    
    log_success "User setup selesai"
}

# --- Remove Other Users (Security) ---
remove_other_users() {
    log_info "=== Removing Other Users (Security Cleanup) ==="
    log_info "Keeping only: root and $DEV_USER"
    echo ""
    
    # Get current user (to avoid deleting logged-in user)
    local current_user
    current_user=$(whoami 2>/dev/null || echo "")
    
    # System users to preserve (UID < 1000 typically)
    # Also preserve common system accounts
    local system_users=(
        "root"
        "daemon"
        "bin"
        "sys"
        "sync"
        "games"
        "man"
        "lp"
        "mail"
        "news"
        "uucp"
        "proxy"
        "www-data"
        "backup"
        "list"
        "irc"
        "gnats"
        "nobody"
        "systemd-timesync"
        "systemd-network"
        "systemd-resolve"
        "messagebus"
        "sshd"
        "xrdp"
        "Debian-exim"
        "statd"
        "tcpdump"
        "tss"
        "landscape"
        "pollinate"
        "ubuntu"
        "debian"
    )
    
    # Get all users with UID >= 1000 (regular users)
    local users_to_check
    users_to_check=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1}')
    
    if [ -z "$users_to_check" ]; then
        log_info "No regular users found to remove"
        return 0
    fi
    
    local removed_count=0
    local skipped_count=0
    local backup_dir="/root/.deleted-users-$(date +%Y%m%d-%H%M%S)"
    
    # Create backup directory
    mkdir -p "$backup_dir"
    
    log_info "Checking users..."
    
    while IFS= read -r username; do
        # Skip if it's our dev user
        if [ "$username" = "$DEV_USER" ]; then
            continue
        fi
        
        # Skip if it's a system user
        local is_system=false
        for sys_user in "${system_users[@]}"; do
            if [ "$username" = "$sys_user" ]; then
                is_system=true
                break
            fi
        done
        
        if [ "$is_system" = true ]; then
            log_info "  ⏭️  Skipping system user: $username"
            skipped_count=$((skipped_count+1))
            continue
        fi
        
        # Skip if it's the current logged-in user
        if [ "$username" = "$current_user" ]; then
            log_warning "  ⚠️  Skipping currently logged-in user: $username"
            log_warning "     This user will not be removed for safety"
            skipped_count=$((skipped_count+1))
            continue
        fi
        
        # Check if user has active processes
        local user_processes
        user_processes=$(ps -u "$username" 2>/dev/null | wc -l)
        
        if [ "$user_processes" -gt 1 ]; then
            log_warning "  ⚠️  User $username has active processes ($user_processes), skipping..."
            skipped_count=$((skipped_count+1))
            continue
        fi
        
        # Get user info
        local user_home
        user_home=$(getent passwd "$username" | cut -d: -f6)
        local user_uid
        user_uid=$(id -u "$username" 2>/dev/null)
        
        log_info "  🗑️  Removing user: $username (UID: $user_uid)"
        
        # Backup home directory if exists
        if [ -d "$user_home" ] && [ "$user_home" != "/" ]; then
            log_info "     Backing up home directory: $user_home"
            local backup_path="$backup_dir/$username-home"
            cp -r "$user_home" "$backup_path" 2>/dev/null || log_warning "     Failed to backup home directory"
        fi
        
        # Remove user (with home directory)
        if userdel -r "$username" 2>/dev/null; then
            log_success "     ✓ User $username removed"
            removed_count=$((removed_count+1))
        else
            # Try without removing home directory if first attempt failed
            if userdel "$username" 2>/dev/null; then
                log_warning "     ⚠️  User removed but home directory kept: $user_home"
                removed_count=$((removed_count+1))
            else
                log_error "     ✗ Failed to remove user: $username"
            fi
        fi
        
        # Remove from sudoers if exists
        if [ -f "/etc/sudoers.d/$username" ]; then
            rm -f "/etc/sudoers.d/$username"
            log_info "     Removed sudoers config for $username"
        fi
        
    done <<< "$users_to_check"
    
    echo ""
    log_info "=== User Cleanup Summary ==="
    log_success "Removed: $removed_count user(s)"
    log_info "Skipped: $skipped_count user(s) (system/active)"
    
    if [ $removed_count -gt 0 ]; then
        log_info "Backup location: $backup_dir"
        log_info "Remaining users: root, $DEV_USER, and system users"
    fi
    
    echo ""
}

