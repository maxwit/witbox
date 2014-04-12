#!/bin/sh

SERVER="192.168.1.1"
GITADMIN="gitolite-admin"

check_out()
{
	cd

	echo "$1:"

	if [ -d $1 ]; then
		cd $1 && git pull
	else
		git clone git@${SERVER}:$1.git $1
	fi
}

check_out ${GITADMIN}
echo

for dir in `grep repo ~/${GITADMIN}/conf/gitolite.conf | sed -e 's/repo //' -e 's/gitolite-admin//'`
do
	check_out $dir
	echo
done
