# open-iscsi Support for Cineworld Image

## Overview

This directory contains a bbappend that adds `open-iscsi` support to the cineworld image by providing an alternative package name for the `iscsi-initiator-utils` recipe from meta-openembedded/meta-networking.

## Implementation Details

### Recipe Source
The `iscsi-initiator-utils` recipe in meta-openembedded uses the official open-iscsi repository:
- **Repository**: `git://github.com/open-iscsi/open-iscsi.git`
- **Branch**: master
- **Protocol**: https

### Package Naming
The upstream recipe is named `iscsi-initiator-utils`, but the common reference name is `open-iscsi`. This bbappend adds:
```
RPROVIDES:${PN} += "open-iscsi"
```

This allows the cineworld-image to reference the package as `open-iscsi` in `IMAGE_INSTALL` while using the existing recipe from meta-openembedded.

### Dependencies
The iscsi-initiator-utils recipe requires:
- openssl
- flex-native
- bison-native
- open-isns (also from meta-openembedded)
- util-linux
- kmod
- systemd (if systemd is enabled in DISTRO_FEATURES)

### Layer Requirements
- **meta-networking** must be included in `bblayers.conf` (already configured)
- **meta-oe** must be included in `bblayers.conf` (already configured)

### Services Provided
When systemd is enabled, the recipe installs:
- `iscsi-initiator.service`
- `iscsi-initiator-targets.service`

### Tools Installed
- `iscsid` - iSCSI daemon
- `iscsiadm` - iSCSI administration utility
- `iscsi-iname` - iSCSI name generator
- `iscsistart` - iSCSI initiator startup utility
- `libopeniscsiusr.so.*` - iSCSI user library

## Usage in Images

In your image recipe (e.g., `cineworld-image.bb`), you can now use:
```bitbake
IMAGE_INSTALL:append = " open-iscsi "
```

## Kernel Module Requirements

The iSCSI functionality also requires kernel modules, which may be built-in or loadable. The cineworld-image.bb has commented examples for loading iSCSI kernel modules if needed:
- `kernel-module-iscsi-tcp`
- `kernel-module-libiscsi`
- `kernel-module-libiscsi-tcp`
- `kernel-module-scsi-transport-iscsi`
- `kernel-module-iscsi-boot-sysfs`

## Verification

To verify the setup:
```bash
# Check that the bbappend is recognized
bitbake-layers show-appends | grep iscsi-initiator-utils

# Verify RPROVIDES includes open-iscsi
bitbake iscsi-initiator-utils -e | grep "^RPROVIDES"

# Verify source repository
bitbake iscsi-initiator-utils -e | grep "^SRC_URI"

# Test image build (dry run)
bitbake cineworld-image --dry-run
```

## References
- [Open-iSCSI Project](https://github.com/open-iscsi/open-iscsi)
- [Open-iSCSI Documentation](http://www.open-iscsi.com/)
