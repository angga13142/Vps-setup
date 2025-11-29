# Installation Guide: IDE & Development Applications

## Quick Installation Commands

### VSCode Installation

#### Method 1: Official Repository (Recommended)
```bash
# Add Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/

# Add repository
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# Install
sudo apt update
sudo apt install code
```

#### Method 2: Direct Download
```bash
# Download .deb package
wget https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64 -O code.deb

# Install
sudo dpkg -i code.deb
sudo apt-get install -f
```

### Cursor Installation

#### AppImage Method (Recommended)
```bash
# Download AppImage
wget https://downloader.cursor.sh/linux/appImage/x64 -O cursor.AppImage
chmod +x cursor.AppImage

# Install to system
sudo mkdir -p /opt/cursor
sudo mv cursor.AppImage /opt/cursor/cursor.AppImage
sudo chmod +x /opt/cursor/cursor.AppImage

# Create symlink
sudo ln -sf /opt/cursor/cursor.AppImage /usr/local/bin/cursor

# Create desktop entry
sudo tee /usr/share/applications/cursor.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Cursor
Comment=AI-powered code editor
Exec=/opt/cursor/cursor.AppImage
Icon=cursor
Type=Application
Categories=Development;IDE;
EOF
```

### Essential Development Tools

#### Package Manager Installation
```bash
# Update package list
sudo apt update

# Install essential tools
sudo apt install -y \
    tmux \
    fzf \
    bat \
    neofetch \
    flameshot \
    ranger \
    httpie \
    dbeaver-ce \
    postman \
    wireshark \
    nmap
```

#### Manual Installations

##### Starship Prompt
```bash
curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init bash)"' >> ~/.bashrc
```

##### exa (Modern ls)
```bash
# Install via cargo (if Rust installed)
cargo install exa

# Or download binary
wget https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip
unzip exa-linux-x86_64-v0.10.1.zip
sudo mv bin/exa /usr/local/bin/
```

##### btop (Better htop)
```bash
# Install via snap or compile from source
sudo snap install btop

# Or via apt (if available in Debian 13)
sudo apt install btop
```

##### Portainer (Docker GUI)
```bash
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 \
    --name portainer --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
```

## Configuration

### VSCode Settings

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
    "extensions.autoUpdate": true,
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true
}
```

### Recommended VSCode Extensions

Install via command line:
```bash
code --install-extension eamodio.gitlens
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint
code --install-extension ms-python.python
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode-remote.remote-ssh
code --install-extension rangav.vscode-thunder-client
code --install-extension yzhang.markdown-all-in-one
```

### Cursor Configuration

Cursor uses similar settings to VSCode. Create `~/.config/Cursor/User/settings.json` with same content as VSCode.

### File Associations

Associate code files with editors:
```bash
# VSCode associations
xdg-mime default code.desktop text/x-python
xdg-mime default code.desktop text/javascript
xdg-mime default code.desktop text/x-typescript
xdg-mime default code.desktop text/x-markdown

# Cursor associations (optional, if preferred)
# xdg-mime default cursor.desktop text/x-python
```

## Verification

### Check Installations
```bash
# Check VSCode
code --version

# Check Cursor
cursor --version

# Check other tools
tmux -V
fzf --version
bat --version
exa --version
neofetch --version
```

### Test Launch
```bash
# Launch VSCode
code .

# Launch Cursor
cursor .

# Launch tools
tmux
ranger
neofetch
```

## Troubleshooting

### VSCode Issues

**Problem**: VSCode not launching
```bash
# Check if installed
dpkg -l | grep code

# Reinstall if needed
sudo apt remove code
sudo apt install code
```

**Problem**: Extensions not installing
```bash
# Check internet connection
ping code.visualstudio.com

# Clear extension cache
rm -rf ~/.vscode/extensions
```

### Cursor Issues

**Problem**: Cursor AppImage not executable
```bash
chmod +x /opt/cursor/cursor.AppImage
```

**Problem**: Desktop entry not working
```bash
# Update desktop database
sudo update-desktop-database

# Check desktop file
cat /usr/share/applications/cursor.desktop
```

### Tool Issues

**Problem**: bat command not found
```bash
# Debian uses 'batcat' instead of 'bat'
alias bat='batcat'
echo "alias bat='batcat'" >> ~/.bashrc
```

**Problem**: fzf not working
```bash
# Source fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Or reinstall
sudo apt remove fzf
sudo apt install fzf
```

## Post-Installation Setup

### 1. Configure Git in IDEs
```bash
# Set Git user (if not already set)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 2. Install Fonts (Optional)
```bash
# Install Fira Code
sudo apt install fonts-firacode

# Or download manually
wget https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip
unzip Fira_Code_v6.2.zip
sudo cp ttf/*.ttf /usr/share/fonts/truetype/
fc-cache -fv
```

### 3. Configure tmux
```bash
# Create tmux config
cat > ~/.tmux.conf << 'EOF'
# Enable mouse support
set -g mouse on

# Start windows and panes at 1
set -g base-index 1
setw -g pane-base-index 1

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Split panes
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Switch panes
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
EOF
```

### 4. Configure fzf
```bash
# Add to .bashrc
cat >> ~/.bashrc << 'EOF'

# fzf configuration
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND='find . -type f 2>/dev/null | grep -v node_modules | grep -v .git'
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
EOF
```

## Next Steps

1. ✅ Verify all tools are installed
2. ✅ Configure IDEs with your preferences
3. ✅ Install recommended extensions
4. ✅ Set up file associations
5. ✅ Test all tools
6. ✅ Customize terminal and shell
7. ✅ Create project templates
