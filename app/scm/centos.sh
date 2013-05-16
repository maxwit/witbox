#!/bin/sh
#

# fixme

path="$HOME/.ssh"

git config --list | grep ^color.ui || \
	git config --global color.ui auto

echo "$user"
echo $USER
if [ ! -x "$path" ]; then 
	exit 1
else
	sudo sed -i '/\:OUTPUT ACCEPT \[0\:0\]/a\-I INPUT -p tcp --dport 9418 -j ACCEPT' /etc/sysconfig/iptables
	sudo /etc/init.d/iptables restart
	sudo sed -i '$a\git daemon --reuseaddr --base-path=/home/git/repositories &' /etc/rc.local

	sudo adduser git
	echo "please input git passwd"
	sudo passwd git
	cd ~
	git clone git://github.com/sitaramc/gitolite
	sudo mkdir -p /home/git/bin
	sudo gitolite/install -to /home/git/bin
	sudo /home/git/bin/gitolite setup -pk `find .ssh -name *.pub`
	sudo chown git:git /home/git -R
fi
