#!/bin/bash

# ==============================================================================
# Python Module - Python Stack
# ==============================================================================

setup_python() {
    update_progress "setup_python"
    log_info "Menginstal Python Stack..."
    
    check_and_install "python3"
    check_and_install "python3-pip"
    check_and_install "python3-venv"
    
    # Verify Python
    if command_exists python3; then
        log_success "Python berhasil diinstal: $(python3 --version)"
    else
        log_error "Python tidak terinstal dengan benar"
        return 1
    fi
    
    log_success "Python setup selesai"
}

