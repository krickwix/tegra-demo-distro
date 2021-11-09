DESCRIPTION = "Packagegroup for inclusion in all Tegra demo images"

LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    haveged \
    procps \
    sshfs-fuse \
    strace \
    tegra-tools-tegrastats \
    kernel-modules \
    linux-firmware \
    parted \
    e2fsprogs \
    e2fsprogs-resize2fs \
    rpm \
    python3-venv \
"
