# 🚀 Advanced Features Guide

Dokumentasi lengkap untuk fitur-fitur advanced VPS Bootstrap Script.

---

## 📋 Table of Contents

1. [Health Check & Status Monitor](#-health-check--status-monitor)
2. [Rollback & Backup Management](#-rollback--backup-management)
3. [Developer Tools Setup](#-developer-tools-setup)
4. [Performance Monitoring](#-performance-monitoring)

---

## 🏥 Health Check & Status Monitor

### Overview
Comprehensive system health check yang memonitor semua komponen, resources, dan services.

### Commands

#### Full Health Check
```bash
sudo ./setup.sh --check
# or
sudo ./setup.sh --healthcheck
```

**Output includes:**
- 📊 System Resources (CPU, RAM, Disk, Swap, Load)
- 🔧 Installed Components status
- 🔒 Security Status (UFW, Fail2Ban, SSH)
- 📈 System Information
- ⚠️ Issues & Warnings summary

#### Quick Stats
```bash
./setup.sh --stats
```

Menampilkan quick overview:
- ✓/✗ Component installation status
- RAM & Disk usage percentage

### Example Output

```
=== System Health Check ===

📊 System Resources:
  CPU Load: 0.45 (4 cores)
  RAM: 1234MB/4096MB (30.1%) ✓
  Disk: 15G/50G (30%) ✓
  Swap: 245MB/4096MB ✓

🔧 Installed Components:
  User 'developer': ✓ Exists
  Sudo Access: ✓ OK
  Docker: ✓ v24.0.7
    Service: ✓ Running
    User in docker group: ✓
  Node.js: ✓ v20.10.0
    npm: ✓ v10.2.3
  Python: ✓ v3.11.2
    pip3: ✓ Installed
  VS Code: ✓ v1.85.1
  Cursor: ✓ Installed
  XRDP: ✓ Installed
    Service: ✓ Running
    Port 3389: ✓ Listening
  Zsh: ✓ Installed
    Oh My Zsh: ✓ Installed

🔒 Security Status:
  UFW Firewall: ✓ Active
    Allowed: 22/tcp, 3389/tcp
  Fail2Ban: ✓ Active
  SSH Service: ✓ Running
    Root login: ✓ Disabled/Limited

=== Health Check Summary ===
✓ System is healthy! No issues found.
```

### Use Cases
- **Daily Monitoring**: Check system status setiap hari
- **After Updates**: Verify components setelah update
- **Troubleshooting**: Quick diagnosis saat ada masalah
- **Documentation**: Generate system status reports

---

## ⏪ Rollback & Backup Management

### Overview
Automated backup system dengan rollback capability. Setiap config file yang dimodifikasi otomatis di-backup.

### Backup System

**Automatic Backups:**
- Created every time script modifies config files
- Stored in `/root/.vps-bootstrap-backups-TIMESTAMP/`
- Preserves directory structure
- Includes file metadata (permissions, ownership)

**Backed up files include:**
- `/etc/fstab` (swap configuration)
- `/etc/sysctl.conf` (system tuning)
- `/etc/sudoers.d/*` (sudo config)
- `/etc/ssh/sshd_config` (SSH settings)
- `/etc/ufw/*` (firewall rules)
- User dotfiles (`.zshrc`, `.bashrc`, etc)
- Application configs

### Commands

#### List Available Backups
```bash
sudo ./setup.sh --list-backups
```

Output:
```
=== Available Backups ===

[1] Backup: .vps-bootstrap-backups-20250125-143022
    Date: 2025-01-25 14:30:22
    Size: 245K
    Files: 12
    Path: /root/.vps-bootstrap-backups-20250125-143022

[2] Backup: .vps-bootstrap-backups-20250124-091545
    Date: 2025-01-24 09:15:45
    Size: 198K
    Files: 9
    Path: /root/.vps-bootstrap-backups-20250124-091545
```

#### Interactive Restore
```bash
sudo ./setup.sh --rollback
```

Process:
1. Lists available backups
2. Select backup number
3. Shows files to be restored
4. Confirmation prompt
5. Creates pre-restore backup (current state)
6. Restores files
7. Reloads affected services

Example session:
```bash
$ sudo ./setup.sh --rollback

=== Available Backups ===
[1] Backup: .vps-bootstrap-backups-20250125-143022
    Date: 2025-01-25 14:30:22
    ...

Enter backup number to restore (or 'q' to quit): 1

=== Backup Contents ===
etc/
  fstab
  sysctl.conf
  sudoers.d/
    developer

Files to restore:
  /etc/fstab
  /etc/sysctl.conf
  /etc/sudoers.d/developer

Proceed with restore? (yes/no): yes

Creating pre-restore backup: /root/.vps-pre-restore-20250125-150345
Restoring files...
  ✓ Restored: /etc/fstab
  ✓ Restored: /etc/sysctl.conf
  ✓ Restored: /etc/sudoers.d/developer

=== Restore Summary ===
Restored: 3 files
Pre-restore backup saved to: /root/.vps-pre-restore-20250125-150345
Reloading affected services...
  ✓ sysctl reloaded

Restore completed!
```

#### Cleanup Old Backups
```bash
sudo ./setup.sh --cleanup-backups
```

- Keeps last 5 backups
- Removes older backups
- Shows freed disk space

### Safety Features

1. **Pre-Restore Backup**: Before restoring, current state is backed up
2. **Validation**: Checks backup integrity before restore
3. **Service Reload**: Automatically reloads affected services
4. **Non-Destructive**: Original backups never modified

### Use Cases
- **Configuration Mistakes**: Rollback bad config changes
- **After Failed Updates**: Restore to working state
- **Testing**: Try configurations safely with rollback option
- **Disaster Recovery**: Quick recovery from system issues

---

## 🔧 Developer Tools Setup

### Overview
One-command setup untuk complete developer environment termasuk Git, SSH keys, GPG, aliases, dan utilities.

### Command
```bash
sudo ./setup.sh --devtools
```

Or with Git config:
```bash
sudo GIT_USER_NAME="John Doe" \
     GIT_USER_EMAIL="john@example.com" \
     ./setup.sh --devtools
```

### What It Installs

#### 1. **Git Configuration**
- Global user.name and user.email
- Useful aliases: `co`, `br`, `ci`, `st`, `unstage`, `last`, `lg`, `tree`
- Better defaults (main branch, auto-coloring, etc)

```bash
# Configured aliases
git co  = git checkout
git st  = git status
git lg  = git log --graph --pretty
git tree = git log --all --graph --oneline
```

#### 2. **SSH Keys**
- Generates ED25519 key pair (modern, secure)
- Creates `~/.ssh/config` with GitHub/GitLab settings
- Shows public key for easy copying to Git providers
- Sets up ssh-agent

Example output:
```
🔑 Setting up SSH Keys...
  Generating SSH key (ed25519)...
  ✓ SSH key generated
  Public key:
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbc123... developer@hostname
  
  Add this key to your GitHub/GitLab:
    GitHub: https://github.com/settings/keys
    GitLab: https://gitlab.com/-/profile/keys
```

#### 3. **GPG Keys (Optional)**
- Checks for existing GPG keys
- Configures Git to sign commits if key exists
- Instructions for generating new key

#### 4. **Shell Aliases & Functions**

**Directory Navigation:**
```bash
..      # cd ..
...     # cd ../..
....    # cd ../../..
ll      # ls -lah
la      # ls -A
```

**Git Shortcuts:**
```bash
g       # git
gs      # git status
ga      # git add
gc      # git commit
gp      # git push
gl      # git pull
gd      # git diff
gco     # git checkout
gb      # git branch
glog    # git log --oneline --graph
```

**Docker Shortcuts:**
```bash
d       # docker
dc      # docker-compose
dps     # docker ps
dpsa    # docker ps -a
di      # docker images
dex     # docker exec -it
dlog    # docker logs -f
dprune  # docker system prune -af
```

**System:**
```bash
update  # sudo apt update && upgrade
ports   # show listening ports
myip    # show public IP
serverstatus # systemctl status
```

**Development:**
```bash
serve   # python3 -m http.server
npmls   # npm list -g --depth=0
pyclean # remove __pycache__ dirs
```

**Useful Functions:**
```bash
mkcd dirname        # mkdir && cd
extract file.zip    # extract any archive
findlarge 100M      # find files > 100MB
psgrep process      # search running processes
```

#### 5. **Developer Utilities**
- `tree` - Directory tree viewer
- `jq` - JSON processor
- `ag` (silversearcher) - Fast code search
- `tmux` - Terminal multiplexer
- `vim` - Text editor
- `ncdu` - Disk usage analyzer
- `ripgrep` - Fast grep alternative

### Configuration Files Modified
- `~/.zshrc` or `~/.bashrc` (aliases & functions)
- `~/.gitconfig` (git settings)
- `~/.ssh/config` (SSH settings)
- `~/.ssh/id_ed25519*` (SSH keys)

### Post-Setup Information
```
=== Developer Tools Configuration ===

Git Configuration:
  Name: John Doe
  Email: john@example.com

SSH Public Key:
  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbc123...

GPG Key: Configured

Available Aliases: g, gs, ga, gc, gp, gl, d, dc, dps, ll, ...
Available Functions: mkcd, extract, findlarge, psgrep
Run 'alias' in terminal to see all aliases
```

### Use Cases
- **New Server Setup**: Quick dev environment setup
- **Team Onboarding**: Consistent dev tools across team
- **Personal Customization**: Your favorite aliases everywhere
- **Productivity**: Shortcuts for common tasks

---

## 📊 Performance Monitoring

### Overview
Comprehensive performance monitoring system dengan automated checks, alerts, dan reporting.

### Setup Command
```bash
sudo ./setup.sh --monitor
```

### What It Installs

#### 1. **Monitoring Tools**
- `htop` - Interactive process viewer
- `iotop` - I/O monitoring
- `nethogs` - Network bandwidth monitor
- `sysstat` - Performance tools (sar, iostat)
- `vnstat` - Network traffic monitor
- `ncdu` - Disk usage analyzer

#### 2. **Monitoring Scripts**
Located in `/opt/vps-monitor/`:

**resource-monitor.sh** - Automated resource checking
- Checks CPU, RAM, Disk, Load, Services
- Logs to `/var/log/vps-monitor.log`
- Alerts to `/var/log/vps-alerts.log` when thresholds exceeded
- Runs every 15 minutes via cron

**performance-report.sh** - Comprehensive system report
- System info, resource usage, top processes
- Network statistics, service status
- Recent alerts summary
- Runs daily at 06:00

**quick-stats.sh** - Quick stats display
- CPU, RAM, Disk, Load in one view

#### 3. **Cron Jobs**
Automatically configured:
```
*/15 * * * * resource-monitor.sh  # Every 15 min
0 6 * * * performance-report.sh   # Daily at 06:00
0 0 * * 0 cleanup old logs        # Weekly
```

#### 4. **Command Shortcuts**
Symlinks created for easy access:
- `vps-monitor` → resource-monitor.sh
- `vps-report` → performance-report.sh
- `vps-stats` → quick-stats.sh

### Commands

#### Quick Stats
```bash
vps-stats
# or
./setup.sh --stats
```

Output:
```
Quick Stats:
  CPU:  15.2%
  RAM:  45%
  Disk: 35%
  Load: 0.78
```

#### Full Performance Report
```bash
vps-report
# or
./setup.sh --report
```

Output includes:
- System Information
- CPU details & load
- Memory usage breakdown
- Disk usage per partition
- Top 5 processes by CPU/Memory
- Network statistics
- Service status
- Recent alerts

#### Real-time Monitor
```bash
./setup.sh --realtime
```

Interactive dashboard with live updates:
```
=========================================
  VPS Real-time Monitor
  2025-01-25 14:35:12
=========================================

CPU Usage: 23%
[▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]

RAM Usage: 45%
[▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░]

Disk Usage: 35% (18G/50G)
[▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]

Load Average:  0.78, 0.65, 0.54
Processes: 145

Top 5 Processes by CPU:
  12345  15.2%  node
  23456   8.3%  docker
  34567   4.1%  xrdp
  45678   2.9%  python3
  56789   1.8%  sshd
```

Updates every 2 seconds, press Ctrl+C to exit.

#### Manual Resource Check
```bash
vps-monitor
```

Runs immediate check and logs results.

### Alert Thresholds
Default thresholds (configurable in script):
- CPU: 80%
- RAM: 85%
- Disk: 85%
- Load per core: 2.0

When exceeded:
- Alert logged to `/var/log/vps-alerts.log`
- Top offending processes logged
- Largest directories logged (for disk)

### Log Files
- `/var/log/vps-monitor.log` - All monitoring activity
- `/var/log/vps-alerts.log` - Alerts only

View recent alerts:
```bash
tail -f /var/log/vps-alerts.log
```

View monitoring log:
```bash
tail -f /var/log/vps-monitor.log
```

### Example Alert
```
[2025-01-25 14:30:45] ALERT: High RAM usage: 87% (threshold: 85%)
[2025-01-25 14:30:45] Top memory processes:
USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
node      1234  5.2 42.1 8234532 1723512 ?     Ssl  10:30   2:15 node server.js
docker    2345  2.1 18.3 4123456  748392 ?     Ssl  09:15   1:45 dockerd
python    3456  1.5 12.4 2345678  507392 ?     Sl   11:20   0:45 python3 app.py
```

### Use Cases
- **Proactive Monitoring**: Catch issues before they become problems
- **Resource Planning**: Track usage trends over time
- **Troubleshooting**: Identify resource hogs quickly
- **Capacity Planning**: Know when to upgrade
- **SLA Monitoring**: Ensure uptime and performance

### Advanced Usage

#### Custom Thresholds
Edit `/opt/vps-monitor/resource-monitor.sh`:
```bash
CPU_THRESHOLD=80     # Change to your preference
RAM_THRESHOLD=85
DISK_THRESHOLD=85
LOAD_THRESHOLD=2.0
```

#### Email Alerts
Configure mail server and modify alert logging to send emails:
```bash
log_alert() {
    echo "[$(date)] ALERT: $1" >> "$ALERT_FILE"
    echo "$1" | mail -s "VPS Alert" admin@example.com
}
```

---

## 🎯 Feature Comparison

| Feature | Health Check | Rollback | DevTools | Monitoring |
|---------|--------------|----------|----------|------------|
| **Purpose** | System status | Restore configs | Dev environment | Resource tracking |
| **Frequency** | On-demand | When needed | One-time setup | Continuous (15min) |
| **Root Required** | Yes | Yes | Yes | Yes (setup) |
| **Logs Generated** | No | Yes | No | Yes |
| **Automated** | No | No | No | Yes (cron) |
| **Interactive** | No | Yes (restore) | Partial | Yes (realtime) |

---

## 💡 Best Practices

### Health Checks
- Run weekly untuk routine maintenance
- Run setelah major changes atau updates
- Use `--stats` untuk quick daily check
- Document alerts dan resolutions

### Backups & Rollback
- Verify backups exist sebelum major changes
- Test rollback in non-production first
- Keep at least 5 backups (auto-cleanup)
- Document what was restored dan why

### Developer Tools
- Setup GPG keys untuk signed commits
- Update Git config saat perlu
- Customize aliases sesuai workflow
- Backup `.zshrc`/`.bashrc` ke dotfiles repo

### Monitoring
- Review alerts weekly
- Adjust thresholds berdasarkan baseline
- Archive old logs regularly
- Setup notifications untuk critical alerts

---

## 🚀 Quick Reference

```bash
# Health & Status
./setup.sh --check         # Full health check
./setup.sh --stats         # Quick stats

# Monitoring
./setup.sh --monitor       # Setup monitoring
./setup.sh --realtime      # Live dashboard
vps-stats                  # Quick stats
vps-report                 # Full report
vps-monitor                # Run check now

# Maintenance
./setup.sh --rollback      # Interactive restore
./setup.sh --list-backups  # Show backups
./setup.sh --cleanup-backups # Clean old backups

# Developer Tools
./setup.sh --devtools      # Setup dev environment

# Installation
./setup.sh                 # Full install
./setup.sh --skip-cursor   # Selective install
```

---

**Happy Monitoring! 📊🚀**

