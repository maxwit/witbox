#!/bin/sh

if [ $# != 1 ]; then
	echo "usage: $0 <disk>"
	exit 1
fi

dev=$1
disk=${dev%%[0-9]}

if [ "$disk" != "$dev" ]; then
	echo "warning: $dev does NOT seem a disk, fall back to $disk"
fi

fdisk $disk < ./fdisk-pc.cmd
partx -u $disk
#kpartx -a $disk

mkfs.vfat -F32 ${disk}1
dosfslabel ${disk}1 WINDOWS

mkfs.ext4 -F ${disk}2
e2label ${disk}2 linux
