#!/bin/bash

#
#  root=LABEL=$iso_label
#  rd.overlay
#  rd.overlay.cow=/dev/sdc2
#  rd.overlay.img=path/to/rootfs.squashfs
#  rd.overlay.cow_size=75% (must be compatible to tmpfs size)
#

. /lib/dracut-lib.sh
. /lib/fs-lib.sh

root=$1
cow_size=
cow_device=$(getarg rd.overlay.cow=)
rootfs_image=$(getarg rd.overlay.img=)

# create overlay dir tree
mkdir -p /run/initramfs/overlay
cd /run/initramfs/overlay

mkdir -m 0755 -p media
mkdir -m 0755 -p lower
mkdir -m 0755 -p upper
mkdir -m 0755 -p overlay

set -x
#
# Setup lower filesystem: use the root device or an fs image embedded
# in it.
#
rootfstype=$(det_fs "$root" "$fstype")
mount -n -t $rootfstype -o ro $root media

if test -n "$rootfs_image"; then
	test -f media/$rootfs_image || {
		warn "overlay image not found: $rootfs_image"
		exit 1
	}
	modprobe -q loop
	# image must be a squashfs one.
	mount -n -t squashfs -o ro media/$rootfs_image lower
else
	mount --rbind media lower
fi

#
# Mountpoint 'media' is used to access the rootfs image so any
# attempts to unmount it will fail. This will be the case for systemd
# during the shutdown process. Therefore we lazily umount it so this
# busy mount will be hidden by the system and will be automatically
# unmounted when the overlay will.
#
# But we still want to make the media mounted since it may be needed
# by the installer later. This also prevents any applications to eject
# it by mistake.
#
umount -l media
mount -n -t $rootfstype -o ro $root media

#
# setup the upper filesystem: the user can provide a backing device
# (to make persistent changes) otherwise we use a tmpfs filesystem
# (volatile changes).
#
if test -n "$cow_device"; then
	if test -b "$cow_device"; then
		test -n "$cow_size" &&
		warn "overlay: ignoring cow size parameter when a cow dev is passed"

		info "Mounting overlay cow device: $cow_device"
		fs=$(det_fs $cow_device)
		mount -n -t $fs $cow_device upper
	else
		warn "overlay: cow device not found: $cow_device"
		warn "overlay: falling back to non-persistent overlay"
		cow_device=
	fi
fi

if test -z "$cow_device"; then
	#
	# default size value is 50% of the system RAM if cow is a tmpfs
	# filesystem.
	#
	cow_size=$(getarg rd.overlay.cow_size=)
	cow_size=${cow_size:-50%}

	info "Mounting overlay cow tmpfs filesystem, size=$cow_size"
	mount -n -t tmpfs -o size=$cow_size,mode=0755 none upper
fi

#
# Finally setup the overlay.
#
mount -t overlayfs overlayfs -olowerdir=lower,upperdir=upper overlay
ln -s /run/initramfs/overlay/overlay /dev/root

if [ -z "$DRACUT_SYSTEMD" ]; then
	cat >$hookdir/mount/01-$$-overlay.sh <<EOF
/bin/mount --rbind /run/initramfs/overlay/overlay $NEWROOT
EOF
fi
