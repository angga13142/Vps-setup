#!/bin/bash

# ==============================================================================
# Test Script - Dry-Run Mode Validation
# ==============================================================================
# Script ini untuk test dry-run mode tanpa mengubah sistem
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     VPS Bootstrap - Dry-Run Mode Test                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test 1: Syntax validation
echo -e "${YELLOW}[TEST 1] Validating script syntax...${NC}"
if bash -n setup.sh 2>&1; then
    echo -e "${GREEN}✓ Syntax OK${NC}"
else
    echo -e "${RED}✗ Syntax errors found${NC}"
    exit 1
fi

# Test 2: Check for DRY_RUN_MODE usage
echo ""
echo -e "${YELLOW}[TEST 2] Checking for DRY_RUN_MODE support...${NC}"
if grep -r "DRY_RUN_MODE" lib/ modules/ config.sh setup.sh 2>/dev/null | grep -q "DRY_RUN_MODE"; then
    echo -e "${GREEN}✓ DRY_RUN_MODE found in codebase${NC}"
else
    echo -e "${RED}✗ DRY_RUN_MODE not found${NC}"
    exit 1
fi

# Test 3: Check for --dry-run parameter
echo ""
echo -e "${YELLOW}[TEST 3] Checking for --dry-run parameter...${NC}"
if grep -q "dry-run\|--test" setup.sh; then
    echo -e "${GREEN}✓ --dry-run parameter found${NC}"
else
    echo -e "${RED}✗ --dry-run parameter not found${NC}"
    exit 1
fi

# Test 4: Validate helper functions support dry-run
echo ""
echo -e "${YELLOW}[TEST 4] Checking helper functions for dry-run support...${NC}"
helpers_with_dry_run=0
helpers_total=0

for func in "run_with_progress" "check_and_install" "batch_install_packages" "ensure_swap_active" "wait_for_memory" "backup_file" "enable_and_start_service" "run_as_user"; do
    helpers_total=$((helpers_total + 1))
    if grep -A 5 "^${func}()" lib/helpers.sh 2>/dev/null | grep -q "DRY_RUN_MODE"; then
        echo -e "  ${GREEN}✓${NC} $func supports dry-run"
        helpers_with_dry_run=$((helpers_with_dry_run + 1))
    else
        echo -e "  ${YELLOW}⚠${NC} $func may not support dry-run"
    fi
done

echo ""
if [ $helpers_with_dry_run -eq $helpers_total ]; then
    echo -e "${GREEN}✓ All helper functions support dry-run${NC}"
else
    echo -e "${YELLOW}⚠ Some helper functions may not fully support dry-run${NC}"
fi

# Test 5: Check modules for dry-run support
echo ""
echo -e "${YELLOW}[TEST 5] Checking modules for dry-run support...${NC}"
if grep -q "DRY_RUN_MODE\|install_package_safe" modules/docker.sh; then
    echo -e "${GREEN}✓ Docker module supports dry-run${NC}"
else
    echo -e "${YELLOW}⚠ Docker module may not fully support dry-run${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Dry-run mode validation complete!${NC}"
echo ""
echo -e "${BLUE}To test dry-run mode, run:${NC}"
echo -e "  ${YELLOW}sudo ./setup.sh --dry-run${NC}"
echo ""
echo -e "${BLUE}Or with environment variables:${NC}"
echo -e "  ${YELLOW}sudo DRY_RUN_MODE=true ./setup.sh${NC}"
echo ""

