#!/bin/bash

# ==============================================================================
# Rollback Module - Restore from Backups
# ==============================================================================

list_backups() {
    log_info "=== Available Backups ==="
    echo ""
    
    local backup_dirs=(/root/.vps-bootstrap-backups-*)
    
    if [ ${#backup_dirs[@]} -eq 0 ] || [ ! -d "${backup_dirs[0]}" ]; then
        log_warning "No backups found"
        return 1
    fi
    
    local count=1
    for backup_dir in "${backup_dirs[@]}"; do
        if [ -d "$backup_dir" ]; then
            local backup_name=$(basename "$backup_dir")
            local backup_date=$(echo "$backup_name" | sed 's/.*-backups-//')
            local backup_size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}')
            local file_count=$(find "$backup_dir" -type f | wc -l)
            
            echo "[$count] Backup: $backup_name"
            echo "    Date: $(date -d "${backup_date:0:8} ${backup_date:9:2}:${backup_date:11:2}:${backup_date:13:2}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo $backup_date)"
            echo "    Size: $backup_size"
            echo "    Files: $file_count"
            echo "    Path: $backup_dir"
            echo ""
            
            count=$((count+1))
        fi
    done
}

show_backup_contents() {
    local backup_dir="$1"
    
    if [ ! -d "$backup_dir" ]; then
        log_error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    log_info "=== Backup Contents: $(basename $backup_dir) ==="
    echo ""
    
    # Show file tree
    if command_exists tree; then
        tree -L 3 "$backup_dir"
    else
        find "$backup_dir" -type f -printf "%P\n" | sort
    fi
    
    echo ""
}

restore_from_backup() {
    local backup_dir="$1"
    local interactive="${2:-true}"
    
    if [ ! -d "$backup_dir" ]; then
        log_error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    log_info "=== Restore from Backup ==="
    log_info "Backup: $(basename $backup_dir)"
    echo ""
    
    # Show what will be restored
    log_info "Files to restore:"
    find "$backup_dir" -type f -printf "  %P\n"
    echo ""
    
    if [ "$interactive" = "true" ]; then
        read -p "Proceed with restore? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            log_info "Restore cancelled"
            return 0
        fi
    fi
    
    # Create restore backup (backup of current state before restore)
    local restore_backup_dir="/root/.vps-pre-restore-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$restore_backup_dir"
    log_info "Creating pre-restore backup: $restore_backup_dir"
    
    # Backup current state of files that will be restored
    while IFS= read -r -d '' file; do
        local relative_path="${file#$backup_dir}"
        local current_file="$relative_path"
        
        if [ -f "$current_file" ]; then
            local backup_path="$restore_backup_dir$(dirname "$relative_path")"
            mkdir -p "$backup_path"
            cp -a "$current_file" "$backup_path/"
        fi
    done < <(find "$backup_dir" -type f -print0)
    
    # Restore files
    log_info "Restoring files..."
    local restored_count=0
    local failed_count=0
    
    while IFS= read -r -d '' file; do
        local relative_path="${file#$backup_dir}"
        local target_file="$relative_path"
        
        # Create target directory if needed
        mkdir -p "$(dirname "$target_file")"
        
        # Restore file
        if cp -a "$file" "$target_file"; then
            log_success "  ✓ Restored: $relative_path"
            restored_count=$((restored_count+1))
        else
            log_error "  ✗ Failed: $relative_path"
            failed_count=$((failed_count+1))
        fi
    done < <(find "$backup_dir" -type f -print0)
    
    echo ""
    log_info "=== Restore Summary ==="
    log_success "Restored: $restored_count files"
    
    if [ $failed_count -gt 0 ]; then
        log_error "Failed: $failed_count files"
    fi
    
    log_info "Pre-restore backup saved to: $restore_backup_dir"
    
    # Reload services that might be affected
    log_info "Reloading affected services..."
    
    if systemctl is-active --quiet xrdp 2>/dev/null; then
        systemctl restart xrdp && log_success "  ✓ XRDP restarted"
    fi
    
    if systemctl is-active --quiet ufw 2>/dev/null; then
        ufw reload && log_success "  ✓ UFW reloaded"
    fi
    
    sysctl -p &>/dev/null && log_success "  ✓ sysctl reloaded"
    
    echo ""
    log_success "Restore completed!"
    log_warning "Please review restored configurations before rebooting"
}

cleanup_old_backups() {
    local keep_count="${1:-5}"
    
    log_info "=== Cleanup Old Backups ==="
    log_info "Keeping last $keep_count backups..."
    echo ""
    
    # Find all backup directories
    local backup_dirs=($(find /root -maxdepth 1 -type d -name ".vps-*-backups-*" -o -name ".vps-pre-restore-*" | sort -r))
    
    if [ ${#backup_dirs[@]} -le $keep_count ]; then
        log_info "Only ${#backup_dirs[@]} backup(s) found. Nothing to cleanup."
        return 0
    fi
    
    local removed_count=0
    local removed_size=0
    
    # Remove old backups (keep only latest $keep_count)
    for ((i=$keep_count; i<${#backup_dirs[@]}; i++)); do
        local backup_dir="${backup_dirs[$i]}"
        local size=$(du -sm "$backup_dir" 2>/dev/null | awk '{print $1}')
        
        log_info "Removing: $(basename $backup_dir) (${size}MB)"
        
        if rm -rf "$backup_dir"; then
            removed_count=$((removed_count+1))
            removed_size=$((removed_size+size))
        else
            log_error "Failed to remove: $backup_dir"
        fi
    done
    
    echo ""
    log_success "Removed $removed_count old backup(s)"
    log_success "Freed ${removed_size}MB of disk space"
}

interactive_restore() {
    list_backups
    
    echo ""
    read -p "Enter backup number to restore (or 'q' to quit): " choice
    
    if [ "$choice" = "q" ]; then
        log_info "Cancelled"
        return 0
    fi
    
    # Get backup directory by number
    local backup_dirs=($(find /root -maxdepth 1 -type d -name ".vps-bootstrap-backups-*" | sort -r))
    local index=$((choice-1))
    
    if [ $index -lt 0 ] || [ $index -ge ${#backup_dirs[@]} ]; then
        log_error "Invalid backup number"
        return 1
    fi
    
    local backup_dir="${backup_dirs[$index]}"
    
    # Show contents
    echo ""
    show_backup_contents "$backup_dir"
    
    # Restore
    restore_from_backup "$backup_dir" true
}

