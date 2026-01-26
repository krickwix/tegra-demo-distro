#!/bin/bash

# Manual setup script - creates repository metadata without requiring sudo
# Run this AFTER you have installed createrepo manually with: sudo apt install createrepo

set -e

RPM_BASE_DIR="/media/fandrieu/build/all/tmp/deploy/rpm"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Tegra RPM Repository - Manual Setup ===${NC}"

# Check if createrepo is installed
if ! command -v createrepo &> /dev/null && ! command -v createrepo_c &> /dev/null; then
    echo -e "${RED}Error: createrepo is not installed${NC}"
    echo -e "${YELLOW}Please install it first with:${NC}"
    echo -e "  ${YELLOW}sudo apt install createrepo${NC}"
    exit 1
fi

# Detect which command to use
if command -v createrepo_c &> /dev/null; then
    CREATEREPO_CMD="createrepo_c"
else
    CREATEREPO_CMD="createrepo"
fi

echo -e "${GREEN}Using: $CREATEREPO_CMD${NC}"

# Check if base directory exists
if [ ! -d "$RPM_BASE_DIR" ]; then
    echo -e "${RED}Error: RPM directory not found: $RPM_BASE_DIR${NC}"
    exit 1
fi

# Get all subdirectories
ARCH_DIRS=$(find "$RPM_BASE_DIR" -maxdepth 1 -type d ! -path "$RPM_BASE_DIR" | sort)

if [ -z "$ARCH_DIRS" ]; then
    echo -e "${RED}Error: No subdirectories found in $RPM_BASE_DIR${NC}"
    exit 1
fi

echo -e "\n${GREEN}Found the following directories:${NC}"
for dir in $ARCH_DIRS; do
    basename "$dir"
done

echo -e "\n${GREEN}Creating repository metadata...${NC}"
echo -e "${YELLOW}This may take several minutes for large repositories...${NC}\n"

total=0
success=0
failed=0

for dir in $ARCH_DIRS; do
    arch_name=$(basename "$dir")
    total=$((total + 1))
    
    # Count RPM packages
    rpm_count=$(find "$dir" -maxdepth 1 -name "*.rpm" 2>/dev/null | wc -l)
    
    if [ $rpm_count -eq 0 ]; then
        echo -e "${YELLOW}[$total] Skipping $arch_name (no RPM packages)${NC}"
        continue
    fi
    
    echo -e "${GREEN}[$total] Processing $arch_name ($rpm_count packages)...${NC}"
    
    # Create or update repository metadata
    if [ -d "$dir/repodata" ]; then
        if $CREATEREPO_CMD --update "$dir" > /dev/null 2>&1; then
            echo -e "    ${GREEN}✓ Updated existing metadata${NC}"
            success=$((success + 1))
        else
            echo -e "    ${RED}✗ Failed to update metadata${NC}"
            failed=$((failed + 1))
        fi
    else
        if $CREATEREPO_CMD "$dir" > /dev/null 2>&1; then
            echo -e "    ${GREEN}✓ Created new metadata${NC}"
            success=$((success + 1))
        else
            echo -e "    ${RED}✗ Failed to create metadata${NC}"
            failed=$((failed + 1))
        fi
    fi
done

echo -e "\n${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Repository Setup Complete!${NC}"
echo -e "  Total directories: $total"
echo -e "  ${GREEN}Successful: $success${NC}"
if [ $failed -gt 0 ]; then
    echo -e "  ${RED}Failed: $failed${NC}"
fi
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"

if [ $success -gt 0 ]; then
    echo -e "\n${GREEN}Next Steps:${NC}"
    echo -e "1. Start the repository server:"
    echo -e "   ${YELLOW}cd /media/fandrieu/build/all/tmp/deploy${NC}"
    echo -e "   ${YELLOW}python3 -m http.server 8080${NC}"
    echo -e ""
    echo -e "2. Repository will be available at:"
    echo -e "   ${YELLOW}http://YOUR_IP:8080/rpm/${NC}"
    echo -e ""
    echo -e "3. On Jetson devices, copy and edit repo config:"
    echo -e "   ${YELLOW}scp device-specific-repos/jetson-agx-xavier.repo nvidia@jetson:/tmp/${NC}"
    echo -e "   Then edit to replace YOUR_SERVER_IP with: YOUR_IP:8080/rpm"
    echo -e ""
    echo -e "For detailed instructions, see: ${YELLOW}INSTALL_INSTRUCTIONS.txt${NC}"
fi
