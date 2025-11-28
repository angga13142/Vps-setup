# Quick Start Guide: Mobile-Ready Coding Workstation

**Feature**: Mobile-Ready Coding Workstation Installation Script  
**Target**: Debian 13 (Trixie)  
**Estimated Time**: 15 minutes

## Prerequisites

- Fresh Debian 13 (Trixie) installation
- Root or sudo access
- Network connectivity
- Minimum 2GB RAM, 10GB disk space

## Installation Steps

### 1. Download the Script

```bash
# Clone or download the script
# (Script location will be determined during implementation)
```

### 2. Make Script Executable

```bash
chmod +x setup-workstation.sh
```

### 3. Run the Script

```bash
sudo ./setup-workstation.sh
```

### 4. Interactive Setup

The script will prompt you for:

1. **Username** (default: `coder`)
   - Press Enter to accept default, or type custom username
   - Must be valid Linux username (alphanumeric, underscore, hyphen)

2. **Password**
   - Type password (input is hidden/silent)
   - Password must not be empty
   - This will be the password for the new user account

3. **Hostname** (e.g., `my-vps`)
   - Enter desired system hostname
   - Must be valid hostname format

4. **Confirmation**
   - Review the inputs
   - Type `yes` to proceed, or `no` to cancel

### 5. Wait for Installation

The script will:
- Set system hostname
- Update package repositories
- Install essential tools (curl, git, htop, vim, build-essential)
- Install XFCE4 desktop environment
- Install and configure XRDP for remote access
- Create user account with custom password
- Configure enhanced terminal prompt with Git awareness
- Install Docker and Docker Compose
- Install Firefox ESR and Chromium browsers
- Install Node.js LTS via NVM
- Configure Python environment
- Apply mobile-optimized desktop settings

**Estimated time**: 10-15 minutes depending on network speed

### 6. Reboot (Required)

After installation completes, reboot the system:

```bash
sudo reboot
```

### 7. Connect via RDP (Mobile Device)

1. Find your server's IP address (displayed in final summary)
2. Use an RDP client on your mobile device
3. Connect to: `your-server-ip:3389`
4. Login with the username and password you created
5. You should see the mobile-optimized XFCE desktop

## Post-Installation Verification

### Verify Terminal Configuration

1. Open terminal in XFCE
2. Check prompt format: Should show `[username@hostname] [directory] [git-branch] $`
3. Test aliases:
   ```bash
   ll          # Should show detailed file listing
   update      # Should update system packages
   docker-clean # Should clean Docker resources
   ```

### Verify Git Branch Detection

```bash
cd /tmp
git clone https://github.com/example/repo.git
cd repo
# Prompt should show current branch name in yellow
```

### Verify Docker

```bash
docker --version
docker ps
# Should work without sudo (user in docker group)
```

### Verify Node.js

```bash
node --version
npm --version
# Should show Node.js LTS version
```

### Verify Python

```bash
python3 --version
# Should show Python 3.x
```

### Verify Mobile Optimization

1. Connect via RDP from mobile device
2. Check font size: Should be 12-13pt (readable without zooming)
3. Check desktop icons: Should be size 48 (finger-friendly)
4. Check panel/taskbar: Should be 48px height (easy to tap)

## Troubleshooting

### Script Fails with "Not Debian 13"

- Verify OS version: `cat /etc/os-release`
- Script only works on Debian 13 (Trixie)

### User Already Exists

- Script will detect existing user
- Either choose different username or handle existing user gracefully

### Network Errors During Installation

- Check internet connectivity
- Verify DNS resolution: `ping google.com`
- Retry script execution (idempotent - safe to re-run)

### XRDP Connection Fails

- Check XRDP service: `systemctl status xrdp`
- Verify firewall allows port 3389
- Check XRDP logs: `journalctl -u xrdp`

### Docker Commands Require Sudo

- User must logout and login again for group changes to take effect
- Or use: `newgrp docker`

### NVM Not Available in Terminal

- Ensure you're logged in as the created user
- Check `.bashrc` has NVM configuration
- Source manually: `source ~/.bashrc`

## Next Steps

1. **Configure SSH Keys** (recommended):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Install Additional Tools**:
   - Your preferred code editor
   - Additional development tools

3. **Configure Git**:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your_email@example.com"
   ```

4. **Start Development**:
   - Your workstation is ready for coding!
   - Use Docker for containerized services
   - Use NVM for Node.js version management

## Support

For issues or questions:
- Check script logs for error messages
- Verify all prerequisites are met
- Ensure Debian 13 (Trixie) compatibility
- Review constitution principles for script behavior
