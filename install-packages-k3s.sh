#!/bin/bash

# Script to install packages on all k3s nodes
# Usage: ./install-packages-k3s.sh <package-name> [package2] [package3] ...

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ $# -eq 0 ]; then
    echo -e "${RED}Usage: $0 <package-name> [package2] [package3] ...${NC}"
    echo -e "\nExample:"
    echo -e "  $0 ca-certificates netbase"
    echo -e "  $0 openssh-server"
    exit 1
fi

PACKAGES="$@"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Install Packages on k3s Nodes                           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Packages to install:${NC}"
for pkg in $PACKAGES; do
    echo -e "  - $pkg"
done

echo -e "\n${YELLOW}Enter k3s node hostnames or IPs (space-separated):${NC}"
read -p "Nodes: " NODES

if [ -z "$NODES" ]; then
    echo -e "${RED}Error: No nodes specified${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Enter SSH user (default: nvidia):${NC}"
read -p "User: " SSH_USER
SSH_USER=${SSH_USER:-nvidia}

echo -e "\n${YELLOW}Install mode:${NC}"
echo -e "  1) Install (if not already installed)"
echo -e "  2) Reinstall (force reinstall)"
echo -e "  3) Upgrade (upgrade if already installed)"
read -p "Choice [1-3]: " MODE
MODE=${MODE:-1}

case $MODE in
    1) DNF_CMD="install -y" ;;
    2) DNF_CMD="reinstall -y" ;;
    3) DNF_CMD="upgrade -y" ;;
    *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
esac

echo -e "\n${YELLOW}Press Enter to continue or Ctrl+C to cancel...${NC}"
read

# Function to install on a single node
install_on_node() {
    local node=$1
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installing on: ${node}${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    # Check connectivity
    if ! ssh ${SSH_USER}@${node} "echo connected" &>/dev/null; then
        echo -e "${RED}✗ Cannot connect to ${node}${NC}"
        return 1
    fi
    
    # Install packages
    echo -e "${YELLOW}Running: sudo dnf ${DNF_CMD} ${PACKAGES}${NC}"
    
    if ssh ${SSH_USER}@${node} "sudo dnf ${DNF_CMD} ${PACKAGES}" 2>&1 | tee /tmp/install_${node}.log; then
        echo -e "${GREEN}✓ Installation successful on ${node}${NC}"
        
        # Show installed versions
        echo -e "\n${YELLOW}Installed versions:${NC}"
        for pkg in $PACKAGES; do
            VERSION=$(ssh ${SSH_USER}@${node} "rpm -q ${pkg} 2>/dev/null" || echo "Not installed")
            echo -e "  ${pkg}: ${VERSION}"
        done
        
        return 0
    else
        echo -e "${RED}✗ Installation failed on ${node}${NC}"
        echo -e "${YELLOW}Check log: /tmp/install_${node}.log${NC}"
        
        # Check for dependency issues
        if grep -q "nothing provides" /tmp/install_${node}.log; then
            echo -e "${RED}Missing dependencies detected:${NC}"
            grep "nothing provides" /tmp/install_${node}.log | sed 's/^/  /'
        fi
        
        return 1
    fi
}

# Install on all nodes
success_count=0
fail_count=0
failed_nodes=""

for node in $NODES; do
    if install_on_node "$node"; then
        success_count=$((success_count + 1))
    else
        fail_count=$((fail_count + 1))
        failed_nodes="${failed_nodes} ${node}"
    fi
done

# Summary
echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  Installation Summary                       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "\n${GREEN}Successful: ${success_count}${NC}"
echo -e "${RED}Failed: ${fail_count}${NC}"

if [ $fail_count -gt 0 ]; then
    echo -e "\n${RED}Failed nodes:${NC}${failed_nodes}"
    echo -e "\n${YELLOW}Troubleshooting:${NC}"
    echo -e "1. Check repository connectivity:"
    echo -e "   ${YELLOW}ssh ${SSH_USER}@<node> 'sudo dnf repolist'${NC}"
    echo -e ""
    echo -e "2. Check for missing dependencies:"
    echo -e "   ${YELLOW}cat /tmp/install_<node>.log${NC}"
    echo -e ""
    echo -e "3. If dependencies are missing, rebuild them:"
    echo -e "   ${YELLOW}See MISSING_DEPENDENCIES_REPORT.txt${NC}"
fi

echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
