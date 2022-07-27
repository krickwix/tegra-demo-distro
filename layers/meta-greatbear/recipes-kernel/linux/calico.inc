FILESEXTRAPATHS:prepend := "${THISDIR}/linux-greatbear:"

SRC_URI += "file://ip_set.scc \
            file://nftables.scc \
	    "

KERNEL_FEATURES:append = " ip_set.scc"
KERNEL_FEATURES:append = " nftables.scc"


