#!/bin/bash

# ==============================================================================
# Node.js Module - Node.js via NVM
# ==============================================================================

setup_nodejs() {
    update_progress "setup_nodejs"
    log_info "Menginstal Node.js via NVM (sebagai user $DEV_USER)..."
    
    if ! run_as_user "$DEV_USER" bash <<'EOF'
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
EOF
    then
        log_error "Gagal menginstal Node.js via NVM"
        return 1
    fi
    
    log_success "Node.js setup selesai"
}

