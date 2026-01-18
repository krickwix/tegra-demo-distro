DESCRIPTION = "Cineworld minimal image with openssh (root login, no password), nvidia-docker, and CUDA features"

LICENSE = "MIT"

# Enable SSH server with root login and empty password
IMAGE_FEATURES += "ssh-server-openssh empty-root-password allow-root-login"

# Inherit core-image for minimal base
inherit core-image

# Add nvidia-docker, CUDA libraries, and related features
CORE_IMAGE_BASE_INSTALL += "nvidia-docker cuda-libraries"

# Add CUDA SDK host tools to the SDK
TOOLCHAIN_HOST_TASK += "nativesdk-packagegroup-cuda-sdk-host"

# Check for required distro features
inherit features_check
REQUIRED_DISTRO_FEATURES = "virtualization"

inherit nopackages
