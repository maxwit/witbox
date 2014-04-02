#!/bin/sh

TOP_DIR="$HOME"
SERVER="192.168.1.1"
GITADMIN="gitolite-admin"

check_out()
{
	cd $TOP_DIR

	echo "$1:"

	if [ -d $1 ]; then
		cd $1 && git pull
	else
		git clone git@${SERVER}:$1.git $1
	fi
}

check_out ${GITADMIN}
echo

DIRS=`grep repo $TOP_DIR/${GITADMIN}/conf/gitolite.conf | sed -e 's/repo //' -e 's/gitolite-admin//'`

for dir in $DIRS
do
	check_out $dir
	echo
done
