#!/bin/bash

#sudo passwd root
#sudo visudo 

dist=`lsb_release -si`

case "$dist" in
Ubuntu|Debian)
	sudo apt-get upgrade -y
	sudo ln -svf bash /bin/sh
	sudo update-alternatives --set editor /usr/bin/vim.basic
	sudo apt-get install -y git gcc g++ vim
	# FIXME with dpkg-reconfigure
	;;
*) # FIXME
	sudo yum install -y http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
	sudo yum install -y git gcc gcc-c++ vim
	# FIXME
	sudo cp -v /usr/bin/vim /bin/vi
	;;
esac

for part in `ls /dev/sda[0-9]*`
do
	index=${part#/dev/sda}
	sudo mkdir -vp /mnt/$index
done

sudo mount LABEL=maxwit /mnt && {
	sudo umount /mnt
	sudo mkdir -p /maxwit
	grep "LABEL=maxwit" /etc/fstab || sudo sed -i '$a\LABEL=maxwit /maxwit ext4 defaults 0 0' /etc/fstab
	sudo mount /maxwit
}

sudo groupadd -g 3000 devel
sudo groupadd -g 5000 maxwit
sudo usermod -g devel -a -G maxwit $USER
sudo groupdel $USER

groups=`groups`
groups=${groups/$USER /}
groups=${groups// /,}
sudo useradd -g devel -G maxwit,$groups -c "Ting Yang" ting
sudo passwd ting 

echo
echo "****************************************"
echo "*       Please reboot now!             *"
echo "****************************************"
echo
