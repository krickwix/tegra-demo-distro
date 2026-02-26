FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://iscsi.cfg"

# Enable iSCSI kernel modules for Longhorn
KERNEL_CONFIG_FRAGMENTS += "file://iscsi.cfg"
