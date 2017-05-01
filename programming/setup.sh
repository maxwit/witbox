#!/usr/bin/env bash

function usage {
	echo "options:"
	echo "  -l languages, seperated with comma, supported languages so far:"
	echo "     cxx"
	echo "     csharp"
	echo "     go"
	echo "     java"
	echo "     js"
	echo "     perl"
	echo "     php"
	echo "     python"
	echo "     ruby"
	echo "     rust"
	echo "     scala"
	echo "     swift"
	echo "  -h this help"
	echo
}

while [[ $# -gt 0 ]]; do
	case $1 in
		-l )
			lang_list=(${2//,/ })
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

if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
	declare -A check
fi

declare -a pkg_list

current_group='undefined'

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

if [[ -e $HOME/.bashrc ]]; then
	profile=$HOME/.bashrc
else # FIXME
	profile=$HOME/.bash_profile
	touch $profile
fi

mkdir -p $HOME/.local/bin
grep '^export PATH=$HOME/.local/bin' > /dev/null 2>&1 $profile || {
	echo 'export PATH=$HOME/.local/bin:$PATH' >> $profile
	# export PATH=$HOME/.local/bin:$PATH
}

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

	if [[ $os_dist == macOS ]]; then
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

pm_install pkg_list[@]

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

function setup_lang_cxx {
	set_group 'C/C++'

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

	pm_install pkg_list[@]
}

function setup_lang_csharp {
	set_group 'C#'
}

function setup_lang_go {
	set_group 'Go'

	pkg_list+=('golang')

	pm_install pkg_list[@]
}

function setup_lang_java {
	set_group 'Java and Groovy'

	case $os_dist in
		macOS )
			pkg_list+=(java)
			;;
		redhat|centos|fedora )
			pkg_list+=(java-1.7.0-openjdk-devel java-1.8.0-openjdk-devel)
			;;
		ubuntu|debian )
			pkg_list+=(openjdk-7-jdk openjdk-9-jdk openjdk-8-jdk)
			;;
	esac

	pm_install pkg_list[@]

	case $os_dist in
		redhat|centos|fedora )
			for (( i = 0; i < 10; i++ )); do
				if [ ! -x /usr/java/jdk1.8.0_131/jre/bin/java ]; then
					[ -e jdk-8u131-linux-x64.rpm ] || \
						wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm
					$installer jdk-8u131-linux-x64.rpm && break
				fi
			done
			;;

		# * )
		# 	if [[ $os == Linux ]]; then
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

	case "$os_dist" in
		macOS )
			brew tap homebrew/php
			pkg_list+=(php56)
			;;
		redhat|centos )
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

	case $os_dist in
		redhat|centos )
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
		python${pydef} -m pip --version > /dev/null 2>&1 && break
		curl https://bootstrap.pypa.io/get-pip.py | sudo -H python${pydef}
	done

	if [ $os_dist == macOS ]; then
		wrapper_sh="$HOME/Library/Python/2.7/bin/virtualenvwrapper.sh"
	else
		wrapper_sh="$HOME/.local/bin/virtualenvwrapper.sh"
	fi

	for (( i = 0; i < 10; i++ )); do
		[[ -e $wrapper_sh ]] && break
		python${pydef} -m pip install --user virtualenvwrapper
	done

	if [[ -n "$pydef" ]]; then
		grep VIRTUALENVWRAPPER_PYTHON $profile > /dev/null || \
			echo "export VIRTUALENVWRAPPER_PYTHON=`which python${pydef}`" >> $profile
	fi

	grep virtualenvwrapper.sh $profile > /dev/null || {
		# workon_home='/opt/virtualenvs'
		# sudo mkdir -p $workon_home
		# sudo chown $USER $workon_home
		# sudo chmod go+rx $workon_home
		# echo "export WORKON_HOME=$workon_home" >> $profile
		echo ". $wrapper_sh" >> $profile
		. $profile
	}
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


function setup_editor_unix {
	set_group 'VIM/Emacs'

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

function setup_editor_ide {
	set_group 'Atom/Code/Sublime'

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

	pm_install pkg_list[@]
}

# call setup handler
for lang in ${lang_list[@]}; do
	setup_lang_$lang
done

# setup_editor_unix
# setup_editor_ide

echo
echo "Done!"
echo
