# Troubleshooting Guide

This guide addresses common issues encountered when using the Mobile-Ready Coding Workstation Setup Script.

## Table of Contents

- [Common Errors](#common-errors)
- [Installation Issues](#installation-issues)
- [Configuration Issues](#configuration-issues)
- [Remote Access Issues](#remote-access-issues)
- [Getting Help](#getting-help)

## Common Errors

### "CUSTOM_PASS: unbound variable" Error

**Symptom**: Script fails with error message:
```
main: line 147: CUSTOM_PASS: unbound variable
```

**Cause**: Variable `CUSTOM_PASS` was used before being initialized, triggering `set -u` (exit on undefined variable).

**Solution**: This issue has been fixed in version 1.0.0. The script now initializes `CUSTOM_PASS` and `CUSTOM_HOSTNAME` to empty strings before their respective input loops.

**Prevention**: Always initialize variables before using them in conditional checks when `set -u` is enabled.

**Status**: ✅ Fixed in v1.0.0

---

### "Malformed stanza" or "Malformed entry (Component)" Docker Repository Error

**Symptom**: Script fails when setting up Docker repository with error:
```
E: Malformed stanza 1 in source list /etc/apt/sources.list.d/docker.sources (type)
E: Malformed entry 1 in sources file /etc/apt/sources.list.d/docker.sources (Component)
```

**Cause**: Docker repository file was created in incorrect format. Debian 13 uses DEB822 format for `.sources` files, which requires specific field separation.

**Solution**: This issue has been fixed in version 1.0.0. The script now:
1. Uses correct DEB822 format with separated `Suites` and `Components` fields
2. Removes old `.list` or malformed `.sources` files during migration
3. Follows official Docker documentation format

**Manual Fix** (if needed):
```bash
# Remove malformed repository file
sudo rm -f /etc/apt/sources.list.d/docker.sources
sudo rm -f /etc/apt/sources.list.d/docker.list

# Re-run the script
sudo ./setup-workstation.sh
```

**Status**: ✅ Fixed in v1.0.0

---

### Password Input Loop Issues

**Symptom**: When running script via `curl ... | bash`, password prompt loops indefinitely:
```
Password cannot be empty. Please enter a password.
Password cannot be empty. Please enter a password.
...
```

**Cause**: When script is piped (`curl ... | bash`), stdin is redirected, causing `read -sp` to read from the pipe instead of the terminal.

**Solution**: This issue has been fixed in version 1.0.0. The script now:
1. Checks if stdin/stdout are terminals (`[ -t 0 ] && [ -t 1 ]`)
2. Redirects `read` commands to `/dev/tty` when script is piped
3. Ensures all interactive prompts work correctly in both direct and piped execution

**Manual Fix** (if needed):
```bash
# Download script first, then run directly
curl -fsSL https://raw.githubusercontent.com/angga13142/Vps-setup/master/scripts/setup-workstation.sh -o setup-workstation.sh
chmod +x setup-workstation.sh
sudo ./setup-workstation.sh
```

**Status**: ✅ Fixed in v1.0.0

---

### XFCE Configuration Not Applying

**Symptom**: After installation, XFCE desktop doesn't show mobile-optimized settings (large fonts, large icons, large panel).

**Cause**: XFCE configuration requires an active XFCE session. If the script runs before user logs in via RDP, `xfconf-query` commands fail silently.

**Solution**: The script includes a fallback mechanism:
1. If `xfconf-query` fails (XFCE not running), an autostart script is created
2. The autostart script applies settings on first XFCE login
3. The script removes itself after execution

**Manual Fix** (if needed):
```bash
# Log in via RDP first, then run configuration manually
su - coder -c "xfconf-query -c xsettings -p /Gtk/FontName -s 'Sans 12'"
su - coder -c "xfconf-query -c xfce4-desktop -p /desktop-icons/icon-size -t int -s 48"
su - coder -c "xfconf-query -c xfce4-panel -p /panels/panel-1/size -t int -s 48"
```

**Verification**:
```bash
# Check if autostart script exists
ls -la /home/coder/.xfce4-mobile-config.sh
ls -la /home/coder/.config/autostart/xfce4-mobile-config.desktop
```

**Status**: ✅ Handled with fallback mechanism

---

## Installation Issues

### Script Not Executable

**Symptom**: Error when trying to run script:
```
bash: ./setup-workstation.sh: Permission denied
```

**Solution**:
```bash
chmod +x setup-workstation.sh
sudo ./setup-workstation.sh
```

---

### "This script requires Debian 13 (Trixie)" Error

**Symptom**: Script exits with error about OS version.

**Cause**: Script is designed specifically for Debian 13 (Trixie).

**Solution**:
- Use Debian 13 (Trixie) or wait for support for other versions
- Check your OS version: `cat /etc/os-release`

---

### "This script must be run as root or with sudo" Error

**Symptom**: Script exits with error about root privileges.

**Solution**:
```bash
sudo ./setup-workstation.sh
```

**Note**: Some operations (user creation, package installation, system configuration) require root privileges.

---

### Docker Installation Fails

**Symptom**: Docker installation step fails with network or GPG errors.

**Possible Causes**:
1. Network connectivity issues
2. Docker GPG key download failure
3. APT repository configuration issues

**Solution**:
```bash
# Check network connectivity
ping -c 3 download.docker.com

# Manually refresh Docker GPG key
sudo rm -f /etc/apt/keyrings/docker.asc
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Re-run Docker setup
sudo ./setup-workstation.sh
```

---

### NVM/Node.js Installation Fails

**Symptom**: NVM or Node.js installation fails.

**Possible Causes**:
1. Network connectivity issues
2. User home directory permissions
3. NVM installation script failure

**Solution**:
```bash
# Check network connectivity
ping -c 3 raw.githubusercontent.com

# Manually install NVM as the user
su - coder -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
su - coder -c 'source ~/.nvm/nvm.sh && nvm install --lts'
```

---

## Configuration Issues

### Shell Configuration Not Applied

**Symptom**: Custom PS1 prompt, aliases, or Git branch detection not working.

**Solution**:
```bash
# Check if .bashrc has custom configuration
grep "Mobile-Ready Workstation Custom Configuration" /home/coder/.bashrc

# If missing, re-run configuration
sudo ./setup-workstation.sh
# Or manually source the configuration
source /home/coder/.bashrc
```

---

### Docker Group Not Applied

**Symptom**: User cannot run Docker commands without sudo.

**Cause**: User must logout and login again for group membership to take effect.

**Solution**:
```bash
# Verify user is in docker group
groups coder

# If not in group, add manually
sudo usermod -aG docker coder

# User must logout and login again
# Or use newgrp (temporary)
newgrp docker
```

---

## Remote Access Issues

### Cannot Connect via RDP

**Symptom**: RDP connection fails or times out.

**Troubleshooting Steps**:

1. **Check XRDP service status**:
   ```bash
   sudo systemctl status xrdp
   ```

2. **Start XRDP if not running**:
   ```bash
   sudo systemctl start xrdp
   sudo systemctl enable xrdp
   ```

3. **Check firewall**:
   ```bash
   # Allow RDP port (3389)
   sudo ufw allow 3389/tcp
   # Or if using iptables
   sudo iptables -A INPUT -p tcp --dport 3389 -j ACCEPT
   ```

4. **Verify IP address**:
   ```bash
   hostname -I
   # Or
   ip addr show
   ```

5. **Test RDP connection locally**:
   ```bash
   # From the server itself
   xrdp-sesman -n
   ```

---

### XRDP Service Not Starting

**Symptom**: XRDP service fails to start.

**Solution**:
```bash
# Check service logs
sudo journalctl -u xrdp -n 50

# Restart service
sudo systemctl restart xrdp

# Check for port conflicts
sudo netstat -tulpn | grep 3389
```

---

## Getting Help

### Check Script Logs

The script outputs progress information to stdout. For detailed debugging:

```bash
# Run with verbose output
sudo bash -x ./setup-workstation.sh 2>&1 | tee installation.log

# Review the log
cat installation.log
```

### Verify Installation

After installation, verify components:

```bash
# Check user exists
id coder

# Check Docker
docker --version
docker compose version

# Check Node.js
su - coder -c 'source ~/.nvm/nvm.sh && node --version'

# Check Python
python3 --version

# Check XRDP
systemctl status xrdp

# Check XFCE packages
dpkg -l | grep xfce4
```

### Report Issues

If you encounter an issue not covered in this guide:

1. **Check existing issues**: Search GitHub issues for similar problems
2. **Create new issue**: Include:
   - OS version: `cat /etc/os-release`
   - Script version: Check script header or git commit
   - Error messages: Full error output
   - Steps to reproduce: Detailed steps
   - Expected vs actual behavior

### Additional Resources

- **README.md**: Project overview and quick start
- **CONTRIBUTING.md**: Development workflow and guidelines
- **CHANGELOG.md**: Version history and changes
- **GitHub Issues**: Known issues and feature requests

---

**Last Updated**: 2025-01-27  
**Script Version**: 1.0.0
