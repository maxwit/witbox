#!/bin/sh

TOP_DIR="/maxwit"
SERVER="192.168.0.1"
GITADMIN="gitolite-admin"

check_out()
{
	cd $TOP_DIR

	if [ -d $1 ]; then
		cd $1 && git pull
	else
		git clone git@${SERVER}:$1.git $1
	fi
}

check_out ${GITADMIN}
echo

DIRS=`grep repo ${GITADMIN}/conf/gitolite.conf | sed -e 's/repo //' -e 's/gitolite-admin//'`

for dir in $DIRS
do
	check_out $dir
	echo
done
