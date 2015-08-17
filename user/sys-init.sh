#!/bin/bash

if [ $UID != 0 ]; then
	echo "pls run as root!"
	exit
fi

which lsb_release || exit 1

dist=`lsb_release -si`
ver=`lsb_release -sr`

apps="git gcc vim emacs tree gparted"

case "$dist" in
Ubuntu|Debian)
	# perl -i -pe 's/\(^%sudo\s\+.*\s\)ALL/\1NOPASSWD:ALL/' /etc/sudoers
	apt-get upgrade -y
	apt-get install -y $apps g++
	ln -svf bash /bin/sh # FIXME with dpkg-reconfigure?
	update-alternatives --set editor /usr/bin/emacs24
	;;
Redhat|CentOS|Fedora|OL) # FIXME
	# perl -i -pe 's/(^%wheel\s+ALL=\(ALL\)\s+ALL)/#\1/g; s/^#\s*(%wheel\s.*NOPASSWD:)/\1/g;' /etc/sudoers
	yum install -y http://rpms.famillecollet.com/enterprise/remi-release-${ver}.rpm
	yum install -y $apps gcc-c++
	# FIXME
	cp -v /usr/bin/vim /bin/vi
	;;
*)
	echo -e "'$dist' not supported yet!\n"
	exit 1
esac

for part in `ls /dev/sda[0-9]*`
do
	index=${part#/dev/sda}
	mkdir -vp /mnt/$index
done

#groupadd devel
#groupadd maxwit
#usermod -g devel -a -G maxwit $SUDO_USER
#groupdel $SUDO_USER
#
#mount LABEL=maxwit /mnt && {
#	umount /mnt
#	WITPATH="/mnt/maxwit"
#	mkdir -vp $WITPATH
#	# FIXME
#	grep "LABEL=maxwit" /etc/fstab || sed -i '$a\LABEL=maxwit '"$WITPATH"' ext4 defaults 0 0' /etc/fstab
#	mount $WITPATH && umount $WITPATH
#} || {
#	WITPATH="/opt/maxwit"
#	mkdir -vp $WITPATH
#	# TODO: init sync?
#}
#
#echo "WITPATH=$WITPATH"
#chown $SUDO_USER.devel -R /opt $WITPATH
#
#echo
#echo "****************************************"
#echo "*       Please reboot now!             *"
#echo "****************************************"
echo
