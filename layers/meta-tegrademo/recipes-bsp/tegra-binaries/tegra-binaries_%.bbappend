FILESEXTRAPATHS:prepend := "${THISDIR}/tegra-binaries:"

SRC_URI:append = " \
    file://tegra234-mb1-bct-gpio-p3767-hdmi-a03.dtsi \
    file://tegra234-mb1-bct-padvoltage-p3767-hdmi-a03.dtsi \
    file://tegra234-mb1-bct-pinmux-p3767-hdmi-a03.dtsi \
    file://tegra234-mb2-bct-misc-p3767-0000.dts \
    file://tegra234-mb2-bct-scr-p3767-0000.dts \
"

do_preconfigure:append() {
    # EAI-I131 carrier custom MB1/MB2 BCT data from Lanner package.
    install -m 0644 ${WORKDIR}/tegra234-mb1-bct-gpio-p3767-hdmi-a03.dtsi ${S}/bootloader/
    install -m 0644 ${WORKDIR}/tegra234-mb1-bct-pinmux-p3767-hdmi-a03.dtsi ${S}/bootloader/
    install -m 0644 ${WORKDIR}/tegra234-mb1-bct-padvoltage-p3767-hdmi-a03.dtsi ${S}/bootloader/
    install -m 0644 ${WORKDIR}/tegra234-mb1-bct-pinmux-p3767-hdmi-a03.dtsi ${S}/bootloader/t186ref/BCT/
    install -m 0644 ${WORKDIR}/tegra234-mb1-bct-padvoltage-p3767-hdmi-a03.dtsi ${S}/bootloader/t186ref/BCT/
    install -m 0644 ${WORKDIR}/tegra234-mb2-bct-misc-p3767-0000.dts ${S}/bootloader/t186ref/BCT/
    install -m 0644 ${WORKDIR}/tegra234-mb2-bct-scr-p3767-0000.dts ${S}/bootloader/t186ref/BCT/
}
