#!/bin/sh

TOP_DIR=$PWD
BUILD_PATH="/maxwit/build"
SOURCE_PATH="/maxwit/source"
distr="ubuntu"

WGET="wget -c -P $SOURCE_PATH"

git_setup()
{
	if [ "$distr" == centos ]; then
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
	else
		sudo apt-get install git git-daemon-run
		sudo cp $TOP_DIR/run /etc/sv/git-daemon/run
		path="$HOME/.ssh"

		if [ ! -x "$path" ]; then
				exit 1
		else
			sudo useradd -d /server/git git
			echo "please input passwd to set git passwd"
			sudo passwd git
			sudo mkdir /server/git
			sudo chown git:git /server/git
			cp $path/*.pub /tmp

			cd /tmp
			git clone git://github.com/sitaramc/gitolite
			echo "please input git passwd"
			su git -c 'mkdir -p /server/git/bin'
			su git -c '/tmp/gitolite/install -to /server/git/bin'
			su git -c '/server/git/bin/gitolite setup -pk /tmp/*.pub'
		fi
	fi
}

cups_setup()
{
	HPLIP_VER="3.13.5"

	if [ "$distr" == centos ]; then
		sudo yum install -y cups
		sudo chkconfig cups on
		sudo yum remove -y hplip hplip-common
	else
		sudo apt-get install cups libcups2-dev libusb-1.0-0-dev python-dev libcupsimage2-dev
		sudo apt-get remove -y hplip hplip-common
	fi

	if [ ! -e $SOURCE_PATH/hplip-${HPLIP_VER}.tar.gz ]; then
		$WGET http://ncu.dl.sourceforge.net/project/hplip/hplip/3.13.5/hplip-${HPLIP_VER}.tar.gz
	fi

	if [ ! -e $SOURCE_PATH/hplip-${HPLIP_VER}-plugin.run ]; then
		$WGET http://www.openprinting.org/download/printdriver/auxfiles/HP/plugins/hplip-${HPLIP_VER}-plugin.run
	fi

	if [ ! -e $BUILD_PATH/hplip-${HPLIP_VER}/.powertool_built ]; then
		cd $BUILD_PATH
		if [ "$distr" == centos ]; then
			tar xvf $SOURCE_PATH/hplip-${HPLIP_VER}.tar.gz && \
			cd hplip-${HPLIP_VER} && \
			./configure --with-hpppddir=/usr/share/ppd/HP \
				--libdir=/usr/lib64 \
				--prefix=/usr \
				--enable-udev-acl-rules \
				--enable-qt4 \
				--disable-libusb01_build \
				--enable-doc-build \
				--disable-cups-ppd-install \
				--disable-foomatic-drv-install \
				--disable-foomatic-ppd-install \
				--disable-hpijs-install \
				--disable-udev_sysfs_rules \
				--disable-policykit \
				--enable-cups-drv-install \
				--enable-hpcups-install \
				--enable-network-build \
				--enable-dbus-build \
				--enable-scan-build \
				--enable-fax-build \
				&& \
			make && \
			sudo make install && \
			touch $BUILD_PATH/hplip-${HPLIP_VER}/.powertool_built || exit 1
		else
			tar xvf $SOURCE_PATH/hplip-${HPLIP_VER}.tar.gz && \
			cd hplip-${HPLIP_VER} && \
			./configure --with-hpppddir=/usr/share/ppd/HP \
				--libdir=/usr/lib64 \
				--prefix=/usr \
				--enable-udev-acl-rules \
				--enable-qt4 \
				--disable-libusb01_build \
				--enable-doc-build \
				--disable-cups-ppd-install \
				--disable-foomatic-drv-install \
				--disable-foomatic-ppd-install \
				--disable-hpijs-install \
				--disable-udev_sysfs_rules \
				--disable-policykit \
				--enable-cups-drv-install \
				--enable-hpcups-install \
				--disable-network-build \
				--enable-dbus-build \
				--disable-scan-build \
				--enable-fax-build \
				&& \
			make && \
			sudo make install && \
			touch $BUILD_PATH/hplip-${HPLIP_VER}/.powertool_built || exit 1
		fi
	fi

	cd $BUILD_PATH
	cp -v $SOURCE_PATH/hplip-${HPLIP_VER}-plugin.run . && \
	patch -p0 < $TOP_DIR/hplip-${HPLIP_VER}-plugin.patch && \
	chmod +x hplip-${HPLIP_VER}-plugin.run && \
	sudo ./hplip-${HPLIP_VER}-plugin.run --nox11 < $TOP_DIR/plugin || exit 1
}

samba_setup()
{
	if [ "$distr" == centos ]; then
		sudo yum install samba samba-client samba-common

		sudo chkconfig smb on
		sudo sed -i '/\:OUTPUT ACCEPT \[0\:0\]/a\-A INPUT -p udp --dport 137 -j ACCEPT\n-A INPUT -p udp --dport 138 -j ACCEPT\n-A INPUT -m state --state NEW -m tcp -p tcp --dport 139 -j ACCEPT\n-A INPUT -m state --state NEW -m tcp -p tcp --dport 445 -j ACCEPT' /etc/sysconfig/iptables
		sudo /etc/init.d/iptables restart

		sudo sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

		cp /etc/samba/smb.conf /tmp
		cat $TOP_DIR/samba >> /tmp/smb.conf
		sudo cp /tmp/smb.conf /etc/samba/smb.conf
		sudo /etc/init.d/smb start
	else
		sudo apt-get install samba

		sudo sed -i "292,299 s/guest ok = no/valid users = @maxwit/g" /etc/samba/smb.conf
		cp /etc/samba/smb.conf /tmp
		cat $TOP_DIR/samba >> /tmp/smb.conf
		sudo cp /tmp/smb.conf /etc/samba/smb.conf

		sudo service smbd start
	fi
}

mysql_setup()
{
	if [ "$distr" == centos ]; then
		sudo yum install mysql mysql-server
		sudo chkconfig mysqld on

		mysqladmin -u root password maxwit2013

		sudo /etc/init.d/mysqld start
	else
		sudo apt-get install mysql-server mysql-client mysql-common

		sudo service mysql start
	fi
}

apache_setup()
{
	if [ "$distr" == centos ]; then
		sudo yum install httpd httpd-devel php php-mysql python mod_wsgi MySQL-python
		sudo chkconfig httpd on

		sudo sed -i '/\:OUTPUT ACCEPT \[0\:0\]/a\-A INPUT -p tcp --dport 80 -j ACCEPT' /etc/sysconfig/iptables
		sudo cp $TOP_DIR/wsgi.conf /etc/httpd/conf.d/wsgi.conf -v

		sudo /etc/init.d/iptables restart
		sudo /etc/init.d/httpd start
	else
		sudo apt-get install apache2 libapache2-mod-python libapache2-mod-auth-mysql

		sudo cp $TOP_DIR/python.conf /etc/apache2/mods-available/ && sudo ln -s ../mods-available/python.conf /etc/apache2/mods-enabled/python.conf
		sudo sed -i '/<Directory \/var\/www\/>/a\\t\tAddHandler mod_python .py\n\t\tPythonHandler index\n\t\tPythonDebug On' /etc/apache2/sites-enabled/000-default
		sudo cp $TOP_DIR/index.py /var/www/

		sudo service apache2 restart
	fi
}


nfs_setup()
{
	mkdir /maxwit/pub

	if [ "$distr" == centos ]; then
		sudo yum install nfs-utils portmap
		sudo chkconfig nfs on

		echo '#MaxWit NFS' >> /tmp/exports
		echo '/maxwit/pub *(rw,async)' >> /tmp/exports
		echo '/maxwit/source *(ro,async)' >> /tmp/exports
		sudo cp /tmp/exports /etc
		sudo chmod 0777 /maxwit/pub

		sudo sed -i '$a\MOUNTD_PORT="4002"\nSTATD_PORT="4003"\nLOCKD_TCPPORT="4004"\nLOCKD_UDPPORT="4004"' /etc/sysconfig/nfs
		sudo sed -i '/\:OUTPUT ACCEPT \[0\:0\]/a\-A INPUT -p udp --dport 2049 -j ACCEPT\n-A INPUT -p tcp --dport 2049 -j ACCEPT\n-A INPUT -p udp --dport 111 -j ACCEPT\n-A INPUT -p tcp --dport 111 -j ACCEPT\n-A INPUT -m state --state NEW -m tcp -p tcp --dport 4002:4004 -j ACCEPT\n-A INPUT -m state --state NEW -m udp -p udp --dport 4002:4004 -j ACCEPT' /etc/sysconfig/iptables

		sudo /etc/init.d/iptables restart
		sudo /etc/init.d/rpcbind start
		sudo /etc/rc.d/init.d/nfs start
	else
		sudo apt-get install nfs-kernel-server

		cp /etc/exports /tmp
		echo '#MaxWit NFS' >> /tmp/exports
		echo '/maxwit/pub *(rw,async)' >> /tmp/exports
		echo '/maxwit/source *(ro,async)' >> /tmp/exports
		sudo cp /tmp/exports /etc
		sudo chmod 777 /maxwit/pub
		sudo service nfs-kernel-server start
	fi
}

git_setup
#cups_setup
#samba_setup
#mysql_setup
#apache_setup
#nfs_setup
