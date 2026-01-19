DESCRIPTION = "Cineworld minimal image with openssh (root login, no password), nvidia-docker, CUDA, and k3s features"

LICENSE = "MIT"

# Enable SSH server with root login and empty password
IMAGE_FEATURES += "ssh-server-openssh empty-root-password allow-root-login"

# Inherit core-image for minimal base
inherit core-image

# Add nvidia-docker, CUDA libraries, k3s, and related features
CORE_IMAGE_BASE_INSTALL += "nvidia-docker cuda-libraries"
CORE_IMAGE_BASE_INSTALL += "k3s-server k3s-agent"

# Add utility packages for cluster management and certificate handling
IMAGE_INSTALL:append = " curl wget ca-certificates "

# Add CUDA SDK host tools to the SDK
TOOLCHAIN_HOST_TASK += "nativesdk-packagegroup-cuda-sdk-host"

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
