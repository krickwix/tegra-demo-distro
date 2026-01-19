DESCRIPTION = "Cineworld full-featured image based on demo-image-full (without GUI) with openssh (root login, no password), \
nvidia-docker, CUDA, TensorRT, VPI, Tegra MMAPI, and k3s for Kubernetes orchestration"

LICENSE = "MIT"

# Use demo-image-common as base (includes ssh, packagegroups, CUDA SDK)
require demo-image-common.inc

# Enable root login with empty password
IMAGE_FEATURES += "empty-root-password allow-root-login"

# Add packages from demo-image-full (excluding X11/graphical components)
CORE_IMAGE_BASE_INSTALL += "libvisionworks-devso-symlink nvidia-docker cuda-libraries"
CORE_IMAGE_BASE_INSTALL += "tegra-mmapi-tests vpi1-tests tensorrt-tests"
CORE_IMAGE_BASE_INSTALL += "${@bb.utils.contains('DISTRO_FEATURES', 'vulkan', 'packagegroup-demo-vulkantests', '', d)}"

# Add k3s for Kubernetes orchestration
CORE_IMAGE_BASE_INSTALL += "k3s-server k3s-agent"

# Add utility packages for cluster management and certificate handling
IMAGE_INSTALL:append = " curl wget ca-certificates "

# Check for required distro features (k3s requires seccomp)
inherit features_check
REQUIRED_DISTRO_FEATURES = "virtualization seccomp"

# Disable k3s services by default - will be configured at cluster build time
disable_k3s_services() {
    if [ -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/system ]; then
        # Mask k3s services to prevent them from starting
        rm -f ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/multi-user.target.wants/k3s.service
        rm -f ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/multi-user.target.wants/k3s-agent.service
    fi
}

ROOTFS_POSTPROCESS_COMMAND += "disable_k3s_services; "

inherit nopackages
