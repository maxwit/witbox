#!/bin/sh

git_setup()
{
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
