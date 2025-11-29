# Terminal Enhancements - Quick Reference

## Recommended Tools Installation

### 1. Starship Prompt
```bash
# Install Starship
curl -sS https://starship.rs/install.sh | sh

# Add to .bashrc
echo 'eval "$(starship init bash)"' >> ~/.bashrc
```

### 2. fzf (Fuzzy Finder)
```bash
# Install via apt
sudo apt install fzf

# Or install latest version
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

### 3. bat (Better cat)
```bash
# Install via apt
sudo apt install bat

# Create alias
echo "alias cat='batcat'" >> ~/.bashrc  # Debian uses 'batcat'
```

### 4. exa (Modern ls)
```bash
# Install via cargo (if Rust installed)
cargo install exa

# Or download binary from GitHub releases
# https://github.com/ogham/exa/releases
```

### 5. Enhanced Aliases
```bash
# Add to .bashrc
cat >> ~/.bashrc << 'EOF'

# Enhanced Aliases
alias gst='git status'
alias gco='git checkout'
alias gcm='git commit -m'
alias gpl='git pull'
alias gps='git push'
alias dc='docker-compose'
alias dps='docker ps'
alias dlog='docker logs -f'
alias ports='netstat -tulanp | grep LISTEN'
alias weather='curl wttr.in'
alias cat='batcat'  # If bat installed
alias ls='exa'      # If exa installed
alias ll='exa -lah' # If exa installed

# Functions
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
            *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

colors() {
    for i in {0..255}; do
        printf "\x1b[38;5;%dmcolour%d\x1b[0m\n" $i $i
    done
}

path() {
    echo $PATH | tr ':' '\n' | nl
}
EOF
```

## Starship Configuration

Create `~/.config/starship.toml`:
```toml
# Get editor completions based on the config schema
"$schema" = 'https://starship.rs/config-schema.json'

# Inserts a blank line between shell prompts
add_newline = true

# Replace the "❯" symbol in the prompt with "➜"
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

# Disable the package module, hiding it from the prompt completely
[package]
disabled = true

[git_branch]
symbol = "🌱 "
truncation_length = 20
truncation_symbol = "…"

[git_status]
conflicted = "🏳 "
up_to_date = "✓ "
untracked = "🤷 "
ahead = "🏎 "
behind = "😰 "
diverged = "⛓ "
stashed = "📦 "
modified = "📝 "
staged = '[++\($count\)](green)'
renamed = "👅 "
deleted = "🗑 "

[nodejs]
symbol = "📦 "

[python]
symbol = "🐍 "

[docker_context]
symbol = "🐳 "

[time]
format = "[$time]($style) "
disabled = false
```

## fzf Key Bindings

Add to `.bashrc`:
```bash
# fzf key bindings (if fzf installed)
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Custom fzf commands
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND='find . -type f 2>/dev/null | grep -v node_modules | grep -v .git'
```

## History Improvements

Add to `.bashrc`:
```bash
# History improvements
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
export HISTTIMEFORMAT="%F %T "
```

## Completion Enhancements

Add to `.bashrc`:
```bash
# Better completion
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set menu-complete-display-prefix on'
```
