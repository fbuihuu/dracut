#!/bin/bash

[ -z "$root" ] && root=$(getarg root=)

# does the user asking us to setup an overlay ?
getargbool 0 rd.overlay || return

case "$root" in
    block:LABEL=*|LABEL=*)
        root="${root#block:}"
        root="$(echo $root | sed 's,/,\\x2f,g')"
        root="block:/dev/disk/by-label/${root#LABEL=}"
        rootok=1 ;;
    block:UUID=*|UUID=*)
        root="${root#block:}"
        root="${root#UUID=}"
        root="$(echo $root | tr "[:upper:]" "[:lower:]")"
        root="block:/dev/disk/by-uuid/${root#UUID=}"
        rootok=1 ;;
    block:PARTUUID=*|PARTUUID=*)
        root="${root#block:}"
        root="${root#PARTUUID=}"
        root="$(echo $root | tr "[:upper:]" "[:lower:]")"
        root="block:/dev/disk/by-partuuid/${root}"
        rootok=1 ;;
    block:PARTLABEL=*|PARTLABEL=*)
        root="${root#block:}"
        root="block:/dev/disk/by-partlabel/${root#PARTLABEL=}"
        rootok=1 ;;
    /dev/*)
        root="block:${root}"
        rootok=1 ;;
esac

# rootfs-block parse hook has been executed and the root device must
# have been recognized otherwise we don't setup an overlay.
case $root in
block:*)
	root=${root#block:} ;;
*)
	warn "won't make an overlay on top of a non block dev '$root'"
	return 1
esac

#
# Take over the rootfs mount.
#
info "setting up an overlay on top of root"

cancel_wait_for_dev "$root"
root=overlay:$root
wait_for_dev /run/initramfs/overlay/overlay
