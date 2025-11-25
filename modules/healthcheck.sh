#!/bin/bash

# ==============================================================================
# Health Check Module - System & Components Status Monitor
# ==============================================================================

run_healthcheck() {
    log_info "=== System Health Check ==="
    echo ""
    
    local issues=0
    local warnings=0
    
    # System Resources
    log_info "📊 System Resources:"
    
    # CPU Load
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    local cpu_cores
    cpu_cores=$(nproc)
    log_info "  CPU Load: $load_avg (${cpu_cores} cores)"
    
    # RAM Usage
    local mem_total mem_used mem_free mem_percent
    mem_total=$(free -m | awk '/^Mem:/{print $2}')
    mem_used=$(free -m | awk '/^Mem:/{print $3}')
    mem_free=$(free -m | awk '/^Mem:/{print $4}')
    mem_percent=$(awk "BEGIN {printf \"%.1f\", ($mem_used/$mem_total)*100}")
    
    if (( $(echo "$mem_percent > 90" | bc -l) )); then
        log_error "  RAM: ${mem_used}MB/${mem_total}MB (${mem_percent}%) ⚠️ CRITICAL"
        issues=$((issues+1))
    elif (( $(echo "$mem_percent > 80" | bc -l) )); then
        log_warning "  RAM: ${mem_used}MB/${mem_total}MB (${mem_percent}%) ⚠️ HIGH"
        warnings=$((warnings+1))
    else
        log_success "  RAM: ${mem_used}MB/${mem_total}MB (${mem_percent}%) ✓"
    fi
    
    # Disk Usage
    local disk_usage disk_percent
    disk_usage=$(df -h / | tail -1 | awk '{print $3"/"$2}')
    disk_percent=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    
    if [ "$disk_percent" -gt 90 ]; then
        log_error "  Disk: $disk_usage (${disk_percent}%) ⚠️ CRITICAL"
        issues=$((issues+1))
    elif [ "$disk_percent" -gt 80 ]; then
        log_warning "  Disk: $disk_usage (${disk_percent}%) ⚠️ HIGH"
        warnings=$((warnings+1))
    else
        log_success "  Disk: $disk_usage (${disk_percent}%) ✓"
    fi
    
    # Swap
    if swapon --show | grep -q swapfile; then
        local swap_used swap_total
        swap_used=$(free -m | awk '/^Swap:/{print $3}')
        swap_total=$(free -m | awk '/^Swap:/{print $2}')
        log_success "  Swap: ${swap_used}MB/${swap_total}MB ✓"
    else
        log_warning "  Swap: Not configured ⚠️"
        warnings=$((warnings+1))
    fi
    
    echo ""
    log_info "🔧 Installed Components:"
    
    # Check User
    if id "$DEV_USER" &>/dev/null; then
        log_success "  User '$DEV_USER': ✓ Exists"
        
        # Check sudo access
        if run_as_user "$DEV_USER" sudo -n true 2>/dev/null; then
            log_success "  Sudo Access: ✓ OK"
        else
            log_warning "  Sudo Access: ⚠️ Not configured"
            warnings=$((warnings+1))
        fi
    else
        log_error "  User '$DEV_USER': ✗ Not found"
        issues=$((issues+1))
    fi
    
    # Check Docker
    if command_exists docker; then
        local docker_version
        docker_version=$(docker --version | cut -d' ' -f3 | tr -d ',')
        log_success "  Docker: ✓ v$docker_version"
        
        # Check Docker service
        if systemctl is-active --quiet docker 2>/dev/null; then
            log_success "    Service: ✓ Running"
        else
            log_warning "    Service: ⚠️ Not running"
            warnings=$((warnings+1))
        fi
        
        # Check Docker group
        if groups "$DEV_USER" | grep -q docker; then
            log_success "    User in docker group: ✓"
        else
            log_warning "    User in docker group: ⚠️ No"
            warnings=$((warnings+1))
        fi
    else
        log_info "  Docker: Not installed"
    fi
    
    # Check Node.js
    if run_as_user "$DEV_USER" bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; command -v node' &>/dev/null; then
        local node_version
        node_version=$(run_as_user "$DEV_USER" bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node --version')
        log_success "  Node.js: ✓ $node_version"
        
        # Check npm
        local npm_version
        npm_version=$(run_as_user "$DEV_USER" bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npm --version')
        log_success "    npm: ✓ v$npm_version"
    else
        log_info "  Node.js: Not installed or not in PATH"
    fi
    
    # Check Python
    if command_exists python3; then
        local python_version
        python_version=$(python3 --version | cut -d' ' -f2)
        log_success "  Python: ✓ v$python_version"
        
        # Check pip
        if command_exists pip3; then
            log_success "    pip3: ✓ Installed"
        else
            log_warning "    pip3: ⚠️ Not installed"
            warnings=$((warnings+1))
        fi
    else
        log_info "  Python: Not installed"
    fi
    
    # Check VS Code
    if command_exists code; then
        local code_version
        code_version=$(code --version 2>/dev/null | head -n1)
        log_success "  VS Code: ✓ v$code_version"
    else
        log_info "  VS Code: Not installed"
    fi
    
    # Check Cursor
    if command_exists cursor || run_as_user "$DEV_USER" bash -c 'command -v cursor' &>/dev/null; then
        log_success "  Cursor: ✓ Installed"
    elif [ -f /opt/cursor/cursor.AppImage ]; then
        log_success "  Cursor: ✓ AppImage available"
    else
        log_info "  Cursor: Not installed"
    fi
    
    # Check XRDP
    if command_exists xrdp; then
        log_success "  XRDP: ✓ Installed"
        
        if systemctl is-active --quiet xrdp 2>/dev/null; then
            log_success "    Service: ✓ Running"
            
            # Check port 3389
            if ss -tlnp | grep -q :3389; then
                log_success "    Port 3389: ✓ Listening"
            else
                log_warning "    Port 3389: ⚠️ Not listening"
                warnings=$((warnings+1))
            fi
        else
            log_warning "    Service: ⚠️ Not running"
            warnings=$((warnings+1))
        fi
    else
        log_info "  XRDP: Not installed"
    fi
    
    # Check XFCE
    if command_exists xfce4-session; then
        log_success "  XFCE4: ✓ Installed"
    else
        log_info "  XFCE4: Not installed"
    fi
    
    # Check Zsh & Oh My Zsh
    if command_exists zsh; then
        log_success "  Zsh: ✓ Installed"
        
        if [ -d "/home/$DEV_USER/.oh-my-zsh" ]; then
            log_success "    Oh My Zsh: ✓ Installed"
        else
            log_info "    Oh My Zsh: Not installed"
        fi
    else
        log_info "  Zsh: Not installed"
    fi
    
    echo ""
    log_info "🔒 Security Status:"
    
    # Check UFW
    if command_exists ufw; then
        if ufw status | grep -q "Status: active"; then
            log_success "  UFW Firewall: ✓ Active"
            
            # Show allowed ports
            local allowed_ports
            allowed_ports=$(ufw status | grep ALLOW | awk '{print $1}' | tr '\n' ', ' | sed 's/,$//')
            log_info "    Allowed: $allowed_ports"
        else
            log_warning "  UFW Firewall: ⚠️ Inactive"
            warnings=$((warnings+1))
        fi
    else
        log_warning "  UFW Firewall: ⚠️ Not installed"
        warnings=$((warnings+1))
    fi
    
    # Check Fail2Ban
    if command_exists fail2ban-client; then
        if systemctl is-active --quiet fail2ban 2>/dev/null; then
            log_success "  Fail2Ban: ✓ Active"
        else
            log_warning "  Fail2Ban: ⚠️ Not running"
            warnings=$((warnings+1))
        fi
    else
        log_info "  Fail2Ban: Not installed"
    fi
    
    # Check SSH
    if systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null; then
        log_success "  SSH Service: ✓ Running"
        
        # Check SSH config
        if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
            log_warning "    Root login: ⚠️ Enabled (security risk)"
            warnings=$((warnings+1))
        else
            log_success "    Root login: ✓ Disabled/Limited"
        fi
    else
        log_warning "  SSH Service: ⚠️ Not running"
        warnings=$((warnings+1))
    fi
    
    echo ""
    log_info "📈 System Information:"
    log_info "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    log_info "  Kernel: $(uname -r)"
    log_info "  Uptime: $(uptime -p)"
    log_info "  Architecture: $(uname -m)"
    
    # Network info
    local ip_address
    ip_address=$(hostname -I | awk '{print $1}')
    log_info "  IP Address: $ip_address"
    
    echo ""
    log_info "=== Health Check Summary ==="
    
    if [ $issues -eq 0 ] && [ $warnings -eq 0 ]; then
        log_success "✓ System is healthy! No issues found."
    elif [ $issues -eq 0 ]; then
        log_warning "⚠️ System has $warnings warning(s)"
    else
        log_error "⚠️ System has $issues issue(s) and $warnings warning(s)"
        log_error "Please review the issues above"
    fi
    
    echo ""
}

# Quick status check (compact version)
quick_status() {
    echo "Quick Status Check:"
    echo "==================="
    
    # Components check
    local components=(docker node python3 code cursor xrdp zsh)
    local component_names=("Docker" "Node.js" "Python" "VS Code" "Cursor" "XRDP" "Zsh")
    
    for i in "${!components[@]}"; do
        local cmd="${components[$i]}"
        local name="${component_names[$i]}"
        
        if command_exists "$cmd" || run_as_user "$DEV_USER" bash -c "command -v $cmd" &>/dev/null; then
            echo "✓ $name"
        else
            echo "✗ $name"
        fi
    done
    
    # System resources
    local mem_percent=$(free | awk '/^Mem:/{printf "%.0f", ($3/$2)*100}')
    local disk_percent=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    
    echo ""
    echo "Resources:"
    echo "  RAM: ${mem_percent}%"
    echo "  Disk: ${disk_percent}%"
}

