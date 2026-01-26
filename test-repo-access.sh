#!/bin/bash

# Script to test repository accessibility

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Tegra RPM Repository Access Test                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

# Prompt for server address
echo -e "\n${YELLOW}Enter the server address to test (e.g., localhost:8080 or 192.168.1.100):${NC}"
read -p "Server: " server_addr

if [ -z "$server_addr" ]; then
    echo -e "${RED}Error: Server address is required${NC}"
    exit 1
fi

# Ensure http:// prefix
if [[ ! $server_addr =~ ^http ]]; then
    server_addr="http://$server_addr"
fi

# Test repositories
repos=("noarch" "armv8a" "armv8a_tegra" "armv8a_tegra186" "armv8a_tegra194" 
       "jetson_agx_xavier_devkit" "jetson_xavier_nx_devkit" "jetson_xavier_nx_devkit_tx2_nx")

echo -e "\n${BLUE}Testing Repository Access:${NC}"
echo -e "═══════════════════════════════════════════════════════════════"

successful=0
failed=0

for repo in "${repos[@]}"; do
    url="${server_addr}/tegra-repo/${repo}/repodata/repomd.xml"
    
    printf "%-35s " "$repo"
    
    if curl -s -f -o /dev/null "$url" 2>/dev/null; then
        echo -e "${GREEN}✓ Accessible${NC}"
        successful=$((successful + 1))
    else
        echo -e "${RED}✗ Not Accessible${NC}"
        failed=$((failed + 1))
    fi
done

echo -e "═══════════════════════════════════════════════════════════════"
echo -e "${BLUE}Results:${NC}"
echo -e "  Successful: ${GREEN}$successful${NC}"
echo -e "  Failed: ${RED}$failed${NC}"

if [ $failed -eq 0 ]; then
    echo -e "\n${GREEN}✓ All repositories are accessible!${NC}"
    echo -e "\n${BLUE}Next steps on client devices:${NC}"
    echo -e "1. Copy repo configuration:"
    echo -e "   ${YELLOW}scp repo-configs/tegra-demo-distro.repo user@client:/tmp/${NC}"
    echo -e ""
    echo -e "2. On client, edit and install:"
    echo -e "   ${YELLOW}sudo nano /tmp/tegra-demo-distro.repo${NC}"
    echo -e "   Replace YOUR_SERVER_IP with: $(echo $server_addr | sed 's#http://##')"
    echo -e "   ${YELLOW}sudo cp /tmp/tegra-demo-distro.repo /etc/yum.repos.d/${NC}"
    echo -e ""
    echo -e "3. Test on client:"
    echo -e "   ${YELLOW}sudo dnf clean all${NC}"
    echo -e "   ${YELLOW}sudo dnf repolist${NC}"
else
    echo -e "\n${YELLOW}⚠ Some repositories are not accessible${NC}"
    echo -e "\n${BLUE}Troubleshooting:${NC}"
    echo -e "1. Check if web server is running:"
    echo -e "   ${YELLOW}./check-repo-status.sh${NC}"
    echo -e ""
    echo -e "2. If using simple HTTP server:"
    echo -e "   ${YELLOW}./start-repo-server.sh${NC}"
    echo -e ""
    echo -e "3. Check server logs:"
    echo -e "   ${YELLOW}sudo journalctl -u nginx -n 50${NC}"
    echo -e "   ${YELLOW}sudo journalctl -u apache2 -n 50${NC}"
fi

echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
