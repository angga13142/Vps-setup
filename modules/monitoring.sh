#!/bin/bash

# ==============================================================================
# Performance Monitoring Module - Resource Monitoring & Alerts
# ==============================================================================

setup_monitoring() {
    update_progress "setup_monitoring"
    log_info "=== Performance Monitoring Setup ==="
    echo ""
    
    # Install monitoring tools
    install_monitoring_tools
    
    # Setup monitoring scripts
    setup_monitoring_scripts
    
    # Setup cron jobs for periodic checks
    setup_monitoring_cron
    
    log_success "Performance monitoring setup selesai"
}

install_monitoring_tools() {
    log_info "Installing monitoring tools..."
    
    local tools=(
        "htop"          # Interactive process viewer
        "iotop"         # I/O monitoring
        "nethogs"       # Network bandwidth monitor
        "sysstat"       # Performance monitoring tools (sar, iostat)
        "vnstat"        # Network traffic monitor
        "ncdu"          # Disk usage analyzer
    )
    
    for tool in "${tools[@]}"; do
        check_and_install "$tool" || log_warning "Failed to install $tool"
    done
    
    log_success "  ✓ Monitoring tools installed"
}

setup_monitoring_scripts() {
    log_info "Creating monitoring scripts..."
    
    local monitor_dir="/opt/vps-monitor"
    mkdir -p "$monitor_dir"
    
    # Create resource monitor script
    cat > "$monitor_dir/resource-monitor.sh" <<'MONITOR_SCRIPT'
#!/bin/bash
# VPS Resource Monitor
# Checks system resources and alerts if thresholds exceeded

LOG_FILE="/var/log/vps-monitor.log"
ALERT_FILE="/var/log/vps-alerts.log"

# Thresholds
CPU_THRESHOLD=80
RAM_THRESHOLD=85
DISK_THRESHOLD=85
LOAD_THRESHOLD=2.0

log_status() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" >> "$ALERT_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" >> "$LOG_FILE"
}

# Check CPU usage (average over 5 minutes)
check_cpu() {
    local cpu_usage=$(top -bn2 -d 0.5 | grep "Cpu(s)" | tail -1 | awk '{print $2}' | cut -d'%' -f1)
    cpu_usage=${cpu_usage%.*}
    
    log_status "CPU Usage: ${cpu_usage}%"
    
    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        log_alert "High CPU usage: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
        
        # Log top processes
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Top CPU processes:" >> "$ALERT_FILE"
        ps aux --sort=-%cpu | head -6 >> "$ALERT_FILE"
    fi
}

# Check RAM usage
check_ram() {
    local ram_percent=$(free | awk '/^Mem:/{printf "%.0f", ($3/$2)*100}')
    
    log_status "RAM Usage: ${ram_percent}%"
    
    if [ "$ram_percent" -gt "$RAM_THRESHOLD" ]; then
        log_alert "High RAM usage: ${ram_percent}% (threshold: ${RAM_THRESHOLD}%)"
        
        # Log top memory processes
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Top memory processes:" >> "$ALERT_FILE"
        ps aux --sort=-%mem | head -6 >> "$ALERT_FILE"
    fi
}

# Check Disk usage
check_disk() {
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    
    log_status "Disk Usage: ${disk_usage}%"
    
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        log_alert "High disk usage: ${disk_usage}% (threshold: ${DISK_THRESHOLD}%)"
        
        # Log largest directories
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Largest directories:" >> "$ALERT_FILE"
        du -hx --max-depth=2 / 2>/dev/null | sort -rh | head -10 >> "$ALERT_FILE"
    fi
}

# Check Load Average
check_load() {
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    local cpu_cores=$(nproc)
    local load_per_core=$(echo "scale=2; $load_avg / $cpu_cores" | bc)
    
    log_status "Load Average: $load_avg (${cpu_cores} cores, ${load_per_core} per core)"
    
    if (( $(echo "$load_per_core > $LOAD_THRESHOLD" | bc -l) )); then
        log_alert "High load average: $load_avg (${load_per_core} per core, threshold: ${LOAD_THRESHOLD})"
    fi
}

# Check for failed services
check_services() {
    local failed_services=$(systemctl --failed --no-legend | awk '{print $1}')
    
    if [ -n "$failed_services" ]; then
        log_alert "Failed services detected:"
        echo "$failed_services" | while read service; do
            log_alert "  - $service"
        done
    fi
}

# Main monitoring
log_status "=== Resource Check Start ==="
check_cpu
check_ram
check_disk
check_load
check_services
log_status "=== Resource Check Complete ==="
MONITOR_SCRIPT
    
    chmod +x "$monitor_dir/resource-monitor.sh"
    log_success "  ✓ Resource monitor script created"
    
    # Create performance report script
    cat > "$monitor_dir/performance-report.sh" <<'REPORT_SCRIPT'
#!/bin/bash
# VPS Performance Report Generator

echo "========================================="
echo "  VPS Performance Report"
echo "  Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="
echo ""

# System Info
echo "System Information:"
echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "  Kernel: $(uname -r)"
echo "  Uptime: $(uptime -p)"
echo ""

# CPU Info
echo "CPU Information:"
echo "  Model: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
echo "  Cores: $(nproc)"
echo "  Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "  Temperature: $(sensors 2>/dev/null | grep -i core | head -1 || echo "N/A")"
echo ""

# Memory Info
echo "Memory Usage:"
free -h | grep -v "+"
echo ""

# Disk Info
echo "Disk Usage:"
df -h | grep -E '^(/dev/|Filesystem)'
echo ""

# Top Processes by CPU
echo "Top 5 Processes by CPU:"
ps aux --sort=-%cpu | head -6 | awk '{printf "  %-10s %-6s %-6s %s\n", $1, $2, $3, $11}'
echo ""

# Top Processes by Memory
echo "Top 5 Processes by Memory:"
ps aux --sort=-%mem | head -6 | awk '{printf "  %-10s %-6s %-6s %s\n", $1, $2, $4, $11}'
echo ""

# Network Stats
echo "Network Statistics:"
if command -v vnstat &>/dev/null; then
    vnstat --oneline 2>/dev/null | awk -F';' '{print "  Today: "$6" / "$7" (RX/TX)"}'
else
    echo "  vnstat not available"
fi
echo ""

# Service Status
echo "Critical Services:"
for service in ssh sshd xrdp docker; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "  ✓ $service: running"
    else
        echo "  ✗ $service: not running"
    fi
done
echo ""

# Recent Alerts
if [ -f /var/log/vps-alerts.log ]; then
    echo "Recent Alerts (last 5):"
    tail -5 /var/log/vps-alerts.log | sed 's/^/  /'
    echo ""
fi

echo "========================================="
REPORT_SCRIPT
    
    chmod +x "$monitor_dir/performance-report.sh"
    log_success "  ✓ Performance report script created"
    
    # Create quick stats script
    cat > "$monitor_dir/quick-stats.sh" <<'STATS_SCRIPT'
#!/bin/bash
# Quick VPS Stats

cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
ram=$(free | awk '/^Mem:/{printf "%.0f", ($3/$2)*100}')
disk=$(df / | tail -1 | awk '{print $5}')
load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')

echo "Quick Stats:"
echo "  CPU:  ${cpu}%"
echo "  RAM:  ${ram}%"
echo "  Disk: ${disk}"
echo "  Load: ${load}"
STATS_SCRIPT
    
    chmod +x "$monitor_dir/quick-stats.sh"
    log_success "  ✓ Quick stats script created"
    
    # Create symlinks for easy access
    ln -sf "$monitor_dir/resource-monitor.sh" /usr/local/bin/vps-monitor 2>/dev/null || true
    ln -sf "$monitor_dir/performance-report.sh" /usr/local/bin/vps-report 2>/dev/null || true
    ln -sf "$monitor_dir/quick-stats.sh" /usr/local/bin/vps-stats 2>/dev/null || true
    
    log_success "  ✓ Symlinks created: vps-monitor, vps-report, vps-stats"
}

setup_monitoring_cron() {
    log_info "Setting up monitoring cron jobs..."
    
    # Create cron job for resource monitoring (every 15 minutes)
    local cron_file="/etc/cron.d/vps-monitor"
    
    cat > "$cron_file" <<'CRON'
# VPS Resource Monitoring
# Runs every 15 minutes

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Resource monitoring
*/15 * * * * root /opt/vps-monitor/resource-monitor.sh >/dev/null 2>&1

# Daily performance report (sent to root's mail if available)
0 6 * * * root /opt/vps-monitor/performance-report.sh > /tmp/vps-daily-report.txt 2>&1

# Weekly cleanup of old logs (keep last 30 days)
0 0 * * 0 root find /var/log -name "vps-*.log" -type f -mtime +30 -delete 2>/dev/null
CRON
    
    chmod 644 "$cron_file"
    log_success "  ✓ Cron jobs configured"
    
    # Restart cron service
    if systemctl is-active --quiet cron 2>/dev/null; then
        systemctl restart cron
    elif systemctl is-active --quiet crond 2>/dev/null; then
        systemctl restart crond
    fi
}

show_monitoring_info() {
    echo ""
    log_info "=== Monitoring Commands ==="
    echo ""
    log_info "Available commands:"
    log_info "  vps-stats     - Quick system stats"
    log_info "  vps-report    - Full performance report"
    log_info "  vps-monitor   - Run resource check"
    log_info "  htop          - Interactive process viewer"
    log_info "  iotop         - I/O usage"
    log_info "  nethogs       - Network usage by process"
    echo ""
    log_info "Log files:"
    log_info "  /var/log/vps-monitor.log  - Monitoring logs"
    log_info "  /var/log/vps-alerts.log   - Alert logs"
    echo ""
    log_info "Monitoring runs automatically every 15 minutes"
    log_info "Daily reports generated at 06:00"
    echo ""
}

# Real-time monitoring
realtime_monitor() {
    log_info "=== Real-time Resource Monitor ==="
    log_info "Press Ctrl+C to stop"
    echo ""
    
    while true; do
        clear
        echo "========================================="
        echo "  VPS Real-time Monitor"
        echo "  $(date '+%Y-%m-%d %H:%M:%S')"
        echo "========================================="
        echo ""
        
        # CPU
        local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        echo "CPU Usage: ${cpu}%"
        printf "["
        local bars=$((${cpu%.*}/2))
        for ((i=0; i<50; i++)); do
            if [ $i -lt $bars ]; then
                printf "▓"
            else
                printf "░"
            fi
        done
        printf "]\n\n"
        
        # RAM
        local ram=$(free | awk '/^Mem:/{printf "%.0f", ($3/$2)*100}')
        echo "RAM Usage: ${ram}%"
        printf "["
        bars=$((ram/2))
        for ((i=0; i<50; i++)); do
            if [ $i -lt $bars ]; then
                printf "▓"
            else
                printf "░"
            fi
        done
        printf "]\n\n"
        
        # Disk
        local disk=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
        local disk_used=$(df -h / | tail -1 | awk '{print $3}')
        local disk_total=$(df -h / | tail -1 | awk '{print $2}')
        echo "Disk Usage: ${disk}% (${disk_used}/${disk_total})"
        printf "["
        bars=$((disk/2))
        for ((i=0; i<50; i++)); do
            if [ $i -lt $bars ]; then
                printf "▓"
            else
                printf "░"
            fi
        done
        printf "]\n\n"
        
        # Load & Network
        echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        echo "Processes: $(ps aux | wc -l)"
        echo ""
        
        echo "Top 5 Processes by CPU:"
        ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "  %-6s %5s%%  %s\n", $2, $3, $11}'
        
        sleep 2
    done
}

