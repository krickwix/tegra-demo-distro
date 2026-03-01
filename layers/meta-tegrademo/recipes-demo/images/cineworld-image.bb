DESCRIPTION = "Cineworld full-featured image based on demo-image-full (without GUI) with openssh (root login, no password), \
nvidia-docker, CUDA, TensorRT, VPI, and Tegra MMAPI for GPU-accelerated container workloads"

LICENSE = "MIT"

# Use demo-image-common as base (includes ssh, packagegroups, CUDA SDK)
require demo-image-common.inc

# Enable root login with empty password and package management
IMAGE_FEATURES += "empty-root-password allow-root-login package-management"

# Add packages from demo-image-full (excluding X11/graphical components)
CORE_IMAGE_BASE_INSTALL += "nvidia-docker cuda-libraries"
# CORE_IMAGE_BASE_INSTALL += "tegra-mmapi-tests vpi1-tests tensorrt-tests"
CORE_IMAGE_BASE_INSTALL += "${@bb.utils.contains('DISTRO_FEATURES', 'vulkan', 'packagegroup-demo-vulkantests', '', d)}"

# Add utility packages for cluster management and certificate handling
IMAGE_INSTALL:append = " curl wget ca-certificates "

# Add iSCSI and SCSI management tools
IMAGE_INSTALL:append = " iscsi-initiator-utils sg3-utils lsscsi "

# Add NFS client support
IMAGE_INSTALL:append = " nfs-utils nfs-utils-client rpcbind "

# Install userspace dependencies used by k3s/container networking.
# k3s itself is intentionally not included in this image.
IMAGE_INSTALL:append = " \
    conntrack-tools \
    iptables \
    iproute2 \
    ethtool \
    socat \
    ebtables \
    nftables \
"

# Include all built kernel modules so k3s/Longhorn dependencies are present
IMAGE_INSTALL:append = " kernel-modules "

# Add kernel modules for storage/networking when they are available as loadable modules.
# On some machines these features are built into the kernel, so make them best-effort.
PACKAGE_INSTALL_ATTEMPTONLY:append = " \
    kernel-module-iscsi-tcp \
    kernel-module-libiscsi \
    kernel-module-libiscsi-tcp \
    kernel-module-scsi-transport-iscsi \
    kernel-module-iscsi-boot-sysfs \
    kernel-module-xt-conntrack \
    kernel-module-xt-mark \
    kernel-module-xt-nat \
    kernel-module-xt-addrtype \
    kernel-module-xt-multiport \
    kernel-module-xt-comment \
    kernel-module-xt-recent \
    kernel-module-xt-statistic \
    kernel-module-nf-conntrack \
    kernel-module-nf-nat \
    kernel-module-ip-tables \
    kernel-module-iptable-filter \
    kernel-module-iptable-nat \
    kernel-module-iptable-mangle \
    kernel-module-ipt-reject \
    kernel-module-ipt-masquerade \
    kernel-module-ip6-tables \
    kernel-module-ip6table-filter \
    kernel-module-ip6table-nat \
    kernel-module-nf-conntrack-netlink \
    kernel-module-br-netfilter \
    kernel-module-ip-vs \
    kernel-module-ip-vs-rr \
    kernel-module-ip-vs-wrr \
    kernel-module-ip-vs-sh \
    kernel-module-veth \
    kernel-module-overlay \
    kernel-module-ceph \
    kernel-module-libceph \
    kernel-module-rbd \
"

# Ensure this image boots without a graphical login/session target
SYSTEMD_DEFAULT_TARGET = "multi-user.target"

# Check for required distro features
inherit features_check
REQUIRED_DISTRO_FEATURES = "virtualization"

# Disable docker service by default - will be configured at cluster build time
disable_docker_service() {
    if [ -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/system ]; then
        # Disable docker service at boot time
        rm -f ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/multi-user.target.wants/docker.service
        rm -f ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/sockets.target.wants/docker.socket
    fi
}

ROOTFS_POSTPROCESS_COMMAND += "disable_docker_service; "

# Ensure netfilter modules/chains exist before k3s/klipper-lb use iptables-nft.
install_k3s_netfilter_bootstrap() {
    install -d ${IMAGE_ROOTFS}${sysconfdir}/modules-load.d
    cat > ${IMAGE_ROOTFS}${sysconfdir}/modules-load.d/k3s-netfilter.conf << 'EOF'
br_netfilter
nf_tables
nft_compat
nf_nat
nf_conntrack
ip_tables
iptable_filter
iptable_nat
EOF

    install -d ${IMAGE_ROOTFS}${sbindir}
    cat > ${IMAGE_ROOTFS}${sbindir}/k3s-netfilter-init.sh << 'EOF'
#!/bin/sh
set -eu

for m in br_netfilter nf_tables nft_compat nf_nat nf_conntrack ip_tables iptable_filter iptable_nat; do
    modprobe "$m" 2>/dev/null || true
done

if command -v nft >/dev/null 2>&1; then
    nft list table ip filter >/dev/null 2>&1 || nft add table ip filter
    nft list chain ip filter INPUT >/dev/null 2>&1 || nft 'add chain ip filter INPUT { type filter hook input priority 0 ; policy accept ; }'
    nft list chain ip filter FORWARD >/dev/null 2>&1 || nft 'add chain ip filter FORWARD { type filter hook forward priority 0 ; policy accept ; }'
    nft list chain ip filter OUTPUT >/dev/null 2>&1 || nft 'add chain ip filter OUTPUT { type filter hook output priority 0 ; policy accept ; }'
    nft list table ip nat >/dev/null 2>&1 || nft add table ip nat
    nft list chain ip nat PREROUTING >/dev/null 2>&1 || nft 'add chain ip nat PREROUTING { type nat hook prerouting priority -100 ; policy accept ; }'
    nft list chain ip nat OUTPUT >/dev/null 2>&1 || nft 'add chain ip nat OUTPUT { type nat hook output priority -100 ; policy accept ; }'
    nft list chain ip nat POSTROUTING >/dev/null 2>&1 || nft 'add chain ip nat POSTROUTING { type nat hook postrouting priority 100 ; policy accept ; }'
fi
EOF
    chmod 0755 ${IMAGE_ROOTFS}${sbindir}/k3s-netfilter-init.sh

    install -d ${IMAGE_ROOTFS}${systemd_system_unitdir}
    cat > ${IMAGE_ROOTFS}${systemd_system_unitdir}/k3s-netfilter-init.service << 'EOF'
[Unit]
Description=Initialize netfilter modules and nft base chains for k3s
DefaultDependencies=no
After=systemd-modules-load.service local-fs.target
Before=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/k3s-netfilter-init.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    install -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_system_unitdir}/k3s-netfilter-init.service \
        ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/multi-user.target.wants/k3s-netfilter-init.service
}

ROOTFS_POSTPROCESS_COMMAND += "install_k3s_netfilter_bootstrap; "

inherit nopackages
