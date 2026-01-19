DESCRIPTION = "Cineworld full-featured image based on demo-image-full (without GUI) with openssh (root login, no password), \
nvidia-docker, CUDA, TensorRT, VPI, and Tegra MMAPI for GPU-accelerated container workloads"

LICENSE = "MIT"

# Use demo-image-common as base (includes ssh, packagegroups, CUDA SDK)
require demo-image-common.inc

# Enable root login with empty password
IMAGE_FEATURES += "empty-root-password allow-root-login"

# Add packages from demo-image-full (excluding X11/graphical components)
CORE_IMAGE_BASE_INSTALL += "libvisionworks-devso-symlink nvidia-docker cuda-libraries"
CORE_IMAGE_BASE_INSTALL += "tegra-mmapi-tests vpi1-tests tensorrt-tests"
CORE_IMAGE_BASE_INSTALL += "${@bb.utils.contains('DISTRO_FEATURES', 'vulkan', 'packagegroup-demo-vulkantests', '', d)}"

# Add utility packages for cluster management and certificate handling
IMAGE_INSTALL:append = " curl wget ca-certificates "

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
