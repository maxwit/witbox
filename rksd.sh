#!/usr/bin/env bash

RKBIN="../rkbin/bin"

soc=`grep -o '^CONFIG_ROCKCHIP_RK[3-9]\+PRO=y' .config`
if [ -z "$soc" ]; then
	soc=`grep -o '^CONFIG_ROCKCHIP_RK[3-9]\+=y' .config`
fi
if [ -z "$soc" ]; then
	echo "u-boot not fingured for Rockchip!"
	exit 1
fi

soc=${soc##*_}
soc=${soc%=y}
echo "u-boot configured for $soc"

soc=`echo $soc | tr A-Z a-z`

# FIXME
bl=(`ls /dev/sd[a-z]`)
if [ ${#bl[@]} -lt 2 ]; then
	echo "not SD/TF card found!"
	exit 1
fi
sd=${bl[-1]}

if grep -q rockchip-linux/u-boot .git/config; then
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
	case $soc in
	rk3399)
		tpl=$RKBIN/rk33/rk3399_ddr_800MHz_v1.27.bin
		spl=$RKBIN/rk33/rk3399_miniloader_v1.26.bin
		;;
	rk3399pro)
		tpl=$RKBIN/rk33/rk3399pro_ddr_933MHz_v1.27.bin
		spl=$RKBIN/rk33/rk3399pro_miniloader_v1.26.bin
		;;
	rk3568)
		tpl=$RKBIN/rk35/rk3568_ddr_1560MHz_v1.13.bin
		spl=$RKBIN/rk35/rk356x_spl_v1.12.bin
		;;
	rk3588)
		tpl=$RKBIN/rk35/rk3588_ddr_lp4_2112MHz_lp5_2736MHz_v1.08.bin
		spl=$RKBIN/rk35/rk3588_spl_v1.11.bin
		;;
	*)
		echo "$soc not supported yet!"
		exit 1
	esac

	uboot=uboot.img
else
	echo "Boot flow 2: u-boot TPL/SPL"

	tpl=tpl/u-boot-tpl.bin
	spl=spl/u-boot-spl.bin

	for img in u-boot.itb fit/uboot.itb; do
		if [ -f $img ]; then
			uboot=$img
			break
		fi
	done
	if [ -z "$img" ]; then
		echo "no u-boot image found!"
		exit 1
	fi
fi

echo "burning to $sd ..."

./tools/mkimage -n $soc -T rksd -d $tpl:$spl idbloader.img

echo 
image_list="idbloader.img@64 $uboot@16384"
if [ $bootflow -eq 1 ]; then
	if [ -e trust.img ]; then
		image_list+=" trust.img@24576"
	else
		echo "trust.img does NOT exist! skipping ..."	
	fi
fi

for info in $image_list
do
	img=${info%@*}
	off=${info#*@}
	echo "$img => $off"
	dd if=$img of=$sd seek=$off
done

#dd if=idbloader.img of=$sd seek=64
#dd if=$uboot of=$sd seek=16384
#
#if [ $bootflow -eq 1 ]; then
#	if [ -e trust.img ]; then
#		dd if=trust.img of=$sd seek=24576
#	else
#		echo "trust.img does NOT exist! skipping ..."	
#	fi
#fi

#dd if=/dev/zero of=$sd seek=24576 count=8192
