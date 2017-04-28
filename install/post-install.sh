#!/usr/bin/env bash

os=`uname -s`

case $os in
	Linux )
		if [ -e /etc/os-release ]; then
			. /etc/os-release
			dist_id=$ID
			version=$VERSION_ID
		elif [ -e /etc/redhat-release ]; then
			dist=(`cat /etc/redhat-release | head -n 1`)
			dist_id=`echo ${dist[0]} | tr A-Z a-z`
			version=${dist[2]%%.*}
		else
			echo -e "Fail to detect the distribution name!\n"
			exit 1
		fi

		case $dist_id in
			ubuntu|debian)
				installer="sudo apt-get install -y"
				;;
			redhat|centos|fedora|ol)
				installer="sudo yum install -y"
				;;
			*)
				echo "Linux distribution '$ID' not supported!"
				exit 1
		esac

		;;

	Darwin )
		which brew > /dev/null || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		which brew > /dev/null || {
			echo "fail to install HomeBrew, pls try again!"
			exit 1
		}
		installer="brew install"
		;;

	*)
		echo "'$os' not supported!"
		exit 1
		;;
esac

function install() {
	for pkg in $@; do
		loc=`which $pkg`
		if [[ -z "$loc" ]]; then
			for (( i = 0; i < 5; i++ )); do
				$installer $pkg && break
			done
		fi
	done
}

install git

exit 0

install git

case $os in
	Linux )
		fullname=$(awk -F : -v user=$USER '$1==user {print $5}' /etc/passwd)
		fullname=${fullname/,*}
		;;
	Darwin )
		fullname="Conke Hu"
		;;
esac

account=${fullname// /.}
account=$(echo $account | tr A-Z a-z)

git config --global user.name "$fullname"
git config --global user.email $account@gmail.com
git config --global color.ui auto
git config --global push.default simple
# git config --global sendemail.smtpserver /usr/bin/msmtp
git config --global merge.ours.driver true
git config --list

exit 0

echo "initializing $ID $VERSION_ID ..."

apps="git gcc vim tree gparted"
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
	cat > $temp << __EOF__
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$USER

[security]

[xdmcp]

[greeter]

[chooser]

[debug]

__EOF__

	sudo cp -v $temp /etc/gdm/custom.conf
}

### user init

cat > ~/.vimrc << EOF
set nu
set ts=4
set hlsearch
let c_space_errors=1
let java_space_errors=1
EOF

cat > ~/.emacs << EOF
(global-linum-mode t)
EOF

echo
