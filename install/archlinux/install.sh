#!/usr/bin/env bash

cd `dirname $0`
bn=`basename $0`

while [[ $# -gt 0 ]]; do
	case $1 in
		-h )
			./main-install.sh -h
			exit 0
			;;
		* )
			# TODO: check
			break
			;;
	esac
	shift
done

if [ $UID != 0 ]; then
	echo "must run as root!"
	exit 1
fi

# TODO: check chroot env

cp -v /etc/pacman.d/mirrorlist{,.orig}
sed -n '/China/{p;n;p}' /etc/pacman.d/mirrorlist.orig > /etc/pacman.d/mirrorlist

pacman -Sy

disk=/dev/sda
if [ -d /sys/firmware/efi ]; then
	table="gpt"
else
	table="msdos"
fi

# FIXME
umount ${disk}[1-9]* 2>/dev/null

parted -s $disk mktable $table

if [ $table = "gpt" ]; then
	esp_size=200 #200M

	echo "mkpart primary fat32 1M $((esp_size+1))M" | parted $disk
	mkfs.vfat -F32 -I -n ESP ${disk}1

	echo "mkpart primary ext4 $((esp_size+1))M -1M" | parted $disk
	mkfs.ext4 -F -L ROOT ${disk}2
else
	echo "mkpart primary ext4 1M -1M" | parted $disk
	mkfs.ext4 -F -L ROOT ${disk}1
  # echo "toggle 0 boot" | parted $disk
fi

echo "toggle 1 boot" | parted $disk

parted $disk print

mount LABEL=ROOT /mnt

pacstrap /mnt base python

genfstab -U -p /mnt
genfstab -U -p /mnt >> /mnt/etc/fstab

mnt_dst="/mnt/main-install.sh"

if [[ -e main-install.sh ]]; then
	cp -v main-install.sh $mnt_dst
else
	for (( i = 0; i < 10; i++ )); do
		if [[ -s $mnt_dst ]]; then
			magic=`tail -1 $mnt_dst`
			if [[ "$magic" == '# __END_OF_MAIN_INSTALL_SCRIPT__' ]]; then
				break
			fi
			rm -f 0.
			$mnt_dst
		fi
		curl -o $mnt_dst https://raw.githubusercontent.com/conke/witbox/master/install/archlinux/install.sh
	done
fi
chmod +x $mnt_dst && \
arch-chroot /mnt ${mnt_dst#/mnt} $@
result=$?
echo -n -e "\nInstallation "
if [[ $result -eq 0 ]]; then
	echo "finished."
	rm $mnt_dst
	echo "rebooting ..."
	reboot
else
	echo "failed!"
fi
