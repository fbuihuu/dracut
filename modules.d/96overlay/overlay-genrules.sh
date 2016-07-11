#!/bin/sh

case "$root" in
overlay:/dev/*)
	devpath=${root#overlay:/dev/}
	cat >>/etc/udev/rules.d/99-overlay.rules <<EOF
KERNEL=="$devpath",  RUN+="/sbin/initqueue --settled --onetime --unique /sbin/overlay-root \$env{DEVNAME}"
SYMLINK=="$devpath", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/overlay-root \$env{DEVNAME}"
EOF
	wait_for_dev "${root#overlay:}"
	;;
esac
