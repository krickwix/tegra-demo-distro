DESCRIPTION = "GBEOS minimal image"

IMAGE_FEATURES:append = " splash ssh-server-openssh package-management"
IMAGE_FEATURES:append = " debug-tweaks empty-root-password allow-empty-password allow-root-login post-install-logging"
IMAGE_FEATURES:append = " splash x11-base x11-sato hwcodecs "
IMAGE_INSTALL = "\
    packagegroup-core-boot \
    packagegroup-core-full-cmdline \
    packagegroup-core-ssh-openssh \
    tzdata python3-pip perl-misc \
    bash parted curl k3s \
    linux-firmware kernel-modules \
    python3-ansible \
    python3-distutils python3-distutils-extra \
    haproxy \
    ${CORE_IMAGE_EXTRA_INSTALL} \
    "
IMAGE_INSTALL:append = " packagegroup-demo-base packagegroup-demo-basetests packagegroup-demo-x11tests packagegroup-demo-vulkantests"
IMAGE_INSTALL:append = " packagegroup-demo-systemd "
IMAGE_INSTALL:append = " libvisionworks-devso-symlink nvidia-docker cuda-libraries tegra-mmapi-tests vpi1-tests "
IMAGE_INSTALL:append = " nvidia-docker cudnn  libvisionworks libvisionworks-sfm libvisionworks-tracking cuda-libraries cuda-toolkit"
# IMAGE_INSTALL:append = " tensorrt tensorrt-tests "
# IMAGE_INSTALL:append = " cuda-toolkit cuda-command-line-tools cuda-samples cuda-shared-binaries libnvvpi1"
TOOLCHAIN_HOST_TASK += "nativesdk-packagegroup-cuda-sdk-host"

inherit features_check core-image setuptools3

fakeroot do_mklinks_lib () {
	cd ${IMAGE_ROOTFS}
	ln -s lib lib64
    rm -f ${IMAGE_ROOTFS}/etc/systemd/system/xserver-nodm.service
    rm -f ${IMAGE_ROOTFS}/etc/systemd/system/display-manager.service
    rm -f ${IMAGE_ROOTFS}/etc/systemd/system/docker.service
}

IMAGE_PREPROCESS_COMMAND += "do_mklinks_lib; "
