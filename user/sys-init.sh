#!/bin/bash

if [ $UID != 0 ]; then
	echo "pls run as root!"
	exit
fi

if [ -e /etc/os-release ]; then
	. /etc/os-release
elif [ -e /etc/redhat-release ]; then
	dist=(`cat /etc/redhat-release | head -n 1`)
	ID=`echo ${dist[0]} | tr A-Z a-z`
	VERSION_ID=${dist[2]%%.*}
else
	echo -e "Fail to detect the running OS!\n"
	exit 1
fi

echo "initializing $ID $VERSION_ID ..."

apps="git maven gcc vim tree gparted"
#sg="maxwit"

case "$ID" in
ubuntu|debian)
	# perl -i -pe 's/\(^%sudo\s\+.*\s\)ALL/\1NOPASSWD:ALL/' /etc/sudoers
	apt-get upgrade -y
	apt-get install -y $apps g++ nfs-common
	ln -svf bash /bin/sh # FIXME with dpkg-reconfigure?
	update-alternatives --set editor /usr/bin/vim.basic
	;;
redhat|centos|fedora|ol) # FIXME
	# perl -i -pe 's/(^%wheel\s+ALL=\(ALL\)\s+ALL)/#\1/g; s/^#\s*(%wheel\s.*NOPASSWD:)/\1/g;' /etc/sudoers
	yum update -y
	perl -i -pe 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-eno*
	yum install -y http://rpms.famillecollet.com/enterprise/remi-release-${VERSION_ID}.rpm
	yum install -y $apps gcc-c++ nfs-utils
	# FIXME
	cp -v /usr/bin/vim /bin/vi
	#sg="$sg,wheel"
	;;
*)
	echo -e "'$ID' not supported yet!\n"
	exit 1
esac

#user=(`ls /home`)
#test ${#user[@]} -eq 1 && {
#	user=${user[0]}
#	pg='devel'
#
#	groupadd $pg
#	groupadd maxwit
#	usermod -g $pg -a -G $sg $user
#	groupdel $user
#
#	chown $user.maxwit -R /opt
#}
#
#for part in `ls /dev/sda[0-9]*`
#do
#	index=${part#/dev/sda}
#	mkdir -vp /mnt/$index
#done
#
#WITPATH="/mnt/witpub"
#mount | grep $WITPATH || {
#	mkdir -vp $WITPATH
#	# FIXME
#	grep "$WITPATH" /etc/fstab || sed -i '$a\'"192.168.3.3:$WITPATH $WITPATH nfs defaults 0 0" /etc/fstab
#	mount $WITPATH || {
#		echo "Fail to mount '$WITPATH', pls check /etc/fstab!"
#		exit 1
#	}
#}

test -e /etc/gdm/custom.conf && {
temp=`mktemp`
cat > $temp << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$user
TimedLoginEnable=true
TimedLogin=$user
TimedLoginDelay=7

[security]

[xdmcp]

[greeter]

[chooser]

[debug]

EOF

cp -v $temp /etc/gdm/custom.conf
}

#poweroff
