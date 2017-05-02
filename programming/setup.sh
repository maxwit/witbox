#!/usr/bin/env bash

lang_support_list=(cxx csharp go java js perl php python ruby rust scala swift)
lang_install_list=(${lang_support_list[@]})

editor_support_list=(vim atom vscode sublime)
editor_install_list=(${editor_support_list[@]})

if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
	declare -A check
fi
declare -a pkg_list

current_group='undefined'

os_kernel=`uname -s`
# zone=`timedatectl | grep 'Time zone' | awk '{print $3}'`

alias curl='curl --connect-timeout 30'

function usage {
	echo   "options:"

	echo   "  -l languages   seperated with comma, supported languages so far:"
	for lang in ${lang_support_list[@]}; do
		echo "                 $lang"
	done

	echo   "  -e editors     seperated with comma, supported editors so far:"
	for editor in ${editor_support_list[@]}; do
		echo "                 $editor"
	done

	echo   "  -h             this help"
	echo
}

while [[ $# -gt 0 ]]; do
	case $1 in
		-l )
			lang_install_list=(${2//,/ })
			for (( i = 0; i < ${#lang_install_list[@]}; i++ )); do
				lang1=`tr [:upper:] [:lower:] <<< ${lang_install_list[$i]}`
				case $lang1 in
					c|c++ )
						lang1=cxx
						;;
					c#|cs )
						lang1=csharp
						;;
					golang )
						lang1=go
						;;
					javascript|ts|typescript )
						lang1=js
						;;
				esac
				# TODO: check valid
				if [[ $lang1 != ${lang_install_list[$i]} ]]; then
					lang_install_list[$i]=$lang1
				fi
			done
			shift
			;;

		-e )
			editor_install_list=(${2//,/ })
			for (( i = 0; i < ${#editor_install_list[@]}; i++ )); do
				editor1=`tr [:upper:] [:lower:] <<< ${editor_install_list[$i]}`
				case $editor1 in
					vi )
						editor1=vim
						;;
					code )
						editor1=vscode
						;;
					subl )
						editor1=sublime
						;;
				esac
				# TODO: check valid
				if [[ $editor1 != ${editor_install_list[$i]} ]]; then
					editor_install_list[$i]=$editor1
				fi
			done
			shift
			;;

		-h )
			usage
			exit 0
			;;

		* )
			echo "invalid option '$1'"
			usage
			exit 1
			;;
	esac

	shift
done

# get OS info
case $os_kernel in
	Linux )
		if [ -e /etc/os-release ]; then
			. /etc/os-release
			os_type=$ID
			os_name=$NAME
			os_version=$VERSION_ID # none on ArchLinux
		elif [ -e /etc/redhat-release ]; then
			dist=(`head -n 1 /etc/redhat-release`)
			os_type=`tr A-Z a-z <<< ${dist[0]}`
			os_name=${dist[0]}
			os_version=${dist[2]}
		else
			echo -e "Unkown Linux distribution!\n"
			exit 1
		fi
		;;

	Darwin )
		os_type='macOS'
		os_name=`sw_vers -productName`
		os_version=`sw_vers -productVersion`
		;;

	FreeBSD )
		os_type='FreeBSD'
		os_name='FreeBSD'
		os_version=`uname -r | awk -F '-' '{print $1}'`
		;;

	* )
		echo -e "OS '$os_kernel' not supported yet!\n"
		exit 1
esac

echo -e "### Setup for $os_name $os_version ###\n"

case $os_type in
	macOS )
		for (( i = 0; i < 10; i++ )); do
			if which brew > /dev/null 2>&1; then
				echo 'HomeBrew has been installed.'
				break
			fi
			/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		done
		pm='brew'
		installer="brew install"
		# TODO: update/upgrade ?
		;;

	ubuntu|debian )
		which apt > /dev/null 2>&1 && pm='apt' || pm='apt-get'
		installer="sudo $pm install -y"
		# $pm update -y
		# $pm upgrade -y
		;;

	rhel|centos|fedora )
		if [[ $os_type == fedora ]]; then
			# need epel?
			pm='dnf'
			installer="sudo dnf --allowerasing install -y"
		else
			major_version=${os_version%%.*}
			if [[ $major_version -ge 7 ]]; then
				for (( i = 0; i < 10; i++ )); do
					if which dnf > /dev/null 2>&1; then
						echo "yum-utils has been installed."
						break
					fi
					sudo yum install -y yum-utils
				done
				pm='dnf'
				installer="sudo dnf --allowerasing install -y"
			else
				pm='yum'
				installer="sudo yum install -y"
				# TODO: add source repo
			fi
			# ISU
			if [[ ! -e /etc/yum.repos.d/ius.repo ]]; then
				curl https://setup.ius.io/ | sudo bash
				$installer yum-plugin-replace
			fi
			# Remi
			for (( i = 0; i < 10; i++ )); do
				if [[ -e /etc/yum.repos.d/remi.repo ]]; then
					echo "remi.repo has been installed"
					break
				fi
				$installer http://rpms.famillecollet.com/enterprise/remi-release-${major_version}.rpm
			done
			# and SCL ?
		fi
		# $pm update -y
		;;

	arch )
		pm='pacman'
		installer='sudo pacman -S --noconfirm'
		# yaourt
		for repo in package-query yaourt; do
			if which $repo > /dev/null 2>&1; then
				echo "$repo has been installed."
			else
				tmp_dir=`mktemp -d`
				for (( i = 0; i < 10; i++ )); do
					[[ -e $tmp_dir/$repo ]] && break
					git clone https://aur.archlinux.org/$repo.git $tmp_dir/$repo
				done
				cd $tmp_dir/$repo && {
					makepkg -si --noconfirm
					cd -
				}
				rm -rf $tmp_dir
			fi
		done
		;;

	FreeBSD )
		pm='pkg'
		installer='pkg install -y'
		;;

	*)
		echo "OS '$os_type' not supported yet!"
		exit 1
		;;
esac

if [[ -e $HOME/.bashrc ]]; then
	profile=$HOME/.bashrc
else # FIXME
	profile=$HOME/.bash_profile
	touch $profile
fi

for dir in bin etc include lib lib64 opt run sbin share usr usr/share var; do
	if [[ ! -e /usr/local/$dir ]]; then
		sudo mkdir -p /usr/local/$dir
		sudo chown $USER /usr/local/$dir
	fi
done

# log="$HOME/witbox-post-install.log"
# echo > $log

function set_group {
	current_group="$@"
	pkg_list=()

	echo "[$current_group]"
}

function pm_install {
	local pkgs=("${!1}")
	local count=${#pkgs[@]}

	if [[ $count -eq 0 ]]; then
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

	if [[ $os_type == macOS ]]; then
		for (( i = 0; i < $count; i++ )); do
			pkg=${pkgs[$i]}
			result=`brew cask search $pkg`
			if [[ "${result:0:15}" == '==> Exact match' ]]; then
				pkgs[$i]="Caskroom/cask/$pkg" # brew cask install
			fi
		done
	fi

	# for (( i = 0; i < 3; i++ )); do
		echo "$pm install ${pkgs[@]} ..."
		$installer ${pkgs[@]} # && break
	# done
	# if [[ $i -eq 3 ]]; then
	# 	echo "[F] $pkg" >> $log
	# fi
}

set_group 'SCM'

case "$os_type" in
	macOS )
		;;
	rhel|centos )
		pkg_list+=(git2u)
		pkg_list+=(subversion)
		;;
	* )
		pkg_list+=(git)
		pkg_list+=(subversion)
		;;
esac

pm_install pkg_list[@]

if [[ ! -e ~/.gitconfig ]]; then
	case $os_kernel in
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

function setup_lang_cxx {
	set_group 'C/C++'

	case $os_kernel in
		Linux )
			pkg_list+=(gcc)
			case $os_type in
				rhel|centos|fedora )
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

	if which cmake > /dev/null 2>&1; then
		echo "CMake has been installed."
	else
		pkg_list+=(cmake)
	fi

	# TODO: conan and clang

	pm_install pkg_list[@]
}

function setup_lang_csharp {
	set_group 'C#'
}

function setup_lang_go {
	set_group 'Go'

	case $os_type in
		arch )
			pkg_list+=('go')
			;;
		* )
			pkg_list+=('golang')
			;;
	esac

	pm_install pkg_list[@]
}

function setup_lang_java {
	set_group 'Java and Groovy'

	case $os_type in
		macOS )
			pkg_list+=(java)
			;;
		rhel|centos|fedora )
			pkg_list+=(java-1.7.0-openjdk-devel java-1.8.0-openjdk-devel)
			;;
		ubuntu|debian )
			pkg_list+=(openjdk-7-jdk openjdk-9-jdk openjdk-8-jdk)
			;;
		arch )
			pkg_list+=(jdk7-openjdk jdk8-openjdk)
			;;
	esac

	pm_install pkg_list[@]

	case $os_type in
		rhel|centos|fedora )
			for (( i = 0; i < 10; i++ )); do
				if [ ! -x /usr/java/jdk1.8.0_131/jre/bin/java ]; then
					[ -e jdk-8u131-linux-x64.rpm ] || \
						wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm
					$installer jdk-8u131-linux-x64.rpm && break
				fi
			done
			;;

		# * )
		# 	if [[ $os_kernel == Linux ]]; then
		# 		wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
		# 	fi
		# 	;;
	esac
}

function setup_lang_js {
	set_group 'JavaScript'

	echo "Installing nvm ..."
	export NVM_DIR="$HOME/.nvm"
	for (( i = 0; i < 10; i++ )); do
		# 'source $profile' does not work, why?
		if [ -n "$NVM_DIR" ] && [ -s $NVM_DIR/nvm.sh ]; then
			break
		fi
		curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
	done

	[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
	[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

	echo "Installing node ..."
	for (( i = 0; i < 10; i++ )); do
		[ -x $NVM_BIN/node ] && break
		nvm install node
		nvm use node
	done

	echo "Installing TypeScript ..."
	# safe?
	for (( i = 0; i < 10; i++ )); do
		[ -x $NVM_BIN/tsc ] && break
		npm install -g typescript
	done
}

function setup_lang_perl {
	set_group 'Perl'
}

function setup_lang_php {
	set_group 'PHP'

	case "$os_type" in
		macOS )
			brew tap homebrew/php
			pkg_list+=(php56)
			;;
		rhel|centos )
			# use remi/scl instead?
			pkg_list+=(php56u)
			;;

		* )
			pkg_list+=(php)
			;;
	esac

	pm_install pkg_list[@]

	# # FIXME
	# for (( i = 0; i < 10; i++ )); do
	#   [[ -e $HOME/.local/bin/composer ]] && break
	#   curl -o composer-setup.php https://getcomposer.org/installer || continue
	# 	# wget -c -O composer-setup.php https://getcomposer.org/installer || continue
	#   php composer-setup.php --install-dir=$HOME/.local/bin --filename=composer
	#   rm composer-setup.php
	# done
	#
	# mkdir -p $HOME/.composer/vendor/bin
	# grep '^export PATH=$HOME/.composer/vendor/bin:$PATH' > /dev/null 2>&1 $profile || {
	# 	echo 'export PATH=$HOME/.composer/vendor/bin:$PATH' >> $profile
	# }
}

function setup_lang_python {
	set_group 'Python'

	# TODO: Anaconda supprt
	pycur=(`python --version 2>&1 | awk '{print $2}' | sed 's/\./ /g'`)
	pydef=""
	if [ ${pycur[0]} == 2 ] && [ ${pycur[1]} -lt 7 ]; then
		pkg_list+=(python27)
		pydef=2.7
	fi

 # FIXME
	case $os_type in
		rhel|centos )
			pkg_list+=(python${pydef/./}-devel python35u python35u-devel) # FIXME: do not hardcode the version
			;;
		ubuntu )
			pkg_list+=(python${pydef/./}-dev python3 python3-dev)
			;;
		* )
			pkg_list+=(python3)
			;;
	esac

	pm_install pkg_list[@]

	for (( i = 0; i < 10; i++ )); do
		if python${pydef} -m pip --version > /dev/null; then
			echo "pip has been installed."
			break
		fi
		curl https://bootstrap.pypa.io/get-pip.py | sudo -H python${pydef}
	done

	alias pip="python${pydef} -m pip"

	for (( i = 0; i < 10; i++ )); do
		if pip show virtualenvwrapper > /dev/null;  then
			echo "virtualenvwrapper has been installed."
			break
		fi
		pip install --user virtualenvwrapper
	done

	if [[ -n "$pydef" ]]; then
		sed -i.orig '/VIRTUALENVWRAPPER_PYTHON/d' $profile
		echo "export VIRTUALENVWRAPPER_PYTHON=`which python${pydef}`" >> $profile
	fi

	# workon_home='/opt/virtualenvs'
	# sudo mkdir -p $workon_home
	# sudo chown $USER $workon_home
	# sudo chmod go+rx $workon_home
	# echo "export WORKON_HOME=$workon_home" >> $profile

	wrapper_site=`pip show virtualenv | awk '$1=="Location:" {print $2}'`
	# readlink --canonicalize not work for BSD
	# wrapper_path=`readlink --canonicalize $wrapper_site/../../../bin/virtualenvwrapper.sh`

	# FIXME: to move above
	user_site_bin=$wrapper_site/../../../bin
	if [[ ! -d $user_site_bin ]]; then
		echo 'should never run here!'
		echo "user site bin: $user_site_bin"
		return
	fi
	cd $user_site_bin
	user_site_bin=$PWD
	cd -


	if [ -e $user_site_bin/virtualenvwrapper.sh ]; then
		wrapper_path=$user_site_bin/virtualenvwrapper.sh
	else
		echo "fail to install virtualenvwrapper!"
		return
	fi

	sed -i.orig '/virtualenvwrapper.sh/d' $profile

	if [[ $HOME${wrapper_path#$HOME} == $wrapper_path ]]; then
		sed -i.orig ":\$HOME${user_site_bin#$HOME}:d" $profile
		echo "export PATH=\$HOME${user_site_bin#$HOME}:\$PATH" >> $profile

		echo ". \$HOME${wrapper_path#$HOME}" >> $profile
	else
		sed -i.orig ":${user_site_bin}:d" $profile
		echo "export PATH=$user_site_bin:\$PATH" >> $profile

		echo ". $wrapper_path" >> $profile
	fi
}

function setup_lang_ruby {
	set_group 'Ruby'

	for (( i = 0; i < 10; i++ )); do
		[ -s $HOME/.rvm/scripts/rvm ] && break
		curl -sSL https://get.rvm.io | bash -s stable --ruby
		# curl -sSL https://get.rvm.io | bash -s stable
	done

	# . $profile
	#
	# for (( i = 0; i < 10; i++ )); do
	# 	rvm install ruby
	# done
}

function setup_lang_rust {
	set_group 'Rust'

	# https://www.rust-lang.org/en-US/other-installers.html

	for (( i = 0; i < 10; i++ )); do
		[ -x $HOME/.cargo/bin/rustc ] && break
		curl -sSf https://sh.rustup.rs | bash -s -- -y
	done
}

function setup_lang_scala {
	set_group 'Scala'
}

function setup_lang_swift {
	set_group 'Swift'
}


function setup_editor_vim {
	set_group 'VIM'

	case "$os_type" in
		macOS )
			;;
		rhel|centos|fedora )
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

	pm_install pkg_list[@]

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
}

function setup_editor_atom {
	set_group 'Atom'

	which atom > /dev/null 2>&1 && {
		echo "Atom has been installed."
		return
	}

	case $os_type in
		macOS )
			pkg_list+=(atom)
			;;

		rhel|centos|fedora )
			;;

		ubuntu|debian )
			;;

		arch )
			pkg_list+=(atom)
			;;
	esac

	# git_list[atom]='https://github.com/atom/atom.git'

	pm_install pkg_list[@]

	# TODO: add extensions
}

function setup_editor_vscode {
	set_group 'VSCode'

	which code > /dev/null 2>&1 && {
		echo "Visual Studio Code has been installed."
		return
	}

	case $os_type in
		macOS )
			pkg_list+=(visual-studio-code)
			;;

		rhel|centos|fedora )
			if [ $os_type == fedora -o $version -ge 7 ]; then
				if [ ! -e /etc/yum.repos.d/vscode.repo ]; then
					sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
					temp=`mktemp`
					cat > $temp << __EOF__
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
__EOF__
					sudo install -m 0644 $temp /etc/yum.repos.d/vscode.repo
					rm $temp
				fi
				pkg_list+=(code)
			fi
			;;

		ubuntu|debian )
			if [[ ! -e /etc/apt/sources.list.d/vscode.list ]]; then
				curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
				sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
				sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
				sudo $pm update -y
			fi
			pkg_list+=(code)
			;;

		arch )
			echo 1 | yaourt visual-studio-code # FIXME
			;;
	esac

	pm_install pkg_list[@]

	# TODO: add extensions
}

function setup_editor_sublime {
	set_group 'Sublime'

	for (( i = 0; i < 10; i++ )); do
		if which subl > /dev/null 2>&1; then
			echo 'Sublime has been installed.'
			break
		fi

		case $os_type in
			macOS )
				$installer sublime-text
				;;

			rhel|centos|fedora )
				;;

			ubuntu|debian )
				;;

			arch )
				echo 1 | yaourt sublime-text # FIXME
				;;
			* )
				return
				;;
		esac
	done
}

# call setup handler
for lang in ${lang_install_list[@]}; do
	setup_lang_$lang
done

for editor in ${editor_install_list[@]}; do
	setup_editor_$editor
done

echo
echo "Done."
echo "please exit current terminal and re-open a new one!"
echo
