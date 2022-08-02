DESCRIPTION = "GBEOS minimal image"
DISTRO = "gbeos"
DISTRO_NAME = "OE4Tegra gbeos Distro"
DISTRO_VERSION_BASE = "4.0"
DISTRO_VERSION = "${DISTRO_VERSION_BASE}+snapshot-${DATE}"
DISTRO_CODENAME = "master"
SDK_VENDOR = "-tdsdk"
SDK_VERSION := "${@'${DISTRO_VERSION}'.replace('snapshot-${DATE}','snapshot')}"

MAINTAINER = "OE4Tegra team <oe4tegra@madison.systems>"

TARGET_VENDOR = "-oe4t"

# New ${DISTRO}-<version> setting for sanity checks.
# Increment version number (and the corresponding
# setting int the template bblayers.conf.sample file)
# each time the layer settings are changed.
REQUIRED_TD_BBLAYERS_CONF_VERSION = "${DISTRO}-4"

LOCALCONF_VERSION = "2"

DISTRO_VERSION[vardepsexclude] = "DATE"
SDK_VERSION[vardepsexclude] = "DATE"

TD_DEFAULT_DISTRO_FEATURES = "largefile opengl ptest multiarch wayland vulkan systemd pam virtualization"

DISTRO_FEATURES ?= "${DISTRO_FEATURES_DEFAULT} ${TD_DEFAULT_DISTRO_FEATURES}"

# Jetson platforms do not use linux-yocto, but for QEMU testing
# align with the poky distro.
PREFERRED_VERSION_linux-yocto ?= "5.15%"
PREFERRED_VERSION_linux-yocto-rt ?= "5.15%"

# Gstreamer libraries are passed through to containers when using
# nvidia-docker, so our version of Gstreamer must match the one in
# the stock L4T/JetPack release.
require conf/include/gstreamer-1.14.conf

SDK_NAME = "${DISTRO}-${TCLIBC}-${SDKMACHINE}-${IMAGE_BASENAME}-${TUNE_PKGARCH}-${MACHINE}"
SDKPATH = "/opt/${DISTRO}/${SDK_VERSION}"

TCLIBCAPPEND = ""

PREMIRRORS ??= "\
bzr://.*/.*   http://downloads.yoctoproject.org/mirror/sources/ \
cvs://.*/.*   http://downloads.yoctoproject.org/mirror/sources/ \
git://.*/.*   http://downloads.yoctoproject.org/mirror/sources/ \
gitsm://.*/.* http://downloads.yoctoproject.org/mirror/sources/ \
hg://.*/.*    http://downloads.yoctoproject.org/mirror/sources/ \
osc://.*/.*   http://downloads.yoctoproject.org/mirror/sources/ \
p4://.*/.*    http://downloads.yoctoproject.org/mirror/sources/ \
svn://.*/.*   http://downloads.yoctoproject.org/mirror/sources/"

SANITY_TESTED_DISTROS ?= " \
            ubuntu-18.04 \n \
            ubuntu-20.04 \n \
            ubuntu-21.10 \n \
            ubuntu-22.04 \n \
            "

# CUDA 10.2 requires gcc 8
CUDA_GCCVERSION = "8.%"

# Most NVIDIA-supplied services expect systemd
INIT_MANAGER = "systemd"

INHERIT += "tegra-support-sanity"
ESDK_CLASS_INHERIT_DISABLE:append = " tegra-support-sanity"

require conf/distro/include/no-static-libs.inc
require conf/distro/include/yocto-uninative.inc
require conf/distro/include/security_flags.inc
INHERIT += "uninative"

BB_SIGNATURE_HANDLER ?= "OEEquivHash"
BB_HASHSERVE ??= "auto"

LICENSE_FLAGS_ACCEPTED += "commercial_faad2"

PREFERRED_PROVIDER_virtual/bootlogo:tegra = "bootlogo-custom"

IMAGE_FEATURES:append = " splash ssh-server-openssh package-management"
IMAGE_FEATURES:append = " debug-tweaks empty-root-password allow-empty-password allow-root-login post-install-logging"
# IMAGE_FEATURES:append = " splash x11-base x11-sato hwcodecs "
IMAGE_FEATURES:append = " splash x11-base hwcodecs "
IMAGE_INSTALL = "\
    packagegroup-core-boot \
    packagegroup-core-full-cmdline \
    packagegroup-core-ssh-openssh \
    tzdata python3-pip perl-misc \
    bash parted curl k3s \
    linux-firmware kernel-modules \
    python3-ansible \
    python3-distutils python3-distutils-extra \
    keepalived dpkg \
    ${CORE_IMAGE_EXTRA_INSTALL} \
    "
IMAGE_INSTALL:append = " packagegroup-demo-base packagegroup-demo-basetests packagegroup-demo-x11tests packagegroup-demo-vulkantests"
IMAGE_INSTALL:append = " packagegroup-demo-systemd "
IMAGE_INSTALL:append = " libvisionworks-devso-symlink nvidia-docker cuda-libraries tegra-mmapi-tests vpi1-tests "
IMAGE_INSTALL:append = " nvidia-docker cudnn  libvisionworks libvisionworks-sfm libvisionworks-tracking cuda-libraries cuda-toolkit"
# IMAGE_INSTALL:append = " tensorrt tensorrt-tests "
IMAGE_INSTALL:append = " cuda-toolkit cuda-command-line-tools cuda-samples cuda-shared-binaries libnvvpi1"
IMAGE_INSTALL:append = " cuda-toolkit cuda-command-line-tools cuda-samples libnvvpi1"
IMAGE_INSTALL:append = " k3s kernel-modules curl dpkg iscsi-initiator-utils python3-ansible "
TOOLCHAIN_HOST_TASK += "nativesdk-packagegroup-cuda-sdk-host"

# inherit features_check core-image setuptools3
inherit core-image setuptools3

fakeroot do_mklinks_lib () {
	cd ${IMAGE_ROOTFS}
	ln -s lib lib64
    rm -f ${IMAGE_ROOTFS}/etc/systemd/system/xserver-nodm.service
    rm -f ${IMAGE_ROOTFS}/etc/systemd/system/display-manager.service
    rm -f ${IMAGE_ROOTFS}/etc/systemd/system/docker.service
}

IMAGE_PREPROCESS_COMMAND += "do_mklinks_lib; "
