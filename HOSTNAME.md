# 🏷️ Hostname & Terminal Customization Guide

Panduan lengkap untuk mengubah hostname dan mempercantik terminal prompt.

---

## 🎯 Problem yang Dipecahkan

**Before:**
```bash
racoondev@instance-template-20251125-20251125-041813:~$
```

**After:**
```bash
racoondev@vps-dev-1125:~$
# atau
racoondev@devbox-racoondev:~$
# atau dengan fancy prompt
┌──racoondev@code-server ~/project (main)
└─❯
```

---

## 🚀 Quick Start

### **Option 1: Interactive Hostname Change**

Paling mudah! Script akan menampilkan pilihan dan guide step-by-step.

```bash
sudo ./setup.sh --hostname
```

Output:
```
=== Change Hostname ===

Current hostname: instance-template-20251125-20251125-041813

Suggested hostnames:
  1. vps-dev-1125
  2. devbox-racoondev
  3. workspace-01
  4. code-server
  5. dev-machine
  6. Custom (enter your own)

Choose option (1-6) or press Enter to keep current: 1

✓ Hostname changed to: vps-dev-1125
  Terminal will show: racoondev@vps-dev-1125
  Reboot recommended for full effect
```

### **Option 2: Set During Installation**

```bash
sudo CUSTOM_HOSTNAME="my-dev-server" ./setup.sh
```

### **Option 3: Manual (Already Installed)**

```bash
# Source modules
source config.sh
source lib/logging.sh
source lib/helpers.sh
source modules/hostname.sh

# Set hostname
CUSTOM_HOSTNAME="my-server"
set_custom_hostname
```

---

## 📝 Hostname Naming Rules

✅ **Valid:**
- Lowercase letters (a-z)
- Numbers (0-9)
- Hyphens (-)
- Length: 1-63 characters
- Must start and end with letter/number

✅ **Examples:**
- `dev-server`
- `workspace01`
- `code-box-2024`
- `my-vps`

❌ **Invalid:**
- `Dev-Server` (uppercase not allowed)
- `my_server` (underscore not allowed)
- `-server` (can't start with hyphen)
- `server-` (can't end with hyphen)
- `my server` (spaces not allowed)

---

## 🎨 Terminal Prompt Customization

Script otomatis setup fancy terminal prompts dengan fitur:
- ✅ **Colorful**: Username, hostname, path dengan warna berbeda
- ✅ **Git Branch**: Menampilkan branch jika di dalam git repo
- ✅ **Timestamp**: Waktu saat ini
- ✅ **Clean**: Multi-line prompt untuk readability

### **Bash Prompt**

Default prompt yang diinstall:
```bash
14:30:45 racoondev@vps-dev-1125:~/project (main)
❯ 
```

Komponennya:
- `14:30:45` - Current time (gray)
- `racoondev` - Username (green)
- `@vps-dev-1125` - Hostname (blue)
- `~/project` - Current directory (yellow)
- `(main)` - Git branch (cyan, jika ada)
- `❯` - Prompt symbol (magenta)

### **Zsh Prompt**

Sama seperti Bash, tapi dengan Oh My Zsh enhancements.

### **Starship Prompt (Optional)**

Modern, highly customizable prompt yang super keren!

**Install with Starship:**
```bash
sudo INSTALL_STARSHIP=true ./setup.sh
```

Or after installation:
```bash
sudo INSTALL_STARSHIP=true ./setup.sh --hostname
```

**Starship Features:**
```bash
┌──racoondev@vps-dev-1125 :~/project 🌱 main [!?]
└─❯ 
```

- `┌──` - Cool box drawing
- Git branch dengan emoji 🌱
- Git status indicators: `[!?]` = modified/untracked files
- Custom symbols dan colors
- Fast & efficient (written in Rust)

---

## 🛠️ Configuration

### **Auto-Generated Hostnames**

Jika tidak set `CUSTOM_HOSTNAME`, script akan generate default:

```bash
vps-dev-MMDD          # e.g., vps-dev-1125 (bulan+tanggal)
devbox-USERNAME       # e.g., devbox-racoondev
workspace-01
code-server
dev-machine
```

### **Custom Hostname Examples**

**Personal Development:**
```bash
sudo CUSTOM_HOSTNAME="john-dev" ./setup.sh
```

**Project-Specific:**
```bash
sudo CUSTOM_HOSTNAME="project-api" ./setup.sh
```

**Environment-Specific:**
```bash
sudo CUSTOM_HOSTNAME="staging-web" ./setup.sh
sudo CUSTOM_HOSTNAME="prod-app-01" ./setup.sh
```

**Fun Names:**
```bash
sudo CUSTOM_HOSTNAME="tardis" ./setup.sh
sudo CUSTOM_HOSTNAME="enterprise" ./setup.sh
sudo CUSTOM_HOSTNAME="skynet" ./setup.sh
```

---

## 📋 Step-by-Step Guide

### **During Fresh Installation**

```bash
# 1. Clone repository
git clone https://github.com/angga13142/Vps-setup.git
cd Vps-setup

# 2. Install with custom hostname
sudo CUSTOM_HOSTNAME="my-awesome-server" \
     DEV_USER="john" \
     DEV_USER_PASSWORD="SecurePass123!" \
     INSTALL_STARSHIP=true \
     ./setup.sh

# 3. Reboot
sudo reboot

# 4. Login via RDP/SSH and verify
hostname  # Should show: my-awesome-server
```

### **After Installation (Change Existing)**

```bash
# 1. Run interactive hostname changer
sudo ./setup.sh --hostname

# 2. Choose new hostname
# (follow prompts)

# 3. Apply changes
sudo reboot

# 4. Verify
hostname
```

### **Applying Prompt Changes Without Reboot**

Hostname change butuh reboot, tapi prompt changes bisa langsung:

```bash
# For Bash
source ~/.bashrc

# For Zsh
source ~/.zshrc

# Or just start new terminal session
```

---

## 🎨 Customize Your Own Prompt

### **Edit Bash Prompt**

Edit `~/.bashrc` dan modify bagian ini:

```bash
# Custom PS1
PS1="${COLOR_TIME}\t${COLOR_RESET} "      # Time
PS1+="${COLOR_USER}\u${COLOR_RESET}"     # Username
PS1+="@"
PS1+="${COLOR_HOST}\h${COLOR_RESET}"     # Hostname
PS1+=":"
PS1+="${COLOR_PATH}\w${COLOR_RESET}"     # Path
PS1+="${COLOR_GIT}\$(parse_git_branch)${COLOR_RESET}"  # Git branch
PS1+="\n${COLOR_PROMPT}❯${COLOR_RESET} "  # Prompt symbol
```

**Color options:**
- `\[\e[1;31m\]` - Bold Red
- `\[\e[1;32m\]` - Bold Green
- `\[\e[1;33m\]` - Bold Yellow
- `\[\e[1;34m\]` - Bold Blue
- `\[\e[1;35m\]` - Bold Magenta
- `\[\e[1;36m\]` - Bold Cyan
- `\[\e[0m\]` - Reset

### **Edit Zsh Prompt**

Edit `~/.zshrc`:

```bash
# Format options
PROMPT='%F{white}%*%f '              # Time
PROMPT+='%F{green}%n%f'              # Username
PROMPT+='@%F{blue}%m%f:'             # Hostname
PROMPT+='%F{yellow}%~%f'             # Path
PROMPT+='%F{cyan}${vcs_info_msg_0_}%f'  # Git info
PROMPT+=$'\n%F{magenta}❯%f '         # New line + prompt
```

### **Starship Configuration**

Edit `~/.config/starship.toml`:

```toml
[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[username]
style_user = "bold green"
show_always = true

# Add more customizations
# See: https://starship.rs/config/
```

---

## 🔧 Troubleshooting

### **Hostname Not Changing**

**Problem:** Hostname masih menampilkan yang lama setelah reboot.

**Solution:**
```bash
# 1. Check hostname files
cat /etc/hostname
cat /etc/hosts

# 2. Manually set (if needed)
sudo hostnamectl set-hostname my-new-hostname

# 3. Update /etc/hosts
sudo nano /etc/hosts
# Change old hostname to new one

# 4. Reboot
sudo reboot
```

### **Prompt Not Updating**

**Problem:** Prompt masih default setelah install.

**Solution:**
```bash
# 1. Check if prompt was added
grep "VPS Bootstrap Custom Prompt" ~/.bashrc

# 2. Reload shell config
source ~/.bashrc  # or ~/.zshrc

# 3. If still not working, check for errors
bash -n ~/.bashrc  # Check for syntax errors

# 4. Start new terminal session
```

### **Starship Not Working**

**Problem:** Starship installed tapi tidak aktif.

**Solution:**
```bash
# 1. Check if installed
which starship

# 2. Check if in shell config
grep "starship init" ~/.bashrc  # or ~/.zshrc

# 3. Manually add if missing
echo 'eval "$(starship init bash)"' >> ~/.bashrc
source ~/.bashrc

# 4. Test starship
starship --version
```

### **Git Branch Not Showing**

**Problem:** Git branch tidak muncul di prompt.

**Solution:**
```bash
# 1. Make sure you're in git repo
cd ~/your-project
git status

# 2. Check if parse_git_branch function exists
type parse_git_branch

# 3. Test function manually
parse_git_branch

# 4. Reload shell config
source ~/.bashrc
```

---

## 💡 Best Practices

### **Hostname Naming**

✅ **Do:**
- Use environment prefix: `prod-`, `staging-`, `dev-`
- Use purpose: `api-server`, `db-master`, `web-01`
- Keep it short and memorable
- Use consistent naming scheme across team

❌ **Don't:**
- Use confusing names: `test123`, `server-old`
- Include dates/versions: `server-2024` (hostname jarang diupdate)
- Use cryptic names: `xyz789`

### **Terminal Prompts**

✅ **Do:**
- Include useful info: git branch, exit status
- Use colors for readability
- Multi-line prompt untuk commands panjang
- Show current directory (truncated)

❌ **Don't:**
- Overly long prompts (takes up space)
- Too many colors (hard to read)
- Include sensitive info (passwords, keys)

### **Starship**

✅ **Do:**
- Customize config untuk workflow Anda
- Enable relevant modules only
- Use Nerd Fonts untuk icons

❌ **Don't:**
- Enable semua modules (slow)
- Use default config blindly
- Forget to install font untuk icons

---

## 🎯 Examples & Use Cases

### **Scenario 1: Multiple VPS Management**

Jika manage banyak VPS, beri nama jelas:

```bash
# API Server
sudo CUSTOM_HOSTNAME="api-prod-01" ./setup.sh

# Database Server
sudo CUSTOM_HOSTNAME="db-master" ./setup.sh

# Web Server
sudo CUSTOM_HOSTNAME="web-nginx-01" ./setup.sh
```

Saat SSH, langsung tahu di server mana:
```bash
ssh user@api-prod-01    # API server
ssh user@db-master      # Database
ssh user@web-nginx-01   # Web server
```

### **Scenario 2: Team Development**

Beri nama per developer:

```bash
# John's dev server
sudo CUSTOM_HOSTNAME="john-dev" ./setup.sh

# Sarah's dev server
sudo CUSTOM_HOSTNAME="sarah-dev" ./setup.sh
```

### **Scenario 3: Fun Personal Server**

```bash
# Star Wars themed
sudo CUSTOM_HOSTNAME="millennium-falcon" ./setup.sh

# Star Trek themed
sudo CUSTOM_HOSTNAME="enterprise-d" ./setup.sh

# Marvel themed
sudo CUSTOM_HOSTNAME="shield-helicarrier" ./setup.sh
```

---

## 📚 Additional Resources

### **Prompt Generators**
- https://bash-prompt-generator.org/
- https://starship.rs/presets/

### **Color Codes**
- https://misc.flogisoft.com/bash/tip_colors_and_formatting

### **Starship Docs**
- https://starship.rs/config/
- https://github.com/starship/starship

### **Oh My Zsh Themes**
- https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

---

## 🚀 Quick Commands Summary

```bash
# Change hostname (interactive)
sudo ./setup.sh --hostname

# Install with custom hostname
sudo CUSTOM_HOSTNAME="my-server" ./setup.sh

# Install with Starship
sudo INSTALL_STARSHIP=true ./setup.sh

# Apply prompt changes (no reboot)
source ~/.bashrc    # or ~/.zshrc

# Check current hostname
hostname

# Manual hostname change
sudo hostnamectl set-hostname new-name

# Test Starship
starship --version
starship config
```

---

**Make your terminal beautiful! 🎨✨**

