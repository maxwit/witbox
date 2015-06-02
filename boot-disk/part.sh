#!/bin/sh

if [ $USER != root ]; then
	echo "must run as super user!"
	exit 1
fi

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

umount ${disk}[1-9]* 2>/dev/null

part_label=()
part_type=()

sys=$2
sch=""
i=0

for s in ${sys//,/ }
do
	if [ "${s:1:1}" == "=" ]; then
		size=${s:2}
	else
		size=""
	fi

	case $s in
	w|w=*)
		part_label[$i]="windows"
		part_type[$i]="ntfs"
		if [ "$size" == "" ]; then
			size=5G
		fi
		;;

	l|l=*)
		part_label[$i]="linux"
		part_type[$i]="ext4"
		if [ "$size" == "" ]; then
			size=6G
		fi
		;;
	x|x=*)
		part_label[$i]="OSX"
		part_type[$i]="vfat"
		if [ "$size" == "" ]; then
			size=8G
		fi
		;;
	*)
		echo "Invalid OS type: $s"
		exit 1
	esac

	echo "size = $size"

	if [ "$size" != "" ]; then
		size="+$size"
	fi
	sch=$sch"n\n\n\n\n${size}\n"

	((i++))
done

#sch=$sch"w\n"
sch=$sch"p\nw\n"

echo "creating partitions ..."
parted -s $disk mktable msdos
echo -e $sch | fdisk $disk

#kpartx -a $disk

for ((j=0; j<i; j++))
do
	type=${part_type[$j]}
	part=${disk}$((j+1))
	label=${part_label[$j]}
	echo "formating $part with $type ..."

	case $type in
	vfat)
		mkfs.vfat -F32 $part
		dosfslabel $part $label
		;;
	ntfs)
		mkfs.ntfs $part
		ntfslabel $part $label
		;;
	ext[234])
		mkfs.$type -F $part
		e2label $part $label
		;;
	*)
		echo "Invalid file system: $type!"
		exit 1
		;;
	esac

	echo
done

sync
