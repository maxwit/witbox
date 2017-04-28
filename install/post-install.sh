#!/usr/bin/env bash

if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
	declare -A check
fi

declare -a pkg_list

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
			ubuntu|debian )
				which apt > /dev/null 2>&1 && pm='sudo apt' || pm='sudo apt-get'
				installer="$pm install -y"
				;;
			redhat|centos|fedora )
				if [[ $os_dist == fedora ]]; then
					# need epel?
					pm='sudo dnf'
				else
					if [[ $version -ge 7 ]]; then
						which dnf > /dev/null 2>&1 || sudo yum install -y yum-utils || {
							echo 'fail to install yum-utils!'
							exit 1
						}
						pm='sudo dnf'
					else
						pm='sudo yum'
					fi
					if [[ ! -e /etc/yum.repos.d/ius.repo ]]; then
						curl https://setup.ius.io/ | sudo bash
					fi
					# if [[ ! -e /etc/yum.repos.d/remi.repo ]]; then
					# 	yum install -y http://rpms.famillecollet.com/enterprise/remi-release-${version}.rpm
					# fi
				fi
				installer="$pm install -y"
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

case $os in
	Linux )
		case $os_dist in
			redhat|centos )
				pkg_list+=(git2u)
				;;
		* )
				pkg_list+=(git)
				;;
		esac
		;;
esac

pkg_list+=(subversion)

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

case $os in
	Linux )
		case $os_dist in
			redhat|centos )
				# 	echo FIXME: use remi/scl instead
				pkg_list+=(php56u)
				;;
			* )
				pkg_list+=(php)
				;;
		esac
		;;
	Darwin )
		pkg_list+=(homebrew/php/composer)
esac

# TODO: install composer

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
				if [ $os_dist == fedora -o $version -ge 7 ]; then
					sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
					sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
					pkg_list+=(code)
				fi
				# VIM
				pkg_list+=(vim-enhanced)
				check[vim-enhanced]=vim # or vimdiff
			;;
			ubuntu|debian )
				# Code
				curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
				sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
				sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
				pkg_list+=(code)
				# VIM
				pkg_list+=(vim-gtk3) # FIXME for old ubuntu/debian
				check[vim-gtk3]=vim.gtk3
			;;
		esac
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
				$pm update -y
				$pm upgrade -y
				;;
			redhat|centos|fedora )
				$pm update -y
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

cat > ~/.vimrc << __EOF__
set nu
set ts=4
set hlsearch
let c_space_errors=1
let java_space_errors=1
__EOF__

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

function instal_vm_tools() {
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

exit 0

# spacemacs

cat > ~/.emacs << EOF
(global-linum-mode t)
EOF

echo
