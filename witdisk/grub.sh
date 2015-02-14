#!/bin/bash

if [ $# != 1 ]
then
	echo "usage: $0 <boot directory>"
	exit 1
fi

boot=${1%/}

disk=""
while read mnt
do
	mnt=($mnt)
	mp=${mnt[1]}
	if [ ${boot:0:${#mp}} == $mp ]
	then
		disk=${mnt[0]}
		break
	fi
done < /proc/mounts

if [ "$disk" == "" ]
then
	echo "No such mount point found! ($boot)"
	exit 1
fi

disk=${disk%%[0-9]}

echo "installing grub to $boot for $disk ..."
exit 1

grub=`which grub2-install`
if [ -z $grub ]
then
	grub="grub-install"
fi

$grub --boot-directory=$boot $disk
