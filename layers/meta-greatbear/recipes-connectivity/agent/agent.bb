SUMMARY = "GreatBear install agent"
DESCRIPTION = "GreatBear install agent"
LICENSE = "MIT"
INSANE_SKIP:${PN} += " already-stripped"

do_install() {
  install -d ${D}${bindir}
  install -m 0755 ${THISDIR}/files/agent ${D}${bindir}/agent
  install -m 0755 ${THISDIR}/files/agent-start.sh ${D}${bindir}/agent-start.sh
  install -d ${D}/etc/systemd/system/multi-user.target.wants
  install ${THISDIR}/files/agent.service ${D}/etc/systemd/system/agent.service
  ln -s ../agent.service ${D}/etc/systemd/system/multi-user.target.wants/agent.service
}