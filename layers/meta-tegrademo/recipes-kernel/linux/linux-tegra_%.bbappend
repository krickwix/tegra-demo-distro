FILESEXTRAPATHS:prepend := "${THISDIR}/linux-tegra:"

SRC_URI += " file://iscsi.cfg file://k3s-full.cfg"

# Enable iSCSI kernel modules for Longhorn
KERNEL_CONFIG_FRAGMENTS += "file://iscsi.cfg"

# Enable k3s/Longhorn kernel dependencies (netfilter, iSCSI, Ceph)
KERNEL_CONFIG_FRAGMENTS += "file://k3s-full.cfg"
