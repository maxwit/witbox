#!/usr/bin/env bash

TOPDIR=$PWD
RKBIN="../rkbin"

SOC=`grep -o '^CONFIG_ROCKCHIP_RK[3-9]\+PRO=y' .config`
if [ -z "$SOC" ]; then
	SOC=`grep -o '^CONFIG_ROCKCHIP_RK[3-9]\+=y' .config`
fi
if [ -z "$SOC" ]; then
	echo "u-boot not fingured for Rockchip!"
	exit 1
fi

SOC=${SOC##*_}
SOC=${SOC%=y}
echo "u-boot configured for $SOC"

soc=`echo $SOC | tr A-Z a-z`

bl=(`ls /dev/mmcblk[0-9] /dev/sd[a-z] 2>/dev/null`)
if [ ${#bl[@]} -eq 0 ]; then
	echo "No SD/TF cards found!"
	exit 1
fi
# FIXME
sd=${bl[-1]}
if mount | grep $sd; then
	echo "$sd is mounted! pls umount it first!"
	exit 1
fi

if [ -x make.sh  ]; then
	bootflow=1
else
	bootflow=2
fi

while [ $# -gt 0 ]; do
	case $1 in
	--boot|--bootflow)
		bootflow=$2
		shift
		;;
	--mini|--miniloader)
		bootflow=1
		;;
	--sd)
		sd=$2
		shift
		;;
	*)
		echo "Invalid option '$1'"
		exit 1
	esac
	shift
done

if [ $bootflow -eq 1 ]; then
	echo "Boot flow 1: Rockchip miniloader"

	idb_list="idblock.bin idbloader.img"
	uboot_list="uboot.img u-boot.img"

	if [ -e trust.img ]; then
		trust=trust.img
	fi
else
	echo "Boot flow 2: u-boot TPL/SPL"

	idb_list="idbloader.img idblock.bin"
	uboot_list="u-boot.itb fit/uboot.itb"
fi

for idb in $idb_list; do
	if [ -e $idb ]; then
		loader=$idb
		break
	fi
done

if [ -z "$loader" ]; then
	echo "no idbloader image found!"
	exit 1
fi

for img in $uboot_list; do
	if [ -f $img ]; then
		uboot=$img
		break
	fi
done

if [ -z "$uboot" ]; then
	echo "no u-boot image found!"
	exit 1
fi

image_list="$loader@64 $uboot@16384"
if [ ! -z "$trust" ]; then
	image_list+=" $trust@24576"
fi

echo "burning to $sd ..."

for info in $image_list
do
	img=${info%@*}
	off=${info#*@}
	echo "$img => $off"
	dd if=$img of=$sd seek=$off
done
