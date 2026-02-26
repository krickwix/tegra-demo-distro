FILESEXTRAPATHS:prepend := "${THISDIR}/linux-tegra:"

SRC_URI += "file://iscsi.cfg"

# Enable iSCSI kernel modules for Longhorn
KERNEL_CONFIG_FRAGMENTS += "file://iscsi.cfg"
