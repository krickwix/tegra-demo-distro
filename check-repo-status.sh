#!/bin/bash

# Script to check the status of the Tegra RPM repository

RPM_BASE_DIR="/media/fandrieu/build/all/tmp/deploy/rpm"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Tegra RPM Repository Status Check                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

if [ ! -d "$RPM_BASE_DIR" ]; then
    echo -e "${RED}ERROR: RPM base directory not found: $RPM_BASE_DIR${NC}"
    exit 1
fi

# Get all subdirectories
ARCH_DIRS=$(find "$RPM_BASE_DIR" -maxdepth 1 -type d ! -path "$RPM_BASE_DIR" | sort)

total_packages=0
total_repos_ready=0
total_repos=0

echo -e "\n${BLUE}Repository Summary:${NC}"
echo -e "═══════════════════════════════════════════════════════════════"

for dir in $ARCH_DIRS; do
    arch_name=$(basename "$dir")
    total_repos=$((total_repos + 1))
    
    # Count packages
    rpm_count=$(find "$dir" -maxdepth 1 -name "*.rpm" 2>/dev/null | wc -l)
    total_packages=$((total_packages + rpm_count))
    
    # Check for repodata
    if [ -d "$dir/repodata" ]; then
        status="${GREEN}✓ Ready${NC}"
        total_repos_ready=$((total_repos_ready + 1))
        
        # Check repodata age
        repomd_file="$dir/repodata/repomd.xml"
        if [ -f "$repomd_file" ]; then
            age=$(stat -c %Y "$repomd_file")
            now=$(date +%s)
            age_hours=$(( (now - age) / 3600 ))
            age_info=" (metadata: ${age_hours}h old)"
        else
            age_info=""
        fi
    else
        status="${RED}✗ Not Ready${NC}"
        age_info=""
    fi
    
    printf "%-35s %6s packages  %s%s\n" "$arch_name" "$rpm_count" "$status" "$age_info"
done

echo -e "═══════════════════════════════════════════════════════════════"
echo -e "${BLUE}Total Repositories:${NC} $total_repos"
echo -e "${BLUE}Repositories Ready:${NC} $total_repos_ready / $total_repos"
echo -e "${BLUE}Total Packages:${NC} $total_packages"

# Check if createrepo_c or createrepo is installed
echo -e "\n${BLUE}Tool Check:${NC}"
if command -v createrepo_c &> /dev/null; then
    version=$(createrepo_c --version 2>&1 | head -1)
    echo -e "  createrepo_c: ${GREEN}✓ Installed${NC} ($version)"
elif command -v createrepo &> /dev/null; then
    version=$(createrepo --version 2>&1 | head -1)
    echo -e "  createrepo: ${GREEN}✓ Installed${NC} ($version)"
else
    echo -e "  createrepo: ${RED}✗ Not Installed${NC}"
    echo -e "    ${YELLOW}Install with: sudo apt install createrepo${NC}"
fi

# Check for web servers
echo -e "\n${BLUE}Web Server Check:${NC}"
web_server_found=false

if command -v nginx &> /dev/null; then
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "  nginx: ${GREEN}✓ Installed and Running${NC}"
        web_server_found=true
    else
        echo -e "  nginx: ${YELLOW}✓ Installed but Not Running${NC}"
        web_server_found=true
    fi
fi

if command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
    if systemctl is-active --quiet apache2 2>/dev/null || systemctl is-active --quiet httpd 2>/dev/null; then
        echo -e "  apache: ${GREEN}✓ Installed and Running${NC}"
        web_server_found=true
    else
        echo -e "  apache: ${YELLOW}✓ Installed but Not Running${NC}"
        web_server_found=true
    fi
fi

if ! $web_server_found; then
    echo -e "  ${YELLOW}No web server detected${NC}"
    echo -e "    Use ${YELLOW}./start-repo-server.sh${NC} for a simple HTTP server"
fi

# Recommendations
echo -e "\n${BLUE}Recommendations:${NC}"

if [ $total_repos_ready -lt $total_repos ]; then
    echo -e "  ${YELLOW}⚠${NC}  Run ${YELLOW}./setup-yum-repo.sh${NC} to initialize repository metadata"
fi

if [ $total_repos_ready -eq $total_repos ] && [ $total_repos_ready -gt 0 ]; then
    echo -e "  ${GREEN}✓${NC}  All repositories are ready!"
    
    if ! $web_server_found || ! systemctl is-active --quiet nginx 2>/dev/null && ! systemctl is-active --quiet apache2 2>/dev/null; then
        echo -e "  ${YELLOW}⚠${NC}  Start web server to make repository accessible"
        echo -e "      ${YELLOW}./start-repo-server.sh${NC} (for testing)"
    fi
fi

# Check if any package is newer than repodata
echo -e "\n${BLUE}Checking for outdated metadata...${NC}"
needs_update=false

for dir in $ARCH_DIRS; do
    if [ -d "$dir/repodata" ]; then
        repomd_file="$dir/repodata/repomd.xml"
        if [ -f "$repomd_file" ]; then
            newest_rpm=$(find "$dir" -maxdepth 1 -name "*.rpm" -newer "$repomd_file" 2>/dev/null | head -1)
            if [ -n "$newest_rpm" ]; then
                echo -e "  ${YELLOW}⚠${NC}  $(basename "$dir"): New packages detected since last metadata update"
                needs_update=true
            fi
        fi
    fi
done

if $needs_update; then
    echo -e "\n  ${YELLOW}Run ./update-repo.sh to update metadata${NC}"
else
    echo -e "  ${GREEN}✓${NC}  All repository metadata is up to date"
fi

echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
