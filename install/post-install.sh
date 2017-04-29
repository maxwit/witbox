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

echo -e "### Setup for $os_dist ###\n"

# get installer ready
case $os_dist in
	ubuntu|debian )
		which apt > /dev/null 2>&1 && pm='sudo apt' || pm='sudo apt-get'
		installer="$pm install -y"
		$pm update -y
		$pm upgrade -y
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
				pm='sudo dnf --allowerasing'
			else
				pm='sudo yum'
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
		installer="$pm install -y"
		$pm update -y
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

if [[ -e $HOME/.bashrc ]]; then
	profile=$HOME/.bashrc
elif [[ -e $HOME/.bash_profile ]]
	profile=$HOME/.bash_profile
else
	profile=$HOME/.bashrc
	touch $profile
fi

grep '^export PATH=$HOME/.local/bin:$PATH' > /dev/null 2>&1 $profile || {
	echo 'export PATH=$HOME/.local/bin:$PATH' >> $profile
	export PATH=$HOME/.local/bin:$PATH
}

# log="$HOME/witbox-post-install.log"
# echo > $log

function install_pkgs() {
	echo "[$group]"

	count=${#pkg_list[@]}
	echo -n "$count packages to be installed: "
	if [[ $count -gt 0 ]]; then
		echo "${pkg_list[@]}" | sed 's/ /, /g'
	else
		echo "(skipped)"
		return
	fi

	# for pkg in $@; do
	# 	if [[ -z "${exe[$pkg]}" ]]; then
	# 		exe=$pkg
	# 	else
	# 		exe=${check[$pkg]}
	# 	fi
	#
	# 	loc=`which $exe`
	# done

	if [[ $os_dist == macOS ]]; then
		tmp_list=()
		for pkg in ${pkg_list[@]}; do
			result=`brew cask search $pkg`
			if [[ "${result:0:15}" == '==> Exact match' ]]; then # which one is better?
				tmp_list+=("Caskroom/cask/$pkg")
				# installer="brew cask install"
			else
				tmp_list+=($pkg)
				# installer="brew install"
			fi
		done
		pkg_list=(${tmp_list[@]})
	fi

	echo "Installing ${pkg_list[@]} ..."
	for (( i = 0; i < 3; i++ )); do
		$installer ${pkg_list[@]} && break
	done
	# if [[ $i -eq 3 ]]; then
	# 	echo "[F] $pkg" >> $log
	# fi
}

group="SCM"
pkg_list=()

case "$os_dist" in
	macOS )
		;;
	redhat|centos )
		pkg_list+=(git2u)
		pkg_list+=(subversion)
		;;
	* )
		pkg_list+=(git)
		pkg_list+=(subversion)
		;;
esac

install_pkgs

if [[ ! -e ~/.gitconfig ]]; then
	case $os in
		Linux )
			fullname=$(awk -F : -v user=$USER '$1==user {print $5}' /etc/passwd)
			fullname=${fullname/,*}
			;;
		macOS )
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
fi

group="C/C++"
pkg_list=()

case $os in
	Linux )
		pkg_list+=(gcc)
		case $os_dist in
			redhat|centos|fedora )
				pkg=gcc-c++
				pkg_list+=($pkg)
				# check[$pkg]=g++
				;;
			* )
				pkg_list+=(g++)
				;;
		esac
		;;
esac

pkg_list+=(cmake)

# TODO: conan and clang

install_pkgs

group="C#"

group="Go"

group="Java and Groovy"

group="JavaScript"

group="Perl"

group="PHP"
pkg_list=()

case "$os_dist" in
	redhat|centos )
		# use remi/scl instead?
		pkg_list+=(php56u)
		;;

	* )
		pkg_list+=(php)
		;;
esac

install_pkgs

# FIXME
for (( i = 0; i < 10; i++ )); do
  [[ -e $HOME/.local/bin/composer ]] && break
  curl -o composer-setup.php https://getcomposer.org/installer || continue
  php composer-setup.php --install-dir=$HOME/.local/bin --filename=composer
  rm composer-setup.php
done

group="Python"
pkg_list=()

# TODO: Anaconda supprt
pycur=(`python --version 2>&1 | awk '{print $2}' | sed 's/\./ /g'`)
pynew=""
if [ ${pycur[0]} == 2 ] && [ ${pycur[1]} -lt 7 ]; then
	pkg_list+=(python27)
	pynew=2.7
fi

case $os_dist in
	redhat|centos )
		pkg_list+=(python35u python35u-devel) # FIXME: do not hardcode the version
		;;
	ubuntu )
		pkg_list+=(python3 python3-dev)
		;;
	* )
		pkg_list+=(python3)
		;;
esac

install_pkgs

for (( i = 0; i < 10; i++ )); do
	which pip${pynew} > /dev/null 2>&1 && break
	curl https://bootstrap.pypa.io/get-pip.py | sudo -H python${pynew}
done

wrapper_sh="$HOME/.local/bin/virtualenvwrapper.sh"

for (( i = 0; i < 10; i++ )); do
	[[ -e $wrapper_sh ]] && break
	pip${pynew} install --user virtualenvwrapper
done

if [[ -n "$pynew" ]]; then
	grep VIRTUALENVWRAPPER_PYTHON $profile > /dev/null || \
		echo "export VIRTUALENVWRAPPER_PYTHON=`which python${pynew}`" >> $profile
fi

grep WORKON_HOME $profile > /dev/null || {
	workon_home='/opt/virtualenvs'
	sudo mkdir -p $workon_home
	sudo chown $USER $workon_home
	sudo chmod go+rx $workon_home
	echo "export WORKON_HOME=$workon_home" >> $profile

	echo "source $wrapper_sh" >> $profile

	source $profile
}

group="Ruby"

group="Rust"

group="Scala"

group="Swift"

group="TypeScript"

group="VIM/Emacs"
pkg_list=()

case "$os_dist" in
	macOS )
		;;
	redhat|centos|fedora )
		pkg_list+=(vim-enhanced)
		# check[vim-enhanced]=vim # or vimdiff
		;;
	ubuntu|debian )
		pkg_list+=(vim-gtk3) # FIXME for old ubuntu/debian
		# check[vim-gtk3]=vim.gtk3
		;;
	* )
		pkg_list+=(vim)
		;;
esac

install_pkgs

[[ ! -e ~/.vimrc ]] &&	cat > ~/.vimrc << __EOF__
set nu
set ts=4
set hlsearch
let c_space_errors=1
let java_space_errors=1
__EOF__

# spacemacs

# cat > ~/.emacs << EOF
# (global-linum-mode t)
# EOF

# Compilers and build tools #

group='Atom/Code/Sublime'
pkg_list=()

case $os_dist in
	macOS )
		pkg_list+=(atom visual-studio-code sublime-text)
		# check[visual-studio-code]=code
		# check[sublime-text]=subl
		;;

	redhat|centos|fedora )
		# VS Code
		if [ $os_dist == fedora -o $version -ge 7 ]; then
			if [ ! -e /etc/yum.repos.d/vscode.repo ]; then
				sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
				# sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
				temp=`mktemp`
				cat > $temp << __EOF__
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
__EOF__
				sudo cp $temp /etc/yum.repos.d/vscode.repo
				rm $temp
			fi
			pkg_list+=(code)
		fi
	;;

	ubuntu|debian )
		# VS Code
		if [[ ! -e /etc/apt/sources.list.d/vscode.list ]]; then
			curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
			sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
			sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
			sudo $pm update -y
		fi
		pkg_list+=(code)
	;;
esac

# git_list[atom]='https://github.com/atom/atom.git'

install_pkgs

# # update repo
#
# case $os in
# 	Linux )
# 		case "$os_dist" in
# 			ubuntu|debian )
# 				$pm update -y
# 				$pm upgrade -y
# 				;;
# 			redhat|centos|fedora )
# 				$pm update -y
# 				;;
# 		esac
# 		;;
# 	macOS )
# 		echo "TODO: brew update?"
# 		;;
# esac

exit 0

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
