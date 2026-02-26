DESCRIPTION = "Cineworld full-featured image based on demo-image-full (without GUI) with openssh (root login, no password), \
nvidia-docker, CUDA, TensorRT, VPI, and Tegra MMAPI for GPU-accelerated container workloads"

LICENSE = "MIT"

# Use demo-image-common as base (includes ssh, packagegroups, CUDA SDK)
require demo-image-common.inc

# Enable root login with empty password and package management
IMAGE_FEATURES += "empty-root-password allow-root-login package-management"

# Add packages from demo-image-full (excluding X11/graphical components)
CORE_IMAGE_BASE_INSTALL += "libvisionworks-devso-symlink nvidia-docker cuda-libraries"
# CORE_IMAGE_BASE_INSTALL += "tegra-mmapi-tests vpi1-tests tensorrt-tests"
CORE_IMAGE_BASE_INSTALL += "${@bb.utils.contains('DISTRO_FEATURES', 'vulkan', 'packagegroup-demo-vulkantests', '', d)}"

# Add utility packages for cluster management and certificate handling
IMAGE_INSTALL:append = " curl wget ca-certificates "

# Add iSCSI and SCSI management tools (open-iscsi requires meta-openembedded layer)
IMAGE_INSTALL:append = " open-iscsi sg3-utils lsscsi "

# Add NFS client support
IMAGE_INSTALL:append = " nfs-utils nfs-utils-client rpcbind "
# Note: NFS kernel modules may be built-in to the kernel rather than loadable modules
# IMAGE_INSTALL:append = " \
#     kernel-module-nfs \
#     kernel-module-nfsv3 \
#     kernel-module-nfsv4 \
#     kernel-module-nfsd \
#     kernel-module-lockd \
#     kernel-module-rpcsec-gss-krb5 \
# "

# Add iSCSI support for Longhorn distributed block storage
# Note: iSCSI kernel modules may be built-in to the kernel rather than loadable modules
IMAGE_INSTALL:append = " \
    kernel-module-iscsi-tcp \
    kernel-module-libiscsi \
    kernel-module-libiscsi-tcp \
    kernel-module-scsi-transport-iscsi \
    kernel-module-iscsi-boot-sysfs \
"

# Add Ceph RBD support for Rook-Ceph storage
# Note: Ceph kernel modules may be built-in to the kernel rather than loadable modules
# IMAGE_INSTALL:append = " \
#     kernel-module-rbd \
#     kernel-module-libceph \
#     kernel-module-ceph \
# "

# Add iptables/netfilter kernel modules for Kubernetes/k3s networking
IMAGE_INSTALL:append = " \
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
"

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

inherit nopackages
