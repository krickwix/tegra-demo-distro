# OpenShift pod workaround: /dev/null is not a character device here.
# GCC selftest rules use /dev/null as both input and output, which fails.

gcc_cross_patch_selftest_devnull() {
    gcc_mk="${B}/gcc/Makefile"

    if [ ! -f "${gcc_mk}" ]; then
        bbwarn "Skipping selftest /dev/null patch: ${gcc_mk} not found"
        return 0
    fi

    : > "${B}/gcc/selftest-devnull.in"
    : > "${B}/gcc/selftest-devnull.out"

    sed -i -e "s#^SELFTEST_FLAGS = -nostdinc .*#SELFTEST_FLAGS = -nostdinc ${B}/gcc/selftest-devnull.in -S -o ${B}/gcc/selftest-devnull.out \\\\#" "${gcc_mk}"
}

remove_sysroot_paths_from_configargs:append() {
    gcc_cross_patch_selftest_devnull
}
