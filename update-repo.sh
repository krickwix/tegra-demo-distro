#!/bin/bash

# Quick script to update repository metadata after adding new packages
# Run this after building new RPM packages

set -e

RPM_BASE_DIR="/media/fandrieu/build/all/tmp/deploy/rpm"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect which createrepo command is available
if command -v createrepo_c &> /dev/null; then
    CREATEREPO_CMD="createrepo_c"
elif command -v createrepo &> /dev/null; then
    CREATEREPO_CMD="createrepo"
else
    echo -e "${RED}Error: Neither createrepo_c nor createrepo is installed${NC}"
    echo -e "Install with: sudo apt install createrepo"
    exit 1
fi

echo -e "${GREEN}=== Updating Tegra RPM Repository ===${NC}"
echo -e "Using: $CREATEREPO_CMD"

# Get all subdirectories
ARCH_DIRS=$(find "$RPM_BASE_DIR" -maxdepth 1 -type d ! -path "$RPM_BASE_DIR" | sort)

for dir in $ARCH_DIRS; do
    arch_name=$(basename "$dir")
    
    # Check if repodata exists
    if [ -d "$dir/repodata" ]; then
        echo -e "${GREEN}Updating: $arch_name${NC}"
        $CREATEREPO_CMD --update "$dir"
    else
        echo -e "${YELLOW}Creating new metadata for: $arch_name${NC}"
        $CREATEREPO_CMD "$dir"
    fi
done

echo -e "\n${GREEN}✓ Repository update complete!${NC}"
echo -e "Changes will be immediately available to clients."
