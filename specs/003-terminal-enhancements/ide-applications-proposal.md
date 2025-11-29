# IDE & Applications Enhancement Proposal

## Overview
Proposal untuk menambahkan IDE (VSCode + Cursor) dan aplikasi penunjang untuk workstation development agar siap digunakan langsung setelah deploy di VPS fresh.

## Research Summary

### VSCode Installation Options

#### 1. VSCode Desktop (GUI)
**Use Case**: Untuk XFCE4 desktop environment yang sudah ada
**Installation Methods**:
- **Method 1**: Official .deb package (Recommended)
  ```bash
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
  sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  sudo apt update
  sudo apt install code
  ```

- **Method 2**: Direct .deb download
  ```bash
  wget https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64 -O code.deb
  sudo dpkg -i code.deb
  sudo apt-get install -f
  ```

**Features**:
- Full GUI editor
- Extension marketplace
- Integrated terminal
- Git integration
- Remote development support

#### 2. VSCode Server (Headless/Remote)
**Use Case**: Untuk remote development via SSH atau browser
**Installation**:
- Automatically installed when connecting via Remote-SSH extension
- Can be manually installed for browser access:
  ```bash
  curl -fsSL https://code-server.dev/install.sh | sh
  ```

**Features**:
- Access via browser (port 8080)
- Full VSCode experience in browser
- Extension support
- Terminal access

### Cursor Installation

**Current Status**: Cursor is primarily a desktop application
**Installation Methods**:

#### Method 1: AppImage (Linux Universal)
```bash
# Download latest AppImage
wget https://downloader.cursor.sh/linux/appImage/x64 -O cursor.AppImage
chmod +x cursor.AppImage

# Create desktop entry
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/cursor.desktop << EOF
[Desktop Entry]
Name=Cursor
Exec=$HOME/cursor.AppImage
Icon=cursor
Type=Application
Categories=Development;IDE;
EOF

# Move to bin for easy access
sudo mv cursor.AppImage /usr/local/bin/cursor
```

#### Method 2: .deb Package (if available)
```bash
# Similar to VSCode installation
wget https://downloader.cursor.sh/linux/deb/x64 -O cursor.deb
sudo dpkg -i cursor.deb
sudo apt-get install -f
```

**Features**:
- AI-powered code completion
- Chat with codebase
- Built on VSCode foundation
- Extension compatibility

**Note**: Cursor doesn't have official headless/server version yet. For remote development, use VSCode Server or Remote-SSH.

## Essential Development Applications

### 1. Code Editors & IDEs
- ✅ **VSCode** - Primary code editor
- ✅ **Cursor** - AI-powered editor
- **Neovim** (optional) - Terminal-based editor
- **Sublime Text** (optional) - Lightweight editor

### 2. Version Control Tools
- ✅ **Git** - Already installed
- **GitKraken** (optional) - GUI Git client
- **GitHub Desktop** (optional) - Simple Git GUI

### 3. Database Tools
- **DBeaver** - Universal database tool
- **MySQL Workbench** - MySQL/MariaDB management
- **pgAdmin** - PostgreSQL management
- **MongoDB Compass** - MongoDB GUI

### 4. API Testing & Development
- **Postman** - API testing tool
- **Insomnia** - REST client
- **HTTPie** - CLI HTTP client
- **curl** - Already installed

### 5. Container & DevOps
- ✅ **Docker** - Already installed
- ✅ **Docker Compose** - Already installed
- **Portainer** - Docker GUI management
- **Kubernetes tools** (kubectl, helm) - If needed

### 6. Terminal & Shell Tools
- **tmux** - Terminal multiplexer
- **screen** - Terminal multiplexer (alternative)
- **zsh** - Enhanced shell (optional)
- **Oh My Zsh** - Zsh framework (if using zsh)

### 7. File Management
- **Ranger** - Terminal file manager
- **Nautilus** - GUI file manager (XFCE default)
- **Thunar** - XFCE file manager (already available)

### 8. Network Tools
- **Wireshark** - Network protocol analyzer
- **nmap** - Network scanner
- **netstat** - Network connections (already available)
- **tcpdump** - Packet analyzer

### 9. System Monitoring
- ✅ **htop** - Already installed
- **btop** - Better htop
- **glances** - System monitoring
- **neofetch** - System info display

### 10. Productivity Tools
- **Flameshot** - Screenshot tool
- **KeepassXC** - Password manager
- **Notion** (web) - Note-taking
- **Obsidian** (optional) - Markdown notes

### 11. Communication
- **Slack** (web/desktop) - Team communication
- **Discord** (web/desktop) - Community chat
- **Telegram Desktop** - Messaging

### 12. Documentation & Markdown
- **Typora** (optional) - Markdown editor
- **Mark Text** - Markdown editor
- **Pandoc** - Document converter

## Recommended Installation Priority

### Phase 1: Core Development Tools (Essential)
1. ✅ VSCode Desktop
2. ✅ Cursor IDE
3. ✅ Git (already installed)
4. ✅ Docker & Docker Compose (already installed)
5. **Postman** - API testing
6. **DBeaver** - Database management

### Phase 2: Terminal & Shell Enhancements
1. **tmux** - Terminal multiplexer
2. **fzf** - Fuzzy finder
3. **bat** - Better cat
4. **exa** - Modern ls
5. **Starship** - Modern prompt
6. **neofetch** - System info

### Phase 3: Productivity Tools
1. **Flameshot** - Screenshot
2. **btop** - Better monitoring
3. **Ranger** - File manager
4. **HTTPie** - HTTP client

### Phase 4: Optional/Advanced
1. **Portainer** - Docker GUI
2. **Neovim** - Terminal editor
3. **zsh + Oh My Zsh** - Enhanced shell
4. **Wireshark** - Network analysis

## Implementation Plan

### Integration with setup-workstation.sh

#### New Function: `install_ide_and_editors()`
```bash
# Purpose: Install VSCode and Cursor IDE
# Dependencies: curl, wget, gpg
# Output: VSCode and Cursor installed and configured
```

#### New Function: `install_development_tools()`
```bash
# Purpose: Install essential development applications
# Includes: Postman, DBeaver, tmux, fzf, bat, exa, etc.
# Output: Development tools installed
```

#### New Function: `configure_ide_settings()`
```bash
# Purpose: Configure VSCode and Cursor with recommended settings
# Creates: Default settings, recommended extensions list
# Output: IDEs configured with best practices
```

## Installation Scripts

### VSCode Installation
```bash
install_vscode() {
    log "INFO" "Installing Visual Studio Code..." "install_vscode()"

    # Add Microsoft GPG key
    if ! wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg 2>/dev/null; then
        log "ERROR" "Failed to download Microsoft GPG key" "install_vscode()"
        return 1
    fi

    sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

    sudo apt update
    if sudo apt install -y code; then
        log "INFO" "✓ VSCode installed successfully" "install_vscode()"
        return 0
    else
        log "ERROR" "Failed to install VSCode" "install_vscode()"
        return 1
    fi
}
```

### Cursor Installation
```bash
install_cursor() {
    log "INFO" "Installing Cursor IDE..." "install_cursor()"

    local cursor_dir="/opt/cursor"
    local cursor_bin="/usr/local/bin/cursor"

    # Download AppImage
    if ! wget -q https://downloader.cursor.sh/linux/appImage/x64 -O /tmp/cursor.AppImage; then
        log "ERROR" "Failed to download Cursor" "install_cursor()"
        return 1
    fi

    # Create directory and install
    sudo mkdir -p "$cursor_dir"
    sudo mv /tmp/cursor.AppImage "$cursor_dir/cursor.AppImage"
    sudo chmod +x "$cursor_dir/cursor.AppImage"

    # Create symlink
    sudo ln -sf "$cursor_dir/cursor.AppImage" "$cursor_bin"

    # Create desktop entry
    sudo mkdir -p /usr/share/applications
    sudo tee /usr/share/applications/cursor.desktop > /dev/null << EOF
[Desktop Entry]
Name=Cursor
Comment=AI-powered code editor
Exec=$cursor_dir/cursor.AppImage
Icon=cursor
Type=Application
Categories=Development;IDE;
EOF

    log "INFO" "✓ Cursor installed successfully" "install_cursor()"
    return 0
}
```

## Configuration Files

### VSCode Settings Template
Create `~/.config/Code/User/settings.json`:
```json
{
    "editor.fontSize": 14,
    "editor.fontFamily": "Fira Code, 'Courier New', monospace",
    "editor.fontLigatures": true,
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.fixAll": "explicit"
    },
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.fontFamily": "Fira Code",
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "workbench.colorTheme": "Default Dark+",
    "extensions.autoUpdate": true
}
```

### Recommended VSCode Extensions
- GitLens
- Prettier
- ESLint
- Python
- Docker
- Remote - SSH
- Thunder Client (API testing)
- Markdown All in One

## Desktop Integration

### XFCE4 Application Menu
- Add VSCode and Cursor to Applications > Development
- Create desktop shortcuts
- Configure file associations (.py, .js, .ts, etc.)

### File Associations
```bash
# Associate code files with VSCode
xdg-mime default code.desktop text/x-python
xdg-mime default code.desktop text/javascript
xdg-mime default code.desktop text/x-typescript
```

## Remote Development Setup

### Option 1: VSCode Remote-SSH
- Install Remote-SSH extension
- Configure SSH keys
- Connect to VPS from local machine

### Option 2: code-server (Browser Access)
- Install code-server
- Configure authentication
- Access via browser at http://vps-ip:8080

## Testing & Verification

### Verification Steps
1. ✅ VSCode launches from Applications menu
2. ✅ Cursor launches from Applications menu
3. ✅ Both can open files and projects
4. ✅ Extensions can be installed
5. ✅ Terminal integration works
6. ✅ Git integration works

## Estimated Impact

### User Experience
- 🚀 Immediate productivity with full-featured IDEs
- 🎨 Professional development environment
- 🔧 All essential tools in one place
- 📦 Ready-to-use after fresh VPS deployment

### Resource Usage
- VSCode: ~200-300MB RAM
- Cursor: ~250-350MB RAM
- Total additional: ~500-650MB RAM

## Compatibility
- ✅ Debian 13 (Trixie) compatible
- ✅ XFCE4 desktop environment
- ✅ Works with existing setup
- ✅ No conflicts with current tools

## Maintenance
- Auto-update via package manager (VSCode)
- Manual update for Cursor (AppImage)
- Extension management via IDE UI

## Next Steps
1. Review and prioritize applications
2. Create detailed implementation spec
3. Implement installation functions
4. Add to setup-workstation.sh workflow
5. Test on fresh Debian 13 installation
6. Document usage and configuration
