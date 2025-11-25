#!/bin/bash

# ==============================================================================
# Hostname Module - Hostname & Terminal Prompt Customization
# ==============================================================================

setup_hostname() {
    update_progress "setup_hostname"
    log_info "=== Hostname & Terminal Customization ==="
    echo ""
    
    # Set hostname
    set_custom_hostname
    
    # Setup fancy terminal prompts
    setup_fancy_prompts
    
    log_success "Hostname & terminal customization selesai"
}

set_custom_hostname() {
    local current_hostname
    current_hostname=$(hostname)
    
    log_info "Current hostname: $current_hostname"
    
    # Check if custom hostname is provided
    if [ -n "$CUSTOM_HOSTNAME" ]; then
        local new_hostname="$CUSTOM_HOSTNAME"
    else
        # Generate nice default hostname
        local suggestions=(
            "vps-dev-$(date +%m%d)"
            "devbox-$DEV_USER"
            "workspace-01"
            "code-server"
            "dev-machine"
        )
        
        log_info "Suggested hostnames:"
        for i in "${!suggestions[@]}"; do
            log_info "  $((i+1)). ${suggestions[$i]}"
        done
        
        # Use first suggestion as default
        new_hostname="${suggestions[0]}"
        log_info "Using: $new_hostname (set CUSTOM_HOSTNAME to override)"
    fi
    
    # Validate hostname
    if ! echo "$new_hostname" | grep -qE '^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$'; then
        log_warning "Hostname '$new_hostname' tidak valid, melewati..."
        return 0
    fi
    
    # Check if already set
    if [ "$current_hostname" = "$new_hostname" ]; then
        log_info "Hostname sudah set ke: $new_hostname"
        return 0
    fi
    
    # Backup hosts file
    backup_file "/etc/hosts"
    backup_file "/etc/hostname"
    
    # Set new hostname
    log_info "Setting hostname to: $new_hostname"
    
    # Update /etc/hostname
    echo "$new_hostname" > /etc/hostname
    
    # Set current hostname (immediate)
    hostnamectl set-hostname "$new_hostname" 2>/dev/null || hostname "$new_hostname"
    
    # Update /etc/hosts
    if grep -q "$current_hostname" /etc/hosts; then
        sed -i "s/$current_hostname/$new_hostname/g" /etc/hosts
    else
        # Add if not exists
        if ! grep -q "127.0.1.1" /etc/hosts; then
            echo "127.0.1.1 $new_hostname" >> /etc/hosts
        fi
    fi
    
    log_success "✓ Hostname changed to: $new_hostname"
    log_info "  Terminal will show: $DEV_USER@$new_hostname"
    log_info "  Reboot recommended for full effect"
}

setup_fancy_prompts() {
    log_info "Setting up fancy terminal prompts..."
    
    # Determine shell rc files
    local bashrc="/home/$DEV_USER/.bashrc"
    local zshrc="/home/$DEV_USER/.zshrc"
    
    # Setup for Bash
    if [ -f "$bashrc" ]; then
        setup_bash_prompt "$bashrc"
    fi
    
    # Setup for Zsh
    if [ -f "$zshrc" ]; then
        setup_zsh_prompt "$zshrc"
    fi
    
    # Optional: Install Starship (modern prompt)
    if [ "$INSTALL_STARSHIP" = "true" ]; then
        install_starship_prompt
    fi
}

setup_bash_prompt() {
    local bashrc="$1"
    
    backup_file "$bashrc"
    
    # Remove old custom prompt if exists
    sed -i '/# VPS Bootstrap Custom Prompt/,/# End Custom Prompt/d' "$bashrc"
    
    # Add colorful prompt
    cat >> "$bashrc" <<'BASHPROMPT'

# VPS Bootstrap Custom Prompt
# Colorful, informative prompt

# Color definitions
COLOR_RESET='\[\e[0m\]'
COLOR_USER='\[\e[1;32m\]'      # Bold Green
COLOR_HOST='\[\e[1;34m\]'      # Bold Blue
COLOR_PATH='\[\e[1;33m\]'      # Bold Yellow
COLOR_GIT='\[\e[1;36m\]'       # Bold Cyan
COLOR_PROMPT='\[\e[1;35m\]'    # Bold Magenta
COLOR_TIME='\[\e[0;37m\]'      # Gray

# Git branch in prompt
parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Custom PS1
PS1="${COLOR_TIME}\t${COLOR_RESET} "
PS1+="${COLOR_USER}\u${COLOR_RESET}"
PS1+="@"
PS1+="${COLOR_HOST}\h${COLOR_RESET}"
PS1+=":"
PS1+="${COLOR_PATH}\w${COLOR_RESET}"
PS1+="${COLOR_GIT}\$(parse_git_branch)${COLOR_RESET}"
PS1+="\n${COLOR_PROMPT}❯${COLOR_RESET} "

export PS1

# End Custom Prompt
BASHPROMPT
    
    log_success "  ✓ Bash prompt configured"
}

setup_zsh_prompt() {
    local zshrc="$1"
    
    backup_file "$zshrc"
    
    # Remove old custom prompt if exists
    sed -i '/# VPS Bootstrap Custom Prompt/,/# End Custom Prompt/d' "$zshrc"
    
    # Add colorful prompt for Zsh
    cat >> "$zshrc" <<'ZSHPROMPT'

# VPS Bootstrap Custom Prompt
# Enhanced Zsh prompt

# Enable colors
autoload -U colors && colors

# Git info
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST

# Custom prompt with colors
PROMPT='%F{white}%*%f %F{green}%n%f@%F{blue}%m%f:%F{yellow}%~%f%F{cyan}${vcs_info_msg_0_}%f
%F{magenta}❯%f '

# End Custom Prompt
ZSHPROMPT
    
    log_success "  ✓ Zsh prompt configured"
}

install_starship_prompt() {
    log_info "Installing Starship prompt..."
    
    # Check if already installed
    if command_exists starship; then
        log_info "  Starship already installed"
        return 0
    fi
    
    # Install Starship
    if curl -sS https://starship.rs/install.sh | sh -s -- -y; then
        log_success "  ✓ Starship installed"
        
        # Configure for bash
        if [ -f "/home/$DEV_USER/.bashrc" ]; then
            if ! grep -q "starship init bash" "/home/$DEV_USER/.bashrc"; then
                echo 'eval "$(starship init bash)"' >> "/home/$DEV_USER/.bashrc"
                log_success "  ✓ Starship enabled for Bash"
            fi
        fi
        
        # Configure for zsh
        if [ -f "/home/$DEV_USER/.zshrc" ]; then
            if ! grep -q "starship init zsh" "/home/$DEV_USER/.zshrc"; then
                echo 'eval "$(starship init zsh)"' >> "/home/$DEV_USER/.zshrc"
                log_success "  ✓ Starship enabled for Zsh"
            fi
        fi
        
        # Create custom starship config
        local starship_config="/home/$DEV_USER/.config/starship.toml"
        mkdir -p "/home/$DEV_USER/.config"
        
        cat > "$starship_config" <<'STARSHIP_CONFIG'
# Starship Configuration
# https://starship.rs/config/

format = """
[┌──](bold green)$username[@](bold white)$hostname $directory$git_branch$git_status
[└─](bold green)$character"""

[username]
style_user = "bold green"
style_root = "bold red"
format = "[$user]($style)"
show_always = true

[hostname]
ssh_only = false
format = "[$hostname](bold blue)"
disabled = false

[directory]
truncation_length = 3
truncate_to_repo = true
format = "[:$path]($style) "
style = "bold yellow"

[git_branch]
symbol = "🌱 "
format = "[$symbol$branch]($style) "
style = "bold cyan"

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold cyan"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[cmd_duration]
min_time = 500
format = "took [$duration](bold yellow) "
STARSHIP_CONFIG
        
        chown -R "$DEV_USER:$DEV_USER" "/home/$DEV_USER/.config"
        log_success "  ✓ Starship config created"
        
    else
        log_warning "  Failed to install Starship, using default prompt"
    fi
}

show_hostname_info() {
    echo ""
    log_info "=== Hostname & Prompt Configuration ==="
    echo ""
    
    log_info "Current hostname: $(hostname)"
    log_info "Terminal will show: $DEV_USER@$(hostname)"
    echo ""
    
    log_info "Terminal Prompt Features:"
    log_info "  ✓ Colorful username & hostname"
    log_info "  ✓ Current directory path"
    log_info "  ✓ Git branch info (if in repo)"
    log_info "  ✓ Timestamp"
    
    if command_exists starship; then
        log_info "  ✓ Starship prompt enabled"
    fi
    
    echo ""
    log_info "To see new prompt:"
    log_info "  1. Logout and login again, OR"
    log_info "  2. Run: source ~/.bashrc  (or ~/.zshrc for Zsh)"
    echo ""
}

# Interactive hostname change
change_hostname_interactive() {
    log_info "=== Change Hostname ===" 
    echo ""
    
    local current_hostname
    current_hostname=$(hostname)
    
    log_info "Current hostname: $current_hostname"
    echo ""
    
    log_info "Suggested hostnames:"
    echo "  1. vps-dev-$(date +%m%d)"
    echo "  2. devbox-$DEV_USER"
    echo "  3. workspace-01"
    echo "  4. code-server"
    echo "  5. dev-machine"
    echo "  6. Custom (enter your own)"
    echo ""
    
    read -p "Choose option (1-6) or press Enter to keep current: " choice
    
    case $choice in
        1) CUSTOM_HOSTNAME="vps-dev-$(date +%m%d)" ;;
        2) CUSTOM_HOSTNAME="devbox-$DEV_USER" ;;
        3) CUSTOM_HOSTNAME="workspace-01" ;;
        4) CUSTOM_HOSTNAME="code-server" ;;
        5) CUSTOM_HOSTNAME="dev-machine" ;;
        6)
            read -p "Enter custom hostname: " CUSTOM_HOSTNAME
            ;;
        "")
            log_info "Keeping current hostname"
            return 0
            ;;
        *)
            log_error "Invalid option"
            return 1
            ;;
    esac
    
    # Validate
    if ! echo "$CUSTOM_HOSTNAME" | grep -qE '^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$'; then
        log_error "Invalid hostname format!"
        log_error "Rules: lowercase, alphanumeric, hyphens, max 63 chars"
        return 1
    fi
    
    export CUSTOM_HOSTNAME
    set_custom_hostname
    
    echo ""
    log_success "Hostname changed!"
    log_info "Reboot or logout/login to see changes"
}

