#!/bin/bash

check() {
    # Included by default.
    return 0
}

depends() {
    echo rootfs-block
}

installkernel() {
    instmods squashfs overlay loop iso9660
}

install() {
    inst umount
    inst losetup # used to mount the squashfs image

    # must be executed *after* rootfs-block cmdline hook
    inst_hook cmdline 99 "$moddir/overlay-parse.sh"

    inst_hook pre-udev 30 "$moddir/overlay-genrules.sh"
    inst "$moddir/overlay-root.sh" "/sbin/overlay-root"
    # should probably just be generally included
    inst_rules 60-cdrom_id.rules

    inst_script "$moddir/overlay-generator.sh" $systemdutildir/system-generators/dracut-overlay-generator

    dracut_need_initqueue
}
