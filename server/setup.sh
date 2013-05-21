#!/bin/sh

TOP_DIR=$PWD
BUILD_PATH="/maxwit/build"
SOURCE_PATH="/maxwit/source"

WGET="wget -c -P $SOURCE_PATH"

git_setup()
{
	return
}

cups_setup()
{
	HPLIP_VER="3.13.5"

	if [ ! -e $SOURCE_PATH/hplip-${HPLIP_VER}.tar.gz ]; then
		$WGET http://ncu.dl.sourceforge.net/project/hplip/hplip/3.13.5/hplip-${HPLIP_VER}.tar.gz
	fi

	if [ ! -e $SOURCE_PATH/hplip-${HPLIP_VER}-plugin.run ]; then
		$WGET http://www.openprinting.org/download/printdriver/auxfiles/HP/plugins/hplip-${HPLIP_VER}-plugin.run
	fi

	if [ ! -e $BUILD_PATH/.powertool_built ]; then
		cd $BUILD_PATH
		tar xvf $SOURCE_PATH/hplip-${HPLIP_VER}.tar.gz && \
		cd hplip-${HPLIP_VER} && \
		./configure --prefix=/usr && \
		make && \
		sudo make install && touch $BUILD_PATH/.powertool_built || exit 1
	fi

	cd $BUILD_PATH
	cp -v $SOURCE_PATH/hplip-${HPLIP_VER}-plugin.run . && \
	patch -p0 < $SOURCE_PATH/hplip-${HPLIP_VER}-plugin.patch && \
	chmod +x hplip-${HPLIP_VER}-plugin.run && \
	sudo ./hplip-${HPLIP_VER}-plugin.run --nox11 < $TOP_DIR/plugin || exit 1
}

samba_setup()
{
	return
}

mysql_setup()
{
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
