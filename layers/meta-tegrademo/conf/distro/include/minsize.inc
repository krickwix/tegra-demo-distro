# Enable size-optimized builds

# Enable link-time optimization
require conf/distro/include/lto.inc
DISTRO_FEATURES:append = " lto"

# Optimize for size and allow garbage collection of unused sections
SELECTED_OPTIMIZATION = "-Os -pipe -fdata-sections -ffunction-sections"
TARGET_LDFLAGS:append = " -Wl,--gc-sections"

# Ensure stripping is enabled for target packages
INHIBIT_PACKAGE_STRIP = "0"
INHIBIT_SYSROOT_STRIP = "0"

# Avoid accidentally pulling debug/source/dev/test packages into images
EXTRA_IMAGE_FEATURES:remove = "dbg-pkgs src-pkgs dev-pkgs ptest-pkgs tools-sdk tools-debug tools-profile tools-testapps eclipse-debug"
