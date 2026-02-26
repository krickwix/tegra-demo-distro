# Work around broken /dev/null in the OpenShift build pod.
# Preseed M4 cache probes and use an explicit empty file for configure tests.
do_configure:prepend() {
    local emptyfile="${B}/config-empty-input"

    : > "${emptyfile}"

    export ac_cv_path_M4="${RECIPE_SYSROOT_NATIVE}${bindir_native}/m4"
    export ac_cv_prog_gnu_m4_gnu="yes"
    export ac_cv_prog_gnu_m4_debugfile="--debugfile"

    if [ -f "${S}/configure" ]; then
        sed -i "s@</dev/null@<${emptyfile}@g" "${S}/configure"
        sed -i "s@< /dev/null@< ${emptyfile}@g" "${S}/configure"
    fi
}
