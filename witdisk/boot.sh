#!/bin/bash

if [ $# != 1 ]
then
	echo "usage: $0 <mount point>"
	exit 1
fi

boot=${1%/}

part=""
while read mnt
do
	mnt=($mnt)
	if [ ${boot} == ${mnt[1]} ]
	then
		part=${mnt[0]}
		break
	fi
done < /proc/mounts

if [ "$part" == "" ]
then
	echo "No such mount point found! ($boot)"
	exit 1
fi

disk=${part%%[0-9]}
index=${part#$disk}
repo="/maxwit/os/linux"

############### copy ISO ###############
mkdir -p $boot/iso

iso_list=(`ls $repo/*.iso`)
prev=""
i=$((${#iso_list[@]}-1))

while ((i>=0))
do
	iso=${iso_list[$i]}
	fn=`basename $iso`
	dist=(${fn//-/ })

	curr=${dist[0]}
	if [ $curr != "$prev" ]; then
		cp -v $iso $boot/iso
	fi

	prev=$curr
	((i--))
done

############# install grub #############
echo "installing grub to $boot for $disk ..."

grub_cmd=`which grub2-install`
if [ -z $grub_cmd ]
then
	grub_cmd="grub-install"
fi

$grub_cmd --boot-directory=$boot $disk

############# generate grub.cfg #############
if [ -d "$boot/grub2" ]
then
	grub_cfg="$boot/grub2/grub.cfg"
elif [ -d "$boot/grub" ]
then
	grub_cfg="$boot/grub/grub.cfg"
else
	echo "The grub directory does not exist!"
	exit 1
fi

echo "Generating $grub_cfg ..."
echo "GRUB_TIMEOUT=5" > $grub_cfg

for iso in `ls $boot/iso/*.iso`
do
	fn=`basename $iso`
	# FIXME!
	dist=(${fn//-/ })

	id=${dist[0]}
	ver=${dist[1]}

	echo "generating menuentry for $id-$ver ..."
	case $id in
	CentOS|RHEL|Fedora|OLinux)
		uuid=`blkid $part | sed 's/.*\sUUID="\([a-z0-9-]*\)"\s.*/\1/'`
		linux="linux (lo)/isolinux/vmlinuz repo=hd:UUID=$uuid:/iso/"
		initrd="initrd (lo)/isolinux/initrd.img"
		;;

	ubuntu)
		linux="linux (lo)/casper/vmlinuz.efi boot=casper iso-scan/filename=/iso/$fn"
		initrd="initrd (lo)/casper/initrd.lz"
		;;
	*)
		echo "Warning: distribution $id not supported (skipped)!"
		continue
		;;
	esac

cat >> $grub_cfg << OEF

menuentry '$id $ver Install' {
	set root='hd0,$index'
	loopback lo /iso/$fn
	$linux
	$initrd
}
OEF

done

echo
