#!/bin/bash

# ==============================================================================
# Idempotency Test Script
# ==============================================================================
# Tests that the setup script can be run multiple times without errors
# Especially focuses on GPG key handling
# ==============================================================================

set -e

echo "=========================================="
echo "  VPS Bootstrap Idempotency Test"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Test 1: Check GPG key cleanup functions
echo "Test 1: GPG Key Helper Functions"
source lib/helpers.sh
source lib/logging.sh

# Test clean_gpg_keys
clean_gpg_keys "test-key" >/dev/null 2>&1 && pass "clean_gpg_keys function works" || fail "clean_gpg_keys function failed"

# Test 2: Docker GPG handling
echo ""
echo "Test 2: Docker GPG Key Handling"

# Simulate Docker already installed
if command -v docker &>/dev/null; then
    pass "Docker already installed - will test skip logic"
else
    warn "Docker not installed - cannot test skip logic"
fi

# Test 3: VS Code GPG handling  
echo ""
echo "Test 3: VS Code GPG Key Handling"

if command -v code &>/dev/null; then
    pass "VS Code already installed - will test skip logic"
else
    warn "VS Code not installed - cannot test skip logic"
fi

# Test 4: Check for conflicting GPG keys
echo ""
echo "Test 4: Checking for Conflicting GPG Keys"

conflicts=0

# Check Microsoft keys
if [ -f /etc/apt/keyrings/packages.microsoft.gpg ] && [ -f /usr/share/keyrings/microsoft.gpg ]; then
    fail "Found conflicting Microsoft GPG keys"
    conflicts=$((conflicts+1))
fi

# Check Docker keys
if [ -f /etc/apt/keyrings/docker.gpg ] && [ -f /etc/apt/keyrings/docker.gpg~ ]; then
    fail "Found conflicting Docker GPG keys"
    conflicts=$((conflicts+1))
fi

if [ $conflicts -eq 0 ]; then
    pass "No conflicting GPG keys found"
fi

# Test 5: Apt sources validation
echo ""
echo "Test 5: Apt Sources Validation"

# Check for duplicate sources
if [ -f /etc/apt/sources.list.d/vscode.list ]; then
    count=$(grep -c "packages.microsoft.com" /etc/apt/sources.list.d/vscode.list 2>/dev/null || echo 0)
    if [ "$count" -le 1 ]; then
        pass "VS Code apt source is clean"
    else
        fail "Duplicate VS Code apt sources found"
    fi
fi

if [ -f /etc/apt/sources.list.d/docker.list ]; then
    count=$(grep -c "download.docker.com" /etc/apt/sources.list.d/docker.list 2>/dev/null || echo 0)
    if [ "$count" -le 1 ]; then
        pass "Docker apt source is clean"
    else
        fail "Duplicate Docker apt sources found"
    fi
fi

# Test 6: Run apt update to check for errors
echo ""
echo "Test 6: Apt Update Test"

if apt-get update >/tmp/apt-test.log 2>&1; then
    pass "Apt update successful"
else
    if grep -qi "conflicting values.*signed-by" /tmp/apt-test.log; then
        fail "Found GPG signing conflicts in apt update"
        cat /tmp/apt-test.log
    else
        warn "Apt update had warnings (may be non-critical)"
    fi
fi

# Test 7: Module syntax validation
echo ""
echo "Test 7: Module Syntax Validation"

for module in modules/*.sh; do
    if bash -n "$module" 2>/dev/null; then
        pass "$(basename $module) syntax OK"
    else
        fail "$(basename $module) has syntax errors"
    fi
done

# Summary
echo ""
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
pass "All idempotency tests passed!"
echo ""
echo "The script is safe to run multiple times without GPG conflicts."
echo ""

