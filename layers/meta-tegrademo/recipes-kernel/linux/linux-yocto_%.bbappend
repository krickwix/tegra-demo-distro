FILESEXTRAPATHS:prepend := "${THISDIR}/linux-tegra:"

SRC_URI += " file://k3s-full.cfg"

# Enable k3s/Longhorn kernel dependencies (netfilter, iSCSI, Ceph)
KERNEL_CONFIG_FRAGMENTS += "file://k3s-full.cfg"
