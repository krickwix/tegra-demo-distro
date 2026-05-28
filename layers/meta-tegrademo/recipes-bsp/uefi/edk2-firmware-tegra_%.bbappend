FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# EAI R36 reaches BOOTAA64.EFI from the NVMe ESP, but L4TLauncher exits
# before extlinux when the platform resource HOB is absent. Let it continue
# as a normal cold boot so it can load Image/initrd from the visible boot FS.
do_configure:prepend() {
    perl -0pi -e 's/return EFI_NOT_FOUND;(\r?\n)  \}(\r?\n\r?\n  BootModeInfo->BootType = PlatformResourceInfo->BootType;)/BootModeInfo->BootType = TegrablBootColdBoot;$1    BootModeInfo->RcmBootOsInfo.Base = 0;$1    BootModeInfo->RcmBootOsInfo.Size = 0;$1    return EFI_SUCCESS;$1  }$2/' \
        ${S_EDK2_NVIDIA}/Silicon/NVIDIA/Drivers/L4TLauncherSupportDxe/L4TLauncherSupportDxe.c
}
