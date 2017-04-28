#!/usr/bin/env bash

if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
	declare -A check
fi

os=`uname -s`

# init:
# 1. read os version
# 2. get installer ready

case $os in
	Linux )
		if [ -e /etc/os-release ]; then
			. /etc/os-release
			os_dist=$ID
			version=$VERSION_ID
		elif [ -e /etc/redhat-release ]; then
			dist=(`cat /etc/redhat-release | head -n 1`)
			os_dist=`echo ${dist[0]} | tr A-Z a-z`
			version=${dist[2]%%.*}
		else
			echo -e "Fail to detect the distribution name!\n"
			exit 1
		fi

		case $os_dist in
			ubuntu|debian)
				which apt > /dev/null 2>&1 || alias apt=apt-get
				installer="sudo apt install -y"
				;;
			fedora )
				installer="sudo dnf install -y"
				;;
			redhat|centos )
				if [[ $version -ge 7 ]]; then
					which dnf > /dev/null 2>&1 || sudo yum install -y yum-utils
					which dnf > /dev/null 2>&1 || alias dnf=yum # should never happen
				else
					alias dnf=yum
				fi
				if [[ ! -e /etc/yum.repos.d/ius.repo ]]; then
					curl https://setup.ius.io/ | sudo bash
				fi
				# if [[ ! -e /etc/yum.repos.d/remi.repo ]]; then
				# 	yum install -y http://rpms.famillecollet.com/enterprise/remi-release-${version}.rpm
				# fi
				;;
			*)
				echo "Linux distribution '$ID' not supported!"
				exit 1
		esac

		;;

	Darwin )
		which brew > /dev/null 2>&1 || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		which brew > /dev/null 2>&1 || {
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

# log="$HOME/witbox-post-install.log"
#
# echo > $log
#
# function pkg_install() {
# 	for pkg in $@; do
# 		if [[ -z "${exe[$pkg]}" ]]; then
# 			exe=$pkg
# 		else
# 			exe=${check[$pkg]}
# 		fi
#
# 		loc=`which $exe`
#
# 		if [[ ! -e "$loc" ]]; then
# 			for (( i = 0; i < 5; i++ )); do
# 				echo $installer $pkg && break
# 				sleep 1
# 			done
# 			if [[ $i -eq 5 ]]; then
# 				echo $pkg >> $log
# 			fi
# 		fi
# 	done
# }

### base and common ###

pkg_list=('git' 'subversion')

### Build tools ###

# C/C++

case $os in
	Linux )
		pkg_list+=(gcc)
		case $os_dist in
			redhat|centos|fedora )
				pkg=gcc-c++
				pkg_list+=($pkg)
				check[$pkg]=g++
				;;
			* )
				pkg_list+=(g++)
				;;
		esac
		;;
esac

pkg_list+=(cmake)

# TODO: add build tools

# C#

# Go

# Java and Groovy

# JavaScript

# Perl

# PHP

# case $os in
# 	Linux )
# 		case $os_dist in
# 			redhat|centos )
# 			 	echo FIXME: use remi/scl instead
# 				;;
# 			* )
# 				pkg_list+=(php)
# 				pkg_list+=(composer)
# 				;;
# 		esac
# 		;;
# 	Darwin )
# 		pkg_list+=(homebrew/php/composer)
# esac

# Python

case $os in
	Darwin )
		pkg_list+=(anaconda3)
		;;
esac

# Ruby

# Rust

# Scala

# Swift

# TypeScript


### Editors: Atom/Code/Sublime/VIM ###

case $os in
	Linux )
		case $os_dist in
			redhat|centos|fedora )
				# Code
				sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
				sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
				# VIM
				pkg_list+=(vim-enhanced)
				check[vim-enhanced]=vim # or vimdiff
			;;
			ubuntu|debian )
				# Code
				curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
				sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
				sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
				# VIM
				pkg_list+=(vim-gtk3) # FIXME for old ubuntu/debian
				check[vim-gtk3]=vim.gtk3
			;;
		esac
		pkg_list+=(code)
		# git_list[atom]='https://github.com/atom/atom.git'
		;;
	Darwin )
		pkg_list+=(atom visual-studio-code sublime-text)
		check[visual-studio-code]=code
		check[sublime-text]=subl
		;;
esac

# update repo

case $os in
	Linux )
		case "$os_dist" in
			ubuntu|debian )
				sudo apt update -y
				sudo apt upgrade -y
				;;
			redhat|centos|fedora )
				sudo dnf install -y epel-release
				sudo dnf update -y
				;;
		esac
		;;
	Darwin )
		echo "TODO: brew update?"
		;;
esac

# check packages to be installed

if [[ $os == Darwin ]]; then
	cask_list=()
	for pkg in ${pkg_list[@]}; do
		if [[ $os == Darwin ]]; then
			result=`brew cask search $pkg`
			if [[ "${result:0:15}" == '==> Exact match' ]]; then
				pkg_list=(${pkg_list[@]/$pkg})
				cask_list+=($pkg)
			fi
		fi
	done

	echo brew install ${pkg_list[@]}
	echo brew cask install ${cask_list[@]}
fi

# now ready for install packages
$installer ${pkg_list[@]}

# pkg_install ${pkg_list[@]}

exit 0

# open-vm-tools
vm=`sudo virt-what`

case "$vm" in
	vmware )
		$installer open-vm-tools
		temp=`mktemp`

		cat > $temp << __EOF__
[Unit]
Description=VMware Shared Folders
Requires=vmware-vmblock-fuse.service
After=vmware-vmblock-fuse.service
ConditionPathExists=/mnt/hgfs
ConditionVirtualization=vmware

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=
ExecStart=/usr/bin/vmhgfs-fuse -o allow_other -o auto_unmount .host:/ /mnt/hgfs

[Install]
WantedBy=multi-user.target
__EOF__

		sudo mkdir -p /mnt/hgfs
		sudo cp -v $temp /etc/systemd/system/hgfs.service
		sudo systemctl enable hgfs
		# sudo systemctl start hgfs
		;;
	# vmware
	# xen
	# docker
	# kvm
	# hyperv
	# parallels
	# qemu
	# virtualbox
esac

exit 0

case $os in
	Linux )
		fullname=$(awk -F : -v user=$USER '$1==user {print $5}' /etc/passwd)
		fullname=${fullname/,*}
		;;
	Darwin )
		fullname=$USER # FIXME
		;;
esac

username=${fullname// /.}
username=$(echo $username | tr A-Z a-z)

git config --global user.name "$fullname"
git config --global user.email $username@gmail.com
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
