SUMMARY = "HAProxy support"
HOMEPAGE = "http://www.haproxy.org/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=2d862e836f92129cdc0ecccc54eed5e0"

SRC_URI = "http://www.haproxy.org/download/2.6/src/haproxy-${PV}.tar.gz"
SRC_URI[sha256sum] = "915b351e6450d183342c4cdcda7771eac4f0f72bf90582adcd15a01c700d29b1"
EXTRA_OEMAKE = "V=1 CC=${TARGET_PREFIX}gcc CXX=${TARGET_PREFIX}g++ TARGET=linux-glibc"
inherit systemd pkgconfig
PACKAGES =+ "haproxy"
#BBCLASSEXTEND = "native"
do_install() {
    oe_runmake DESTDIR=${D} install
}
do_compile() {
    export CFLAGS="${TOOLCHAIN_OPTIONS}"
    export CXXFLAGS="${TOOLCHAIN_OPTIONS}"
    make V=1 CC=${TARGET_PREFIX}gcc CXX=${TARGET_PREFIX}g++ TARGET=linux-glibc
}
