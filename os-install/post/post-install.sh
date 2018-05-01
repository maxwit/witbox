#!/usr/bin/env bash

if [[ $UID -eq 0 ]]; then
	echo "do NOT run as root!"
	exit 1
fi

# if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
# 	declare -A check
# fi

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
		sudo $pm update -y
		# sudo $pm autoremove -y libreoffice-common
		sudo $pm upgrade -y
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
			# if [[ $version -ge 7 ]]; then
			# 	which dnf > /dev/null 2>&1 || sudo yum install -y yum-utils || {
			# 		echo 'fail to install yum-utils!'
			# 		exit 1
			# 	}
			# 	pm='dnf'
			# 	installer="sudo dnf --allowerasing install -y"
			# else
			# 	# TODO: add source repo
				pm='yum'
				installer="sudo yum install -y"
			# fi

			# if [[ ! -e /etc/yum.repos.d/ius.repo ]]; then
			# 	curl https://setup.ius.io/ | sudo bash
			# 	sudo yum install -y yum-plugin-replace
			# fi
			# if [[ ! -e /etc/yum.repos.d/remi.repo ]]; then
			# 	yum install -y http://rpms.famillecollet.com/enterprise/remi-release-${version}.rpm
			# fi
			# and SCL ?
		fi
		$installer yum-plugin-fastestmirror
		# $pm update -y
		;;

	archlinux)
		tmp_dir=`mktemp -d`

		for repo in package-query yaourt; do
			if which $repo > /dev/null 2>&1; then
				echo "$repo has been installed."
				break
			fi

			for (( i = 0; i < 10; i++ )); do
				git clone https://aur.archlinux.org/$repo.git $tmp_dir/$repo
				cd $tmp_dir/$repo && {
					for (( i = 0; i < 10; i++ )); do
						makepkg -si --noconfirm && break
					done
					break
				}
			done
		done
		;;

	# macOS: make sure SIP disabled
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

sudo sh -c "echo '$USER ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers.d/$USER"

$installer tree

function install_vm_tools() {
	$installer open-vm-tools || exit 1

	for s in open-vm-tools vmtoolsd vmware-vmblock-fuse; do
		if systemctl list-unit-files | grep $s > /dev/null; then
			requires=$s.service
			break
		fi
	done

	if [[ -z "$requires" ]]; then
		echo "no vm service found!"
		exit 1
	fi

	temp=`mktemp`
	cat > $temp << __EOF__
[Unit]
Description=VMware Shared Folders
Requires=$requires
After=$requires
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
	sudo cp $temp /etc/systemd/system/hgfs.service
	rm $temp
	sudo systemctl enable --now hgfs
}

function enable_auto_login() {
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
		sudo cp $temp /etc/gdm/custom.conf
		rm $temp
}

case $os in
	Linux)
		if [[ -e /etc/gdm/custom.conf ]]; then
			enable_auto_login
		fi

		$installer vim openssh-server

		case $os_dist in
			ubuntu|debian )
				sudo update-alternatives --set editor /usr/bin/vim.basic
				;;
			redhat|centos|fedora )
				sudo ln -svf /usr/bin/vim /bin/vi
				sudo systemctl enable --now ssh
				;;
		esac

		which virt-what > /dev/null 2>&1 || $installer virt-what || exit 1
		vm=`sudo virt-what`
		case "$vm" in
			vmware )
				install_vm_tools
				;;
			# xen
			# kvm
			# hyperv
			# parallels
			# qemu
			# virtualbox
		esac
		;;

	# TODO: robust
	Darwin)
		brew install bash
		brew install bash-completion
		sudo sh -c 'echo /usr/local/bin/bash >> /etc/shells'
		sudo chpass -s /usr/local/bin/bash $USER
		echo 'export CLICOLOR=1' > ~/.bashrc
		echo '[ -f $(brew --prefix)/etc/bash_completion ] && . $(brew --prefix)/etc/bash_completion' >> ~/.bashrc
		echo 'source ~/.bashrc' > ~/.bash_profile

		# FIXME
		for pkg in findutils gnu-tar gnu-sed gawk; do
			brew install --with-default-names $pkg
			echo "export PATH=/usr/local/opt/$pkg/libexec/gnubin:\$PATH" >> ~/.bashrc
		done
		;;

	# BSD)
esac

inode=(`ls -l ~/.viminfo`)
if [[ ${inode[2]} != $USER ]]; then
	rm -vf ~/.viminfo
fi

test -e ~/.vimrc || cat > ~/.vimrc << __EOF__
syntax on
set hlsearch
set nu
__EOF__

$installer python3 || exit 1
curl https://bootstrap.pypa.io/get-pip.py | sudo -H python3

user_site=`python3 -m site --user-site`
user_path="${user_site/\/lib\/python*}/bin"
echo "export PATH=$user_path:\$PATH" >> ~/.bashrc
