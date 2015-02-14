#!/bin/bash

if [ $# != 3 ]; then
	echo "usage: $0 -s <system list> <disk>"
	echo "i.e.: $0 -s w,x,l /dev/sdb"
	exit 1
fi

dev=$3
# FIXME
disk=${dev%%[0-9]}
if [ "$disk" != "$dev" ]; then
	echo "warning: $dev does NOT seem a disk, fall back to $disk"
fi

if [ ! -b $disk ]; then
	echo "No such device: $disk!"
	exit 1
fi

umount ${disk}*

sch=""
sys=$2

for s in ${sys//,/ }
do
	size=0
	sch=$sch"n\n\n\n\n"

	case $s in
	w|w=*)
		echo windows;
		size=4G
		;;
	l|l=*)
		echo linux;
		size=4G
		;;
	x|x=*)
		echo OS X;
		size=1G
		;;
	*)
		echo "Invalid OS type: $s"
		exit 1
	esac

	if [ $size == 0 ]; then
		sch=$sch"\n"
	else
		sch=$sch"+${size}\n"
	fi
done

sch=$sch"p\nw\n"

echo "creating partitions ..."
parted -s $disk mktable msdos

echo -e $sch | fdisk $disk

exit 0

#kpartx -a $disk

mkfs.vfat -F32 ${disk}1
dosfslabel ${disk}1 WINDOWS

mkfs.ext4 -F ${disk}2
e2label ${disk}2 linux
