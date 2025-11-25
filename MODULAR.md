# 📁 Modular Architecture Documentation

## 🎯 Overview

Script VPS Bootstrap telah di-refactor menjadi **modular architecture** yang lebih maintainable, testable, dan flexible. Kini Anda dapat dengan mudah:

- ✅ Enable/disable component tertentu
- ✅ Add/remove module dengan mudah
- ✅ Maintain setiap component secara independen
- ✅ Test individual modules
- ✅ Customize installation sesuai kebutuhan

---

## 📂 Structure

```
project/
├── setup.sh                 # Main orchestrator script
├── config.sh               # Configuration variables
├── lib/                    # Shared libraries
│   ├── logging.sh         # Logging functions (log_info, log_success, etc)
│   ├── validators.sh      # Pre-flight checks & validations
│   ├── helpers.sh         # Helper functions (retry, backup, etc)
│   └── verification.sh    # Post-installation verification
└── modules/               # Installation modules (one per component)
    ├── system.sh          # System preparation & optimization
    ├── user.sh            # User management
    ├── desktop.sh         # XFCE & XRDP installation
    ├── docker.sh          # Docker installation
    ├── nodejs.sh          # Node.js via NVM
    ├── python.sh          # Python stack
    ├── vscode.sh          # VS Code installation
    ├── cursor.sh          # Cursor IDE installation
    └── shell.sh           # Zsh & Oh My Zsh setup
```

---

## 🚀 Usage

### **Basic Installation (All Components)**

```bash
# Default: Install semua components
sudo ./setup.sh
```

### **Custom User & Password**

```bash
sudo DEV_USER="angga" DEV_USER_PASSWORD="MyPass123!" ./setup.sh
```

### **Selective Installation (Skip Components)**

```bash
# Skip Cursor & VS Code installation
sudo ./setup.sh --skip-cursor --skip-vscode

# Skip Desktop Environment (headless server)
sudo ./setup.sh --skip-desktop

# Skip Docker
sudo ./setup.sh --skip-docker
```

### **Advanced: Via Environment Variables**

```bash
# Customize via config variables
sudo INSTALL_CURSOR=false \
     INSTALL_VSCODE=false \
     INSTALL_DOCKER=false \
     DEV_USER="myname" \
     ./setup.sh
```

---

## ⚙️ Configuration (`config.sh`)

Semua konfigurasi terpusat di `config.sh`:

```bash
# User Configuration
export DEV_USER="${DEV_USER:-developer}"
export DEV_USER_PASSWORD="${DEV_USER_PASSWORD:-DevPass123!}"

# System Configuration
export TIMEZONE="${TIMEZONE:-Asia/Jakarta}"

# Installation Options (true/false)
export INSTALL_SYSTEM="${INSTALL_SYSTEM:-true}"
export INSTALL_USER="${INSTALL_USER:-true}"
export INSTALL_DESKTOP="${INSTALL_DESKTOP:-true}"
export INSTALL_DOCKER="${INSTALL_DOCKER:-true}"
export INSTALL_NODEJS="${INSTALL_NODEJS:-true}"
export INSTALL_PYTHON="${INSTALL_PYTHON:-true}"
export INSTALL_VSCODE="${INSTALL_VSCODE:-true}"
export INSTALL_CURSOR="${INSTALL_CURSOR:-true}"
export INSTALL_SHELL="${INSTALL_SHELL:-true}"
```

---

## 📚 Library Functions

### **lib/logging.sh**
Fungsi logging dengan warna dan file output:

```bash
log_info "Informational message"
log_success "Success message"
log_error "Error message"
log_warning "Warning message"
update_progress "current_step_name"
```

### **lib/helpers.sh**
Utility functions:

```bash
check_and_install "package_name"     # Install/reinstall package if needed
backup_file "/path/to/file"          # Backup file before modification
command_exists "command_name"        # Check if command exists
retry_command 3 5 "command"          # Retry command 3 times with 5s delay
enable_and_start_service "service"   # Enable and start systemd service
run_as_user "username" command       # Execute command as specific user
```

### **lib/validators.sh**
Pre-flight checks:

```bash
check_root()                # Ensure running as root
check_lock()               # Prevent concurrent runs
check_disk_space()         # Verify min 10GB available
check_memory()             # Check RAM availability
check_internet()           # Test internet connectivity
check_debian_version()     # Validate Debian 12/13
validate_password()        # Password complexity check
validate_username()        # Username format validation
run_preflight_checks()     # Run all checks
```

### **lib/verification.sh**
Post-installation verification:

```bash
verify_installation()   # Verify all installed components
```

---

## 🧩 Modules

### **modules/system.sh**
- System update & upgrade
- Install essential packages
- Configure swap (4GB)
- System limits tuning
- UFW firewall setup

### **modules/user.sh**
- Create/update dev user
- Configure sudo access
- Setup home directory

### **modules/desktop.sh**
- Install XFCE4 desktop environment
- Install & configure XRDP
- Setup .xsession

### **modules/docker.sh**
- Add Docker repository
- Install Docker CE & components
- Add user to docker group

### **modules/nodejs.sh**
- Install NVM
- Install Node.js LTS
- Install global packages (yarn, pnpm, typescript)

### **modules/python.sh**
- Install Python 3
- Install pip & venv

### **modules/vscode.sh**
- Add Microsoft repository
- Install VS Code

### **modules/cursor.sh**
- Try official installer (primary)
- Fallback to Snap
- Fallback to AppImage download
- Create desktop entry

### **modules/shell.sh**
- Install Zsh & powerline fonts
- Install Nerd Fonts
- Install Oh My Zsh
- Set Zsh as default shell

---

## 🛠️ Adding New Module

1. **Create module file:**
```bash
# Create file: modules/mynewmodule.sh
#!/bin/bash
setup_mynewmodule() {
    update_progress "setup_mynewmodule"
    log_info "Installing My New Module..."
    
    # Your installation logic here
    check_and_install "package_name"
    
    log_success "My New Module setup selesai"
}
```

2. **Add configuration:**
```bash
# In config.sh
export INSTALL_MYNEWMODULE="${INSTALL_MYNEWMODULE:-true}"
```

3. **Source module in setup.sh:**
```bash
# In setup.sh
source "$SCRIPT_DIR/modules/mynewmodule.sh"
```

4. **Add to main() function:**
```bash
# In setup.sh main() function
[ "$INSTALL_MYNEWMODULE" = "true" ] && setup_mynewmodule
```

5. **Add verification (optional):**
```bash
# In lib/verification.sh
if [ "$INSTALL_MYNEWMODULE" = "true" ]; then
    if command_exists mynewcommand; then
        log_success "✓ My New Module terinstal"
    else
        log_warning "⚠ My New Module tidak ditemukan"
        warnings=$((warnings+1))
    fi
fi
```

---

## 🧪 Testing Individual Modules

```bash
# Source dependencies
source config.sh
source lib/logging.sh
source lib/helpers.sh
source lib/validators.sh

# Test specific module
source modules/docker.sh
setup_docker
```

---

## 📊 Advantages of Modular Architecture

| Aspect | Monolithic | Modular |
|--------|------------|---------|
| **Maintainability** | Hard to maintain | Easy to maintain |
| **Testability** | Hard to test | Easy to test individual modules |
| **Reusability** | Hard to reuse | Modules can be reused |
| **Customization** | All or nothing | Pick and choose components |
| **Code Organization** | 1000+ lines in one file | <100 lines per file |
| **Collaboration** | Merge conflicts | Easier team collaboration |
| **Debugging** | Hard to debug | Easy to isolate issues |

---

## 🔧 Troubleshooting

### **Module fails to load:**
```bash
# Check syntax
bash -n modules/yourmodule.sh

# Check if sourcing works
source modules/yourmodule.sh
echo $?  # Should be 0
```

### **Function not found:**
Make sure libraries are sourced before modules:
```bash
source lib/logging.sh   # Must be before modules
source lib/helpers.sh   # Must be before modules
source modules/yourmodule.sh
```

### **Permission denied:**
```bash
chmod +x setup.sh modules/*.sh lib/*.sh
```

---

## 📝 Best Practices

1. **Each module should:**
   - Have a single responsibility
   - Be independent (minimal dependencies)
   - Use logging functions consistently
   - Handle errors gracefully
   - Return proper exit codes

2. **Always use:**
   - `log_info/success/warning/error` for output
   - `update_progress` to track current step
   - `backup_file` before modifying configs
   - `retry_command` for network operations
   - `command_exists` before using commands

3. **Naming conventions:**
   - Module files: `lowercase.sh`
   - Functions: `verb_noun()` (e.g., `setup_docker`, `verify_installation`)
   - Variables: `UPPERCASE_WITH_UNDERSCORE`

---

## 🎓 Learning More

- Each module is self-documented with comments
- Read `lib/helpers.sh` for available utility functions
- Check `config.sh` for all configurable options
- Review `setup.sh` for orchestration logic

---

**Happy Hacking! 🚀**

