#!/bin/bash
# Script to configure GitHub branch protection rules
# Requires GitHub CLI (gh) to be installed and authenticated

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER="${GITHUB_REPOSITORY_OWNER:-angga13142}"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-Vps-setup}"
BRANCH="${1:-master}"
MODE="${2:-flexible}"

echo -e "${GREEN}Setting up branch protection for: ${BRANCH}${NC}"
echo -e "Repository: ${REPO_OWNER}/${REPO_NAME}"
echo -e "Mode: ${MODE}"
echo ""

# Check if gh CLI is installed
if ! command -v gh &>/dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
    echo "Install it with: sudo apt-get install gh"
    echo "Or visit: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &>/dev/null; then
    echo -e "${YELLOW}Not authenticated. Please run: gh auth login${NC}"
    exit 1
fi

# Function to set strict protection (require PR)
set_strict_protection() {
    echo -e "${GREEN}Setting STRICT protection (require PR + CI checks)...${NC}"
    gh api "repos/${REPO_OWNER}/${REPO_NAME}/branches/${BRANCH}/protection" \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["lint","test"]}' \
        --field enforce_admins=true \
        --field required_pull_request_reviews='{"dismissal_restrictions":{},"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":1}' \
        --field restrictions=null \
        --field allow_force_pushes=false \
        --field allow_deletions=false
    echo -e "${GREEN}✓ Strict protection enabled${NC}"
}

# Function to set flexible protection (allow direct push with CI checks)
set_flexible_protection() {
    echo -e "${GREEN}Setting FLEXIBLE protection (allow direct push with CI checks)...${NC}"
    gh api "repos/${REPO_OWNER}/${REPO_NAME}/branches/${BRANCH}/protection" \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["lint","test"]}' \
        --field enforce_admins=false \
        --field restrictions=null \
        --field allow_force_pushes=false \
        --field allow_deletions=false
    echo -e "${GREEN}✓ Flexible protection enabled${NC}"
}

# Function to set minimal protection (only CI checks, no PR required)
set_minimal_protection() {
    echo -e "${GREEN}Setting MINIMAL protection (CI checks only, no PR required)...${NC}"
    gh api "repos/${REPO_OWNER}/${REPO_NAME}/branches/${BRANCH}/protection" \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["lint","test"]}' \
        --field enforce_admins=false \
        --field restrictions=null \
        --field allow_force_pushes=false \
        --field allow_deletions=false
    echo -e "${GREEN}✓ Minimal protection enabled${NC}"
}

# Function to remove protection
remove_protection() {
    echo -e "${YELLOW}Removing branch protection...${NC}"
    gh api "repos/${REPO_OWNER}/${REPO_NAME}/branches/${BRANCH}/protection" \
        --method DELETE
    echo -e "${GREEN}✓ Protection removed${NC}"
}

# Main logic
case "${MODE}" in
    strict)
        set_strict_protection
        ;;
    flexible)
        set_flexible_protection
        ;;
    minimal)
        set_minimal_protection
        ;;
    remove|disable)
        remove_protection
        ;;
    *)
        echo -e "${RED}Error: Invalid mode '${MODE}'${NC}"
        echo "Usage: $0 [branch] [mode]"
        echo ""
        echo "Modes:"
        echo "  strict    - Require PR + CI checks + 1 approval (most secure)"
        echo "  flexible  - Allow direct push with CI checks (recommended for development)"
        echo "  minimal   - CI checks only, no PR required (least restrictive)"
        echo "  remove    - Remove all protection (not recommended)"
        echo ""
        echo "Examples:"
        echo "  $0 master flexible    # Set flexible protection on master"
        echo "  $0 develop minimal    # Set minimal protection on develop"
        echo "  $0 master remove      # Remove protection (use with caution)"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Branch protection configured successfully!${NC}"
echo "View settings at: https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches"
