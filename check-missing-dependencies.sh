#!/bin/bash

# Script to check for missing dependencies in the RPM repository
# This scans all RPM packages and identifies missing dependencies

set -e

RPM_BASE_DIR="/media/fandrieu/build/all/tmp/deploy/rpm"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Checking RPM Repository for Missing Dependencies        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}This may take several minutes...${NC}\n"

# Create temporary files
PROVIDES_FILE="/tmp/repo_provides.txt"
REQUIRES_FILE="/tmp/repo_requires.txt"
MISSING_FILE="/tmp/missing_deps.txt"

# Clean up previous runs
rm -f "$PROVIDES_FILE" "$REQUIRES_FILE" "$MISSING_FILE"

# Get all subdirectories
ARCH_DIRS=$(find "$RPM_BASE_DIR" -maxdepth 1 -type d ! -path "$RPM_BASE_DIR" | sort)

echo -e "${GREEN}Step 1: Collecting all provided packages and libraries...${NC}"

# Collect all provides from all packages
for dir in $ARCH_DIRS; do
    arch_name=$(basename "$dir")
    echo -e "  Scanning $arch_name..."
    
    find "$dir" -maxdepth 1 -name "*.rpm" -exec rpm -qp --provides {} \; 2>/dev/null | \
        sort -u >> "$PROVIDES_FILE"
done

# Remove duplicates
sort -u "$PROVIDES_FILE" -o "$PROVIDES_FILE"

total_provides=$(wc -l < "$PROVIDES_FILE")
echo -e "${GREEN}  Found $total_provides unique provided capabilities${NC}"

echo -e "\n${GREEN}Step 2: Collecting all required dependencies...${NC}"

# Collect all requires from all packages
for dir in $ARCH_DIRS; do
    arch_name=$(basename "$dir")
    echo -e "  Scanning $arch_name..."
    
    find "$dir" -maxdepth 1 -name "*.rpm" -exec rpm -qp --requires {} \; 2>/dev/null | \
        grep -v "^rpmlib(" | \
        grep -v "^rtld(" | \
        sort -u >> "$REQUIRES_FILE"
done

# Remove duplicates
sort -u "$REQUIRES_FILE" -o "$REQUIRES_FILE"

total_requires=$(wc -l < "$REQUIRES_FILE")
echo -e "${GREEN}  Found $total_requires unique required capabilities${NC}"

echo -e "\n${GREEN}Step 3: Finding missing dependencies...${NC}"

# Find requirements that don't have a provider
while IFS= read -r requirement; do
    # Extract just the package/library name (before version operators)
    req_name=$(echo "$requirement" | sed 's/[><=].*//' | xargs)
    
    # Skip if empty
    [ -z "$req_name" ] && continue
    
    # Check if it's provided by any package
    if ! grep -qF "$req_name" "$PROVIDES_FILE" 2>/dev/null; then
        echo "$requirement" >> "$MISSING_FILE"
    fi
done < "$REQUIRES_FILE"

echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Results:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

if [ ! -f "$MISSING_FILE" ] || [ ! -s "$MISSING_FILE" ]; then
    echo -e "${GREEN}✅ No missing dependencies found!${NC}"
    echo -e "${GREEN}All packages have their dependencies satisfied within the repository.${NC}"
else
    missing_count=$(wc -l < "$MISSING_FILE" | xargs)
    echo -e "${YELLOW}⚠  Found $missing_count potentially missing dependencies:${NC}"
    echo -e ""
    
    # Group by type
    echo -e "${YELLOW}Shared Libraries:${NC}"
    grep "\.so" "$MISSING_FILE" | sort -u | head -20
    
    echo -e "\n${YELLOW}Packages:${NC}"
    grep -v "\.so" "$MISSING_FILE" | grep -v "^lib" | sort -u | head -20
    
    echo -e "\n${YELLOW}Library Packages:${NC}"
    grep -v "\.so" "$MISSING_FILE" | grep "^lib" | sort -u | head -20
    
    if [ "$missing_count" -gt 60 ]; then
        echo -e "\n${YELLOW}... and $(($missing_count - 60)) more${NC}"
    fi
    
    echo -e "\n${BLUE}Full list saved to: $MISSING_FILE${NC}"
    
    # Check for known critical dependencies
    echo -e "\n${RED}Critical Missing Dependencies:${NC}"
    
    critical_found=false
    
    if grep -q "libisns" "$MISSING_FILE"; then
        echo -e "  ${RED}❌ open-isns${NC} - Required by iscsi-initiator-utils"
        critical_found=true
    fi
    
    if grep -q "libc6.*2.35" "$MISSING_FILE"; then
        echo -e "  ${RED}❌ glibc >= 2.35${NC} - System C library version mismatch"
        critical_found=true
    fi
    
    if ! $critical_found; then
        echo -e "  ${GREEN}No critical system dependencies missing${NC}"
    fi
fi

echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Recommendations:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

if [ -f "$MISSING_FILE" ] && [ -s "$MISSING_FILE" ]; then
    echo -e "1. Review MISSING_DEPENDENCIES_REPORT.txt for detailed analysis"
    echo -e "2. Rebuild missing packages in your Yocto environment:"
    echo -e "   ${YELLOW}bitbake <missing-package>${NC}"
    echo -e "3. Update repository after rebuilding:"
    echo -e "   ${YELLOW}./update-repo.sh${NC}"
fi

# Cleanup
echo -e "\n${GREEN}Temporary files:${NC}"
echo -e "  Provides: $PROVIDES_FILE"
echo -e "  Requires: $REQUIRES_FILE"
echo -e "  Missing:  $MISSING_FILE"

echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
