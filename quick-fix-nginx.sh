#!/bin/bash

echo "Creating simple nginx configuration for Tegra repository..."

# Copy the working configuration
sudo cp /tmp/tegra-working.conf /etc/nginx/sites-available/tegra-simple.conf

# Enable it
sudo ln -sf /etc/nginx/sites-available/tegra-simple.conf /etc/nginx/sites-enabled/tegra-simple.conf

# Test configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx

echo ""
echo "Repository should now be available at:"
echo "  http://$(hostname -I | awk '{print $1}'):8080/"
echo ""
echo "Test with:"
echo "  wget http://localhost:8080/noarch/repodata/repomd.xml"
