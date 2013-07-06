#!/bin/sh

WITPART=`awk '{print $2}' /proc/mounts | grep -i -w WitDisk`

if [ -z "$WITPART" ]; then
	echo "Please insert MaxWit Magic Disk!"
	exit 1
fi

PART=`grep -w $WITPART /proc/mounts | awk '{print $1}'`
DISK=${PART%%[0-9]*}
INDEX=${PART##${DISK}}

VERSION=`lsb_release -sr`
IMAGE64="ubuntu-${VERSION}-desktop-amd64.iso"
IMAGE32="ubuntu-${VERSION}-desktop-i386.iso"

echo "Installing grub to $PART ..."
sudo grub-install --boot-directory=$WITPART/boot $DISK || exit 1

# fixme
cat > /tmp/grub.cfg << EOF
menuentry 'Ubuntu ${VERSION} (64Bit) Installation' {
	set root='hd0,msdos$INDEX'
	loopback lo /boot/${IMAGE64}
	linux (lo)/casper/vmlinuz.efi boot=casper iso-scan/filename=/boot/${IMAGE64}
	initrd (lo)/casper/initrd.lz
}

menuentry 'Ubuntu ${VERSION} (32Bit) Installation' {
	set root='hd0,msdos$INDEX'
	loopback lo /boot/${IMAGE32}
	linux (lo)/casper/vmlinuz boot=casper iso-scan/filename=/boot/${IMAGE32}
	initrd (lo)/casper/initrd.lz
}
EOF

sudo cp -v /tmp/grub.cfg $WITPART/boot/grub

sudo wget -P $WITPART/boot/grub http://192.168.0.1/pub/$IMAGE32
sudo wget -P $WITPART/boot/grub http://192.168.0.1/pub/$IMAGE64

sync && sudo umount $WITPART

#echo "cp IMAGE64_PATH $WITPART/boot/ ..."
#sudo cp -v $IMAGE64_PATH $WITPART/boot/
