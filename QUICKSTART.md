# Tegra YUM/DNF Repository - Quick Start Guide

## 🚀 Get Started in 3 Steps

### Step 1: Initialize the Repository

Run the setup script to create repository metadata:

```bash
cd /home/fandrieu/Documents/tegra-demo-distro
./setup-yum-repo.sh
```

This will:
- ✅ Install `createrepo_c` (if needed)
- ✅ Generate repository metadata for all 8 package directories
- ✅ Create client configuration files
- ✅ Generate web server configurations

### Step 2: Start the Repository Server

**Quick Option (For Testing):**

```bash
./start-repo-server.sh
```

This starts a simple HTTP server on port 8080.

**Production Option (Nginx):**

```bash
sudo cp repo-configs/nginx-tegra-repo.conf /etc/nginx/sites-available/tegra-repo.conf
sudo ln -s /etc/nginx/sites-available/tegra-repo.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### Step 3: Configure Client Devices

On your Jetson device:

```bash
# Copy the appropriate repo file to your Jetson device
scp device-specific-repos/jetson-agx-xavier.repo nvidia@jetson:/tmp/

# On the Jetson device
sudo cp /tmp/jetson-agx-xavier.repo /etc/yum.repos.d/

# Edit to set your server IP
sudo nano /etc/yum.repos.d/jetson-agx-xavier.repo
# Replace YOUR_SERVER_IP with your actual server IP (e.g., 192.168.1.100)

# Update repository cache
sudo dnf clean all
sudo dnf makecache

# Test it
sudo dnf repolist
sudo dnf search alsa
```

---

## 📦 What Packages Are Available?

Your repository contains **8 package directories**:

| Directory | Description | Packages |
|-----------|-------------|----------|
| `noarch` | Architecture-independent packages | ca-certificates, alsa configs, etc. |
| `armv8a` | Base ARMv8a architecture | Base system packages |
| `armv8a_tegra` | Common Tegra packages | Tegra-specific libraries |
| `armv8a_tegra186` | TX2 platform (Tegra 186) | TX2-specific packages |
| `armv8a_tegra194` | Xavier platform (Tegra 194) | Xavier-specific packages |
| `jetson_agx_xavier_devkit` | AGX Xavier device-specific | Device drivers & configs |
| `jetson_xavier_nx_devkit` | Xavier NX device-specific | Device drivers & configs |
| `jetson_xavier_nx_devkit_tx2_nx` | Xavier NX + TX2 module | Module-specific packages |

---

## 🔧 Maintenance Commands

**Check Repository Status:**
```bash
./check-repo-status.sh
```

**Update After Building New Packages:**
```bash
./update-repo.sh
```

**Test Repository Access:**
```bash
./test-repo-access.sh
```

---

## 🎯 Device-Specific Setup

### Jetson AGX Xavier
```bash
scp device-specific-repos/jetson-agx-xavier.repo nvidia@jetson:/tmp/
```

### Jetson Xavier NX
```bash
scp device-specific-repos/jetson-xavier-nx.repo nvidia@jetson:/tmp/
```

### Jetson Xavier NX with TX2 NX Module
```bash
scp device-specific-repos/jetson-xavier-nx-tx2.repo nvidia@jetson:/tmp/
```

---

## 🌐 Repository URLs

Once your server is running, packages are available at:

```
http://YOUR_SERVER_IP/tegra-repo/
├── noarch/
├── armv8a/
├── armv8a_tegra/
├── armv8a_tegra186/
├── armv8a_tegra194/
├── jetson_agx_xavier_devkit/
├── jetson_xavier_nx_devkit/
└── jetson_xavier_nx_devkit_tx2_nx/
```

---

## ✅ Verify Everything Works

### On Server:
```bash
# Check status
./check-repo-status.sh

# Test local access
curl http://localhost:8080/rpm/noarch/repodata/repomd.xml
```

### On Client (Jetson):
```bash
# List repos
sudo dnf repolist | grep tegra

# Search for packages
sudo dnf search netbase

# Install a test package
sudo dnf install netbase
```

---

## 🔥 Common Issues

**Problem:** `createrepo_c: command not found`
```bash
sudo apt update && sudo apt install -y createrepo-c
```

**Problem:** Client can't connect to repository
```bash
# On server, allow port 80
sudo ufw allow 80/tcp

# Test from client
curl http://SERVER_IP/tegra-repo/noarch/repodata/repomd.xml
```

**Problem:** Packages not found
```bash
# Update repository metadata
./update-repo.sh

# On client
sudo dnf clean all && sudo dnf makecache
```

---

## 📚 Full Documentation

For detailed information, see: **[YUM_REPO_README.md](YUM_REPO_README.md)**

---

## 📁 Files Created

```
tegra-demo-distro/
├── setup-yum-repo.sh              # Main setup script
├── update-repo.sh                 # Update repository metadata
├── start-repo-server.sh           # Simple HTTP server
├── check-repo-status.sh           # Check repository health
├── test-repo-access.sh            # Test repository accessibility
├── QUICKSTART.md                  # This file
├── YUM_REPO_README.md             # Detailed documentation
├── device-specific-repos/         # Device-specific repo files
│   ├── jetson-agx-xavier.repo
│   ├── jetson-xavier-nx.repo
│   └── jetson-xavier-nx-tx2.repo
└── repo-configs/                  # Generated configs (after setup)
    ├── tegra-demo-distro.repo     # All-in-one client config
    ├── nginx-tegra-repo.conf      # Nginx configuration
    └── apache-tegra-repo.conf     # Apache configuration
```

---

**Ready to go? Start with Step 1! 🚀**
