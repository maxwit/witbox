#!/usr/bin/env bash

function usage {
	echo "usage: $0 [-t gpt|msdos] <disk>"
	echo "i.e.: $0 /dev/sdb"
}

if [ $UID != 0 ]; then
	echo "must run as super user!"
	exit 1
fi

# os=`uname -s`
if [ -d /sys/firmware/efi ]; then
	table="gpt"
else
	table="msdos"
fi

while [[ $# -gt 0 ]]; do
	case $1 in
		-t )
			table=$2
			shift
			;;
		-h )
			usage
			exit 0
			;;
		/dev/* )
			device=$1
			;;
		* )
			echo "invalid argument '$1'"
			usage
			exit 1
			;;
	esac

	shift
done

if [ -z "$device" -o ! -b "$device" ]; then
	echo "invalid block device '$device'!"
	usage
	exit 1
fi

# FIXME
disk=${device%%[0-9]}
if [ "$disk" != "$device" ]; then
	echo "warning: $device does NOT seem a disk, fall back to $disk"
fi

if [ ! -b $disk ]; then
	echo "No such device: $disk!"
	exit 1
fi

umount ${disk}[1-9]* 2>/dev/null
###################
parted -s $disk mktable $table

last=10240

echo "mkpart primary fat32 1M -${last}M" | parted $disk
mkfs.vfat -F32 -I -n DATA ${disk}1

if [ $table = "gpt" ]; then
	echo "mkpart primary fat32 -${last} -$((last-100))M" | parted $disk
	mkfs.vfat -F32 -I -n ESP ${disk}2

	echo "mkpart primary ext4 -$((last-100))M -1M" | parted $disk
	mkfs.ext4 -F -L linux ${disk}3

	echo "toggle 2 boot" | parted $disk
else
	echo "toggle 1 boot" | parted $disk

	echo "mkpart primary ext4 -${last}M -1M" | parted $disk
	mkfs.ext4 -F -L linux ${disk}2
fi

parted $disk print
