FILESEXTRAPATHS:prepend := "${THISDIR}/linux-greatbear:"

SRC_URI += "file://kubernetes.scc \
	    "

KERNEL_FEATURES:append = " kubernetes.scc"


