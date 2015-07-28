#!/bin/bash

if [ $UID != 0 ]; then
	echo "pls run as root!"
	exit
fi

dist=`lsb_release -si`
ver=`lsb_release -sr`

case "$dist" in
Ubuntu|Debian)
	perl -i -pe 's/\(^%sudo\s\+.*\s\)ALL/\1NOPASSWD:ALL/' /etc/sudoers
	apt-get upgrade -y
	apt-get install -y git gcc g++ vim emacs tree
	ln -svf bash /bin/sh # FIXME with dpkg-reconfigure?
	update-alternatives --set editor /usr/bin/emacs24
	;;
*) # FIXME
	perl -i -pe 's/(^%wheel\s+ALL=\(ALL\)\s+ALL)/#\1/g; s/^#\s*(%wheel\s.*NOPASSWD:)/\1/g;' /etc/sudoers
	yum install -y http://rpms.famillecollet.com/enterprise/remi-release-$ver.rpm
	yum install -y git gcc gcc-c++ vim emacs tree
	# FIXME
	cp -v /usr/bin/vim /bin/vi
	;;
esac

groupadd devel
groupadd maxwit
usermod -g devel -a -G maxwit $SUDO_USER
groupdel $SUDO_USER

# groups=$(groups $SUDO_USER)
# groups=${groups/$SUDO_USER /}
# groups=${groups// /,}
# useradd -g devel -G maxwit,$groups -c "Ting Yang" ting
# passwd ting 

for part in `ls /dev/sda[0-9]*`
do
	index=${part#/dev/sda}
	mkdir -vp /mnt/$index
done

mount LABEL=maxwit /mnt && {
	umount /mnt
	WITPATH="/mnt/maxwit"
	mkdir -vp $WITPATH
	# FIXME
	grep "LABEL=maxwit" /etc/fstab || sed -i '$a\LABEL=maxwit '"$WITPATH"' ext4 defaults 0 0' /etc/fstab
	mount $WITPATH && umount $WITPATH
} || {
	WITPATH="/opt/maxwit"
	mkdir -vp $WITPATH
	# TODO: init sync?
}

echo "WITPATH=$WITPATH"
chown $SUDO_USER.devel -R /opt $WITPATH

echo
echo "****************************************"
echo "*       Please reboot now!             *"
echo "****************************************"
echo
