#!/usr/bin/env bash

function usage {
	echo "usage: $0 [-t gpt|msdos] <disk>"
	echo "i.e.: $0 -t gpt /dev/sdb"
}

if [ $UID != 0 ]; then
	echo "must run as super user!"
	exit 1
fi

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

esp_size=200 #200M

if [ $table = "gpt" ]; then
	echo "mkpart primary fat32 1M $((esp_size+1))M" | parted $disk
	mkfs.vfat -F32 -I -n ESP ${disk}1

	echo "mkpart primary ext4 $((esp_size+1))M -1M" | parted $disk
	mkfs.ext4 -F -L ROOT ${disk}2
else
	echo "mkpart primary ext4 -${last}M -1M" | parted $disk
	mkfs.ext4 -F -L ROOT ${disk}1
  # echo "toggle 0 boot" | parted $disk
fi

echo "toggle 1 boot" | parted $disk

parted $disk print

mount LABEL=ROOT /mnt

pacstrap /mnt base

genfstab -U -p /mnt
genfstab -U -p /mnt >> /mnt/etc/fstab

cp -v after-chroot.sh /mnt/
chmod +x /mnt/after-chroot.sh
arch-chroot /mnt /after-chroot.sh
echo "reboot now!"
