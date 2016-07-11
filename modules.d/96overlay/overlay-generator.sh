#!/bin/bash

# does the user asking us to setup an overlay ?
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
getargbool 0 rd.overlay || exit 0

GENERATOR_DIR="$2"
[ -z "$GENERATOR_DIR" ] && exit 1

mkdir -p "$GENERATOR_DIR"

cat >"$GENERATOR_DIR"/sysroot.mount<<EOF
[Unit]
Before=initrd-root-fs.target

[Mount]
Where=/sysroot
What=/run/initramfs/overlay/overlay
Options=bind
EOF
