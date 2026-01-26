#!/bin/bash

# Tegra RPM Repository Setup Script
# This script creates yum/dnf repository metadata for all RPM packages

set -e

# Configuration
RPM_BASE_DIR="/media/fandrieu/build/all/tmp/deploy/rpm"
REPO_BASE_DIR="/var/www/html/tegra-repo"
REPO_NAME="tegra-demo-distro"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Tegra RPM Repository Setup ===${NC}"

# Check if running as root for some operations
if [[ $EUID -ne 0 ]] && [[ "$1" != "--local-only" ]]; then
   echo -e "${YELLOW}Warning: This script may need sudo for web server setup.${NC}"
   echo -e "${YELLOW}Run with --local-only to skip web server configuration.${NC}"
fi

# Check for createrepo_c or createrepo
echo -e "\n${GREEN}Checking for createrepo...${NC}"
if command -v createrepo_c &> /dev/null; then
    CREATEREPO_CMD="createrepo_c"
    echo -e "${GREEN}createrepo_c is already installed.${NC}"
elif command -v createrepo &> /dev/null; then
    CREATEREPO_CMD="createrepo"
    echo -e "${GREEN}createrepo is already installed.${NC}"
else
    echo -e "${YELLOW}createrepo not found. Installing...${NC}"
    sudo apt update
    # Try createrepo-c first (newer systems), fall back to createrepo (Ubuntu 18.04)
    if sudo apt install -y createrepo-c 2>/dev/null; then
        CREATEREPO_CMD="createrepo_c"
    else
        sudo apt install -y createrepo
        CREATEREPO_CMD="createrepo"
    fi
fi

echo -e "${GREEN}Using: $CREATEREPO_CMD${NC}"

# Get all subdirectories containing RPM packages
echo -e "\n${GREEN}Scanning for RPM directories...${NC}"
ARCH_DIRS=$(find "$RPM_BASE_DIR" -maxdepth 1 -type d ! -path "$RPM_BASE_DIR" | sort)

if [ -z "$ARCH_DIRS" ]; then
    echo -e "${RED}Error: No subdirectories found in $RPM_BASE_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}Found the following architecture/device directories:${NC}"
for dir in $ARCH_DIRS; do
    basename "$dir"
done

# Create repository metadata for each directory
echo -e "\n${GREEN}Creating repository metadata...${NC}"
for dir in $ARCH_DIRS; do
    arch_name=$(basename "$dir")
    echo -e "${GREEN}Processing: $arch_name${NC}"
    
    # Count RPM packages
    rpm_count=$(find "$dir" -maxdepth 1 -name "*.rpm" | wc -l)
    echo -e "  Found $rpm_count RPM packages"
    
    if [ $rpm_count -eq 0 ]; then
        echo -e "${YELLOW}  Skipping (no RPM packages found)${NC}"
        continue
    fi
    
    # Create or update repository metadata
    if [ -d "$dir/repodata" ]; then
        echo -e "  Updating existing repository metadata..."
        $CREATEREPO_CMD --update "$dir"
    else
        echo -e "  Creating new repository metadata..."
        $CREATEREPO_CMD "$dir"
    fi
    
    echo -e "${GREEN}  ✓ Repository metadata created successfully${NC}"
done

# Create a repo file for clients
echo -e "\n${GREEN}Creating repository configuration files...${NC}"
mkdir -p ./repo-configs

cat > ./repo-configs/tegra-demo-distro.repo << 'EOF'
# Tegra Demo Distro - RPM Repository Configuration
# Copy this file to /etc/yum.repos.d/ on target systems

# Base architecture packages
[tegra-armv8a]
name=Tegra Demo Distro - ARMv8a
baseurl=http://YOUR_SERVER_IP/tegra-repo/armv8a
enabled=1
gpgcheck=0
priority=10

[tegra-armv8a-tegra]
name=Tegra Demo Distro - ARMv8a Tegra
baseurl=http://YOUR_SERVER_IP/tegra-repo/armv8a_tegra
enabled=1
gpgcheck=0
priority=10

[tegra-armv8a-tegra186]
name=Tegra Demo Distro - ARMv8a Tegra 186 (TX2)
baseurl=http://YOUR_SERVER_IP/tegra-repo/armv8a_tegra186
enabled=1
gpgcheck=0
priority=10

[tegra-armv8a-tegra194]
name=Tegra Demo Distro - ARMv8a Tegra 194 (Xavier)
baseurl=http://YOUR_SERVER_IP/tegra-repo/armv8a_tegra194
enabled=1
gpgcheck=0
priority=10

# Device-specific packages
[tegra-jetson-agx-xavier]
name=Tegra Demo Distro - Jetson AGX Xavier DevKit
baseurl=http://YOUR_SERVER_IP/tegra-repo/jetson_agx_xavier_devkit
enabled=1
gpgcheck=0
priority=5

[tegra-jetson-xavier-nx]
name=Tegra Demo Distro - Jetson Xavier NX DevKit
baseurl=http://YOUR_SERVER_IP/tegra-repo/jetson_xavier_nx_devkit
enabled=1
gpgcheck=0
priority=5

[tegra-jetson-xavier-nx-tx2]
name=Tegra Demo Distro - Jetson Xavier NX DevKit TX2
baseurl=http://YOUR_SERVER_IP/tegra-repo/jetson_xavier_nx_devkit_tx2_nx
enabled=1
gpgcheck=0
priority=5

# Architecture-independent packages
[tegra-noarch]
name=Tegra Demo Distro - NoArch
baseurl=http://YOUR_SERVER_IP/tegra-repo/noarch
enabled=1
gpgcheck=0
priority=10

EOF

echo -e "${GREEN}Created: ./repo-configs/tegra-demo-distro.repo${NC}"

# Setup web server (if not local-only)
if [[ "$1" != "--local-only" ]]; then
    echo -e "\n${GREEN}Setting up web server access...${NC}"
    
    # Check for nginx or apache
    if command -v nginx &> /dev/null; then
        echo -e "${GREEN}Found nginx. Creating configuration...${NC}"
        
        # Create nginx configuration
        cat > ./repo-configs/nginx-tegra-repo.conf << EOF
server {
    listen 80;
    server_name _;
    
    root /var/www/html;
    autoindex on;
    
    location /tegra-repo {
        alias $RPM_BASE_DIR;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
    
    # Enable directory listing
    location ~ /\.ht {
        deny all;
    }
}
EOF
        echo -e "${GREEN}Created: ./repo-configs/nginx-tegra-repo.conf${NC}"
        echo -e "${YELLOW}To enable: sudo cp ./repo-configs/nginx-tegra-repo.conf /etc/nginx/sites-available/tegra-repo.conf${NC}"
        echo -e "${YELLOW}           sudo ln -s /etc/nginx/sites-available/tegra-repo.conf /etc/nginx/sites-enabled/${NC}"
        echo -e "${YELLOW}           sudo nginx -t && sudo systemctl reload nginx${NC}"
        
    elif command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
        echo -e "${GREEN}Found Apache. Creating configuration...${NC}"
        
        cat > ./repo-configs/apache-tegra-repo.conf << EOF
Alias /tegra-repo "$RPM_BASE_DIR"

<Directory "$RPM_BASE_DIR">
    Options +Indexes +FollowSymLinks
    Require all granted
    IndexOptions FancyIndexing NameWidth=* DescriptionWidth=*
</Directory>
EOF
        echo -e "${GREEN}Created: ./repo-configs/apache-tegra-repo.conf${NC}"
        echo -e "${YELLOW}To enable: sudo cp ./repo-configs/apache-tegra-repo.conf /etc/apache2/conf-available/${NC}"
        echo -e "${YELLOW}           sudo a2enconf apache-tegra-repo && sudo systemctl reload apache2${NC}"
        
    else
        echo -e "${YELLOW}No web server found. You can use Python's built-in HTTP server:${NC}"
        echo -e "${YELLOW}    cd $RPM_BASE_DIR && python3 -m http.server 8080${NC}"
    fi
else
    echo -e "\n${YELLOW}Skipping web server setup (--local-only mode)${NC}"
fi

# Create a simple HTTP server script
cat > ./start-repo-server.sh << EOF
#!/bin/bash
# Simple HTTP server for testing the repository

PORT=8080
BASE_DIR="$RPM_BASE_DIR"

echo "Starting HTTP server on port \$PORT..."
echo "Repository will be available at: http://localhost:\$PORT/"
echo "Press Ctrl+C to stop"

cd "\$BASE_DIR/.." && python3 -m http.server \$PORT
EOF

chmod +x ./start-repo-server.sh
echo -e "\n${GREEN}Created: ./start-repo-server.sh (simple HTTP server for testing)${NC}"

# Create summary
echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo -e "\n${GREEN}Repository metadata has been created for:${NC}"
for dir in $ARCH_DIRS; do
    arch_name=$(basename "$dir")
    echo -e "  ✓ $arch_name"
done

echo -e "\n${GREEN}Next Steps:${NC}"
echo -e "1. ${YELLOW}Start the repository server:${NC}"
echo -e "   Option A (Simple test server): ${YELLOW}./start-repo-server.sh${NC}"
echo -e "   Option B (Production): Configure nginx/apache using the generated configs in ./repo-configs/"
echo -e ""
echo -e "2. ${YELLOW}On client machines, install the repo configuration:${NC}"
echo -e "   ${YELLOW}sudo cp repo-configs/tegra-demo-distro.repo /etc/yum.repos.d/${NC}"
echo -e "   ${YELLOW}Edit the file to replace YOUR_SERVER_IP with your actual server IP${NC}"
echo -e ""
echo -e "3. ${YELLOW}Test the repository:${NC}"
echo -e "   ${YELLOW}sudo dnf clean all${NC}"
echo -e "   ${YELLOW}sudo dnf repolist${NC}"
echo -e "   ${YELLOW}sudo dnf search <package-name>${NC}"
echo -e ""
echo -e "${GREEN}Repository URL pattern:${NC}"
echo -e "  http://YOUR_SERVER_IP/tegra-repo/{armv8a,noarch,jetson_*}/"
