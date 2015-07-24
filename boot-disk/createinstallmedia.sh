#!/bin/sh

if [ $USER != root ]; then
	echo "must run as super user!"
	exit 1
fi

if [ $# = 1 ]; then
	root=$1
	repo=$1/iso
elif [ $# = 2 ]; then
	root=$2
	repo=$1
else
	echo "usage: $0 [iso path] <mount point>"
	exit 1
fi

root=${root%%/}
part=""

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
root_iso=$root/iso
mkdir -vp $boot $root_iso

############### copy ISO ###############
if [ -f $repo ]; then
	iso_list=$repo
elif [ -d $repo ]; then
	iso_list=`ls $repo/*.iso`
else
	echo "'$repo' is invalid!"
	exit 1
fi

for iso in $iso_list
do
	fn=`basename $iso`
	if [ ! -e $root_iso/$fn ]; then
		cp -v $iso $root_iso
	fi
done

############# install grub #############
echo "installing grub to $boot for $disk ..."

which grub2-install
if [ $? = 0 ]; then
    grub_cmd="grub2-install"
    grub_cfg="$boot/grub2/grub.cfg"
else
    grub_cmd="grub-install"
    grub_cfg="$boot/grub/grub.cfg"
fi

function dev_tag(){
	local dev=$1
	local tag=$2
	value=`blkid -s $tag $dev | perl -p -e 's/.*="(.*?)".*/\1/'`
}

dev_tag $disk 'PTTYPE'
table=$value
if [ $table = "gpt" ]; then
	grub_cmd="$grub_cmd --target=x86_64-efi"

	esp=`parted $disk print | awk '{if ($1 >= 1 && $1 <= 128 && $8 == "esp") {print $1} }'`
	if [ -z $esp ]; then
		echo "ESP partition not found!"
		exit 1
	fi
	umount $disk$esp 2>/dev/null
	mkdir -p $boot/efi
	mount $disk$esp $boot/efi
else
	grub_cmd="$grub_cmd --target=i386-pc"
fi

$grub_cmd --boot-directory=$boot $disk

echo "Generating $grub_cfg ..."
echo "GRUB_TIMEOUT=5" > $grub_cfg
if [ $table = "gpt" ]; then
	echo "insmod part_gpt" >> $grub_cfg
fi

for iso in `ls $root_iso/*.iso`
do
	fn=`basename $iso`
	dev_tag $iso 'LABEL'
	dist=$value
	if [ -z "$dist" ]; then
		echo "'$iso' is NOT a valid ISO image!"
		echo
		continue
	fi

	echo "generating menuentry for $dist ..."
	case "$dist" in
		RHEL* | CentOS* | OL* | Fedora*)			
			dev_tag $part 'UUID'
			uuid=$value
			linux="isolinux/vmlinuz repo=hd:UUID=$uuid:/iso/"
			initrd="isolinux/initrd.img"
			;;

		Ubuntu* | Deiban*)
			linux="casper/vmlinuz.efi boot=casper iso-scan/filename=/iso/$fn"
			initrd="casper/initrd.lz"
			;;
		*)
			echo "Warning: distribution $dist not supported (skipped)!"
			continue
			;;
	esac
	
	cat >> $grub_cfg << OEF

menuentry '$dist' {
	set root='hd0,$index'
	loopback lo /iso/$fn
	linux (lo)/$linux
	initrd (lo)/$initrd
}
OEF

done

echo

