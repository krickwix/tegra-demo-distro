# libbsd native install uses /dev/null as assembler input for format.ld generation.
# In this OpenShift pod /dev/null is not a character device.
do_install:prepend() {
    if [ -f "${B}/src/Makefile" ]; then
        : > "${B}/src/empty-assembler.s"
        sed -i "s@-x assembler /dev/null@-x assembler ${B}/src/empty-assembler.s@g" "${B}/src/Makefile"
    fi
}
