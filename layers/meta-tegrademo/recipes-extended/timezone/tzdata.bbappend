# OpenShift pod workaround: avoid /dev/null as leap-seconds file for zic.
do_compile() {
    oe_runmake -C ${S} tzdata.zi
    : > ${WORKDIR}/empty-leapseconds
    for zone in ${TZONES}; do
        ${STAGING_BINDIR_NATIVE}/zic -b ${ZIC_FMT} -d ${B}/zoneinfo -L ${WORKDIR}/empty-leapseconds ${S}/${zone}
        ${STAGING_BINDIR_NATIVE}/zic -b ${ZIC_FMT} -d ${B}/zoneinfo/posix -L ${WORKDIR}/empty-leapseconds ${S}/${zone}
        ${STAGING_BINDIR_NATIVE}/zic -b ${ZIC_FMT} -d ${B}/zoneinfo/right -L ${S}/leapseconds ${S}/${zone}
    done
}
