# Installing Packages on k3s Nodes from Tegra Repository

## 🚀 Quick Start

### Step 1: Deploy Repository Configuration to k3s Nodes

```bash
cd /home/fandrieu/Documents/tegra-demo-distro
./deploy-to-k3s-nodes.sh
```

This will:
1. Ask for your k3s node hostnames/IPs
2. Auto-detect each device type (AGX Xavier, Xavier NX, etc.)
3. Deploy the appropriate repository configuration
4. Update the DNF cache on each node
5. Verify connectivity

### Step 2: Install Packages

```bash
# Install a single package on all nodes
./install-packages-k3s.sh ca-certificates

# Install multiple packages
./install-packages-k3s.sh openssh-server netbase alsa-utils

# Upgrade existing packages
./install-packages-k3s.sh <package-name>  # Choose option 3
```

---

## 📋 Manual Installation (Alternative Method)

### On Each k3s Node:

#### 1. Copy Repository Configuration

```bash
# From your build server
scp device-specific-repos/jetson-agx-xavier.repo nvidia@jetson-node:/tmp/

# On the Jetson node
sudo cp /tmp/jetson-agx-xavier.repo /etc/yum.repos.d/
```

#### 2. Update Repository Cache

```bash
sudo dnf clean all
sudo dnf makecache
```

#### 3. Verify Repository

```bash
# List enabled repositories
sudo dnf repolist

# Should show:
# tegra-jetson-agx-xavier
# tegra-armv8a-tegra194
# tegra-armv8a-tegra
# tegra-armv8a
# tegra-noarch
```

#### 4. Test Installation

```bash
# Search for packages
sudo dnf search alsa

# Install a package
sudo dnf install ca-certificates

# List available packages
sudo dnf list available | grep tegra
```

---

## 🔧 Troubleshooting

### Issue: Cannot reach repository server

**Check connectivity:**
```bash
# Test HTTP access
wget http://192.168.0.78:8080/noarch/repodata/repomd.xml

# Test network connectivity
ping 192.168.0.78
```

**Solution:**
- Ensure firewall allows port 8080 on server
- Verify nginx is running: `systemctl status nginx`
- Check if nodes are on the same network

### Issue: "nothing provides" error (Missing Dependencies)

**Example error:**
```
Error: 
 Problem: package iscsi-initiator-utils-2.1.6-r0.armv8a requires open-isns >= 0.101, but none of the providers can be installed
  - nothing provides libisns.so.0()(64bit)
```

**Solution:**

1. **On your build server**, rebuild the missing package:
   ```bash
   cd /media/fandrieu/build
   bitbake open-isns -c package_write_rpm
   ```

2. **Update the repository:**
   ```bash
   cd /home/fandrieu/Documents/tegra-demo-distro
   ./update-repo.sh
   ```

3. **On k3s nodes**, refresh cache:
   ```bash
   sudo dnf clean all && sudo dnf makecache
   ```

4. **Retry installation**

### Issue: Repository not found

**Check repo file:**
```bash
cat /etc/yum.repos.d/jetson-agx-xavier.repo
```

**Verify baseurl points to correct server:**
```
baseurl=http://192.168.0.78:8080/jetson_agx_xavier_devkit
```

**Solution:** Edit the file and correct the server IP/port if needed.

### Issue: GPG signature verification failed

**Solution:** GPG checking is disabled by default. If enabled, verify:
```bash
grep gpgcheck /etc/yum.repos.d/*.repo
```

Should show `gpgcheck=0`. If not, edit the file:
```bash
sudo nano /etc/yum.repos.d/jetson-agx-xavier.repo
# Set: gpgcheck=0
```

---

## 📊 Repository Structure on k3s Nodes

After deployment, your k3s nodes will have access to:

| Repository | Purpose | Priority |
|------------|---------|----------|
| tegra-jetson-agx-xavier | Device-specific packages | 5 (highest) |
| tegra-armv8a-tegra194 | Xavier platform packages | 10 |
| tegra-armv8a-tegra | Common Tegra packages | 10 |
| tegra-armv8a | Base ARM64 packages | 10 |
| tegra-noarch | Architecture-independent | 10 |

**Priority:** Lower number = higher priority. Device-specific packages override generic ones.

---

## 🧪 Testing Your Setup

### Test 1: List All Available Packages

```bash
sudo dnf list available | wc -l
# Should show thousands of packages
```

### Test 2: Search for Specific Packages

```bash
sudo dnf search openssh
sudo dnf search alsa
sudo dnf search kernel
```

### Test 3: Check Package Information

```bash
sudo dnf info ca-certificates
```

### Test 4: Install a Test Package

```bash
sudo dnf install netbase -y
rpm -q netbase
```

### Test 5: View Repository Statistics

```bash
sudo dnf repoinfo tegra-noarch
```

---

## 🔄 Keeping Packages Updated

### Update Individual Packages

```bash
sudo dnf upgrade openssh-server
```

### Update All Packages from Tegra Repos

```bash
sudo dnf upgrade --repo=tegra-*
```

### Check for Available Updates

```bash
sudo dnf check-update
```

---

## 🎯 Common Package Installation Scenarios

### Scenario 1: Install SSH Server on All Nodes

```bash
./install-packages-k3s.sh openssh-server openssh-sshd
```

### Scenario 2: Install iSCSI Tools (after fixing dependencies)

```bash
# First, rebuild open-isns on build server
cd /media/fandrieu/build
bitbake open-isns -c package_write_rpm
cd /home/fandrieu/Documents/tegra-demo-distro
./update-repo.sh

# Then install on k3s nodes
./install-packages-k3s.sh iscsi-initiator-utils open-isns
```

### Scenario 3: Install Development Tools

```bash
./install-packages-k3s.sh gcc binutils make
```

### Scenario 4: Install System Utilities

```bash
./install-packages-k3s.sh htop nano vim wget curl
```

---

## 📝 Best Practices

1. **Always test on one node first** before deploying to all nodes
2. **Check for missing dependencies** before large deployments
3. **Keep repository metadata updated** after building new packages
4. **Monitor disk space** on nodes (packages can be large)
5. **Document installed packages** for each node type
6. **Use version pinning** for critical packages if needed

---

## 🔐 Security Considerations

- Repository currently runs without GPG signature checking
- Consider enabling HTTPS (SSL/TLS) for production
- Restrict repository access by IP if needed
- Keep track of package versions for security updates

---

## 📞 Quick Reference Commands

### On Build Server

```bash
# Update repository after building packages
./update-repo.sh

# Check repository status
./check-repo-status.sh

# Check for missing dependencies
./check-missing-dependencies.sh
```

### On k3s Nodes

```bash
# Refresh repository cache
sudo dnf clean all && sudo dnf makecache

# List repos
sudo dnf repolist

# Search packages
sudo dnf search <keyword>

# Install package
sudo dnf install <package>

# List installed packages from Tegra repos
rpm -qa | grep -E "armv8a|tegra|noarch"
```

---

## 🚨 Known Issues

### Issue: open-isns Missing

**Status:** Identified - RPM not deployed
**Affected:** iscsi-initiator-utils
**Solution:** See `ISNS_QUICK_FIX.txt`

### Issue: GLIBC Version Requirements

Some packages may require glibc >= 2.35. Verify your k3s nodes have compatible versions:
```bash
ldd --version
```

---

For detailed troubleshooting, see:
- `DEPLOYMENT_COMPLETE.md` - Full repository documentation
- `MISSING_DEPENDENCIES_REPORT.txt` - Dependency analysis
- `ISNS_QUICK_FIX.txt` - Fix for iSNS dependencies
