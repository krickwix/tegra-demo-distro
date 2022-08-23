IMAGE_FEATURES += "ssh-server-openssh"

LICENSE = "MIT"

LICENSE_FLAGS_ACCEPTED += "commercial"

inherit core-image

CORE_IMAGE_BASE_INSTALL += "packagegroup-demo-base packagegroup-demo-basetests"
CORE_IMAGE_BASE_INSTALL += "${@'packagegroup-demo-systemd' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'systemd' else ''}"
TOOLCHAIN_HOST_TASK += "nativesdk-packagegroup-cuda-sdk-host"

inherit nopackages

IMAGE_FEATURES += "splash"

inherit features_check

#REQUIRED_DISTRO_FEATURES = "x11 opengl virtualization systemd"
REQUIRED_DISTRO_FEATURES = "virtualization systemd"

#CORE_IMAGE_BASE_INSTALL += "packagegroup-demo-x11tests"
#CORE_IMAGE_BASE_INSTALL += "${@bb.utils.contains('DISTRO_FEATURES', 'vulkan', 'packagegroup-demo-vulkantests', '', d)}"
#CORE_IMAGE_BASE_INSTALL += "libvisionworks-devso-symlink tegra-mmapi-tests vpi1-tests tensorrt-tests"
CORE_IMAGE_BASE_INSTALL += "nvidia-docker cuda-libraries cudnn cuda-toolkit cuda-nvml nvidia-container-toolkit"

IMAGE_INSTALL:append = " tzdata python3-pip perl-misc \
    bash parted curl \
    linux-firmware kernel-modules \
    python3-ansible \
    python3-distutils python3-distutils-extra \
    keepalived dpkg \
    iscsi-initiator-utils tgt \
    agent \
"
MACHINE_HWCODECS = ""