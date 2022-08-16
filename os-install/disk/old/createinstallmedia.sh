#!/usr/bin/env bash

if [ $UID != 0 ]; then
	echo "must run as super user!"
	exit 1
fi

usage() {
	echo "usage: $0 --isopath/-p <iso path> --volume/-m <mount point>"
}

while [[ $# -gt 0 ]]; do
	case $1 in
	--volume|-m )
		root="$2"
		shift
		;;
	--isopath|-p )
		repo="$2"
		shift
		;;
	-h )
		usage
		exit 0
		;;
	* )
		echo "invalid option '$1'"
		usage
		exit 1
		;;
	esac

	shift
done

root=${root%%/}
part=""

if [ -z "$root" -o -z "$repo" ]; then
	usage
	exit 1
fi

while read mnt
do
	mnt=($mnt)
	if [ ${root} == ${mnt[1]} ]; then
		part=${mnt[0]}
		break
	fi
done < /proc/mounts

if [ "$part" == "" ]; then
	echo "No such mount point found! ($root)"
	exit 1
fi

disk=${part%%[0-9]}
index=${part#$disk}

boot=$root/boot
boot_iso=$root/iso
mkdir -vp $boot $boot_iso

############### copy ISO ###############
if [ -d $repo ]; then
	src_list=(`ls $repo/*.iso`)
	if [ ${#src_list[@]} -eq 0 ]; then
		echo "No iso files in '$repo'!"
		exit 1
	fi
elif [ -e $repo ]; then
	src_list=($repo)
else
	echo "'$repo' is invalid!"
	exit 1
fi

iso_list=()

count=1
for iso in ${src_list[@]}
do
	echo "[$count/${#src_list[@]}]"

	iso_fn=`basename $iso`

	iso_list=(${iso_list[@]} $iso_fn)

	if [ -e $boot_iso/$iso_fn ]; then
		echo "$boot_iso/$iso_fn already exists"
	else
		cp -v $iso $boot_iso
	fi

	((count++))
done

############# install grub #############
echo "installing grub to $boot for $disk ..."

if which grub2-install > /dev/null; then
	grub_cmd="grub2-install"
	grub_cfg="$boot/grub2/grub.cfg"
elif which grub-install > /dev/null; then
	grub_cmd="grub-install --removable"
	grub_cfg="$boot/grub/grub.cfg"
else
	echo "No grub installer found!"
	exit 1
fi

function blk_tag() {
	blkid -s $1 $2| perl -p -e 's/.*="(.*?)".*/\1/'
	#blkid -s $1 $2 | awk -F ": $1=" '{print $2}'
}

pttype=`blk_tag PTTYPE $disk`
echo "$disk partition type: $pttype"

if [ $pttype = "gpt" ]; then
	grub_cmd="$grub_cmd --target=x86_64-efi"

	esp=`parted $disk print | awk '/boot.*esp/{print $1}'`
	num='^[0-9]+$'
	if ! [[ "$esp" =~ $num ]]; then
		echo "ESP partition not found!"
		exit 1
	fi
	umount $disk$esp 2>/dev/null
	mkdir -p $boot/efi
	mount $disk$esp $boot/efi
	#rm -rf $boot/efi/EFI
else
	grub_cmd="$grub_cmd --target=i386-pc"
fi

rm -rf $boot/grub $boot/grub2

$grub_cmd --boot-directory=$boot $disk || exit 1

echo "Generating $grub_cfg ..."
echo "GRUB_TIMEOUT=5" > $grub_cfg
if [ $pttype = "gpt" ]; then
	echo "insmod part_gpt" >> $grub_cfg
fi
echo "insmod ext2" >> $grub_cfg

for iso_fn in ${iso_list[@]}
do
	label=`blk_tag LABEL $boot_iso/$iso_fn`
	if [ -z "$label" ]; then
		echo "'$boot_iso/$iso_fn' is NOT a valid ISO image!"
		#rm -vf $boot_iso/$iso_fn
		echo
		continue
	fi

	echo "generating menuentry for $label ..."
	case "$label" in
		RHEL* | AlmaLinux* | Rocky* | CentOS* | OL* | Fedora*)
			uuid=`blk_tag UUID $part`
			linux="isolinux/vmlinuz repo=hd:UUID=$uuid:/iso/"
			initrd="isolinux/initrd.img"
			;;

		Ubuntu* | Debian*)
			linux="casper/vmlinuz boot=casper iso-scan/filename=/iso/$iso_fn"
			initrd="casper/initrd"
			;;
		*)
			echo "Warning: distribution '$label' not supported (skipped)!"
			continue
			;;
	esac

	cat >> $grub_cfg << _OEF_

menuentry 'Install $label' {
	set root='hd0,$index'
	loopback lo /iso/$iso_fn
	linux (lo)/$linux
	initrd (lo)/$initrd
}
_OEF_

done

if [ $pttype = "gpt" ]; then
	umount $boot/efi
fi

echo

