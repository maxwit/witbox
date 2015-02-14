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

sys=$2
sch=""

for s in ${sys//,/ }
do
	size=""

	case $s in
	w|w=*)
		echo windows
		size=5G
		;;
	l|l=*)
		echo linux
		size=1536M
		;;
	x|x=*)
		echo OS X
		size=1G
		;;
	*)
		echo "Invalid OS type: $s"
		exit 1
	esac

	if [ "$size" != "" ]; then
		size="+$size"
	fi
	sch=$sch"n\n\n\n\n${size}\n"
done

#sch=$sch"w\n"
sch=$sch"p\nw\n"

echo "creating partitions ..."
parted -s $disk mktable msdos
echo -e $sch | fdisk $disk

exit 0

#kpartx -a $disk

mkfs.ntfs ${disk}1
ntfslabel ${disk}1 WINDOWS

mkfs.vfat -F32 ${disk}2
dosfslabel ${disk}2 OSX

mkfs.ext4 -F ${disk}3
e2label ${disk}3 linux
