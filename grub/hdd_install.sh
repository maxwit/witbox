#!/bin/sh

if [ $# -eq 1 ]; then
	PART="$1"

	echo $PART | grep [0-9] || { 
		echo "Usage: $0 <partition>"
		exit 1
	}
else
	PART="/dev/sdb1"
fi

DISK=${PART%%[0-9]*}
INDEX=${PART##${DISK}}

MP=`mount | grep "$PART" | awk '{print $3}'`

if [ -z "$MP" ]; then
	echo "\"$PART\" not mounted! please mount it first"
	exit 1
fi

echo $MP

for iso in `ls $MP/boot/ubuntu-*.iso 2>/dev/null`
do
	IMAGE=${iso#$MP/boot/}
	break;
done

if [ -z "$IMAGE" ]; then
	echo "Ubuntu ISO not found in $MP/boot!"
	IMAGE="ubuntu-13.04-desktop-amd64.iso"
fi

echo "Installing grub to $PART ..."
sudo grub-install --boot-directory=$MP/boot $DISK || exit 1

cat > /tmp/grub.cfg << EOF
menuentry 'Ubuntu Installation' {
	set root='hd0,msdos$INDEX'
	loopback lo /boot/${IMAGE}
	linux (lo)/casper/vmlinuz.efi boot=casper iso-scan/filename=/boot/${IMAGE}
	initrd (lo)/casper/initrd.lz
}
EOF

sudo cp -v /tmp/grub.cfg $MP/boot/grub
