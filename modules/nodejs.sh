#!/bin/bash

# ==============================================================================
# Node.js Module - Node.js via NVM
# ==============================================================================

setup_nodejs() {
    update_progress "setup_nodejs"
    log_info "Menginstal Node.js via NVM (sebagai user $DEV_USER)..."
    
    # Create temporary script for NVM installation
    local nvm_script="/tmp/install-nvm-$$.sh"
    cat > "$nvm_script" <<'NVMEOF'
#!/bin/bash
set -e

# Download and install NVM
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
    echo "NVM sudah terinstal, skip download"
fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Verify NVM loaded
if ! command -v nvm &> /dev/null; then
    echo "ERROR: NVM gagal dimuat"
    exit 1
fi

# Install LTS Node
nvm install --lts
nvm use --lts
nvm alias default lts/*

# Verify Node installation
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js tidak terinstal dengan benar"
    exit 1
fi

echo "Node.js berhasil diinstal: $(node --version)"
echo "NPM version: $(npm --version)"

# Install global packages
npm install -g yarn pnpm typescript ts-node || echo "WARNING: Beberapa npm global packages gagal diinstal"
NVMEOF
    
    chmod +x "$nvm_script"
    
    # Use run_with_progress to respect VERBOSE_MODE
    if ! run_with_progress "Installing Node.js via NVM" "run_as_user \"$DEV_USER\" bash \"$nvm_script\""; then
        rm -f "$nvm_script"
        log_error "Gagal menginstal Node.js via NVM"
        return 1
    fi
    
    rm -f "$nvm_script"
    log_success "Node.js setup selesai"
}

