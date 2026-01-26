# Tegra Demo Distro - YUM/DNF Repository Setup

This directory contains scripts and configuration files to set up and manage a YUM/DNF repository for your Tegra RPM packages.

## Quick Start

### 1. Initial Setup

Run the setup script to create repository metadata and generate configuration files:

```bash
./setup-yum-repo.sh
```

This will:
- Install `createrepo_c` if needed
- Generate repository metadata for all package directories
- Create client configuration files
- Generate web server configurations

### 2. Start the Repository Server

**Option A: Simple Test Server (Quick Start)**

```bash
./start-repo-server.sh
```

This starts a Python HTTP server on port 8080. Good for testing and local networks.

**Option B: Production Server (Nginx)**

```bash
# Copy the nginx configuration
sudo cp repo-configs/nginx-tegra-repo.conf /etc/nginx/sites-available/tegra-repo.conf
sudo ln -s /etc/nginx/sites-available/tegra-repo.conf /etc/nginx/sites-enabled/

# Test and reload nginx
sudo nginx -t
sudo systemctl reload nginx
```

**Option C: Production Server (Apache)**

```bash
# Copy the apache configuration
sudo cp repo-configs/apache-tegra-repo.conf /etc/apache2/conf-available/
sudo a2enconf apache-tegra-repo
sudo systemctl reload apache2
```

## Repository Structure

The repository contains packages organized by architecture and device:

```
/media/fandrieu/build/all/tmp/deploy/rpm/
├── armv8a/                          # Base ARMv8a packages
├── armv8a_tegra/                    # Tegra-specific packages
├── armv8a_tegra186/                 # TX2 platform packages
├── armv8a_tegra194/                 # Xavier platform packages
├── jetson_agx_xavier_devkit/        # Jetson AGX Xavier specific
├── jetson_xavier_nx_devkit/         # Jetson Xavier NX specific
├── jetson_xavier_nx_devkit_tx2_nx/  # Xavier NX with TX2 module
└── noarch/                          # Architecture-independent packages
```

## Client Configuration

### All-in-One Configuration

For clients that should have access to all repositories:

```bash
# On the target Jetson device
sudo cp repo-configs/tegra-demo-distro.repo /etc/yum.repos.d/

# Edit the file to replace YOUR_SERVER_IP with your server's IP
sudo nano /etc/yum.repos.d/tegra-demo-distro.repo

# Update repository cache
sudo dnf clean all
sudo dnf makecache
```

### Device-Specific Configuration

For device-specific setups, use the appropriate configuration file:

**Jetson AGX Xavier:**
```bash
sudo cp device-specific-repos/jetson-agx-xavier.repo /etc/yum.repos.d/
```

**Jetson Xavier NX:**
```bash
sudo cp device-specific-repos/jetson-xavier-nx.repo /etc/yum.repos.d/
```

**Jetson Xavier NX with TX2 NX:**
```bash
sudo cp device-specific-repos/jetson-xavier-nx-tx2.repo /etc/yum.repos.d/
```

Remember to edit the repo file and replace `YOUR_SERVER_IP` with your actual server IP address.

## Updating the Repository

After building new packages, update the repository metadata:

```bash
./update-repo.sh
```

This will update the metadata for all package directories. Changes are immediately available to clients.

## Testing the Repository

### On the Server

Check that the repository is accessible:

```bash
# If using simple HTTP server (port 8080)
curl http://localhost:8080/rpm/noarch/repodata/repomd.xml

# If using nginx/apache
curl http://localhost/tegra-repo/noarch/repodata/repomd.xml
```

### On Client Devices

```bash
# List available repositories
sudo dnf repolist

# Search for packages
sudo dnf search alsa

# Install a package
sudo dnf install ca-certificates

# List all available packages from Tegra repos
sudo dnf repository-packages tegra-noarch list available
```

## Repository Priority

The repository configurations use priorities to ensure correct package selection:

- **Priority 5**: Device-specific packages (highest priority)
- **Priority 10**: Architecture and common packages

Lower numbers = higher priority. Device-specific packages will be preferred over generic ones.

## Troubleshooting

### Repository metadata not found

Make sure you've run `./setup-yum-repo.sh` to create the metadata:

```bash
./setup-yum-repo.sh
```

### Web server not serving packages

Check that the web server is running and configured correctly:

```bash
# For nginx
sudo systemctl status nginx
sudo nginx -t

# For apache
sudo systemctl status apache2
sudo apache2ctl configtest
```

### Clients can't connect

1. Check firewall settings on the server:
   ```bash
   sudo ufw allow 80/tcp
   ```

2. Verify the server IP in the client's repo file:
   ```bash
   cat /etc/yum.repos.d/tegra-demo-distro.repo
   ```

3. Test connectivity from client:
   ```bash
   curl http://SERVER_IP/tegra-repo/noarch/repodata/repomd.xml
   ```

### GPG signature checking

Currently, GPG checking is disabled (`gpgcheck=0`) in the repository configurations. To enable GPG signing:

1. Create a GPG key for signing packages
2. Sign all RPM packages with `rpm --addsign`
3. Export the public key and distribute to clients
4. Update repo files to set `gpgcheck=1` and add `gpgkey=` URL

## Security Considerations

- Consider enabling GPG package signing for production deployments
- Use HTTPS instead of HTTP for sensitive environments
- Implement proper firewall rules to restrict access
- Consider using repository authentication if needed

## Repository URLs

The repository will be available at:

- **Base URL**: `http://YOUR_SERVER_IP/tegra-repo/`
- **Architecture packages**: 
  - `http://YOUR_SERVER_IP/tegra-repo/armv8a/`
  - `http://YOUR_SERVER_IP/tegra-repo/armv8a_tegra/`
  - `http://YOUR_SERVER_IP/tegra-repo/armv8a_tegra186/`
  - `http://YOUR_SERVER_IP/tegra-repo/armv8a_tegra194/`
- **Device packages**:
  - `http://YOUR_SERVER_IP/tegra-repo/jetson_agx_xavier_devkit/`
  - `http://YOUR_SERVER_IP/tegra-repo/jetson_xavier_nx_devkit/`
  - `http://YOUR_SERVER_IP/tegra-repo/jetson_xavier_nx_devkit_tx2_nx/`
- **NoArch packages**: `http://YOUR_SERVER_IP/tegra-repo/noarch/`

## Advanced Configuration

### Custom Repository Location

To use a different base directory, edit the variables in `setup-yum-repo.sh`:

```bash
RPM_BASE_DIR="/your/custom/path"
REPO_BASE_DIR="/var/www/html/your-repo"
```

### Adding New Devices

When you add new device-specific package directories:

1. Build the new packages
2. Run `./update-repo.sh` to generate metadata
3. Create a new device-specific repo file in `device-specific-repos/`
4. Distribute to target devices

## Support

For issues or questions about this repository setup, check:

1. Repository metadata exists: `ls -la /media/fandrieu/build/all/tmp/deploy/rpm/*/repodata/`
2. Web server logs: `sudo journalctl -u nginx` or `sudo journalctl -u apache2`
3. Client DNF logs: `sudo dnf --verbose search test`
