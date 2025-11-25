#!/bin/bash

# ==============================================================================
# Developer Tools Module - Git, SSH, GPG, Dotfiles Setup
# ==============================================================================

setup_devtools() {
    update_progress "setup_devtools"
    log_info "=== Developer Tools Setup ==="
    echo ""
    
    # Git Configuration
    setup_git_config
    
    # SSH Keys
    setup_ssh_keys
    
    # GPG Keys (optional)
    setup_gpg_keys
    
    # Shell Aliases & Functions
    setup_shell_aliases
    
    # Developer utilities
    install_dev_utilities
    
    log_success "Developer tools setup selesai"
}

setup_git_config() {
    log_info "📝 Configuring Git..."
    
    # Check if git is installed
    if ! command_exists git; then
        ensure_swap_active
        check_and_install "git"
    fi
    
    # Interactive git config for user
    if run_as_user "$DEV_USER" bash -c 'git config --global user.name' &>/dev/null; then
        local current_name current_email
        current_name=$(run_as_user "$DEV_USER" bash -c 'git config --global user.name')
        current_email=$(run_as_user "$DEV_USER" bash -c 'git config --global user.email')
        
        log_info "  Current Git config:"
        log_info "    Name: $current_name"
        log_info "    Email: $current_email"
    else
        log_info "  Git not configured yet"
        
        # Set default if not in interactive mode
        if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
            run_as_user "$DEV_USER" bash <<EOF
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
EOF
            log_success "  ✓ Git configured with provided credentials"
        else
            log_info "  Set GIT_USER_NAME and GIT_USER_EMAIL env vars to auto-configure"
        fi
    fi
    
    # Useful git aliases
    run_as_user "$DEV_USER" bash <<'EOF'
# Git aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
git config --global alias.tree "log --all --graph --decorate --oneline"

# Better defaults
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor vim
git config --global color.ui auto
EOF
    
    log_success "  ✓ Git aliases configured"
}

setup_ssh_keys() {
    log_info "🔑 Setting up SSH Keys..."
    
    local ssh_dir="/home/$DEV_USER/.ssh"
    local ssh_key="$ssh_dir/id_ed25519"
    
    # Create .ssh directory if not exists
    if [ ! -d "$ssh_dir" ]; then
        run_as_user "$DEV_USER" mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
    fi
    
    # Check if SSH key already exists
    if [ -f "$ssh_key" ]; then
        log_info "  SSH key already exists: $ssh_key"
        log_info "  Public key:"
        cat "$ssh_key.pub" | sed 's/^/    /'
    else
        # Generate SSH key
        local email="${GIT_USER_EMAIL:-$DEV_USER@$(hostname)}"
        
        log_info "  Generating SSH key (ed25519)..."
        if run_with_progress "Generating SSH key (ed25519)" "run_as_user \"$DEV_USER\" ssh-keygen -t ed25519 -C \"$email\" -f \"$ssh_key\" -N \"\""; then
            if [ -f "$ssh_key" ]; then
                log_success "  ✓ SSH key generated"
                log_info "  Public key:"
                cat "$ssh_key.pub" | sed 's/^/    /'
                echo ""
                log_info "  Add this key to your GitHub/GitLab:"
                log_info "    GitHub: https://github.com/settings/keys"
                log_info "    GitLab: https://gitlab.com/-/profile/keys"
            else
                log_error "  ✗ Failed to generate SSH key"
                return 1
            fi
        else
            log_error "  ✗ Failed to generate SSH key"
            return 1
        fi
    fi
    
    # SSH config for common hosts
    local ssh_config="$ssh_dir/config"
    if [ ! -f "$ssh_config" ]; then
        run_as_user "$DEV_USER" bash <<'EOF'
cat > ~/.ssh/config <<'SSHCONFIG'
# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes

# Default settings
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
SSHCONFIG
chmod 600 ~/.ssh/config
EOF
        log_success "  ✓ SSH config created"
    fi
    
    # Start ssh-agent and add key
    run_as_user "$DEV_USER" bash <<'EOF'
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
EOF
}

setup_gpg_keys() {
    log_info "🔐 GPG Keys Setup (optional)..."
    
    # Install GPG if not present
    if ! command_exists gpg; then
        ensure_swap_active
        check_and_install "gnupg"
    fi
    
    # Check if GPG key exists
    if run_as_user "$DEV_USER" bash -c 'gpg --list-secret-keys --keyid-format=long' 2>/dev/null | grep -q sec; then
        log_info "  GPG key already exists"
        
        # Show existing keys
        local key_id
        key_id=$(run_as_user "$DEV_USER" bash -c 'gpg --list-secret-keys --keyid-format=long 2>/dev/null' | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -1)
        
        if [ -n "$key_id" ]; then
            log_info "  Key ID: $key_id"
            
            # Configure git to use GPG key
            run_as_user "$DEV_USER" bash <<EOF
git config --global user.signingkey $key_id
git config --global commit.gpgsign true
git config --global tag.gpgsign true
EOF
            log_success "  ✓ Git configured to sign commits with GPG"
        fi
    else
        log_info "  No GPG key found"
        log_info "  To generate: gpg --full-generate-key"
        log_info "  To configure git: git config --global user.signingkey <KEY_ID>"
    fi
}

setup_shell_aliases() {
    log_info "⚡ Setting up shell aliases and functions..."
    
    # Determine shell rc file
    local shell_rc
    if [ -f "/home/$DEV_USER/.zshrc" ]; then
        shell_rc="/home/$DEV_USER/.zshrc"
    else
        shell_rc="/home/$DEV_USER/.bashrc"
    fi
    
    # Backup shell rc
    backup_file "$shell_rc"
    
    # Add custom aliases section
    if ! grep -q "# VPS Bootstrap Custom Aliases" "$shell_rc" 2>/dev/null; then
        run_as_user "$DEV_USER" bash <<'EOF'
cat >> ~/.zshrc 2>/dev/null || cat >> ~/.bashrc <<'ALIASES'

# VPS Bootstrap Custom Aliases
# =============================

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# Docker shortcuts
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dprune='docker system prune -af'

# System
alias update='sudo apt update && sudo apt upgrade -y'
alias ports='sudo netstat -tulpn'
alias myip='curl -s ifconfig.me'
alias serverstatus='sudo systemctl status'

# Development
alias serve='python3 -m http.server'
alias npmls='npm list -g --depth=0'
alias pyclean='find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true'

# Useful functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar x "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find large files
findlarge() {
    find . -type f -size +${1:-100M} -exec ls -lh {} \; | awk '{print $9 ": " $5}'
}

# Process search
psgrep() {
    ps aux | grep -v grep | grep -i -e VSZ -e "$1"
}

ALIASES
EOF
        log_success "  ✓ Shell aliases and functions added"
    else
        log_info "  Aliases already configured"
    fi
}

install_dev_utilities() {
    log_info "🛠️ Installing developer utilities..."
    
    # Check which utilities need to be installed
    local utilities_to_install=""
    local utilities=("tree" "jq" "silversearcher-ag" "tmux" "vim" "ncdu" "ripgrep")
    
    for util in "${utilities[@]}"; do
        if ! command_exists "$util"; then
            if [ -z "$utilities_to_install" ]; then
                utilities_to_install="$util"
            else
                utilities_to_install="$utilities_to_install $util"
            fi
        fi
    done
    
    # Install all missing utilities in batch (to prevent OOM)
    if [ -n "$utilities_to_install" ]; then
        batch_install_packages "$utilities_to_install" "developer utilities"
    else
        log_info "  Semua developer utilities sudah terinstal"
    fi
    
    log_success "  ✓ Developer utilities installed"
}

show_devtools_info() {
    echo ""
    log_info "=== Developer Tools Configuration ==="
    echo ""
    
    # Git config
    if run_as_user "$DEV_USER" bash -c 'git config --global user.name' &>/dev/null; then
        log_info "Git Configuration:"
        log_info "  Name: $(run_as_user "$DEV_USER" bash -c 'git config --global user.name')"
        log_info "  Email: $(run_as_user "$DEV_USER" bash -c 'git config --global user.email')"
    fi
    
    # SSH key
    if [ -f "/home/$DEV_USER/.ssh/id_ed25519.pub" ]; then
        echo ""
        log_info "SSH Public Key:"
        cat "/home/$DEV_USER/.ssh/id_ed25519.pub" | sed 's/^/  /'
    fi
    
    # GPG key
    if run_as_user "$DEV_USER" bash -c 'gpg --list-secret-keys --keyid-format=long' 2>/dev/null | grep -q sec; then
        echo ""
        log_info "GPG Key: Configured"
    fi
    
    echo ""
    log_info "Available Aliases: g, gs, ga, gc, gp, gl, d, dc, dps, ll, ..."
    log_info "Available Functions: mkcd, extract, findlarge, psgrep"
    log_info "Run 'alias' in terminal to see all aliases"
    
    echo ""
}

