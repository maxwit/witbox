#!/bin/sh

git_setup()
{
	sudo yum install git git-daemon

	path="$HOME/.ssh"

	git config --list | grep ^color.ui || \
	git config --global color.ui auto

	if [ ! -x "$path" ]; then
			exit 1
	else
		sudo sed -i '/\:OUTPUT ACCEPT \[0\:0\]/a\-I INPUT -p tcp --dport 9418 -j ACCEPT' /etc/sysconfig/iptables
		sudo /etc/init.d/iptables restart
		sudo sed -i '$a\git daemon --reuseaddr --base-path=/server/git/repositories &' /etc/rc.local

		sudo useradd -d /server/git git
		echo "please input passwd to set git passwd"
		sudo passwd git
		cp $path/*.pub /tmp

		cd /tmp
		git clone git://github.com/sitaramc/gitolite
		echo "please input git passwd"
		su git -c 'mkdir -p /server/git/bin'
		su git -c '/tmp/gitolite/install -to /server/git/bin'
		su git -c '/server/git/bin/gitolite setup -pk /tmp/*.pub'
	fi
	return
}

cups_setup()
{
	HPLIP_VER="3.13.5"

	if [ ! -e /maxwit/soruce/hplip-${HPLIB_VER}.tar.gz ]; then
		wget -c -P /maxwit/soruce http://prdownloads.sourceforge.net/hplip/hplip-${HPLIB_VER}.tar.gz
	fi
}

samba_setup()
{
	return
}

mysql_setup()
{
	sudo yum install mysql mysql-server

	mysqladmin -u root password maxwit2013

	return
}

apache_setup()
{
	return
}


nfs_setup()
{
	return
}

git_setup
cups_setup
samba_setup
mysql_setup
apache_setup
nfs_setup
