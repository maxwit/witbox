#!/usr/bin/env bash

if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
	declare -A check
fi

declare -a pkg_list

group='undefined'

os=`uname -s`

# get OS version
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
			echo -e "Linux distribution not supported yet!\n"
			exit 1
		fi
		;;

	Darwin )
		os_dist=macOS
		# TODO: versions
		;;

	* )
		echo -e "OS '$os' not supported yet!\n"
		exit 1
esac

alias curl='curl --connect-timeout 30'

echo -e "### Setup for $os_dist ###\n"

# get installer ready
case $os_dist in
	ubuntu|debian )
		which apt > /dev/null 2>&1 && pm='apt' || pm='apt-get'
		installer="sudo $pm install -y"
		# $pm update -y
		# $pm upgrade -y
		;;

	redhat|centos|fedora )
		if [[ $os_dist == fedora ]]; then
			# need epel?
			pm='dnf'
			installer="sudo dnf --allowerasing install -y"
		else
			if [[ $version -ge 7 ]]; then
				which dnf > /dev/null 2>&1 || sudo yum install -y yum-utils || {
					echo 'fail to install yum-utils!'
					exit 1
				}
				pm='dnf'
				installer="sudo dnf --allowerasing install -y"
			else
				# TODO: add source repo
				pm='yum'
				installer="sudo yum install -y"
			fi

			if [[ ! -e /etc/yum.repos.d/ius.repo ]]; then
				curl https://setup.ius.io/ | sudo bash
				sudo yum install -y yum-plugin-replace
			fi
			# if [[ ! -e /etc/yum.repos.d/remi.repo ]]; then
			# 	yum install -y http://rpms.famillecollet.com/enterprise/remi-release-${version}.rpm
			# fi
			# and SCL ?
		fi
		# $pm update -y
		;;

	macOS )
		which brew > /dev/null 2>&1 || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		which brew > /dev/null 2>&1 || {
			echo "fail to install HomeBrew, pls try again!"
			exit 1
		}
		installer="brew install"
		# TODO: update/upgrade ?
		;;

	*)
		echo "'$os_dist' not supported!"
		exit 1
		;;
esac

#########################

# macOS: make sure SIP disabled

$installer tree

case $os_dist in
	macOS )
	# sudoers
	sudo sed "s/\(^%admin.*(ALL)\) ALL$/\1 NOPASSWD:ALL/" /etc/sudoers

	# bash
	brew install bash
	sudo sh -c 'echo /usr/local/bin/bash >> /etc/shells'
	sudo chpass -s /usr/local/bin/bash $USER
	;;
esac

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

function instal_vm_tools() {
	$installer open-vm-tools
	case $os_dist in
		redhat|centos )
			requires=vmtoolsd
			;;
		ubuntu )
			requires=open-vm-tools
			;;
		* )
		  requires=vmware-vmblock-fuse
			;;
	esac
	temp=`mktemp`
	cat > $temp << __EOF__
[Unit]
Description=VMware Shared Folders
Requires=$requires.service
After=$requires.service
ConditionPathExists=/mnt/hgfs
ConditionVirtualization=vmware

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/vmhgfs-fuse -o allow_other -o auto_unmount .host:/ /mnt/hgfs

[Install]
WantedBy=multi-user.target
__EOF__

	sudo mkdir -p /mnt/hgfs
	sudo cp -v $temp /etc/systemd/system/hgfs.service
	rm $temp
	sudo systemctl enable hgfs
	# sudo systemctl start hgfs
}

if [[ $os == Linux ]]; then
	kver=`uname -r`
	kver=(${kver//./ })
	kmajor=${kver[0]}

	which virt-what > /dev/null 2>&1 || $installer virt-what

	vm=`sudo virt-what`

	case "$vm" in
		vmware )
			# open-vm-tools
			if [[ $kmajor -ge 4 ]]; then # really begin with 4.0?
					instal_vm_tools
			fi
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
fi

# Bridge

# VPN
# /usr/lib/networkmanager/nm-l2tp-service --debug

# for (( i = 0; i < 10; i++ )); do
#   git clone https://aur.archlinux.org/package-query.git
#   cd package-query && {
#     makepkg -si || exit 1
#     cd ..
#     break
#   }
# done
#
# for (( i = 0; i < 10; i++ )); do
#   git clone https://aur.archlinux.org/yaourt.git
#   cd yaourt && {
#     makepkg -si
#     cd ..
#     break
#   }
# done
#
# yaourt tree
