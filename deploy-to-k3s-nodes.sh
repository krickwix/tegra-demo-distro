#!/bin/bash

# Script to deploy Tegra RPM repository configuration to k3s nodes
# This copies the repo configuration to all k3s nodes and updates the repository cache

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Deploy Tegra Repository to k3s Nodes                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

# Configuration
REPO_SERVER="192.168.0.78:8080"
REPO_BASE_URL="http://${REPO_SERVER}"

# Prompt for k3s nodes
echo -e "\n${YELLOW}Enter k3s node hostnames or IPs (space-separated):${NC}"
echo -e "${YELLOW}Example: jetson-master jetson-worker1 jetson-worker2${NC}"
read -p "Nodes: " NODES

if [ -z "$NODES" ]; then
    echo -e "${RED}Error: No nodes specified${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Enter SSH user for k3s nodes (default: nvidia):${NC}"
read -p "User: " SSH_USER
SSH_USER=${SSH_USER:-nvidia}

echo -e "\n${GREEN}Configuration:${NC}"
echo -e "  Repository Server: ${REPO_SERVER}"
echo -e "  SSH User: ${SSH_USER}"
echo -e "  Target Nodes: ${NODES}"

echo -e "\n${YELLOW}Press Enter to continue or Ctrl+C to cancel...${NC}"
read

# Function to deploy to a single node
deploy_to_node() {
    local node=$1
    local node_name=$(echo "$node" | cut -d'.' -f1 | tr '[:upper:]' '[:lower:]')
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Deploying to: ${node}${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    # Detect device type
    echo -e "${YELLOW}[1/6]${NC} Detecting device type..."
    DEVICE_TYPE=$(ssh ${SSH_USER}@${node} "cat /proc/device-tree/model 2>/dev/null || echo 'Unknown'")
    echo -e "  Device: ${DEVICE_TYPE}"
    
    # Select appropriate repo file
    REPO_FILE=""
    if echo "$DEVICE_TYPE" | grep -qi "AGX Xavier"; then
        REPO_FILE="device-specific-repos/jetson-agx-xavier.repo"
        echo -e "  ${GREEN}Using AGX Xavier repository configuration${NC}"
    elif echo "$DEVICE_TYPE" | grep -qi "Xavier NX"; then
        REPO_FILE="device-specific-repos/jetson-xavier-nx.repo"
        echo -e "  ${GREEN}Using Xavier NX repository configuration${NC}"
    elif echo "$DEVICE_TYPE" | grep -qi "TX2"; then
        REPO_FILE="device-specific-repos/jetson-xavier-nx-tx2.repo"
        echo -e "  ${GREEN}Using Xavier NX TX2 repository configuration${NC}"
    else
        echo -e "  ${YELLOW}Device type unknown, using AGX Xavier as default${NC}"
        REPO_FILE="device-specific-repos/jetson-agx-xavier.repo"
    fi
    
    if [ ! -f "$REPO_FILE" ]; then
        echo -e "  ${RED}ERROR: Repo file not found: $REPO_FILE${NC}"
        return 1
    fi
    
    # Copy repo file
    echo -e "${YELLOW}[2/6]${NC} Copying repository configuration..."
    scp "$REPO_FILE" ${SSH_USER}@${node}:/tmp/tegra-demo-distro.repo || {
        echo -e "  ${RED}ERROR: Failed to copy repo file${NC}"
        return 1
    }
    
    # Install repo file
    echo -e "${YELLOW}[3/6]${NC} Installing repository configuration..."
    ssh ${SSH_USER}@${node} "sudo cp /tmp/tegra-demo-distro.repo /etc/yum.repos.d/" || {
        echo -e "  ${RED}ERROR: Failed to install repo file${NC}"
        return 1
    }
    
    # Test connectivity
    echo -e "${YELLOW}[4/6]${NC} Testing repository connectivity..."
    if ssh ${SSH_USER}@${node} "wget -q -O /dev/null --timeout=5 ${REPO_BASE_URL}/noarch/repodata/repomd.xml 2>&1"; then
        echo -e "  ${GREEN}✓ Repository is accessible${NC}"
    else
        echo -e "  ${RED}✗ Cannot reach repository server${NC}"
        echo -e "  ${YELLOW}Checking network connectivity...${NC}"
        ssh ${SSH_USER}@${node} "ping -c 2 ${REPO_SERVER%%:*}" || echo -e "  ${RED}Cannot ping server${NC}"
    fi
    
    # Clean and update DNF cache
    echo -e "${YELLOW}[5/6]${NC} Updating DNF repository cache..."
    ssh ${SSH_USER}@${node} "sudo dnf clean all && sudo dnf makecache" 2>&1 | grep -v "^$" || {
        echo -e "  ${RED}ERROR: Failed to update DNF cache${NC}"
        return 1
    }
    
    # List repositories
    echo -e "${YELLOW}[6/6]${NC} Verifying repositories..."
    ssh ${SSH_USER}@${node} "sudo dnf repolist | grep tegra" || {
        echo -e "  ${YELLOW}WARNING: No Tegra repositories found${NC}"
    }
    
    echo -e "${GREEN}✓ Successfully deployed to ${node}${NC}"
}

# Deploy to all nodes
success_count=0
fail_count=0

for node in $NODES; do
    if deploy_to_node "$node"; then
        success_count=$((success_count + 1))
    else
        fail_count=$((fail_count + 1))
    fi
done

# Summary
echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Deployment Summary                       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "\n${GREEN}Successful: ${success_count}${NC}"
echo -e "${RED}Failed: ${fail_count}${NC}"

if [ $success_count -gt 0 ]; then
    echo -e "\n${GREEN}Next Steps:${NC}"
    echo -e "1. Test package installation on a node:"
    echo -e "   ${YELLOW}ssh ${SSH_USER}@<node> 'sudo dnf search alsa'${NC}"
    echo -e "   ${YELLOW}ssh ${SSH_USER}@<node> 'sudo dnf install ca-certificates'${NC}"
    echo -e ""
    echo -e "2. Install packages on all nodes:"
    echo -e "   ${YELLOW}./install-packages-k3s.sh <package-name>${NC}"
fi

echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
